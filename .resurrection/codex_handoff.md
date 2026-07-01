# Codex Handoff: AnimateDex

Read this handoff and project_report.md first.

## Project Identity
- Name: AnimateDex
- Path: /Users/andrew/AnimateDex
- Purpose: Purpose could not be inferred confidently from filesystem signals.

## Current Git State
- Repo root: /Users/andrew/AnimateDex | Branch: feature/macos-ui-ux-overhaul | Status: dirty | Remote: git@github.com:westkitty/AnimateDex.git
- Latest commit: c6348264fc37425ea13eddbc293ba769cd639a99 Add native app bundle launch path

## Detected Project Type
- Type: swift_package
- Confidence: 0.75
- Evidence:
  - Found Package.swift

## Likely Commands
- [build] swift build
- [test] swift test

## Fragile Files
- .build/arm64-apple-macosx/debug/AnimateDex-entitlement.plist
- .build/arm64-apple-macosx/debug/AnimateDex.dSYM/Contents/Info.plist
- .build/arm64-apple-macosx/debug/AnimateDexPackageTests.xctest/Contents/MacOS/AnimateDexPackageTests.dSYM/Contents/Info.plist
- examples/sample_project/README.md
- README.md

## Duplicate Or Stale Candidates
- sibling-near-duplicate: dex

## Secret-Risk Warning Summary
No secret-risk matches detected.

## Top 5 Recommended Next Actions
1. Inspect the current uncommitted Git changes before making new edits.
2. Back up or review fragile configuration files before any risky changes.
3. Validate the project with the hinted test command: swift test
4. Validate the project with the hinted build command: swift build
5. Read `.resurrection/project_report.md` and make one bounded change at a time.

## Strict Codex Instruction Block

Read this handoff and project_report.md first.
Make one bounded change only.
Do not rewrite the project.
Do not delete or reorganize files.
Inspect existing files before editing.
Run the smallest relevant validation command available.
If validation cannot be run, explain why.
Report changed files, commands run, test results, and remaining risks.
