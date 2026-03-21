#!/bin/bash
# WhatsApp Voice Transcription Tool
# Usage: ./whatsapp-voice-transcribe.sh <audio_file_or_url>

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: whatsapp-voice-transcribe.sh <audio_file_or_url>"
    echo ""
    echo "Examples:"
    echo "  whatsapp-voice-transcribe.sh /path/to/voice_message.ogg"
    echo "  whatsapp-voice-transcribe.sh https://example.com/audio.mp3"
    exit 1
fi

# If it's a URL, download it first
if [[ "$FILE" == http* ]]; then
    echo "[*] Downloading audio from URL..."
    TMP_FILE="/tmp/voice_$(date +%s).ogg"
    curl -sL "$FILE" -o "$TMP_FILE"
    if [ $? -ne 0 ] || [ ! -f "$TMP_FILE" ]; then
        echo "Error: Failed to download audio"
        exit 1
    fi
    FILE="$TMP_FILE"
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "[*] Transcribing voice message..."
echo ""

# Use whisper-auto for transcription
TRANSCRIPT=$(/root/.openclaw/workspace/skills/whisper-auto/whisper-auto.sh transcribe --file "$FILE" --model base 2>&1)

EXIT_CODE=$?

# Cleanup temp file if we downloaded it
if [[ "$TMP_FILE" == /tmp/voice_* ]]; then
    rm -f "$TMP_FILE"
fi

if [ $EXIT_CODE -eq 0 ] && [ -n "$TRANSCRIPT" ]; then
    echo "✓ Transcription:"
    echo ""
    echo "$TRANSCRIPT"
else
    echo "✗ Transcription failed"
    exit 1
fi
