# whisper-ptt

Push-to-talk voice transcription with CUDA-accelerated Whisper.

## Stack
- Python 3.10+, Windows only, NVIDIA GPU required
- faster-whisper, silero-vad, pynput, sounddevice, pyautogui

## Key Files
| File | Purpose |
|------|---------|
| `ptt.py` | Main script — transcription engine, hotkeys, commands |
| `CUSTOM_FUNCTIONALITY.md` | Extension guide |

## Run
```bash
python ptt.py       # with console
pythonw ptt.py      # headless
```

## Service
There is NO scheduled task. `watchdog.ps1` (launched at logon via a shortcut in
`shell:startup` — `powershell -WindowStyle Hidden -File watchdog.ps1`) relaunches
`ptt.py` via the venv `pythonw` within ~5 min whenever it's down. A `.disabled`
flag file in the repo root (written by `disable-whisper.ps1` / tray "Disable
Whisper") makes the watchdog stop PTT and keep it stopped; `enable-whisper.ps1`
removes the flag, starts PTT now, and ensures the watchdog is running.
A healthy PTT shows as TWO `pythonw.exe` pids (venv shim + Python311 worker) =
ONE logical instance — do not kill the child. A named mutex
(`Global\WhisperPTT_SingleInstance`) makes any duplicate launch exit cleanly.

## Config (top of ptt.py)
- `DEVICE_NAME` — mic name (default: "Volt 2")
- `MODEL_SIZE` — whisper model (default: "base")
- `INITIAL_PROMPT` — legacy in-code vocab (first-run seed for `dictionary.json`)
- `DUCK_LEVEL` — audio ducking during transcription
- `BEEP_BACKEND` — beep output backend (`"winsound"` default, or `"sounddevice"` fallback)
- `OLLAMA_MODEL` / `OLLAMA_URL` — optional LLM cleanup pass (off by default)

## Dictionary
- `dictionary.json` (machine-local, auto-created): `prompt_prefix`, `vocab`,
  `corrections`. Edit + tray → Dictionary → Reload. Teach key (F7) learns
  corrections by diffing the user's selected fix against the last paste.

## Hotkeys
- F9 / middle mouse: hold to record
- F10: toggle hot mic (continuous VAD)
- F8: toggle VAD on/off
- F7: teach (learn corrections from selected fixed text)

## Tests
- `python tests/test_dictionary.py` — text pipeline only, no heavy deps needed

## Restart (Hard Rule)
When user reports PTT is down/offline/not working, run immediately — no confirmation needed.
Use exactly one of the following blocks based on your current shell. Do not mix.

### WSL
```bash
cmd.exe /c "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\Users\\alexb\\Documents\\Bots\\whisper-ptt\\enable-whisper.ps1"
sleep 3
cmd.exe /c "tasklist | findstr pythonw"   # expect ~2 pids (venv shim + worker) = one instance
```
- Never `taskkill /F /IM pythonw.exe` — that kills EVERY pythonw on the box, not just PTT

### Windows (PowerShell or CMD)
```powershell
# Bring PTT up now (also removes the .disabled flag and ensures the watchdog):
& "C:\Users\alexb\Documents\Bots\whisper-ptt\enable-whisper.ps1"
Start-Sleep -Seconds 3
Get-Process pythonw -ErrorAction SilentlyContinue   # expect ~2 pids (venv shim + worker) = one instance
# Or just wait — watchdog.ps1 relaunches within ~5 min if it crashed.
```

## Constraints
- Windows-only (pycaw, pyautogui, watchdog.ps1 self-heal)
- Requires CUDA toolkit + PyTorch CUDA build
- Log: `%TEMP%\whisper-ptt.log`
