#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dist_dir="$repo_root/dist"
app_dir="$dist_dir/AnimateDex.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
plist_path="$contents_dir/Info.plist"

cd "$repo_root"

swift build

bin_dir="$(swift build --show-bin-path)"
executable_path="$bin_dir/AnimateDex"

rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir"
cp "$executable_path" "$macos_dir/AnimateDex"
chmod +x "$macos_dir/AnimateDex"

cat >"$plist_path" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>AnimateDex</string>
    <key>CFBundleDisplayName</key>
    <string>AnimateDex</string>
    <key>CFBundleIdentifier</key>
    <string>productions.stinkyweasel.AnimateDex</string>
    <key>CFBundleVersion</key>
    <string>0.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleExecutable</key>
    <string>AnimateDex</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "$app_dir"
echo "open \"$app_dir\""
