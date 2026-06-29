# Architecture

AnimateDex is a native macOS SwiftUI application built as a Swift Package.

## Layers

- `App`: application entry point and top-level window wiring
- `Models`: durable JSON-backed project data
- `Services`: import, inspection, sequence ordering, workspace management, Motion Recipe application, AI prompt brief generation, and rendering
- `Views`: dashboard, sequence browser, inspector, validation, Motion Recipe, and render panels
- `Utilities`: JSON, process execution, and sort helpers

## Data Flow

1. User creates or opens a workspace.
2. Import service copies supported images into `assets/originals`.
3. Inspection service reads dimensions, file sizes, and orientation.
4. Sequence detection service assigns a generic order.
5. Validation issues are derived from import and sequence results.
6. Motion Recipe validation and preview run against the current scene plan when text is present.
7. Project JSON files are written to the workspace.
8. Render service checks `ffmpeg`, renders scene segments, and concatenates them into MP4.

## Project Workspace

Each workspace is a `.animdex` folder containing:

- `animate_project.json`
- `scene_plan.json`
- `import_report.json`
- `motion_recipe_applied.json`
- `motion_recipe_report.txt`
- `scene_plan.before_motion_recipe.json`
- `assets/originals`
- `assets/working`
- `exports`
- `logs`
- `temp`

## JSON Schema

The project file stores the workspace identity, source path, and render settings.
The scene plan stores one scene per imported image with deterministic ordering and motion preset assignment.
The import report stores unsupported files, unreadable assets, and validation issues.
The Motion Recipe report stores the deterministic change set, backup path, ignored fields, and warnings from the last apply operation.

## Why It Is Project-Agnostic

The importer only uses file metadata and image dimensions. It does not encode storyboard-specific names, counts, or dimensions. Sequence ordering is numeric-first but generic, with natural sort and import order as fallbacks.
