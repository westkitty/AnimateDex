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

## Use a Motion Recipe

1. Open a workspace with an imported scene plan.
2. Paste JSON into the Motion Recipe panel or load one of the bundled examples.
3. Click `Validate` to check schema, ranges, and target coverage.
4. Click `Preview Changes` to see affected scenes and render-setting changes.
5. Click `Apply Recipe` to write the updated scene plan and project files.
6. Open `motion_recipe_report.txt` in the workspace if you need the apply summary.

## Render

1. Set render width, height, FPS, and output filename.
2. Click `Render`.
3. Watch the render log panel for ffmpeg progress or failures.
4. Open the exports folder when the render finishes.

## Outputs

- `exports/proof_render.mp4`
- `exports/render_manifest.json`
- `logs/render_log.txt`
- `motion_recipe_applied.json`
- `motion_recipe_report.txt`
- `scene_plan.before_motion_recipe.json`

## ZIP Import Notes

- macOS junk files are ignored.
- Unsupported files are listed in the import report.
- The source archive is not modified.

## First Real ZIP Verification Status

- Date: 2026-06-28
- Sample folder test: passed
- Real ZIP import: passed
- Real ZIP render: passed
- Real ZIP outputs: workspace `exports/proof_render.mp4`, `exports/render_manifest.json`, `logs/render_log.txt`
- Irregular image behavior: one portrait frame in the real ZIP was flagged and treated with a safe preset instead of being stretched
- Git hygiene: extracted media and generated MP4s stay out of version control
