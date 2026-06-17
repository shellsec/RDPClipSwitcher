#Requires -RunAsAdministrator
<#
.SYNOPSIS
    RDP 剪贴板 / 驱动器重定向一键开关（GPO 注册表等价实现）
.DESCRIPTION
    兼容 Windows Server 2016/2019/2022/2025 与 Windows 10/11。
    对应 GPO：计算机配置 → 管理模板 → Windows 组件 → 远程桌面服务
              → 远程桌面会话主机 → 设备和资源重定向
#>

$PolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$TcpKey    = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"

function Get-RegDword {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path $Path)) { return $null }
    $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $prop) { return $null }
    return $prop.$Name
}

function Format-PolicyState {
    param([int]$Value)
    switch ($Value) {
        0 { return "已禁用（允许）" }
        1 { return "已启用（禁止）" }
        default { return "未配置" }
    }
}

function Get-RdpRedirectionStatus {
    $clipPolicy = Get-RegDword -Path $PolicyKey -Name "fDisableClip"
    $cdmPolicy  = Get-RegDword -Path $PolicyKey -Name "fDisableCdm"
    $clipTcp    = Get-RegDword -Path $TcpKey -Name "fDisableClip"

    $clipBlocked = ($clipPolicy -eq 1) -or ($clipTcp -eq 1)
    $cdmBlocked  = ($cdmPolicy -eq 1)

    return @{
        ClipPolicy   = $clipPolicy
        ClipTcp      = $clipTcp
        CdmPolicy    = $cdmPolicy
        ClipBlocked  = $clipBlocked
        CdmBlocked   = $cdmBlocked
    }
}

function Ensure-PolicyKey {
    if (-not (Test-Path $PolicyKey)) {
        New-Item -Path $PolicyKey -Force | Out-Null
    }
}

function Set-ClipboardAllow {
    Ensure-PolicyKey
    Set-ItemProperty -Path $PolicyKey -Name "fDisableClip" -Value 0 -Type DWord
    if (Test-Path $TcpKey) {
        Set-ItemProperty -Path $TcpKey -Name "fDisableClip" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    }
    gpupdate /force | Out-Null
    Write-Host "已允许 RDP 剪贴板重定向。" -ForegroundColor Green
}

function Set-ClipboardBlock {
    Ensure-PolicyKey
    Set-ItemProperty -Path $PolicyKey -Name "fDisableClip" -Value 1 -Type DWord
    gpupdate /force | Out-Null
    Write-Host "已禁止 RDP 剪贴板重定向。" -ForegroundColor Yellow
}

function Set-DriveAllow {
    Ensure-PolicyKey
    Set-ItemProperty -Path $PolicyKey -Name "fDisableCdm" -Value 0 -Type DWord
    gpupdate /force | Out-Null
    Write-Host "已允许 RDP 驱动器重定向。" -ForegroundColor Green
}

function Set-DriveBlock {
    Ensure-PolicyKey
    Set-ItemProperty -Path $PolicyKey -Name "fDisableCdm" -Value 1 -Type DWord
    gpupdate /force | Out-Null
    Write-Host "已禁止 RDP 驱动器重定向。" -ForegroundColor Yellow
}

function Show-Status {
    $s = Get-RdpRedirectionStatus
    $os = (Get-CimInstance Win32_OperatingSystem).Caption

    Write-Host ""
    Write-Host "========== RDP 重定向状态 ==========" -ForegroundColor Cyan
    Write-Host "系统: $os"
    Write-Host ""
    Write-Host "剪贴板 (fDisableClip):"
    Write-Host "  GPO 策略键: $(Format-PolicyState $s.ClipPolicy)  (值: $($s.ClipPolicy))"
    if ($null -ne $s.ClipTcp) {
        Write-Host "  RDP-Tcp 覆盖: $(Format-PolicyState $s.ClipTcp)  (值: $($s.ClipTcp))"
    } else {
        Write-Host "  RDP-Tcp 覆盖: 无"
    }
    if ($s.ClipBlocked) {
        Write-Host "  >> 实际效果: 禁止复制粘贴" -ForegroundColor Red
    } else {
        Write-Host "  >> 实际效果: 允许复制粘贴" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "驱动器 (fDisableCdm):"
    Write-Host "  GPO 策略键: $(Format-PolicyState $s.CdmPolicy)  (值: $($s.CdmPolicy))"
    if ($s.CdmBlocked) {
        Write-Host "  >> 实际效果: 禁止文件拖拽/盘符挂载" -ForegroundColor Red
    } else {
        Write-Host "  >> 实际效果: 允许文件拖拽/盘符挂载" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "生效提示: 修改后请断开 RDP 重连；客户端还需在 mstsc 本地资源中勾选磁盘。"
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-Host ""
    Write-Host "  RDPClipSwitcher - 远程桌面重定向开关" -ForegroundColor Cyan
    Write-Host "  ------------------------------------"
    Write-Host "  1) 允许剪贴板（开复制粘贴）"
    Write-Host "  2) 禁止剪贴板（关复制粘贴）"
    Write-Host "  3) 查看当前状态"
    Write-Host "  4) 允许驱动器重定向（开文件通道）"
    Write-Host "  5) 禁止驱动器重定向（关文件通道）"
    Write-Host "  0) 退出"
    Write-Host ""
}

while ($true) {
    Show-Menu
    $choice = Read-Host "请选择"
    switch ($choice) {
        "1" { Set-ClipboardAllow }
        "2" { Set-ClipboardBlock }
        "3" { Show-Status }
        "4" { Set-DriveAllow }
        "5" { Set-DriveBlock }
        "0" { break }
        default { Write-Host "无效选项，请重新输入。" -ForegroundColor Red }
    }
}
