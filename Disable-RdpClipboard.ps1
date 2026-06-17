#Requires -RunAsAdministrator
# ===== 禁止 RDP 剪贴板（启用“不允许剪贴板重定向”）=====

$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "fDisableClip" -Value 1 -Type DWord

gpupdate /force | Out-Null
Write-Host "已禁止 RDP 剪贴板重定向（复制粘贴被阻断）。建议重新连接一次会话。" -ForegroundColor Yellow
