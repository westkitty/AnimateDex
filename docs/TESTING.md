# Testing

## Manual Flow

1. Run `./scripts/doctor.sh`.
2. Run `swift build`.
3. Run `swift test`.
4. Launch the app with `swift run`.
5. Create a workspace and import `examples/sample_project/images`.
6. Confirm the sequence browser shows `image1.png`, `image2.png`, `image10.png`.
7. Render a proof MP4.

## Sample Project

Generate the sample images with:

```bash
./scripts/make_sample_project.sh
```

## Render Validation

- Confirm the MP4 exists in `exports/`.
- Confirm `render_manifest.json` exists.
- Confirm `render_log.txt` contains the ffmpeg command output.

## Known Failure Cases

- `ffmpeg` missing
- unreadable images
- unsupported archive contents
- empty import
- permission denied writing to the workspace
