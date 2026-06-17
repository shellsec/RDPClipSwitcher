#Requires -RunAsAdministrator
# ===== 允许驱动器重定向（文件复制粘贴靠它）=====

$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "fDisableCdm" -Value 0 -Type DWord

gpupdate /force | Out-Null
Write-Host "已允许 RDP 驱动器重定向（文件拖拽/盘符挂载）。建议重新连接一次会话。" -ForegroundColor Green
