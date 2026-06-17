#Requires -RunAsAdministrator
# ===== 禁止驱动器重定向 =====

$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "fDisableCdm" -Value 1 -Type DWord

gpupdate /force | Out-Null
Write-Host "已禁止 RDP 驱动器重定向。建议重新连接一次会话。" -ForegroundColor Yellow
