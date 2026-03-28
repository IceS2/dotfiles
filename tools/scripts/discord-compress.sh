#!/bin/bash
# Compress video for Discord upload using NVENC two-pass encoding
# Usage: discord-compress <input> [size_mb]
# Default target: 25MB

set -euo pipefail

INPUT="${1:-}"
TARGET_MB="${2:-25}"
MIN_VIDEO_BITRATE=500  # kbps, below this quality is unwatchable
AUDIO_BITRATE=128      # kbps

if [[ -z "$INPUT" ]]; then
    echo "Usage: discord-compress <input> [size_mb]"
    echo "  size_mb: target file size in MB (default: 25)"
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: file not found: $INPUT"
    exit 1
fi

# Get video duration in seconds
DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$INPUT")
DURATION_INT=${DURATION%.*}

if [[ -z "$DURATION" || "$DURATION_INT" -eq 0 ]]; then
    echo "Error: could not determine video duration"
    exit 1
fi

# Calculate target video bitrate: (size_MB * 8192 kbit/MB) / duration_s - audio_bitrate
TARGET_TOTAL_KBPS=$(( (TARGET_MB * 8192) / DURATION_INT ))
VIDEO_BITRATE=$(( TARGET_TOTAL_KBPS - AUDIO_BITRATE ))

# Check if bitrate is too low
if [[ "$VIDEO_BITRATE" -lt "$MIN_VIDEO_BITRATE" ]]; then
    MAX_DURATION=$(( (TARGET_MB * 8192) / (MIN_VIDEO_BITRATE + AUDIO_BITRATE) ))
    MAX_MIN=$(( MAX_DURATION / 60 ))
    MAX_SEC=$(( MAX_DURATION % 60 ))
    echo "Error: video is too long (${DURATION_INT}s) for ${TARGET_MB}MB target"
    echo "  Calculated bitrate: ${VIDEO_BITRATE}kbps (minimum: ${MIN_VIDEO_BITRATE}kbps)"
    echo "  Maximum duration at acceptable quality: ${MAX_MIN}m${MAX_SEC}s"
    echo "  Suggestion: trim the video first with LosslessCut or:"
    echo "    ffmpeg -ss START -to END -i \"$INPUT\" -c copy trimmed.mkv"
    exit 1
fi

# Generate output filename
DIR=$(dirname "$INPUT")
BASE=$(basename "$INPUT")
NAME="${BASE%.*}"
OUTPUT="${DIR}/${NAME}_discord.mp4"

echo "Input:    $INPUT"
echo "Duration: ${DURATION_INT}s"
echo "Target:   ${TARGET_MB}MB"
echo "Bitrate:  ${VIDEO_BITRATE}kbps video + ${AUDIO_BITRATE}kbps audio"
echo "Output:   $OUTPUT"
echo ""

# Two-pass NVENC encoding
echo "Pass 1/2 (analysis)..."
ffmpeg -y -i "$INPUT" \
    -c:v h264_nvenc -b:v "${VIDEO_BITRATE}k" -preset p7 \
    -pass 1 -an -f null /dev/null 2>/dev/null

echo "Pass 2/2 (encoding)..."
ffmpeg -y -i "$INPUT" \
    -c:v h264_nvenc -b:v "${VIDEO_BITRATE}k" -preset p7 \
    -pass 2 -c:a aac -b:a "${AUDIO_BITRATE}k" \
    "$OUTPUT" 2>/dev/null

# Report result
OUTPUT_SIZE=$(stat -c%s "$OUTPUT")
OUTPUT_MB=$(( OUTPUT_SIZE / 1048576 ))
echo ""
echo "Done: ${OUTPUT_MB}MB — $OUTPUT"
