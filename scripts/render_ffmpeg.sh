#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT_DIR="${1:-$ROOT/examples/sample_project/images}"
OUTPUT_DIR="${2:-$ROOT/test_output}"
OUTPUT_FILE="$OUTPUT_DIR/proof_render.mp4"

mkdir -p "$OUTPUT_DIR"

if ! command -v ffmpeg >/dev/null; then
  echo "ffmpeg not available"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

LIST_FILE="$TMP_DIR/list.txt"
for image in "$INPUT_DIR"/*.png "$INPUT_DIR"/*.jpg "$INPUT_DIR"/*.jpeg; do
  [[ -e "$image" ]] || continue
  seg="$TMP_DIR/$(basename "${image%.*}").mp4"
  ffmpeg -y -loop 1 -i "$image" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black,format=yuv420p" -t 3 -an -c:v libx264 -pix_fmt yuv420p "$seg" >/dev/null 2>&1
  printf "file '%s'\n" "$seg" >> "$LIST_FILE"
done

ffmpeg -y -f concat -safe 0 -i "$LIST_FILE" -c copy "$OUTPUT_FILE"
echo "$OUTPUT_FILE"
