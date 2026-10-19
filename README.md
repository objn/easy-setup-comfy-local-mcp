# ComfyUI MCP + ChatGPT — Windows Portable

Set up **ComfyUI Windows Portable for NVIDIA**, using its bundled `python_embeded` environment, and connect it to ChatGPT through OpenAI Secure MCP Tunnel.

The setup described here was developed using Windows 11 and an RTX 3080 Ti with 12 GB VRAM. ChatGPT calls Comfy MCP tools through the tunnel, while ComfyUI runs on your computer.

## 1. Prerequisites

- A working ComfyUI Portable installation with the models and custom nodes you need.
- Internet access to install packages, download the tunnel client, and connect to OpenAI.
- An OpenAI Platform account with permission to create and use tunnels.
- A ChatGPT account or workspace that allows adding custom MCP servers and using their plugins.
- The scripts from this repository.

| File | Purpose |
|---|---|
| [Install-and-Run.cmd](./Install-and-Run.cmd) | Double-click to install MCP and start ComfyUI. |
| [Install-and-Run.ps1](./Install-and-Run.ps1) | PowerShell script used by the MCP setup launcher. |
| [Setup-Tunnel.cmd](./Setup-Tunnel.cmd) | Download, install, configure, and start the tunnel for the first time. |
| [Run-Tunnel.cmd](./Run-Tunnel.cmd) | Start a previously configured tunnel. |
| [Tunnel.ps1](./Tunnel.ps1) | PowerShell script for tunnel setup and subsequent runs. |

> These scripts install local software and configure the client. They do not automatically create an OpenAI tunnel, API key, or ChatGPT plugin.

## 2. Prepare ComfyUI first

1. Follow the [ComfyUI Windows Portable documentation](https://docs.comfy.org/installation/comfyui_portable_windows) and download the appropriate NVIDIA Portable package.
2. Extract it to a location such as `F:\ComfyUI_windows_portable`.
3. Install or update your NVIDIA driver as required by that ComfyUI package.
4. Start ComfyUI using its supplied launcher, such as `run_nvidia_gpu.bat`.
5. Confirm that `http://127.0.0.1:8188` opens.
6. Install models in their appropriate folders according to the workflow instructions, along with any required custom nodes.
7. Successfully run at least one workflow in ComfyUI before proceeding.

If you already have a working Portable installation, use it and skip the download.

The ComfyUI startup command used by these scripts is:

```powershell
.\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build
```

The scripts assume port `8188`. If you use another port or additional startup arguments, update the scripts and `COMFY_LOCAL_URL` accordingly.

## 3. Get the scripts and place them correctly

### Option A: Clone with Git

Open PowerShell and clone the repository. Replace the example URL with the actual repository URL:

```powershell
git clone https://github.com/YOUR-USER/YOUR-REPO.git
cd YOUR-REPO
```

Copy all five scripts into your Portable root:

```powershell
$PortableRoot = 'F:\ComfyUI_windows_portable'
$ScriptFiles = @(
    'Install-and-Run.cmd',
    'Install-and-Run.ps1',
    'Setup-Tunnel.cmd',
    'Run-Tunnel.cmd',
    'Tunnel.ps1'
)
Copy-Item -LiteralPath $ScriptFiles -Destination $PortableRoot
```

### Option B: Download individual files

Open each script link in the table above and use GitHub's **Download raw file** button. Download all five files and ensure Windows does not append `.txt` to their names.

Place the scripts alongside `python_embeded` and `ComfyUI`:

| File or folder | Example location |
|---|---|
| Bundled Python | `F:\ComfyUI_windows_portable\python_embeded\` |
| Existing ComfyUI and models | `F:\ComfyUI_windows_portable\ComfyUI\` |
| MCP setup launcher | `F:\ComfyUI_windows_portable\Install-and-Run.cmd` |
| MCP setup PowerShell script | `F:\ComfyUI_windows_portable\Install-and-Run.ps1` |
| Tunnel setup launcher | `F:\ComfyUI_windows_portable\Setup-Tunnel.cmd` |
| Tunnel run launcher | `F:\ComfyUI_windows_portable\Run-Tunnel.cmd` |
| Tunnel PowerShell script | `F:\ComfyUI_windows_portable\Tunnel.ps1` |

**Run the scripts from the Portable root, alongside `python_embeded` and `ComfyUI`. Do not place them inside `ComfyUI` or run them from a separate clone outside the Portable installation.**

## 4. Install Comfy MCP and start ComfyUI

Double-click **`Install-and-Run.cmd`**.

The script will:

1. Check the bundled Python interpreter and pip.
2. Install `comfy-mcp` and `comfy-cli>=1.14.0` into that Python environment.
3. Register your existing ComfyUI folder using `comfy set-default`.
4. Read package versions using `importlib.metadata`.
5. Generate `Start-Comfy-MCP.cmd` and `comfy-mcp-config.json`.
6. Start ComfyUI using the existing startup command, or reuse a ComfyUI instance already running on port 8188.

It reuses your ComfyUI installation and models. Pip may adjust shared dependencies to satisfy the installed packages.

For manual installation, the main command is:

```powershell
.\python_embeded\python.exe -s -m pip install comfy-mcp "comfy-cli>=1.14.0"
```

**Keep the ComfyUI window open.** Once the server is ready, open `http://127.0.0.1:8188`.

### Generated files

- `Start-Comfy-MCP.cmd`: a stdio MCP entry point for an MCP client. Starting it manually may produce no output while it waits for protocol messages.
- `comfy-mcp-config.json`: an example configuration for clients that accept `mcpServers`. This file is not imported directly into the ChatGPT web interface.
- For the ChatGPT setup in this guide, the tunnel client launches `comfy-mcp.exe`. You do not need to start `Start-Comfy-MCP.cmd` separately.

## 5. Required permissions and where to request them

OpenAI Platform permissions, API key permissions, and ChatGPT plugin permissions are separate.

| Action | Required permissions | Where to configure or request access |
|---|---|---|
| View tunnel information | Tunnels Read | OpenAI Platform organization owner or RBAC administrator. |
| Create or edit a tunnel | Tunnels Read + Manage | Administrator of the same Platform organization. |
| Run the tunnel client | Tunnels Read + Use and a runtime key with sufficient access | Platform organization administrator and API key settings. |
| Select a tunnel when adding MCP | Tunnels Read + Use and the correct workspace association | Platform tunnel settings and the relevant administrator. |
| Add and use a custom MCP plugin in ChatGPT | Permission to create, install, and use custom MCP integrations for the account or workspace | ChatGPT workspace owner or administrator, where applicable. |
| Write local files and run scripts | Read/write access to the Portable folder and permission to execute programs | Your Windows account or device administrator if organizational policies apply. |

The Portable scripts normally do not require **Run as administrator**. The `.cmd` launchers use `-ExecutionPolicy Bypass` only for the PowerShell process they start; they do not change the persistent execution policy.

For personal accounts, select the personal Platform organization associated with your account. If the Tunnels page reports insufficient access, resolve the organization-level permissions first. Selecting `All` for an API key does not grant permissions your account lacks.

**A ChatGPT subscription alone does not establish tunnel access or permission to add custom MCP servers in every workspace.** Check the actual options and permissions available to your account.

## 6. Create a tunnel in OpenAI Platform

1. Open [Platform → Tunnels](https://platform.openai.com/settings/organization/tunnels).
2. Select the intended organization.
3. Create a tunnel, for example `comfy mcp private`.
4. Associate it with the Platform organization and the ChatGPT workspace where you will use the plugin.
5. Copy its `tunnel_...` ID for the setup script.

Use the same tunnel ID in both the script and ChatGPT's custom MCP configuration.

Use the **Tunnel** connection option and its tunnel ID. Do not copy an internal OpenAI URL from an error message into the public Server URL field.

## 7. Create a runtime API key

Open [Platform → Organization API Keys](https://platform.openai.com/settings/organization/api-keys) under the organization that owns the tunnel.

A runtime API key authenticates the tunnel client to OpenAI while it polls for requests and posts responses. It is separate from your ChatGPT password and any Comfy API key.

Suggested settings:

| Field | Setting |
|---|---|
| Owned by | `You` for personal use. |
| Name | For example, `Comfy Tunnel`. |
| Project | A project in the relevant organization. |
| Expiration | Choose an expiration appropriate for your use. |
| Permissions | `Restricted`. |
| Tunnels | `Read` + `Use`. |
| Tunnels Manage | Not required for scripts that use an existing tunnel. |
| Model inference, Files, and other permissions | Not required just to transport these MCP requests. |

If the UI uses different labels, select the equivalent of Tunnels Read + Use and check the organization-level permissions as well.

Create the key and paste it into the script's hidden prompt. **Do not share it in chat or screenshots.**

The scripts pass the key through the process environment as `CONTROL_PLANE_API_KEY` and do not write it to a file. Subsequent runs prompt again unless that variable is already available in the environment.

An Admin API key is not required for a runtime client that only uses an existing tunnel.

## 8. Install and start the tunnel for the first time

With ComfyUI running, double-click **`Setup-Tunnel.cmd`**.

The script will:

1. Download the latest standard Windows `tunnel-client` release from `openai/tunnel-client` if no installed executable is present.
2. Verify its SHA256 against the release's `SHA256SUMS.txt` before using the download.
3. Extract and install the client under `tunnel-tools`.
4. Ask for the tunnel ID you created earlier.
5. Ask for the runtime API key using a hidden prompt.
6. Create the `comfy-local` profile.
7. Check ComfyUI and run `doctor`.
8. Start the tunnel and wait for requests.

The MCP command is:

```text
./python_embeded/Scripts/comfy-mcp.exe
```

Forward slashes prevent the command parser from consuming Windows path backslashes. The working directory is set to the Portable root.

**Use `Setup-Tunnel.cmd` for initial setup. After setup succeeds, use `Run-Tunnel.cmd`.** Running Setup again reuses the installed binary rather than forcing an update, and the client may reject creation of a profile that already exists.

If downloading is blocked or a suitable Windows asset cannot be selected, the script stops with an error. Review that message before continuing.

## 9. Check tunnel readiness

Open:

- [Tunnel UI](http://127.0.0.1:8080/ui)
- [Readiness](http://127.0.0.1:8080/readyz)

Or run this in another terminal:

```powershell
curl.exe -i http://127.0.0.1:8080/readyz
```

Expected response:

```text
HTTP/1.1 200 OK

ready
```

Startup messages observed during setup included:

```text
RESULT ok
poller started
tunnel metadata fetched
🟢 tunnel-client started
```

These confirm client startup and reported readiness. **Make an actual tool call from ChatGPT to verify the complete connection.**

## 10. Add Comfy MCP to ChatGPT

In the ChatGPT account or workspace associated with the tunnel:

1. Open Plugins and select `+` → **Add custom MCP server**.
2. Enter a name, such as `comfy mcp private`.
3. Set Connection to **Tunnel**.
4. Select the existing tunnel or enter its `tunnel_...` ID.
5. Set Authentication to **No authentication**.
6. Read the risk notice, verify the details, and acknowledge it.
7. Select **Create as a plugin** and install the plugin.
8. Select the plugin in chat using `@` and test it.

Menu names may vary with the UI and your account permissions.

### Why use No authentication?

The stdio Comfy MCP server in this setup does not expose OAuth. You do not need an OAuth client ID or client secret.

The runtime API key authenticates the tunnel client to OpenAI. The Authentication field in the custom MCP form refers to authentication with the MCP server itself, which is a separate layer.

### Test prompt

```text
Use comfy mcp private to call server_info and check my ComfyUI instance.
```

Look for an actual tool result reporting ComfyUI status. A plain-text response without a tool call does not verify the connection.

After `server_info` succeeds, inspect models and nodes or test an existing workflow.

## 11. Start it on subsequent days

Normal startup order:

1. Start ComfyUI using your existing Portable launcher and wait for it to become available on port 8188.
2. Double-click **`Run-Tunnel.cmd`**.
3. Enter the runtime API key when prompted.
4. Check readiness if needed.
5. Open ChatGPT and select the installed plugin.
6. Begin with `server_info`.

You do not need to reinstall MCP or recreate the tunnel or plugin each time.

Keep both ComfyUI and the tunnel running. ChatGPT cannot reach your computer after you shut it down or stop the tunnel.

For stdio, run **only one active tunnel-client instance per tunnel ID**. Stop the old instance before starting another so related session requests do not reach separate MCP processes.

## 12. Troubleshooting

| Symptom | Explanation or next step |
|---|---|
| Setup hangs at `[3/4]` after printing the CLI version | An earlier script ran `comfy-mcp.exe --version`, which waited for stdio messages. Use the current script, which reads versions through `importlib.metadata`. |
| `.python_embededScriptscomfy-mcp.exe` cannot be found | The command parser consumed backslashes. Use the corrected command: `./python_embeded/Scripts/comfy-mcp.exe`. |
| `does not implement OAuth` | This MCP server does not expose OAuth. Select No authentication. An OAuth discovery response alone does not establish why plugin creation failed. |
| `unsupported channel "harpoon"` | A request reached Harpoon without a registered target. Comfy MCP uses `main`. This can occur during OAuth discovery; distinguish it from the actual plugin creation error. Do not add arbitrary targets to suppress the message. |
| No new logs when creating the plugin | This alone does not prove that requests failed to arrive. Check readiness and the Network response for the creation request. |
| Statsig `ERR_BLOCKED_BY_CLIENT` | The browser or an extension blocked that request. It does not by itself prove the cause of an MCP connection failure. |
| Tunnel appears in Platform but not ChatGPT | Check the ChatGPT workspace association, selected organization, and Tunnels Read + Use permissions. |
| `401` or `403` | Inspect that request's response. Check the key, expiration, organization, and permissions before replacing the key. |
| `codex_plugin ... SKIP` | The Codex plugin is optional for the ChatGPT connection described here. |
| MCP runs but image generation fails | Check `server_info`, models, custom nodes, and workflow dependencies separately from tunnel connectivity. |

### If ChatGPT cannot create the plugin

1. Complete the form and select No authentication.
2. Open DevTools with F12 → Network and clear the request list.
3. Click Create once.
4. Inspect requests that fail after the click. Record the request name, status code, and response.
5. Compare the timestamp with new tunnel logs.

Do not share cookies, Authorization headers, API keys, or HAR files containing secrets.

Local testing during development confirmed successful `initialize` and `tools/list` responses from Comfy MCP. Use a successful ChatGPT tool call as evidence that the complete connection works.

## 13. Repository maintenance

Keep the scripts at the same level as this README and preserve their filenames so relative links and launchers work correctly.

- Replace `https://github.com/YOUR-USER/YOUR-REPO.git` with the actual repository URL.
- Do not commit API keys, profiles containing personal information, Python environments, models, or downloaded runtime files.
- The supplied `.gitignore` excludes runtime directories and generated setup files.
- `.gitattributes` specifies CRLF for CMD/PowerShell files and LF for Markdown.
- The scripts accept API keys through a hidden prompt and do not write them to files.
- When modifying the scripts, test setup, repeated runs, readiness, and actual ChatGPT tool calls on Windows.

Observed during development: packages installed, ComfyUI started, the tunnel started, `/readyz` returned `200 ready`, and local MCP `initialize` and `tools/list` calls succeeded. Verify the full connection with a tool call from the intended ChatGPT account.

## References

- [ComfyUI Windows Portable](https://docs.comfy.org/installation/comfyui_portable_windows)
- [Official Comfy MCP](https://github.com/Comfy-Org/comfy-mcp)
- [OpenAI Secure MCP Tunnel](https://developers.openai.com/api/docs/guides/secure-mcp-tunnels)
- [Tunnel client releases](https://github.com/openai/tunnel-client/releases/latest)
- [Tunnel client configuration](https://github.com/openai/tunnel-client/blob/master/docs/configuration.md)
- [Connector behavior and channel routing](https://github.com/openai/tunnel-client/blob/master/docs/connectors.md)
- [Add a custom MCP server to ChatGPT](https://developers.openai.com/api/docs/guides/custom-mcp-server)
