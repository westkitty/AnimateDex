# User Guide

## Open or Create a Project

1. Launch AnimateDex.
2. Click `New Project` or `Open Existing Project`.
3. Pick a workspace folder ending in `.animdex`.

## Import Images

1. Open a workspace.
2. Click `Import Folder or ZIP`.
3. Select a folder of images or a ZIP archive.
4. Review the import status and validation panel.

## Review the Sequence

- The sequence browser shows the imported images in the detected order.
- The scene inspector shows file size, dimensions, sequence number, and motion preset.
- Validation issues stay visible even when the import is usable.

## Render

1. Set render width, height, FPS, and output filename.
2. Click `Render`.
3. Watch the render log panel for ffmpeg progress or failures.
4. Open the exports folder when the render finishes.

## Outputs

- `exports/proof_render.mp4`
- `exports/render_manifest.json`
- `logs/render_log.txt`

## ZIP Import Notes

- macOS junk files are ignored.
- Unsupported files are listed in the import report.
- The source archive is not modified.
