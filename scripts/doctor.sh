#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "cwd: $(pwd)"
echo "repo: $ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "not macOS"
  exit 1
fi

command -v swift >/dev/null || { echo "swift missing"; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg missing"; exit 1; }
command -v xcodebuild >/dev/null || { echo "xcodebuild missing"; exit 1; }

if [[ ! -f "$ROOT/Package.swift" ]]; then
  echo "Package.swift missing"
  exit 1
fi

if [[ ! -d "$ROOT/AnimateDex" ]]; then
  echo "AnimateDex source folder missing"
  exit 1
fi

"$ROOT/scripts/make_sample_project.sh" >/tmp/animateDex-sample-project.log 2>&1 || {
  cat /tmp/animateDex-sample-project.log
  echo "sample project generation failed"
  exit 1
}

echo "doctor ok"
