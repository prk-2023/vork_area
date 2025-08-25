#!/bin/bash

# === Configuration ===
OUTPUT_DIR="/home/pi/audio_clips"   # Change to preferred location
DURATION=$((15 * 60))               # 15 minutes in seconds
SAMPLE_RATE=16000                   # 16 kHz, good enough for voice
BITRATE=32                          # MP3 bitrate in kbps
AUDIO_DEVICE="plughw:1,0"           # Check with `arecord -l` for your mic

# === Ensure output directory exists ===
mkdir -p "$OUTPUT_DIR"

echo "[INFO] Starting continuous recording of 15-minute clips..."
echo "[INFO] Saving to: $OUTPUT_DIR"

# === Infinite recording loop ===
while true; do
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    FILENAME="${OUTPUT_DIR}/clip_${TIMESTAMP}.mp3"

    echo "[INFO] Recording 15-minute clip: $FILENAME"

    arecord -D "$AUDIO_DEVICE" -f S16_LE -r "$SAMPLE_RATE" -c 1 -d "$DURATION" | \
    lame -r -s "$SAMPLE_RATE" -m m -b "$BITRATE" - "$FILENAME"

    echo "[INFO] Clip saved: $FILENAME"
done

