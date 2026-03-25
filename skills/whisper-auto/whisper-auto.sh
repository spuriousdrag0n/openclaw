#!/bin/bash
# Whisper Auto - API first, local fallback

COMMAND="$1"
shift

FILE=""
MODEL="base"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --file)
            FILE="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$FILE" ]; then
    echo "Usage: whisper-auto.sh transcribe --file <audio_file> [--model <model>]"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

# Try OpenAI API FIRST
echo "[*] Trying OpenAI Whisper API..." >&2
API_OUTPUT=$(/root/.nvm/versions/node/v22.22.0/bin/openclaw skills run openai-whisper-api transcribe --file "$FILE" 2>&1)
API_EXIT=$?

if [ $API_EXIT -eq 0 ] && [ -n "$API_OUTPUT" ] && [[ ! "$API_OUTPUT" == *"error"* ]]; then
    echo "$API_OUTPUT"
    echo "[✓] API transcription complete" >&2
    exit 0
fi

echo "[✗] API failed or returned error, trying local..." >&2

# Local fallback
echo "[*] Trying local Whisper (model: $MODEL)..." >&2
LOCAL_OUTPUT=$(/usr/local/bin/whisper "$FILE" --model "$MODEL" --output_format txt --output_dir /tmp 2>&1)
LOCAL_EXIT=$?

if [ $LOCAL_EXIT -eq 0 ]; then
    TXT_FILE="/tmp/$(basename "$FILE" | sed 's/\.[^.]*$//').txt"
    if [ -f "$TXT_FILE" ]; then
        cat "$TXT_FILE"
        rm -f "$TXT_FILE"
        echo "[✓] Local transcription complete" >&2
        exit 0
    fi
fi

echo "[✗] Both API and local transcription failed" >&2
exit 1
