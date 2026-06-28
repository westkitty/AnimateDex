# Architecture

AnimateDex is a native macOS SwiftUI application built as a Swift Package.

## Layers

- `App`: application entry point and top-level window wiring
- `Models`: durable JSON-backed project data
- `Services`: import, inspection, sequence ordering, workspace management, and rendering
- `Views`: dashboard, sequence browser, inspector, validation, and render panels
- `Utilities`: JSON, process execution, and sort helpers

## Data Flow

1. User creates or opens a workspace.
2. Import service copies supported images into `assets/originals`.
3. Inspection service reads dimensions, file sizes, and orientation.
4. Sequence detection service assigns a generic order.
5. Validation issues are derived from import and sequence results.
6. Project JSON files are written to the workspace.
7. Render service checks `ffmpeg`, renders scene segments, and concatenates them into MP4.

## Project Workspace

Each workspace is a `.animdex` folder containing:

- `animate_project.json`
- `scene_plan.json`
- `import_report.json`
- `assets/originals`
- `assets/working`
- `exports`
- `logs`
- `temp`

## JSON Schema

The project file stores the workspace identity, source path, and render settings.
The scene plan stores one scene per imported image with deterministic ordering and motion preset assignment.
The import report stores unsupported files, unreadable assets, and validation issues.

## Why It Is Project-Agnostic

The importer only uses file metadata and image dimensions. It does not encode storyboard-specific names, counts, or dimensions. Sequence ordering is numeric-first but generic, with natural sort and import order as fallbacks.
