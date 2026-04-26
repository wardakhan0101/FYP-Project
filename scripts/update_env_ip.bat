@echo off
REM scripts/update_env_ip.bat
REM
REM Detects this Windows machine's current LAN IP and writes it into OLLAMA_URL
REM in .env so a physical Android device on the same Wi-Fi can reach Ollama.
REM Run this any time your IP changes.
REM
REM Usage (from project root OR scripts/):
REM   scripts\update_env_ip.bat

setlocal EnableDelayedExpansion

cd /d "%~dp0.."

set ENV_FILE=.env

if not exist "%ENV_FILE%" (
    echo ERROR: %ENV_FILE% not found in %cd%.
    exit /b 1
)

REM Grab first IPv4 that isn't 127.*
set LAN_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r /c:"IPv4 Address"') do (
    set "raw=%%a"
    set "raw=!raw: =!"
    if "!LAN_IP!"=="" (
        if not "!raw:~0,4!"=="127." set "LAN_IP=!raw!"
    )
)

if "%LAN_IP%"=="" (
    echo ERROR: Could not detect a LAN IP. Are you on Wi-Fi or Ethernet?
    exit /b 1
)

set NEW_URL=http://%LAN_IP%:11434/api/chat

REM Rewrite .env, replacing OLLAMA_URL line if present.
powershell -NoProfile -Command ^
    "$p='%ENV_FILE%'; $u='%NEW_URL%'; $c = Get-Content $p; " ^
    "if ($c -match '^OLLAMA_URL=') { $c = $c | ForEach-Object { if ($_ -match '^OLLAMA_URL=') { 'OLLAMA_URL=' + $u } else { $_ } } } " ^
    "else { $c += 'OLLAMA_URL=' + $u } ; " ^
    "Set-Content -Path $p -Value $c"

echo [OK] .env: OLLAMA_URL=%NEW_URL%

REM Ensure Ollama is listening on all interfaces (persists via setx).
setx OLLAMA_HOST "0.0.0.0" >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] OLLAMA_HOST=0.0.0.0 ^(if this was just set, quit and relaunch the Ollama app^).
) else (
    echo [WARN] Could not set OLLAMA_HOST. Run manually: setx OLLAMA_HOST "0.0.0.0"
)

REM Tunnel the TTS server (Accent_engine on :8000) into every connected Android
REM device so 127.0.0.1:8000 in the Flutter client reaches this machine. Survives
REM until the phone is unplugged or rebooted, then this script re-establishes it.
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] adb not found on PATH -- skipping TTS port forward.
) else (
    set FOUND_DEVICE=0
    for /f "skip=1 tokens=1,2" %%a in ('adb devices') do (
        if "%%b"=="device" (
            set FOUND_DEVICE=1
            adb -s %%a reverse tcp:8000 tcp:8000 >nul
            if !errorlevel! equ 0 (
                echo [OK] adb reverse tcp:8000 -^> tcp:8000 on %%a ^(TTS^)
            ) else (
                echo [WARN] adb reverse failed on %%a -- start the TTS server first or check USB debugging.
            )
        )
    )
    if !FOUND_DEVICE!==0 (
        echo [WARN] adb: no device attached -- skipping TTS port forward ^(run again once your phone is plugged in^).
    )
)

echo.

REM Loud reminder if the TTS server isn't already running locally on :8000.
REM adb reverse only forwards the port -- something has to actually be listening.
netstat -an | findstr /r /c:"LISTENING" | findstr ":8000 " >nul 2>nul
if %errorlevel% neq 0 (
    echo ############################################################
    echo #                                                          #
    echo #   !!  TTS SERVER IS NOT RUNNING  !!                      #
    echo #                                                          #
    echo #   Open a NEW terminal and run:                           #
    echo #                                                          #
    echo #     cd Accent_engine                                     #
    echo #     venv\Scripts\activate                                #
    echo #     uvicorn tts_service:app --host 0.0.0.0 --port 8000   #
    echo #                                                          #
    echo #   Without this, the AI voice in scenario chat is silent. #
    echo #                                                          #
    echo ############################################################
    echo.
) else (
    echo [OK] TTS server is already running on :8000.
)

echo Done. Fully stop+restart Flutter to pick up the new .env ^(hot reload won't^).
endlocal
