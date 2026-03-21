#!/bin/bash
# Auto-failover Whisper: local -> API

AUDIO_FILE="$1"
MODEL="${2:-base}"

if [ -z "$AUDIO_FILE" ]; then
    echo "Usage: whisper_auto.sh <audio_file> [model]"
    echo "Models: tiny, base, small, medium, large, turbo"
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "Error: File not found: $AUDIO_FILE"
    exit 1
fi

# Try local first
echo "[*] Trying local Whisper (model: $MODEL)..." >&2
LOCAL_OUTPUT=$(/usr/local/bin/whisper "$AUDIO_FILE" --model "$MODEL" --output_format txt --output_dir /tmp 2>&1)
LOCAL_EXIT=$?

if [ $LOCAL_EXIT -eq 0 ]; then
    TXT_FILE="/tmp/$(basename "$AUDIO_FILE" | sed 's/\.[^.]*$//').txt"
    if [ -f "$TXT_FILE" ]; then
        cat "$TXT_FILE"
        rm -f "$TXT_FILE"
        echo "[✓] Local transcription complete" >&2
        exit 0
    fi
fi

echo "[✗] Local failed ($LOCAL_EXIT), trying API..." >&2

# API fallback using openai-whisper-api skill
echo "[*] Trying OpenAI Whisper API..." >&2
API_OUTPUT=$(/root/.nvm/versions/node/v22.22.0/bin/openclaw skills run openai-whisper-api transcribe --file "$AUDIO_FILE" 2>&1)
API_EXIT=$?

if [ $API_EXIT -eq 0 ] && [ -n "$API_OUTPUT" ]; then
    echo "$API_OUTPUT"
    echo "[✓] API transcription complete" >&2
    exit 0
fi

echo "[✗] Both local and API transcription failed" >&2
echo "Local error: $LOCAL_OUTPUT" >&2
echo "API error: $API_OUTPUT" >&2
exit 1
