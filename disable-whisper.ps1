# Disable Whisper PTT: stop dictation, free its VRAM, and keep it off.
# Writes the .disabled flag (watchdog.ps1 respects it, so it won't relaunch),
# then stops any running ptt.py. Re-enable with enable-whisper.ps1 or the
# "Enable Whisper" desktop shortcut.
$repo = $PSScriptRoot
$flag = Join-Path $repo ".disabled"
Set-Content -Path $flag -Value ("disabled " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) -Encoding utf8

$procs = @(Get-CimInstance Win32_Process -Filter "Name='pythonw.exe' OR Name='python.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'ptt\.py' })
$procs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Write-Host ("Whisper PTT disabled (stopped {0} process(es), VRAM freed). Re-enable: enable-whisper.ps1" -f $procs.Count)
