#Requires -RunAsAdministrator
# Block RDP clipboard redirection (enable "Do not allow clipboard redirection")

$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "fDisableClip" -Value 1 -Type DWord

gpupdate /force | Out-Null
Write-Host "RDP clipboard redirection: BLOCKED. Reconnect your RDP session." -ForegroundColor Yellow
