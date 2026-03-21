---
name: whisper-auto
description: Whisper transcription with auto-failover (local -> API)
version: 1.0.0
---

# Whisper Auto

Transcribe audio using local Whisper first, fallback to OpenAI API if local fails.

## Usage

```bash
openclaw skills run whisper-auto transcribe --file /path/to/audio.mp3 [--model base]
```

## Options

- `--file`: Path to audio file (required)
- `--model`: Model size (tiny, base, small, medium, large, turbo). Default: base

## Priority

1. Local Whisper (free, no API key)
2. OpenAI Whisper API (paid, fallback)
