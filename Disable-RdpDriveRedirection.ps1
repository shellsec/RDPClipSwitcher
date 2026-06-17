#Requires -RunAsAdministrator
# Block RDP drive redirection

$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "fDisableCdm" -Value 1 -Type DWord

gpupdate /force | Out-Null
Write-Host "RDP drive redirection: BLOCKED. Reconnect your RDP session." -ForegroundColor Yellow
