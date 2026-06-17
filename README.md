# RDPClipSwitcher

Toggle RDP clipboard & drive redirection on the server — one click, no `gpedit.msc`.

**Repository:** [github.com/shellsec/RDPClipSwitcher](https://github.com/shellsec/RDPClipSwitcher)

[English](#english) | [中文](#中文)

## ☕ Buy Me a Cola · 请我喝可乐

Open source takes effort — sponsorship is appreciated:  
开源不易，欢迎赞助支持：

👉 [Afdian / 爱发电](https://ifdian.net/a/shellsec)

## Related tools · 相关工具

More Windows Server / RDS utilities by [shellsec](https://github.com/shellsec):

| Project | Description |
|---------|-------------|
| [RDS_Grace_Period_Reset](https://github.com/shellsec/RDS_Grace_Period_Reset) | Windows Server RDS grace period reset tool · RDS 宽限期重置工具 |

---

# English

Toggle RDP clipboard and drive redirection on the **server side** with one click — no need to open `gpedit.msc` every time.

How it works: writes the equivalent GPO registry keys and runs `gpupdate /force`.

## Supported systems

| Type | Versions |
|------|----------|
| Windows Server | 2016, 2019, 2022, 2025 (and same-generation RDS session hosts) |
| Windows client | Windows 10, Windows 11 (Pro / Enterprise editions that accept incoming RDP) |

**Where to run**: on the machine being remoted **into** (the RDP **server**), with **Administrator** rights.

**Not supported**: Home editions (no inbound RDP host by default), Linux xrdp, older Server versions (2008 R2 / 2012 R2) not verified.

**Script encoding**: all `.ps1` files are UTF-8 with BOM; UI text is English (ASCII) for compatibility with Windows PowerShell 4.0+ on GBK systems. If you see garbled Chinese / parser errors, re-download the latest scripts from GitHub.

## Files

| File | Description |
|------|-------------|
| `RDPClipSwitcher.ps1` | Interactive menu (enable / disable / status) |
| `RDPClipSwitcher-Lib.ps1` | Shared helper (`Restart-RdpClip`) |
| `Run-RDPClipSwitcher.bat` | Double-click to launch menu with elevation |
| `Restart-RdpClip.ps1` | Restart `rdpclip.exe` only (no policy change) |
| `Enable-RdpClipboard.ps1` | Allow clipboard redirection |
| `Disable-RdpClipboard.ps1` | Block clipboard redirection |
| `Enable-RdpDriveRedirection.ps1` | Allow drive redirection (file channel) |
| `Disable-RdpDriveRedirection.ps1` | Block drive redirection |

## Installation

**Recommended path (standard deployment):**

`C:\Program Files\RDPClipSwitcher`

**Alternative (testing / frequent edits, no spaces in path):**

`C:\Tools\RDPClipSwitcher`

First-time setup on the RDP **server** (elevated PowerShell):

```powershell
$dest = "${env:ProgramFiles}\RDPClipSwitcher"
New-Item -ItemType Directory -Path $dest -Force
git clone https://github.com/shellsec/RDPClipSwitcher.git $dest

Set-ExecutionPolicy Bypass -Scope Process -Force
& "$dest\RDPClipSwitcher.ps1"
```

Or download a zip from [Releases](https://github.com/shellsec/RDPClipSwitcher/releases) and extract the **entire folder** (including `RDPClipSwitcher-Lib.ps1`) to `$dest`.

Daily use: double-click `Run-RDPClipSwitcher.bat` in that folder.

| Note | Detail |
|------|--------|
| Updates | Writing to Program Files requires Administrator |
| Path with spaces | Always quote: `& "C:\Program Files\RDPClipSwitcher\RDPClipSwitcher.ps1"` |
| Do not copy single files | Keep all scripts in the same directory |

## Quick start

### Get from GitHub

```powershell
git clone https://github.com/shellsec/RDPClipSwitcher.git "${env:ProgramFiles}\RDPClipSwitcher"
cd "${env:ProgramFiles}\RDPClipSwitcher"
```

Or download a zip from [Releases](https://github.com/shellsec/RDPClipSwitcher/releases) and extract to the install path above.

### Option A: Menu (recommended)

1. Install to `C:\Program Files\RDPClipSwitcher` (see [Installation](#installation)).
2. Double-click `Run-RDPClipSwitcher.bat` (requests admin elevation).
3. Follow the menu.

Or in an elevated PowerShell:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
& ".\RDPClipSwitcher.ps1"
```

Menu:

```
  Quick (clipboard + drives together):
  1) Allow ALL  (text copy/paste + files)
  2) Block ALL  (text copy/paste + files)
  Clipboard only (text):
  3) Allow clipboard
  4) Block clipboard
  Drive only (files):
  5) Allow drives
  6) Block drives
  7) Show current status
  8) Restart rdpclip.exe only
  0) Exit
```

**Note:** Clipboard (`fDisableClip`) and drive (`fDisableCdm`) are separate Windows policies. Option `2` blocks text only; use `2` Block ALL or option `6` to also block files. Most users should use `1` / `2`.

### Option B: Individual scripts

Right-click Start → **Windows PowerShell (Admin)**, then run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force

# Allow clipboard
& ".\Enable-RdpClipboard.ps1"

# Block clipboard
& ".\Disable-RdpClipboard.ps1"

# Allow drives
& ".\Enable-RdpDriveRedirection.ps1"

# Block drives
& ".\Disable-RdpDriveRedirection.ps1"
```

## GPO mapping

GPO path:

```
Computer Configuration
  → Administrative Templates
    → Windows Components
      → Remote Desktop Services
        → Remote Desktop Session Host
          → Device and Resource Redirection
            → Do not allow clipboard redirection
            → Do not allow drive redirection
```

Registry:

| Value name | Path | Meaning |
|------------|------|---------|
| `fDisableClip` | `HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services` | `1` = block clipboard; `0` / missing = allow |
| `fDisableCdm` | same as above | `1` = block drives; `0` / missing = allow |
| `fDisableClip` (override) | `HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp` | if set to `1`, clipboard is also blocked |

When allowing clipboard, scripts set the GPO key to `0` and clear any hard override on RDP-Tcp.

## When changes take effect

1. Script completes successfully on the server as Administrator.
2. Clipboard changes **automatically restart `rdpclip.exe`** (kill all instances, start in the current session).
3. If clipboard still fails, **disconnect and reconnect** RDP. On multi-user RDS, other sessions may need reconnect.
4. In rare cases, restart the `TermService` service; usually not required.

## Text copies but files don't?

Usually this is **drive redirection**, not clipboard policy:

1. **Server**: run `Enable-RdpDriveRedirection.ps1`, or menu option `4`.
2. **Client**: in `mstsc` → Show Options → Local Resources → More → check local drives.

GPO only controls server-side allowance; whether the client redirects drives is chosen at connect time.

## Check status manually

Elevated PowerShell:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ErrorAction SilentlyContinue |
  Select-Object fDisableClip, fDisableCdm

Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -ErrorAction SilentlyContinue |
  Select-Object fDisableClip
```

Or use menu option `3` for a summary of GPO keys, RDP-Tcp override, and effective result.

## Notes

- Changes local (or per-computer) policy registry only; does not edit domain GPO templates in the console. If domain policy overrides with higher precedence, coordinate with your domain admin.
- In production, use option `3` to inspect current state before changing anything.
- Blocking clipboard can reduce data exfiltration risk; ensure policy compliance before enabling redirection.

---

# 中文

在远程桌面（RDP）**服务端**一键开关剪贴板与驱动器重定向，无需每次打开 `gpedit.msc` 手动改组策略。

本质：修改 GPO 对应注册表项 + 执行 `gpupdate /force`。

## 适用系统

| 类型 | 版本 |
|------|------|
| Windows Server | 2016、2019、2022、2025（及同代 RDS 会话主机） |
| Windows 客户端 | Windows 10、Windows 11（Pro / Enterprise 等支持被远程桌面的版本） |

**运行位置**：被远程的那台机器（RDP **服务端**），需**管理员**权限。

**不适用**：Home 版（默认不能作 RDP 主机）、Linux xrdp、未经验证的旧版 Server（2008 R2 / 2012 R2）。

**脚本编码**：所有 `.ps1` 为 UTF-8 BOM；界面文案为英文（ASCII），兼容 GBK 环境下的 Windows PowerShell 4.0+。若出现中文乱码或 ParserError，请从 GitHub 重新下载最新脚本。

## 文件说明

| 文件 | 说明 |
|------|------|
| `RDPClipSwitcher.ps1` | 菜单式主脚本（开/关/查状态） |
| `RDPClipSwitcher-Lib.ps1` | 公共函数（重启 rdpclip） |
| `Run-RDPClipSwitcher.bat` | 双击自动提权启动菜单 |
| `Restart-RdpClip.ps1` | 仅重启 rdpclip.exe（不改策略） |
| `Enable-RdpClipboard.ps1` | 一键允许剪贴板 |
| `Disable-RdpClipboard.ps1` | 一键禁止剪贴板 |
| `Enable-RdpDriveRedirection.ps1` | 一键允许驱动器重定向（文件通道） |
| `Disable-RdpDriveRedirection.ps1` | 一键禁止驱动器重定向 |

## 安装路径

**推荐路径（正式部署）：**

`C:\Program Files\RDPClipSwitcher`

**备选路径（临时测试、常改脚本，路径无空格）：**

`C:\Tools\RDPClipSwitcher`

在 RDP **服务端**首次部署（管理员 PowerShell）：

```powershell
$dest = "${env:ProgramFiles}\RDPClipSwitcher"
New-Item -ItemType Directory -Path $dest -Force
git clone https://github.com/shellsec/RDPClipSwitcher.git $dest

Set-ExecutionPolicy Bypass -Scope Process -Force
& "$dest\RDPClipSwitcher.ps1"
```

或从 [Releases](https://github.com/shellsec/RDPClipSwitcher/releases) 下载 zip，将**整个文件夹**（含 `RDPClipSwitcher-Lib.ps1`）解压到 `$dest`。

日常使用：双击该目录下的 `Run-RDPClipSwitcher.bat`。

| 说明 | 内容 |
|------|------|
| 更新 | 写入 Program Files 需要管理员权限 |
| 路径含空格 | 执行时请加引号：`& "C:\Program Files\RDPClipSwitcher\RDPClipSwitcher.ps1"` |
| 勿只复制单个脚本 | 所有 `.ps1` 须在同一目录 |

## 快速使用

### 从 GitHub 获取

```powershell
git clone https://github.com/shellsec/RDPClipSwitcher.git "${env:ProgramFiles}\RDPClipSwitcher"
cd "${env:ProgramFiles}\RDPClipSwitcher"
```

或下载 [Releases](https://github.com/shellsec/RDPClipSwitcher/releases) 压缩包，解压到上述安装路径。

### 方式一：菜单（推荐）

1. 安装到 `C:\Program Files\RDPClipSwitcher`（见 [安装路径](#安装路径)）。
2. 双击 `Run-RDPClipSwitcher.bat`（会自动请求管理员权限）。
3. 按提示选择操作。

或在管理员 PowerShell 中：

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
& ".\RDPClipSwitcher.ps1"
```

菜单选项：

```
  Quick (clipboard + drives together):
  1) Allow ALL  (text copy/paste + files)
  2) Block ALL  (text copy/paste + files)
  Clipboard only (text):
  3) Allow clipboard
  4) Block clipboard
  Drive only (files):
  5) Allow drives
  6) Block drives
  7) Show current status
  8) Restart rdpclip.exe only
  0) Exit
```

**说明：** 剪贴板（`fDisableClip`）与驱动器（`fDisableCdm`）是 Windows 里两条独立策略。以前选 `2` 只关文本复制；要一起关文件通道请选 `2` Block ALL 或 `6`。日常建议直接用 `1` / `2`。

### 方式二：单条脚本

右键开始菜单 → **Windows PowerShell（管理员）**，执行对应脚本：

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force

# 允许剪贴板
& ".\Enable-RdpClipboard.ps1"

# 禁止剪贴板
& ".\Disable-RdpClipboard.ps1"

# 允许驱动器
& ".\Enable-RdpDriveRedirection.ps1"

# 禁止驱动器
& ".\Disable-RdpDriveRedirection.ps1"
```

## 与组策略的对应关系

GPO 路径：

```
计算机配置
  → 管理模板
    → Windows 组件
      → 远程桌面服务
        → 远程桌面会话主机
          → 设备和资源重定向
            → 不允许剪贴板重定向
            → 不允许驱动器重定向
```

注册表：

| 键名 | 路径 | 值含义 |
|------|------|--------|
| `fDisableClip` | `HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services` | `1` = 禁止剪贴板；`0` / 不存在 = 允许 |
| `fDisableCdm` | 同上 | `1` = 禁止驱动器；`0` / 不存在 = 允许 |
| `fDisableClip`（覆盖） | `HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp` | 若存在且为 `1`，也会阻断剪贴板 |

允许剪贴板时，脚本会将 GPO 键设为 `0`，并清理 RDP-Tcp 上可能的硬覆盖。

## 生效条件

1. 脚本在服务端以管理员身份执行成功。
2. 修改剪贴板策略后会**自动重启 `rdpclip.exe`**（结束所有实例，并在当前会话重新启动）。
3. 若仍无效，**断开 RDP 重连**；多用户 RDS 上其他会话可能也需重连。
4. 极少数环境需重启 `TermService` 服务；一般不必。

## 文本能复制、文件复制不了？

通常不是剪贴板策略问题，而是**驱动器重定向**未开启：

1. **服务端**：运行 `Enable-RdpDriveRedirection.ps1`，或菜单选 `4`。
2. **客户端**：`mstsc` → 显示选项 → 本地资源 → 详细信息 → 勾选本地磁盘。

GPO 只能管服务端是否允许；客户端是否勾选磁盘由用户连接时决定。

## 手动查看当前状态

管理员 PowerShell：

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ErrorAction SilentlyContinue |
  Select-Object fDisableClip, fDisableCdm

Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -ErrorAction SilentlyContinue |
  Select-Object fDisableClip
```

或使用菜单选项 `3`，会汇总 GPO 键、RDP-Tcp 覆盖及实际效果。

## 注意事项

- 仅修改本机（或域内该计算机）策略注册表，不会自动改域 GPO 控制台中的模板；若域策略强制下发且优先级更高，需与域管理员协调。
- 生产环境变更前建议先选 `3` 查看当前状态。
- 禁止剪贴板可用于降低数据外泄风险；开放前确认符合安全规范。
