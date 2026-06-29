# AnimateDex

AnimateDex is a native macOS SwiftUI app for importing folders or ZIP archives of still images, inspecting them, assigning deterministic motion presets, applying Motion Recipe JSON workflows, writing editable project files, and rendering a basic MP4 proof with local `ffmpeg`.

## What It Is

- A local macOS desktop app
- A project workspace manager
- A deterministic image-sequence inspector
- A simple proof renderer
- A local Motion Recipe workflow

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

For the normal macOS app experience, build and launch the bundle:

```bash
./scripts/run_app_bundle.sh
```

## macOS UI/UX Pass

- Resize the window normally; the layout uses a resizable split view.
- Use the sidebar to import, open, and switch workflow sections.
- Copy status, diagnostics, and render output paths from the visible panels.
- Motion Recipe lives in its own section and expects externally generated JSON.
- Use the `.app` bundle in `dist/` for the real menu bar and window shell.

## Import

1. Create or open a workspace.
2. Click `Import Folder or ZIP`.
3. Select a folder of images or a ZIP archive.

## Render

1. Import a valid sequence.
2. Review validation issues.
3. Click `Render`.
4. Find outputs in the workspace `exports` folder.

## Motion Recipes

1. Paste a Motion Recipe JSON object into the Motion Recipe panel.
2. Or load one of the bundled examples from `examples/recipes/`.
3. Validate and preview the change set.
4. Apply the recipe to update the scene plan and render settings.
5. Check `motion_recipe_report.txt` in the workspace for the applied result.

## Current Limitations

- The app uses cuts and basic deterministic motion.
- Crossfades are not implemented yet.
- Audio tracks are not implemented yet.
- Complex camera math is intentionally simple.
- Motion Recipe currently targets `sequenceIndex` ranges only.

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
