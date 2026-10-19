# Run from the ComfyUI Portable root (beside python_embeded and ComfyUI).
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-Location -LiteralPath $PSScriptRoot

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed (exit $LASTEXITCODE): $Program" }
}

try {
    $Python = Join-Path $PSScriptRoot 'python_embeded\python.exe'
    $ComfyRoot = Join-Path $PSScriptRoot 'ComfyUI'
    if (!(Test-Path -LiteralPath $Python) -or !(Test-Path -LiteralPath (Join-Path $ComfyRoot 'main.py'))) {
        throw 'Extract both setup files into the Portable root, beside python_embeded and ComfyUI. Do not put them inside ComfyUI.'
    }

    Write-Host '[1/4] Checking embedded Python...' -ForegroundColor Cyan
    Invoke-Checked $Python @('-s', '-c', 'import sys; print(sys.version); sys.exit(0 if sys.version_info >= (3,10) else 1)')
    Invoke-Checked $Python @('-s', '-m', 'pip', '--version')

    Write-Host '[2/4] Installing Comfy MCP and comfy-cli (internet required)...' -ForegroundColor Cyan
    Invoke-Checked $Python @('-s', '-m', 'pip', 'install', '--disable-pip-version-check', 'comfy-mcp', 'comfy-cli>=1.14.0')

    $Cli = Join-Path $PSScriptRoot 'python_embeded\Scripts\comfy.exe'
    $Mcp = Join-Path $PSScriptRoot 'python_embeded\Scripts\comfy-mcp.exe'
    if (!(Test-Path -LiteralPath $Cli) -or !(Test-Path -LiteralPath $Mcp)) {
        throw 'Installation did not create the expected executables in python_embeded\Scripts.'
    }
    $env:COMFY_BIN = $Cli
    $env:COMFY_LOCAL_URL = 'http://127.0.0.1:8188'
    Write-Host '[3/4] Registering existing ComfyUI and checking MCP...' -ForegroundColor Cyan
    Invoke-Checked $Cli @('set-default', $ComfyRoot)
    # Read metadata only: never start the stdio server for a version check.
    Invoke-Checked $Python @('-s', '-c', "from importlib.metadata import version; print('comfy-cli:', version('comfy-cli')); print('comfy-mcp:', version('comfy-mcp'))")

    # A reusable stdio entry point for an MCP client or tunnel.
    # Keep stdout clean: no echo, pause, or installation output here.
    $Launcher = @'
@echo off
setlocal
cd /d "%~dp0"
set "COMFY_BIN=%~dp0python_embeded\Scripts\comfy.exe"
set "COMFY_LOCAL_URL=http://127.0.0.1:8188"
"%~dp0python_embeded\Scripts\comfy-mcp.exe"
exit /b %errorlevel%
'@
    # ASCII launcher uses only relative paths; supports non-ASCII installation roots.
    Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Start-Comfy-MCP.cmd') -Value $Launcher -Encoding Ascii
    $Config = @{ mcpServers = @{ 'comfy-mcp' = @{
        command = $Mcp
        env = @{ COMFY_BIN = $Cli; COMFY_LOCAL_URL = $env:COMFY_LOCAL_URL }
    } } }
    $Config | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'comfy-mcp-config.json') -Encoding UTF8

    Write-Host '[4/4] MCP installed. Starting ComfyUI...' -ForegroundColor Green
    Write-Host 'MCP entry point: Start-Comfy-MCP.cmd (for your MCP client/tunnel)'
    Write-Host 'Client config: comfy-mcp-config.json'
    Write-Host 'ChatGPT connection still requires separate tunnel setup.'
    Write-Host 'ComfyUI: http://127.0.0.1:8188'

    # Reuse an existing live ComfyUI, but do not mistake another HTTP server for it.
    $AlreadyRunning = $false
    try {
        $Stats = Invoke-RestMethod -Uri 'http://127.0.0.1:8188/system_stats' -TimeoutSec 3
        $AlreadyRunning = $null -ne $Stats.PSObject.Properties['system']
    } catch { }
    if ($AlreadyRunning) {
        Write-Host 'ComfyUI is already running; reusing it.' -ForegroundColor Green
        Start-Process 'http://127.0.0.1:8188'
        [void](Read-Host 'Setup finished. Press Enter to close')
    } else {
        Write-Host 'Keep this window open while ComfyUI is running. Ctrl+C stops it.'
        Invoke-Checked $Python @('-s', 'ComfyUI\main.py', '--windows-standalone-build')
    }
} catch {
    Write-Host "`nSetup stopped: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Copy the error above if you need help.'
    [void](Read-Host 'Press Enter to close')
    exit 1
}
