# Enable Whisper PTT: remove the disable flag, start dictation, and make sure the
# self-heal watchdog is running. Opposite of disable-whisper.ps1.
$repo = $PSScriptRoot
Remove-Item (Join-Path $repo ".disabled") -ErrorAction SilentlyContinue

$pyw = Join-Path $repo ".venv\Scripts\pythonw.exe"
if (-not (Test-Path $pyw)) { $pyw = "pythonw.exe" }

# Start ptt.py if it isn't already running.
$running = @(Get-CimInstance Win32_Process -Filter "Name='pythonw.exe' OR Name='python.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'ptt\.py' })
if ($running.Count -eq 0) {
    Start-Process -FilePath $pyw -ArgumentList "ptt.py" -WorkingDirectory $repo
    Write-Host "Started ptt.py"
} else {
    Write-Host "ptt.py already running"
}

# Ensure the watchdog is running too (self-heal across crashes / future logons handle it via shell:startup).
$wd = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'watchdog\.ps1' })
if ($wd.Count -eq 0) {
    Start-Process -FilePath "powershell.exe" -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',(Join-Path $repo 'watchdog.ps1'))
    Write-Host "Started watchdog"
} else {
    Write-Host "watchdog already running"
}

Write-Host "Whisper PTT enabled."
