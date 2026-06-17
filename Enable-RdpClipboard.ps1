#Requires -RunAsAdministrator
# Allow RDP clipboard redirection (disable "Do not allow clipboard redirection")

. "$PSScriptRoot\RDPClipSwitcher-Lib.ps1"

$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "fDisableClip" -Value 0 -Type DWord

$tcp = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
if (Test-Path $tcp) {
    Set-ItemProperty -Path $tcp -Name "fDisableClip" -Value 0 -Type DWord -ErrorAction SilentlyContinue
}

gpupdate /force | Out-Null
Restart-RdpClip
Write-Host "RDP clipboard redirection: ALLOWED." -ForegroundColor Green
