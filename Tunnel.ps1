param([switch]$Setup)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-Location -LiteralPath $PSScriptRoot
$Tools = Join-Path $PSScriptRoot 'tunnel-tools'
$Client = Join-Path $Tools 'tunnel-client.exe'
$IdFile = Join-Path $Tools 'tunnel-id.txt'
$Profile = 'comfy-local'
$HadKey = Test-Path Env:CONTROL_PLANE_API_KEY

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed (exit $LASTEXITCODE). Review the output above." }
}

try {
    $Cli = Join-Path $PSScriptRoot 'python_embeded\Scripts\comfy.exe'
    $Mcp = Join-Path $PSScriptRoot 'python_embeded\Scripts\comfy-mcp.exe'
    if (!(Test-Path -LiteralPath $Cli) -or !(Test-Path -LiteralPath $Mcp)) {
        throw 'Put these scripts beside python_embeded and ComfyUI. Install Comfy MCP first.'
    }
    $env:COMFY_BIN = $Cli
    $env:COMFY_LOCAL_URL = 'http://127.0.0.1:8188'
    $env:PATH = (Split-Path -Parent $Cli) + ';' + $env:PATH

    if ($Setup) {
        New-Item -ItemType Directory -Path $Tools -Force | Out-Null
        if (!(Test-Path -LiteralPath $Client)) {
            Write-Host '[1/4] Finding latest official Windows release...' -ForegroundColor Cyan
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $Headers = @{ 'User-Agent' = 'Comfy-Tunnel-Setup'; Accept = 'application/vnd.github+json' }
            $Release = Invoke-RestMethod -Uri 'https://api.github.com/repos/openai/tunnel-client/releases/latest' -Headers $Headers -TimeoutSec 60
            $Arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { 'arm64|aarch64' } else { 'amd64|x86_64|x64' }
            $Assets = @($Release.assets | Where-Object {
                $_.name -match '^tunnel-client[-_]' -and $_.name -notmatch '^tunnel-client[-_]runtime' -and
                $_.name -match '(?i)windows' -and $_.name -match $Arch -and $_.name -match '\.zip$'
            })
            if ($Assets.Count -ne 1) {
                Write-Host ($Release.assets.name -join "`n")
                throw 'Cannot uniquely select the Windows client ZIP. Download the standard tunnel-client bundle from the official release and put tunnel-client.exe in tunnel-tools.'
            }
            $Asset = $Assets[0]
            $Zip = Join-Path $Tools 'client-download.zip'
            $ChecksumFile = Join-Path $Tools 'SHA256SUMS.txt'
            Write-Host "Downloading $($Release.tag_name): $($Asset.name)"
            Invoke-WebRequest -UseBasicParsing -Uri $Asset.browser_download_url -OutFile $Zip -TimeoutSec 300
            $Sums = @($Release.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' })
            if ($Sums.Count -ne 1) { throw 'Official SHA256SUMS.txt is missing; download will not be executed.' }
            Invoke-WebRequest -UseBasicParsing -Uri $Sums[0].browser_download_url -OutFile $ChecksumFile -TimeoutSec 60
            $Expected = $null
            foreach ($Line in Get-Content -LiteralPath $ChecksumFile) {
                if ($Line -match '^([a-fA-F0-9]{64})\s+\*?(.+?)\s*$') {
                    $HashValue = $Matches[1]
                    $HashName = ($Matches[2] -replace '^\./', '')
                    if ($HashName -ceq $Asset.name) { $Expected = $HashValue; break }
                }
            }
            if (!$Expected -or (Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash -ine $Expected) {
                throw 'SHA256 verification failed; download will not be executed.'
            }
            Write-Host '[2/4] Checksum verified. Installing portable client...' -ForegroundColor Cyan
            $Extract = Join-Path $Tools ('extract-' + [Guid]::NewGuid().ToString('N'))
            Expand-Archive -LiteralPath $Zip -DestinationPath $Extract
            $Executables = @(Get-ChildItem -LiteralPath $Extract -Filter 'tunnel-client.exe' -Recurse -File)
            if ($Executables.Count -ne 1) { throw 'Expected exactly one tunnel-client.exe in the release bundle.' }
            # Preserve any files shipped alongside the executable.
            Copy-Item -Path (Join-Path $Executables[0].Directory.FullName '*') -Destination $Tools -Recurse -Force
            Remove-Item -LiteralPath $Extract -Recurse -Force
            Remove-Item -LiteralPath $Zip
        } else {
            Write-Host '[1-2/4] Reusing installed tunnel-client.exe.' -ForegroundColor Green
        }
        Invoke-Checked $Client @('help', 'quickstart')
        Write-Host '[3/4] Configure tunnel. Create its ID in Platform first.' -ForegroundColor Cyan
        Write-Host 'https://platform.openai.com/settings/organization/tunnels'
        $SavedId = if (Test-Path -LiteralPath $IdFile) { (Get-Content -LiteralPath $IdFile -Raw).Trim() } else { '' }
        $TunnelId = (Read-Host "Tunnel ID (Enter reuses: $SavedId)").Trim()
        if (!$TunnelId) { $TunnelId = $SavedId }
        if ($TunnelId -notmatch '^tunnel_[A-Za-z0-9_-]+$') { throw 'Invalid tunnel ID. Expected tunnel_...' }
    } elseif (!(Test-Path -LiteralPath $Client) -or !(Test-Path -LiteralPath $IdFile)) {
        throw 'Run Setup-Tunnel.cmd first.'
    }

    if ([string]::IsNullOrWhiteSpace($env:CONTROL_PLANE_API_KEY)) {
        $Secret = Read-Host 'OpenAI runtime API key (hidden, not saved)' -AsSecureString
        try { $env:CONTROL_PLANE_API_KEY = [System.Net.NetworkCredential]::new('', $Secret).Password }
        finally { $Secret.Dispose(); Remove-Variable Secret }
        if ([string]::IsNullOrWhiteSpace($env:CONTROL_PLANE_API_KEY)) { throw 'API key is required.' }
    }
    if ($Setup) {
        # Forward slashes survive the MCP command parser; cwd is Portable root.
        Invoke-Checked $Client @('init', '--sample', 'sample_mcp_stdio_local', '--profile', $Profile, '--tunnel-id', $TunnelId, '--mcp-command', './python_embeded/Scripts/comfy-mcp.exe')
        Set-Content -LiteralPath $IdFile -Value $TunnelId -Encoding Ascii
    }
    Write-Host 'Checking ComfyUI...' -ForegroundColor Cyan
    $Stats = Invoke-RestMethod -Uri ($env:COMFY_LOCAL_URL + '/system_stats') -TimeoutSec 5
    if ($null -eq $Stats.PSObject.Properties['system']) { throw 'Port 8188 does not appear to be ComfyUI.' }
    Write-Host '[4/4] Diagnosing tunnel...' -ForegroundColor Cyan
    Invoke-Checked $Client @('doctor', '--profile', $Profile, '--explain')
    Write-Host 'Starting tunnel. Keep ComfyUI and this window open. Ctrl+C stops the tunnel.' -ForegroundColor Green
    Write-Host 'In ChatGPT: Plugins > + > Add custom MCP server > Connection: Tunnel.'
    Write-Host 'Tunnel ID:' (Get-Content -LiteralPath $IdFile -Raw).Trim()
    Invoke-Checked $Client @('run', '--profile', $Profile)
} catch {
    Write-Host "`nTunnel stopped: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Check the output above. No API key is written to a file by this script.'
    exit 1
} finally {
    if (!$HadKey) { Remove-Item Env:CONTROL_PLANE_API_KEY -ErrorAction SilentlyContinue }
}
