#!/usr/bin/env bash
# ============================================
# extract-color.sh — Extract most vibrant color from an image
# ============================================
# Matugen's quantization (Material You Score algorithm) weights 70% by pixel
# frequency, so dark wallpapers produce near-black source colors.  This script
# finds the most *saturated* color cluster instead — giving the visually
# dominant vibrant accent.
#
# Algorithm:
#   1. Resize to 150x150, filter out dark (v<0.15) and grey (s<0.2) pixels
#   2. Group remaining into 12 hue buckets (30° each)
#   3. Score each bucket by s² * v of its weighted-average color
#      - s² strongly favors saturation (the accent "pop")
#      - v ensures reasonable brightness
#      - Minimum 5 pixels per bucket filters single-pixel noise
#   4. Accent override: the s²v winner must beat the most-populated bucket
#      by ≥20%.  If the margin is smaller, the dominant color IS the
#      wallpaper's character (e.g. a pastel sky) and population wins.
#   5. Return the weighted-average color of the chosen bucket
#
# Why 12 buckets (not 18/24): finer buckets fragment small vibrant regions
# (e.g. a sunset pink split across two buckets) and expose tiny noise clusters.
# 30° resolution keeps visually coherent hue groups together.
#
# TODO: When matugen 4.0 hits Arch stable (currently in extra-testing as of
#       2025-02), test `matugen image <img> --prefer saturation` as a potential
#       replacement.  It re-ranks Score results by saturation, which may suffice
#       for accents >1% of pixels.  Also adds --source-color-index N (0-3).
#
# Usage: extract-color.sh <image>
# Output: hex color without '#' (e.g. D3357C)

set -euo pipefail

image="${1:?Usage: extract-color.sh <image>}"
[[ -f "$image" ]] || { echo "File not found: $image" >&2; exit 1; }

python3 -W ignore::DeprecationWarning << PYEOF
from PIL import Image
import colorsys

img = Image.open("$image")
img = img.resize((150, 150))

# 12 hue buckets (30° each), weighted by saturation * brightness
buckets = {}  # bucket -> [total_weight, r_weighted, g_weighted, b_weighted, count]
for pixel in img.getdata():
    r, g, b = pixel[0], pixel[1], pixel[2]
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if v < 0.15 or s < 0.2:
        continue
    bucket = int(h * 12) % 12
    weight = s * v
    if bucket not in buckets:
        buckets[bucket] = [0.0, 0.0, 0.0, 0.0, 0]
    buckets[bucket][0] += weight
    buckets[bucket][1] += r * weight
    buckets[bucket][2] += g * weight
    buckets[bucket][3] += b * weight
    buckets[bucket][4] += 1

if not buckets:
    print("")
else:
    # Score all valid buckets
    scored = []  # [(bucket, score, count)]
    for bucket, (total_w, rs, gs, bs, count) in buckets.items():
        if total_w == 0 or count < 5:
            continue
        avg_r = rs / total_w / 255
        avg_g = gs / total_w / 255
        avg_b = bs / total_w / 255
        _, avg_s, avg_v = colorsys.rgb_to_hsv(avg_r, avg_g, avg_b)
        score = avg_s * avg_s * avg_v
        scored.append((bucket, score, count))

    if not scored:
        print("")
    else:
        # Find the s²v winner and the most-populated bucket
        by_score = max(scored, key=lambda x: x[1])
        by_count = max(scored, key=lambda x: x[2])

        # The accent must beat the dominant color by ≥20% on s²v.
        # Otherwise the dominant IS the wallpaper's character.
        ACCENT_MARGIN = 1.20
        if by_score[0] == by_count[0]:
            chosen = by_score[0]
        elif by_score[1] >= by_count[1] * ACCENT_MARGIN:
            chosen = by_score[0]  # clear accent — saturation wins
        else:
            chosen = by_count[0]  # close call — population wins

        _, rs, gs, bs, _ = buckets[chosen]
        total_w = buckets[chosen][0]
        r = int(rs / total_w)
        g = int(gs / total_w)
        b = int(bs / total_w)
        print(f"{r:02x}{g:02x}{b:02x}")
PYEOF
