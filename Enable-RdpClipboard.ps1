#Requires -RunAsAdministrator
# ===== 允许 RDP 剪贴板（关闭“不允许剪贴板重定向”）=====

$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "fDisableClip" -Value 0 -Type DWord

# 清理 RDP-Tcp 可能残留的硬覆盖
$tcp = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
if (Test-Path $tcp) {
    Set-ItemProperty -Path $tcp -Name "fDisableClip" -Value 0 -Type DWord -ErrorAction SilentlyContinue
}

gpupdate /force | Out-Null
Write-Host "已允许 RDP 剪贴板重定向（复制粘贴）。建议重新连接一次会话。" -ForegroundColor Green
