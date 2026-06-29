# Testing

## Manual Flow

1. Run `./scripts/doctor.sh`.
2. Run `swift build`.
3. Run `swift test`.
4. Launch the app with `swift run`.
5. Create a workspace and import `examples/sample_project/images`.
6. Confirm the sequence browser shows `image1.png`, `image2.png`, `image10.png`.
7. Paste a bundled Motion Recipe example and confirm validation plus preview.
8. Render a proof MP4.
9. Copy diagnostics from the sidebar and confirm the text includes workspace, source, scene count, and paths.

## Sample Project

Generate the sample images with:

```bash
./scripts/make_sample_project.sh
```

## Render Validation

- Confirm the MP4 exists in `exports/`.
- Confirm `render_manifest.json` exists.
- Confirm `render_log.txt` contains the ffmpeg command output.

## Motion Recipe Validation

- Confirm the Motion Recipe panel loads the bundled examples from `examples/recipes/`.
- Confirm validation rejects malformed JSON and unsupported schema versions.
- Confirm preview reports the affected scenes before apply.
- Confirm apply writes `motion_recipe_applied.json`, `motion_recipe_report.txt`, and `scene_plan.before_motion_recipe.json`.

## UI/UX Validation

- Confirm the window resizes larger and smaller without clipping the main content.
- Confirm the empty state offers enabled import and open actions.
- Confirm long status and diagnostics text can be copied from the GUI.
- Confirm cancelled pickers return to a calm ready state instead of a scary error.

## Known Failure Cases

- `ffmpeg` missing
- unreadable images
- unsupported archive contents
- empty import
- permission denied writing to the workspace
- unsupported Motion Recipe schema versions

## First Real ZIP Verification Status

- Date: 2026-06-28
- Sample folder test: passed
- Real ZIP path tested: `/Users/andrew/Library/CloudStorage/GoogleDrive-digitalghosts269@gmail.com/My Drive/macbook/Starsilk_PlanetaryTemplates/codec_storyboard_s001_s100_outpainted_collection.zip`
- Real ZIP import: passed
- Real ZIP render: passed
- Real ZIP scene count: 100
- Irregular image handling: passed; one portrait source frame was flagged and assigned `problem_insert`
- Known launch quirk: accessibility automation was required in this environment to exercise the file-picker flow reliably
- Output locations: workspace `exports/`, `logs/`, and `temp/`
- Git hygiene: generated media and imported assets remained ignored and were not committed
