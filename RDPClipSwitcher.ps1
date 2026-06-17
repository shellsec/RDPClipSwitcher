#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Toggle RDP clipboard / drive redirection via GPO registry keys.
.DESCRIPTION
    Windows Server 2016/2019/2022/2025, Windows 10/11.
    PowerShell 4.0+ (Windows PowerShell). UI strings are ASCII for encoding safety.

    Clipboard (fDisableClip) = text copy/paste between local and remote session.
    Drive (fDisableCdm)      = file copy, drag-drop, mapped drives (\\tsclient\C).
    They are separate GPO policies; use 1/2 to change both at once.
#>

. "$PSScriptRoot\RDPClipSwitcher-Lib.ps1"

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
    param($Value)
    if ($null -eq $Value) { return "Not configured" }
    switch ($Value) {
        0 { return "Disabled (allowed)" }
        1 { return "Enabled (blocked)" }
        default { return "Unknown ($Value)" }
    }
}

function Get-OsCaption {
    try {
        return (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption
    } catch {
        return (Get-WmiObject Win32_OperatingSystem).Caption
    }
}

function Get-RdpRedirectionStatus {
    $clipPolicy = Get-RegDword -Path $PolicyKey -Name "fDisableClip"
    $cdmPolicy  = Get-RegDword -Path $PolicyKey -Name "fDisableCdm"
    $clipTcp    = Get-RegDword -Path $TcpKey -Name "fDisableClip"

    $clipBlocked = ($clipPolicy -eq 1) -or ($clipTcp -eq 1)
    $cdmBlocked  = ($cdmPolicy -eq 1)

    return @{
        ClipPolicy  = $clipPolicy
        ClipTcp     = $clipTcp
        CdmPolicy   = $cdmPolicy
        ClipBlocked = $clipBlocked
        CdmBlocked  = $cdmBlocked
    }
}

function Ensure-PolicyKey {
    if (-not (Test-Path $PolicyKey)) {
        New-Item -Path $PolicyKey -Force | Out-Null
    }
}

function Apply-PolicyUpdate {
    gpupdate /force | Out-Null
}

function Set-ClipboardRegistry {
    param([int]$DisableValue)
    Ensure-PolicyKey
    Set-ItemProperty -Path $PolicyKey -Name "fDisableClip" -Value $DisableValue -Type DWord
    if ($DisableValue -eq 0 -and (Test-Path $TcpKey)) {
        Set-ItemProperty -Path $TcpKey -Name "fDisableClip" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    }
}

function Set-DriveRegistry {
    param([int]$DisableValue)
    Ensure-PolicyKey
    Set-ItemProperty -Path $PolicyKey -Name "fDisableCdm" -Value $DisableValue -Type DWord
}

function Set-AllAllow {
    Set-ClipboardRegistry -DisableValue 0
    Set-DriveRegistry -DisableValue 0
    Apply-PolicyUpdate
    Restart-RdpClip
    Write-Host "ALL ALLOWED: clipboard (text) + drives (files)." -ForegroundColor Green
}

function Set-AllBlock {
    Set-ClipboardRegistry -DisableValue 1
    Set-DriveRegistry -DisableValue 1
    Apply-PolicyUpdate
    Restart-RdpClip
    Write-Host "ALL BLOCKED: clipboard (text) + drives (files)." -ForegroundColor Yellow
}

function Set-ClipboardAllow {
    Set-ClipboardRegistry -DisableValue 0
    Apply-PolicyUpdate
    Restart-RdpClip
    Write-Host "Clipboard (text only): ALLOWED." -ForegroundColor Green
}

function Set-ClipboardBlock {
    Set-ClipboardRegistry -DisableValue 1
    Apply-PolicyUpdate
    Restart-RdpClip
    Write-Host "Clipboard (text only): BLOCKED." -ForegroundColor Yellow
}

function Set-DriveAllow {
    Set-DriveRegistry -DisableValue 0
    Apply-PolicyUpdate
    Write-Host "Drives (files only): ALLOWED. Reconnect RDP if files still fail." -ForegroundColor Green
}

function Set-DriveBlock {
    Set-DriveRegistry -DisableValue 1
    Apply-PolicyUpdate
    Write-Host "Drives (files only): BLOCKED. Reconnect RDP if needed." -ForegroundColor Yellow
}

function Show-Status {
    $s = Get-RdpRedirectionStatus
    $os = Get-OsCaption
    $clipRunning = Get-Process -Name rdpclip -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "========== RDP Redirection Status ==========" -ForegroundColor Cyan
    Write-Host "OS: $os"
    if ($clipRunning) {
        Write-Host "rdpclip.exe: running ($($clipRunning.Count) instance(s))"
    } else {
        Write-Host "rdpclip.exe: not running" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Clipboard (fDisableClip) = text copy/paste:"
    Write-Host "  GPO policy: $(Format-PolicyState $s.ClipPolicy)  (value: $($s.ClipPolicy))"
    if ($null -ne $s.ClipTcp) {
        Write-Host "  RDP-Tcp override: $(Format-PolicyState $s.ClipTcp)  (value: $($s.ClipTcp))"
    } else {
        Write-Host "  RDP-Tcp override: none"
    }
    if ($s.ClipBlocked) {
        Write-Host "  >> Effective: text copy/paste BLOCKED" -ForegroundColor Red
    } else {
        Write-Host "  >> Effective: text copy/paste ALLOWED" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Drive (fDisableCdm) = files / drive mapping:"
    Write-Host "  GPO policy: $(Format-PolicyState $s.CdmPolicy)  (value: $($s.CdmPolicy))"
    if ($s.CdmBlocked) {
        Write-Host "  >> Effective: files / drives BLOCKED" -ForegroundColor Red
    } else {
        Write-Host "  >> Effective: files / drives ALLOWED" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Tip: enable local drives in mstsc if file copy fails."
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-Host ""
    Write-Host "  RDPClipSwitcher" -ForegroundColor Cyan
    Write-Host "  ------------------------------------"
    Write-Host "  Quick (clipboard + drives together):"
    Write-Host "  1) Allow ALL  (text copy/paste + files)"
    Write-Host "  2) Block ALL  (text copy/paste + files)"
    Write-Host "  ------------------------------------"
    Write-Host "  Clipboard only (text):"
    Write-Host "  3) Allow clipboard"
    Write-Host "  4) Block clipboard"
    Write-Host "  Drive only (files / \\tsclient drives):"
    Write-Host "  5) Allow drives"
    Write-Host "  6) Block drives"
    Write-Host "  ------------------------------------"
    Write-Host "  7) Show current status"
    Write-Host "  8) Restart rdpclip.exe only"
    Write-Host "  0) Exit"
    Write-Host ""
}

while ($true) {
    Show-Menu
    Write-Host "Enter choice (0-8): " -NoNewline
    $choice = Read-Host
    switch ($choice) {
        "1" { Set-AllAllow }
        "2" { Set-AllBlock }
        "3" { Set-ClipboardAllow }
        "4" { Set-ClipboardBlock }
        "5" { Set-DriveAllow }
        "6" { Set-DriveBlock }
        "7" { Show-Status }
        "8" { Restart-RdpClip }
        "0" { break }
        default { Write-Host "Invalid option." -ForegroundColor Red }
    }
}
