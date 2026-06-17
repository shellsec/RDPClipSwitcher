# Shared helpers for RDPClipSwitcher (ASCII only)

function Restart-RdpClip {
    $clipExe = Join-Path $env:Windir "System32\rdpclip.exe"
    $killed = 0

    $procs = Get-Process -Name rdpclip -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) {
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            $killed++
        }
    }

    if ($killed -eq 0) {
        cmd /c "taskkill /F /IM rdpclip.exe" 2>$null | Out-Null
    }

    Start-Sleep -Milliseconds 800

    if (-not (Test-Path $clipExe)) {
        Write-Host "Warning: rdpclip.exe not found." -ForegroundColor Yellow
        return
    }

    try {
        Start-Process -FilePath $clipExe -ErrorAction Stop
        Write-Host "rdpclip.exe restarted (killed $killed instance(s), started in this session)." -ForegroundColor Cyan
    } catch {
        Write-Host "Could not start rdpclip in this session; reconnect RDP." -ForegroundColor Yellow
    }

    if ($killed -gt 1) {
        Write-Host "Note: other RDP sessions may still need reconnect." -ForegroundColor DarkGray
    }
}
