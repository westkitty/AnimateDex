#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SAMPLE_DIR="$ROOT/examples/sample_project"
IMAGES_DIR="$SAMPLE_DIR/images"

mkdir -p "$IMAGES_DIR"

if ! command -v ffmpeg >/dev/null; then
  echo "ffmpeg is required to generate sample images, but it is not available."
  exit 1
fi

make_image() {
  local color="$1"
  local output="$2"
  if [[ -f "$output" ]]; then
    return
  fi
  ffmpeg -y -f lavfi -i "color=c=$color:s=640x360" -frames:v 1 "$output" >/dev/null 2>&1
}

make_image "red" "$IMAGES_DIR/image1.png"
make_image "green" "$IMAGES_DIR/image2.png"
make_image "blue" "$IMAGES_DIR/image10.png"

cat > "$SAMPLE_DIR/README.md" <<'EOF'
Sample source images for AnimateDex.

Use this folder to test import ordering, sequence detection, and render setup.
EOF

echo "$SAMPLE_DIR"
