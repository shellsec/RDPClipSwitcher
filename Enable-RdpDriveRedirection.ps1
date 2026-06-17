#Requires -RunAsAdministrator
# Allow RDP drive redirection (files / drive mapping)

$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "fDisableCdm" -Value 0 -Type DWord

gpupdate /force | Out-Null
Write-Host "RDP drive redirection: ALLOWED. Reconnect your RDP session." -ForegroundColor Green
