#!/bin/bash
# Whisper with failover: local first, API fallback

AUDIO_FILE="$1"
OUTPUT_DIR="${2:-.}"

if [ -z "$AUDIO_FILE" ]; then
    echo "Usage: whisper_priority.sh <audio_file> [output_dir]"
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "Error: Audio file not found: $AUDIO_FILE"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Try local Whisper first
echo "[*] Attempting local Whisper transcription..."
if /usr/local/bin/whisper "$AUDIO_FILE" --model base --output_dir "$OUTPUT_DIR" --output_format txt 2>/dev/null; then
    echo "[✓] Local Whisper succeeded"
    cat "$OUTPUT_DIR"/*.txt 2>/dev/null
    exit 0
else
    echo "[✗] Local Whisper failed, falling back to API..."
fi

# Fallback to API
echo "[*] Attempting OpenAI Whisper API..."
if command -v openclaw >/dev/null 2>&1; then
    # Use the openai-whisper-api skill
    RESULT=$(openclaw skills run openai-whisper-api --audio "$AUDIO_FILE" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
        echo "$RESULT" > "$OUTPUT_DIR/$(basename "$AUDIO_FILE" .mp3).txt"
        echo "[✓] API Whisper succeeded"
        echo "$RESULT"
        exit 0
    fi
fi

echo "[✗] Both local and API Whisper failed"
exit 1
