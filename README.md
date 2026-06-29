# AnimateDex

AnimateDex is a native macOS SwiftUI app for importing folders or ZIP archives of still images, inspecting them, assigning deterministic motion presets, writing editable JSON project files, and rendering a basic MP4 proof with local `ffmpeg`.

## What It Is

- A local macOS desktop app
- A project workspace manager
- A deterministic image-sequence inspector
- A simple proof renderer

## What It Is Not

- Not Electron
- Not a browser app
- Not cloud dependent
- Not an AI video generator
- Not a source-media editor

## Requirements

- macOS
- Swift 6 toolchain
- `ffmpeg`
- Xcode command line tools for full build workflows

## Build

```bash
swift build
swift test
```

## Run

```bash
swift run
```

## Import

1. Create or open a workspace.
2. Click `Import Folder or ZIP`.
3. Select a folder of images or a ZIP archive.

## Render

1. Import a valid sequence.
2. Review validation issues.
3. Click `Render`.
4. Find outputs in the workspace `exports` folder.

## Current Limitations

- The app uses cuts and basic deterministic motion.
- Crossfades are not implemented yet.
- Audio tracks are not implemented yet.
- Complex camera math is intentionally simple.

## Troubleshooting

- If `ffmpeg` is missing, install it with Homebrew:

```bash
brew install ffmpeg
```

- If the build fails, run `./scripts/doctor.sh` and inspect the reported missing tools.

## First Real ZIP Verification Status

- Date: 2026-06-28
- Sample folder test: passed
- Real ZIP tested: `/Users/andrew/Library/CloudStorage/GoogleDrive-digitalghosts269@gmail.com/My Drive/macbook/Starsilk_PlanetaryTemplates/codec_storyboard_s001_s100_outpainted_collection.zip`
- Real ZIP import: passed
- Real ZIP render: passed
- Remaining unverified: fully manual file-picker navigation in this desktop environment
- Output locations: workspace `exports/`, `logs/`, and `temp/`
- Git hygiene: generated media, render outputs, and extracted assets stay ignored and were not committed
