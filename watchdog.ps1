# whisper-ptt watchdog: auto-start at logon + self-heal.
# Launches ptt.py (venv pythonw) if no whisper-ptt python process is running,
# then re-checks every 5 minutes forever. Put a shortcut to this script in
# shell:startup (powershell -WindowStyle Hidden -File watchdog.ps1).
# Paths are derived from the script location, so it works from any clone.
#
# Disable flag: if ".disabled" exists in this folder, the watchdog will NOT
# launch ptt.py and will stop any running instance (frees the Whisper model from
# VRAM). Written by the tray "Disable Whisper" item / disable-whisper.ps1;
# removed by enable-whisper.ps1. Lets you turn Whisper off and keep it off until
# you explicitly re-enable it.

$repo = $PSScriptRoot
$pyw  = Join-Path $repo ".venv\Scripts\pythonw.exe"
if (-not (Test-Path $pyw)) { $pyw = "pythonw.exe" }   # no venv: use PATH python
$log  = Join-Path $repo "watchdog.log"
$flag = Join-Path $repo ".disabled"

function Test-Ptt {
    $p = Get-Process pythonw -ErrorAction SilentlyContinue |
         Where-Object { try { $_.Path -like "*whisper-ptt*" } catch { $false } }
    return [bool]$p
}

function Stop-Ptt {
    # Kill any ptt.py instance regardless of which interpreter launched it.
    Get-CimInstance Win32_Process -Filter "Name='pythonw.exe' OR Name='python.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'ptt\.py' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

while ($true) {
    if (Test-Path $flag) {
        # Disabled by the user: make sure ptt.py is not running, then idle.
        Stop-Ptt
    }
    elseif (-not (Test-Ptt)) {
        Start-Process -FilePath $pyw -ArgumentList "ptt.py" -WorkingDirectory $repo
        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $log -Value "$stamp started ptt.py" -Encoding utf8
    }
    Start-Sleep -Seconds 300
}
