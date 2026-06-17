#Requires -RunAsAdministrator
# Restart rdpclip.exe (clipboard monitor) without changing policy

. "$PSScriptRoot\RDPClipSwitcher-Lib.ps1"
Restart-RdpClip
