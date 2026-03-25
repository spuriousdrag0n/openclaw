#!/bin/bash
# WhatsApp Voice Message Handler - Auto-transcribe voice messages
source /root/.openclaw/workspace/scripts/env-setup.sh

# This script is designed to be called by OpenClaw when a voice message is received
# Usage: whatsapp-voice-handler.sh <audio_file_path> <sender_id> <chat_id>

AUDIO_FILE="$1"
SENDER="$2"
CHAT_ID="$3"

if [ -z "$AUDIO_FILE" ] || [ ! -f "$AUDIO_FILE" ]; then
    echo "Error: Audio file not provided or not found"
    exit 1
fi

# Transcribe using whisper-auto (local -> API fallback)
TRANSCRIPT=$(/root/.openclaw/workspace/skills/whisper-auto/whisper-auto.sh transcribe --file "$AUDIO_FILE" --model base 2>/dev/null)

if [ -z "$TRANSCRIPT" ]; then
    echo "Error: Transcription failed"
    exit 1
fi

# Send transcription back to the chat
/usr/local/bin/openclaw message send --channel whatsapp --target "$CHAT_ID" --message "🎤 Voice message transcription:\n\n$TRANSCRIPT"

echo "Transcription sent to $CHAT_ID"
