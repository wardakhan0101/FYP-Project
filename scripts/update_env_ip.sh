#!/usr/bin/env bash
# scripts/update_env_ip.sh
#
# Detects this Mac's current LAN IP and writes it into OLLAMA_URL in .env so a
# physical Android device on the same Wi-Fi can reach Ollama. Run this any time
# your laptop's IP changes (new Wi-Fi, lease renewal, etc).
#
# Usage (from project root OR scripts/):
#   ./scripts/update_env_ip.sh
#
# Recommended: wire this in as a pre-launch step in Android Studio's Flutter
# run configuration, or just alias `flutter run` to call it first.

set -e
cd "$(dirname "$0")/.."

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found in $(pwd)." >&2
  exit 1
fi

# First non-loopback IPv4 on any active interface.
LAN_IP=$(ifconfig | awk '/^[a-z0-9]+: / {iface=$1} /inet / && $2 !~ /^127\./ && iface!=""{print $2; exit}')

if [ -z "$LAN_IP" ]; then
  echo "ERROR: Could not detect a LAN IP. Are you connected to Wi-Fi or Ethernet?" >&2
  exit 1
fi

NEW_URL="http://${LAN_IP}:11434/api/chat"

if grep -q "^OLLAMA_URL=" "$ENV_FILE"; then
  # BSD sed needs the '' after -i on macOS.
  sed -i '' "s|^OLLAMA_URL=.*|OLLAMA_URL=${NEW_URL}|" "$ENV_FILE"
else
  echo "OLLAMA_URL=${NEW_URL}" >> "$ENV_FILE"
fi

echo "[OK] .env: OLLAMA_URL=${NEW_URL}"

# Make sure Ollama is listening on all interfaces.
CURRENT_HOST=$(launchctl getenv OLLAMA_HOST 2>/dev/null || true)
if [ "$CURRENT_HOST" != "0.0.0.0" ]; then
  echo "[WARN] OLLAMA_HOST is '${CURRENT_HOST:-unset}'. Setting to 0.0.0.0..."
  launchctl setenv OLLAMA_HOST "0.0.0.0"
  echo "       Quit AND relaunch the Ollama menubar app now for this to take effect."
fi

# Tunnel the TTS server (Accent_engine on :8000) into every connected Android
# device so 127.0.0.1:8000 in the Flutter client reaches the Mac. Survives
# until the phone is unplugged or rebooted, then this script re-establishes it.
if command -v adb >/dev/null 2>&1; then
  DEVICES=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
  if [ -z "$DEVICES" ]; then
    echo "[WARN] adb: no device attached — skipping TTS port forward (run again once your phone is plugged in)."
  else
    for D in $DEVICES; do
      if adb -s "$D" reverse tcp:8000 tcp:8000 >/dev/null; then
        echo "[OK] adb reverse tcp:8000 -> tcp:8000 on $D (TTS)"
      else
        echo "[WARN] adb reverse failed on $D — start the TTS server first or check USB debugging."
      fi
    done
  fi
else
  echo "[WARN] adb not found on PATH — skipping TTS port forward."
fi

echo ""

# Loud reminder if the TTS server isn't already running locally on :8000.
# adb reverse only forwards the port — something has to actually be listening.
if ! lsof -nP -iTCP:8000 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "############################################################"
  echo "#                                                          #"
  echo "#   !!  TTS SERVER IS NOT RUNNING  !!                      #"
  echo "#                                                          #"
  echo "#   Open a NEW terminal and run:                           #"
  echo "#                                                          #"
  echo "#     cd Accent_engine                                     #"
  echo "#     source venv/bin/activate                             #"
  echo "#     uvicorn tts_service:app --host 0.0.0.0 --port 8000   #"
  echo "#                                                          #"
  echo "#   Without this, the AI voice in scenario chat is silent. #"
  echo "#                                                          #"
  echo "############################################################"
  echo ""
else
  echo "[OK] TTS server is already running on :8000."
fi

echo "Done. Fully stop+restart Flutter to pick up the new .env (hot reload won't)."
