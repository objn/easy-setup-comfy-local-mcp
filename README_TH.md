# ComfyUI MCP + ChatGPT — Windows Portable

คู่มือนี้ใช้กับ **ComfyUI Windows Portable สำหรับ NVIDIA** ที่มี `python_embeded` อยู่ในชุดเดียวกัน ตัวอย่างเครื่องที่ใช้ตั้งค่าเป็น Windows 11 และ RTX 3080 Ti 12 GB

เป้าหมาย: ให้ ChatGPT เรียก tools ของ Comfy MCP ผ่าน Secure MCP Tunnel แล้วสั่งงาน ComfyUI ที่รันบนเครื่องผู้ใช้

## 1. สิ่งที่ต้องเตรียม

- ComfyUI Portable ที่เปิดใช้งานได้ และติดตั้ง models / custom nodes ที่ต้องการแล้ว
- อินเทอร์เน็ตสำหรับติดตั้งแพ็กเกจ ดาวน์โหลด Tunnel client และเชื่อมกับ OpenAI
- บัญชี OpenAI Platform ที่มีสิทธิ์สร้างและใช้ Tunnel
- บัญชีหรือ ChatGPT workspace ที่เพิ่ม custom MCP server และใช้งาน plugin ได้
- ดาวน์โหลดหรือ clone repository นี้เพื่อรับสคริปต์ด้านล่าง

| ไฟล์ | หน้าที่ |
|---|---|
| [Install-and-Run.cmd](./Install-and-Run.cmd) | ดับเบิลคลิกเพื่อติดตั้ง MCP และเปิด ComfyUI |
| [Install-and-Run.ps1](./Install-and-Run.ps1) | PowerShell ที่ตัวเรียกติดตั้ง MCP ใช้ |
| [Setup-Tunnel.cmd](./Setup-Tunnel.cmd) | ดาวน์โหลด ติดตั้ง ตั้งค่า และเปิด Tunnel ครั้งแรก |
| [Run-Tunnel.cmd](./Run-Tunnel.cmd) | เปิด Tunnel ที่ตั้งค่าไว้แล้ว |
| [Tunnel.ps1](./Tunnel.ps1) | PowerShell สำหรับ Setup และ Run Tunnel |

> สคริปต์ติดตั้งซอฟต์แวร์ในเครื่องและตั้งค่า client ให้ แต่ไม่ได้สร้าง Tunnel, API key หรือ ChatGPT plugin ให้อัตโนมัติ

## 2. ดาวน์โหลดและเตรียม ComfyUI ให้เรียบร้อยก่อน

1. เปิด [เอกสาร ComfyUI Windows Portable](https://docs.comfy.org/installation/comfyui_portable_windows) และดาวน์โหลดชุด Portable ที่เหมาะกับ NVIDIA
2. แตกไฟล์ไปยังตำแหน่งที่ต้องการ เช่น `F:\ComfyUI_windows_portable`
3. ติดตั้งหรืออัปเดต NVIDIA driver ตามข้อกำหนดของชุด ComfyUI ที่ดาวน์โหลด
4. เปิด ComfyUI ด้วยไฟล์ launcher ของชุด Portable เช่น `run_nvidia_gpu.bat`
5. ตรวจว่าเข้า `http://127.0.0.1:8188` ได้
6. วาง models ตามชนิดของโมเดลและคำแนะนำของ workflow รวมถึงติดตั้ง custom nodes ที่ workflow ต้องใช้
7. ทดลองรัน workflow ใน ComfyUI ให้สำเร็จอย่างน้อยหนึ่งครั้ง

หากมี Portable ที่ทำงานได้อยู่แล้ว ให้ใช้ของเดิมและข้ามการดาวน์โหลดใหม่

คำสั่งเปิด ComfyUI ที่ใช้ในรอบนี้คือ:

```powershell
.\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build
```

สคริปต์ของเราใช้คำสั่งนี้และพอร์ต `8188` หากคุณใช้พอร์ตอื่นหรือมี argument พิเศษ ต้องปรับสคริปต์และ `COMFY_LOCAL_URL` ให้ตรงกัน

## 3. รับสคริปต์จาก GitHub และวางให้ถูกตำแหน่ง

### วิธี A: ใช้ Git

เปิด PowerShell แล้ว clone repository โดยแทน URL ตัวอย่างด้วย URL ของ repository ที่คุณใช้งาน:

```powershell
git clone https://github.com/YOUR-USER/YOUR-REPO.git
cd YOUR-REPO
```

คัดลอกสคริปต์ทั้งห้าไฟล์ไปยัง Portable root ตัวอย่าง:

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

### วิธี B: ดาวน์โหลดไฟล์ทีละไฟล์

เปิดลิงก์สคริปต์ในตารางด้านบน แล้วใช้ **Download raw file** ของ GitHub ให้ครบทั้งห้าไฟล์ ตรวจว่า Windows ไม่เติม `.txt` ต่อท้ายชื่อไฟล์

นำสคริปต์ไปวางข้าง `python_embeded` และ `ComfyUI` เช่น:

| ไฟล์ / โฟลเดอร์ | ตำแหน่งตัวอย่าง |
|---|---|
| Python ของ Portable | `F:\ComfyUI_windows_portable\python_embeded\` |
| ComfyUI และ models เดิม | `F:\ComfyUI_windows_portable\ComfyUI\` |
| ตัวเรียกติดตั้ง MCP | `F:\ComfyUI_windows_portable\Install-and-Run.cmd` |
| PowerShell ติดตั้ง MCP | `F:\ComfyUI_windows_portable\Install-and-Run.ps1` |
| ตัวเรียกติดตั้ง Tunnel | `F:\ComfyUI_windows_portable\Setup-Tunnel.cmd` |
| ตัวเรียกเปิด Tunnel ครั้งถัดไป | `F:\ComfyUI_windows_portable\Run-Tunnel.cmd` |
| PowerShell ของ Tunnel | `F:\ComfyUI_windows_portable\Tunnel.ps1` |

**ให้ไฟล์สคริปต์อยู่ข้าง `python_embeded` และ `ComfyUI` ไม่ใช่อยู่ภายใน `ComfyUI` หรือโฟลเดอร์ repository ที่แยกจาก Portable**

## 4. ติดตั้ง Comfy MCP และเปิด ComfyUI

ดับเบิลคลิก **`Install-and-Run.cmd`**

สคริปต์จะ:

1. ตรวจ Python ของ Portable และ pip
2. ติดตั้ง `comfy-mcp` และ `comfy-cli>=1.14.0` ลงใน Python ตัวเดิม
3. ใช้ `comfy set-default` ระบุโฟลเดอร์ ComfyUI เดิม
4. อ่านเวอร์ชันแพ็กเกจผ่าน `importlib.metadata`
5. สร้าง `Start-Comfy-MCP.cmd` และ `comfy-mcp-config.json`
6. เปิด ComfyUI ด้วยคำสั่งเดิม หรือใช้ ComfyUI ที่เปิดอยู่แล้วบนพอร์ต 8188

ไม่ต้องติดตั้ง ComfyUI ใหม่หรือดาวน์โหลด models ซ้ำ แต่ pip อาจปรับ dependency ที่ใช้ร่วมกันเพื่อให้ตรงตามแพ็กเกจที่ติดตั้ง

หากติดตั้งด้วยตนเอง คำสั่งหลักคือ:

```powershell
.\python_embeded\python.exe -s -m pip install comfy-mcp "comfy-cli>=1.14.0"
```

**เปิดหน้าต่าง ComfyUI ค้างไว้** หลัง server พร้อม ให้เข้า `http://127.0.0.1:8188`

### ไฟล์ที่สร้างขึ้นใช้ทำอะไร

- `Start-Comfy-MCP.cmd`: จุดเรียก MCP แบบ stdio สำหรับ MCP client ไม่ใช่หน้าต่างแชต การเปิดเองอาจเงียบและรอรับข้อมูล
- `comfy-mcp-config.json`: ตัวอย่าง config สำหรับ client ที่รองรับ `mcpServers` ไม่ใช่ไฟล์ที่นำไปวางในหน้า ChatGPT โดยตรง
- การเชื่อม ChatGPT ตามคู่มือนี้ใช้ Tunnel client เรียก `comfy-mcp.exe` ให้ ไม่ต้องดับเบิลคลิกเปิด `Start-Comfy-MCP.cmd` เพิ่ม

## 5. สิทธิ์ที่ต้องมี และขอจากที่ไหน

สิทธิ์ OpenAI Platform, สิทธิ์ API key และสิทธิ์เพิ่ม plugin ใน ChatGPT เป็นคนละส่วน

| สิ่งที่จะทำ | สิทธิ์ที่ต้องมี | จัดการหรือขอจากที่ไหน |
|---|---|---|
| ดูข้อมูล Tunnel | Tunnels Read | OpenAI Platform organization owner / RBAC administrator |
| สร้างหรือแก้ไข Tunnel | Tunnels Read + Manage | ผู้ดูแล organization เดียวกัน |
| รัน Tunnel client | Tunnels Read + Use และ runtime key ที่มีสิทธิ์เพียงพอ | ผู้ดูแล Platform organization และหน้าจัดการ API keys |
| เลือก Tunnel ตอนเพิ่ม MCP | Tunnels Read + Use และการผูก workspace ให้ถูกต้อง | Platform tunnel settings และผู้ดูแลที่เกี่ยวข้อง |
| เพิ่มและใช้ custom MCP plugin ใน ChatGPT | สิทธิ์สร้าง/ติดตั้ง/ใช้ custom MCP ตามบัญชีหรือ workspace | ChatGPT workspace owner / administrator หากเป็น workspace ที่มีผู้ดูแล |
| เขียนไฟล์และรันสคริปต์ในเครื่อง | สิทธิ์อ่าน/เขียนโฟลเดอร์ Portable และรันโปรแกรม | บัญชี Windows ของคุณ หรือผู้ดูแลเครื่องถ้ามีนโยบายองค์กร |

โดยทั่วไปสคริปต์แบบ Portable ไม่ต้อง Run as administrator และไม่เปลี่ยน Execution Policy ถาวร ตัว `.cmd` ใช้ `-ExecutionPolicy Bypass` เฉพาะ PowerShell process ที่เปิดขึ้น

สำหรับบัญชีส่วนตัว ให้เลือก personal Platform organization ของบัญชีนั้น หากหน้า Tunnels แสดงว่าไม่มีสิทธิ์ ต้องแก้สิทธิ์ระดับ organization ก่อน การเลือก `All` ใน API key ไม่ได้เพิ่มสิทธิ์ที่บัญชีไม่มี

**การมีแพ็กเกจ ChatGPT อย่างเดียวไม่ยืนยันว่ามีสิทธิ์ Tunnels หรือเพิ่ม custom MCP ในทุก workspace** ให้ตรวจเมนูและสิทธิ์จริงของบัญชี

## 6. สร้าง Tunnel ใน OpenAI Platform

1. เปิด [Platform → Tunnels](https://platform.openai.com/settings/organization/tunnels)
2. เลือก organization ที่ต้องการใช้งาน
3. สร้าง Tunnel เช่นชื่อ `comfy mcp private`
4. ผูกกับ Platform organization และ ChatGPT workspace ที่จะใช้ plugin
5. คัดลอก ID รูปแบบ `tunnel_...` เก็บไว้กรอกในสคริปต์

ใช้ Tunnel ID เดียวกันทั้งในสคริปต์และหน้าเพิ่ม custom MCP ของ ChatGPT

อย่านำ URL ภายใน OpenAI จากข้อความ error มาใส่เป็น public Server URL ให้ใช้ตัวเลือก **Tunnel** และ Tunnel ID

## 7. สร้าง runtime API key

เปิด [Platform → Organization API Keys](https://platform.openai.com/settings/organization/api-keys) ภายใต้ organization ที่มี Tunnel

runtime API key คือ credential ที่ Tunnel client ใช้ยืนยันตัวตนกับ OpenAI ขณะ polling และส่งผลกลับ ไม่ใช่รหัสผ่าน ChatGPT และไม่ใช่ Comfy API key

ค่าที่ใช้ตอนสร้าง key:

| ช่อง | ค่าที่แนะนำสำหรับงานนี้ |
|---|---|
| Owned by | `You` สำหรับการใช้งานส่วนตัว |
| Name | เช่น `Comfy Tunnel` |
| Project | โปรเจกต์ใน organization ที่เกี่ยวข้อง |
| วันหมดอายุ | เลือกตามระยะเวลาที่ต้องการใช้ |
| Permissions | `Restricted` |
| Tunnels | `Read` + `Use` |
| Tunnels Manage | ไม่จำเป็นสำหรับสคริปต์ที่ใช้ Tunnel ที่สร้างแล้ว |
| สิทธิ์เรียกโมเดล, Files และรายการอื่น | ไม่จำเป็นสำหรับการส่ง MCP ผ่าน Tunnel นี้ |

หากชื่อหรือรูปแบบตัวเลือกต่างจากนี้ ให้ดูรายละเอียดของ Tunnels แล้วเลือกสิทธิ์เทียบเท่า Read + Use พร้อมตรวจสิทธิ์ระดับ organization ด้วย

กดสร้างและคัดลอก key ไปกรอกในช่องซ่อนข้อความของสคริปต์ **ไม่ส่ง key ในแชตหรือใส่ลงภาพหน้าจอ**

สคริปต์ใช้ตัวแปร `CONTROL_PLANE_API_KEY` ใน process โดยไม่เขียน key ลงไฟล์ และจะถามใหม่ในการเปิดครั้งถัดไปหากไม่มีตัวแปรนี้ใน environment

ไม่ต้องใช้ Admin API key สำหรับ runtime ที่ทำหน้าที่ใช้ Tunnel เดิม

## 8. ติดตั้งและเปิด Tunnel ครั้งแรก

เมื่อ ComfyUI เปิดอยู่แล้ว ให้ดับเบิลคลิก **`Setup-Tunnel.cmd`**

สคริปต์จะ:

1. ดาวน์โหลด standard Windows `tunnel-client` รุ่นล่าสุดจาก repository `openai/tunnel-client` หากยังไม่มีไฟล์ที่ติดตั้งไว้
2. ตรวจ SHA256 เทียบกับ `SHA256SUMS.txt` ของ release ก่อนใช้ไฟล์ที่ดาวน์โหลด
3. แตกและติดตั้ง client ภายใน `tunnel-tools`
4. ถาม Tunnel ID ที่คุณสร้างไว้แล้ว
5. ถาม runtime API key แบบซ่อนข้อความ
6. สร้าง profile ชื่อ `comfy-local`
7. ตรวจ ComfyUI และรัน `doctor`
8. เปิด Tunnel และรอรับคำขอ

สคริปต์ใช้คำสั่ง MCP แบบนี้:

```text
./python_embeded/Scripts/comfy-mcp.exe
```

ใช้ `/` เพื่อไม่ให้ command parser กินเครื่องหมาย `\` ใน Windows path และตั้ง working directory เป็น Portable root

**ใช้ `Setup-Tunnel.cmd` สำหรับติดตั้ง/ตั้งค่าครั้งแรก หลังตั้งค่าสำเร็จให้ใช้ `Run-Tunnel.cmd`** การรัน Setup ซ้ำจะใช้ binary เดิม ไม่ได้บังคับอัปเดต และ client อาจปฏิเสธการสร้าง profile ชื่อซ้ำ

ถ้าการดาวน์โหลดถูกบล็อกหรือเลือก Windows asset ไม่ได้ สคริปต์จะหยุดพร้อม error ให้ตรวจข้อความก่อนดำเนินการต่อ

## 9. ตรวจว่า Tunnel พร้อม

เปิด:

- [Tunnel UI](http://127.0.0.1:8080/ui)
- [Readiness](http://127.0.0.1:8080/readyz)

หรือรันใน terminal อีกหน้าต่าง:

```powershell
curl.exe -i http://127.0.0.1:8080/readyz
```

ผลที่ต้องการ:

```text
HTTP/1.1 200 OK

ready
```

log ที่พบในรอบตั้งค่านี้:

```text
RESULT ok
poller started
tunnel metadata fetched
🟢 tunnel-client started
```

ผลเหล่านี้ยืนยันการเริ่ม client และสถานะพร้อม แต่ **ต้องทดสอบเรียก tool จาก ChatGPT อีกครั้งเพื่อยืนยันการทำงานครบเส้นทาง**

## 10. เพิ่ม Comfy MCP ใน ChatGPT

เปิด ChatGPT ในบัญชี/workspace ที่ผูกกับ Tunnel แล้ว:

1. เปิดหน้า Plugins และกด `+` → **Add custom MCP server**
2. ตั้งชื่อ เช่น `comfy mcp private`
3. ตั้ง Connection เป็น **Tunnel**
4. เลือก Tunnel เดิม หรือกรอก `tunnel_...`
5. เลือกการยืนยันตัวตนเป็น **No authentication / ไม่มีการยืนยันตัวตน**
6. ยอมรับข้อความความเสี่ยงหลังอ่านและตรวจข้อมูล
7. กด **Create as a plugin / สร้างเป็นปลั๊กอิน** และติดตั้ง plugin
8. เลือก plugin ในแชตด้วย `@` แล้วทดสอบ

ชื่อเมนูอาจต่างกันตามหน้า UI และสิทธิ์ของบัญชี

### ทำไมเลือกไม่มีการยืนยันตัวตน

Comfy MCP แบบ stdio ในการตั้งค่านี้ไม่ได้ให้บริการ OAuth ดังนั้นไม่ต้องกรอก OAuth client ID หรือ client secret

การยืนยันตัวตนของ Tunnel กับ OpenAI ใช้ runtime API key ในสคริปต์ ส่วนช่อง Authentication ในหน้าเพิ่ม MCP เป็นเรื่องการยืนยันตัวตนของ MCP server ซึ่งเป็นคนละชั้นกัน

### คำสั่งทดสอบ

```text
ใช้ comfy mcp private เรียก server_info ตรวจสอบ ComfyUI ของฉัน
```

ควรเห็นผล tool จริงที่รายงานสถานะ ComfyUI หากยังไม่เห็น tool call อย่าเพิ่งสรุปว่าเชื่อมสำเร็จจากคำตอบข้อความอย่างเดียว

หลัง `server_info` สำเร็จ ค่อยตรวจรายชื่อ models / nodes หรือทดลอง workflow ที่มีอยู่แล้ว

## 11. เปิดใช้งานในวันถัดไป

ลำดับปกติ:

1. เปิด ComfyUI ด้วย launcher เดิมของ Portable และรอให้พร้อมบน 8188
2. ดับเบิลคลิก **`Run-Tunnel.cmd`**
3. กรอก runtime API key เมื่อสคริปต์ถาม
4. ตรวจ readiness หากจำเป็น
5. เปิด ChatGPT และเลือก plugin ที่ติดตั้งไว้
6. เริ่มด้วย `server_info`

ไม่ต้องติดตั้ง MCP, สร้าง Tunnel หรือสร้าง plugin ใหม่ทุกครั้ง

ต้องเปิดทั้ง ComfyUI และ Tunnel ค้างไว้ หากปิดเครื่องหรือปิด Tunnel แล้ว ChatGPT จะเรียกเครื่องไม่ได้

สำหรับ stdio ให้มี **Tunnel client เพียงหนึ่ง instance ต่อ Tunnel ID** ปิด instance เก่าก่อนเปิดใหม่ เพื่อไม่ให้คำขอใน session เดียวกันไปคนละ MCP process

## 12. ปัญหาที่พบและวิธีตรวจ

| อาการ | ความหมาย / วิธีจัดการ |
|---|---|
| ติดตั้งค้างขั้น `[3/4]` หลังแสดงเวอร์ชัน CLI | สคริปต์รุ่นแรกเคยเรียก `comfy-mcp.exe --version` แล้วรอ stdio ใช้สคริปต์ปัจจุบันซึ่งอ่านเวอร์ชันผ่าน `importlib.metadata` |
| หา `.python_embededScriptscomfy-mcp.exe` ไม่เจอ | command parser กิน `\` ใช้ Tunnel script ที่แก้เป็น `./python_embeded/Scripts/comfy-mcp.exe` |
| `does not implement OAuth` | MCP นี้ไม่มี OAuth เลือก No authentication ข้อความจาก endpoint ตรวจ OAuth เพียงอย่างเดียวยังไม่ยืนยันเหตุผลที่สร้าง plugin ล้มเหลว |
| `unsupported channel "harpoon"` | คำขอเข้าช่อง Harpoon แต่ไม่มี target ที่ลงทะเบียน ช่อง Comfy MCP เป็น `main` อาจพบใน OAuth discovery ต้องแยกจาก error ของคำขอสร้าง plugin จริง ไม่ควรเพิ่ม target แบบเดาสุ่ม |
| ไม่มี log ใหม่เมื่อกดสร้าง plugin | ไม่พอสรุปว่าคำขอไม่ถึง ตรวจ readiness และ Network Response ของ request ตอนกดสร้าง |
| `ERR_BLOCKED_BY_CLIENT` ใน Statsig | เบราว์เซอร์หรือส่วนขยายบล็อกคำขอนั้น ยังไม่พิสูจน์ว่าเป็นต้นเหตุของปัญหา MCP |
| มี Tunnel ใน Platform แต่ไม่ปรากฏใน ChatGPT | ตรวจการผูก ChatGPT workspace, organization ที่เลือก และ Tunnels Read + Use |
| `401` / `403` | อ่าน Response ของคำขอนั้น ตรวจ key, วันหมดอายุ, organization และสิทธิ์ ไม่จำเป็นต้องสร้าง key ใหม่ก่อนเห็นสาเหตุ |
| `codex_plugin ... SKIP` | ส่วนเสริมสำหรับ Codex ไม่ใช่ข้อบังคับของการเชื่อม ChatGPT ตามคู่มือนี้ |
| MCP รันได้ แต่ workflow สร้างภาพไม่ได้ | ตรวจ `server_info`, models, custom nodes และ workflow dependencies แยกจากปัญหา Tunnel |

### หากหน้า ChatGPT สร้าง plugin ไม่สำเร็จ

1. กรอกข้อมูลทั้งหมดและเลือก No authentication ให้เรียบร้อย
2. เปิด DevTools ด้วย F12 → Network แล้วล้างรายการ
3. กดสร้างเพียงครั้งเดียว
4. ดู request ที่ล้มเหลวหลังการกด โดยเก็บชื่อ request, Status Code และ Response
5. เปรียบเทียบเวลานั้นกับ log ใหม่ใน Tunnel

ไม่ส่ง Cookie, Authorization header, API key หรือ HAR ที่มีข้อมูลลับ

การทดสอบในรอบนี้ยืนยันแล้วว่า Comfy MCP ตอบ `initialize` และ `tools/list` ในเครื่องได้ โดยต้องใช้ผลเรียก tool จาก ChatGPT เป็นหลักฐานของการเชื่อมครบเส้นทาง

## 13. สำหรับผู้ดูแล repository

อัปโหลดไฟล์ในชุดนี้ไปที่ repository โดยรักษาชื่อไฟล์และให้สคริปต์อยู่ระดับเดียวกับ README เพื่อให้ลิงก์และตัวเรียกใช้งานตรงกัน

- เปลี่ยน URL `https://github.com/YOUR-USER/YOUR-REPO.git` ในตัวอย่างให้เป็น repository จริง
- อย่า commit API keys, profile ที่มีข้อมูลส่วนตัว, โฟลเดอร์ Python, models หรือ runtime downloads
- `.gitignore` ที่ให้มาช่วยกันไฟล์ runtime และไฟล์ที่สร้างจากการติดตั้งออกจาก repository
- `.gitattributes` กำหนด CRLF สำหรับ CMD/PowerShell และ LF สำหรับ Markdown
- สคริปต์รับ API key ผ่านช่องซ่อนข้อความ และไม่เขียน key ลงไฟล์
- ในการแก้สคริปต์ ควรทดสอบบน Windows โดยตรวจ setup, การรันซ้ำ, readiness และการเรียก tool จาก ChatGPT

ผลจากการใช้งานระหว่างพัฒนา: ติดตั้งแพ็กเกจได้ เปิด ComfyUI ได้ Tunnel เริ่มทำงาน `/readyz` ตอบ `200 ready` และ MCP ตอบ `initialize` กับ `tools/list` ได้ในเครื่อง ทั้งนี้ให้ยืนยันการเชื่อมครบเส้นทางด้วย tool call ในบัญชีผู้ใช้งานจริง

## แหล่งอ้างอิง

- [ComfyUI Windows Portable](https://docs.comfy.org/installation/comfyui_portable_windows)
- [Comfy MCP ตัวทางการ](https://github.com/Comfy-Org/comfy-mcp)
- [OpenAI Secure MCP Tunnel](https://developers.openai.com/api/docs/guides/secure-mcp-tunnels)
- [Tunnel client releases](https://github.com/openai/tunnel-client/releases/latest)
- [Tunnel client configuration](https://github.com/openai/tunnel-client/blob/master/docs/configuration.md)
- [Connector behavior และ channel routing](https://github.com/openai/tunnel-client/blob/master/docs/connectors.md)
- [เพิ่ม custom MCP ใน ChatGPT](https://developers.openai.com/api/docs/guides/custom-mcp-server)
