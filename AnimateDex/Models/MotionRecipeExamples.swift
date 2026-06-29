import Foundation

enum MotionRecipeExample: String, CaseIterable, Identifiable {
    case slowArchiveBuild
    case highEnergyTrailer
    case problemImageSafeInsert
    case verticalSocialCut

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slowArchiveBuild:
            "Slow Archive Build"
        case .highEnergyTrailer:
            "High Energy Trailer"
        case .problemImageSafeInsert:
            "Problem Image Safe Insert"
        case .verticalSocialCut:
            "Vertical Social Cut"
        }
    }

    var json: String {
        switch self {
        case .slowArchiveBuild:
            """
            {
              "schemaVersion": 1,
              "recipeName": "Slow Archive Build",
              "description": "A calm archival pass with longer holds and subtle motion.",
              "target": {
                "matchMode": "sequenceIndex",
                "sceneRange": {
                  "start": 1,
                  "end": 12
                }
              },
              "globalRenderSettings": {
                "outputWidth": 1920,
                "outputHeight": 1080,
                "fps": 24,
                "defaultSceneDuration": 4
              },
              "globalDefaults": {
                "durationSeconds": 4,
                "motionPreset": "gentle_drift",
                "transitionIn": "cut",
                "transitionOut": "cut"
              },
              "sections": [
                {
                  "name": "Opening card",
                  "sceneRange": {
                    "start": 1,
                    "end": 2
                  },
                  "durationSeconds": 5,
                  "motionPreset": "locked_off",
                  "transitionIn": "fade",
                  "transitionOut": "cut",
                  "notes": "Hold the title frames longer."
                },
                {
                  "name": "Core sequence",
                  "sceneRange": {
                    "start": 3,
                    "end": 10
                  },
                  "durationSeconds": 4,
                  "motionPreset": "slow_push_in",
                  "transitionIn": "cut",
                  "transitionOut": "cut",
                  "notes": "Keep motion restrained."
                },
                {
                  "name": "Closer",
                  "sceneRange": {
                    "start": 11,
                    "end": 12
                  },
                  "durationSeconds": 5,
                  "motionPreset": "slow_pull_out",
                  "transitionIn": "cut",
                  "transitionOut": "fade",
                  "notes": "Ease out slowly."
                }
              ],
              "sceneOverrides": [
                {
                  "sequenceIndex": 2,
                  "durationSeconds": 6,
                  "motionPreset": "locked_off",
                  "transitionIn": "fade",
                  "transitionOut": "cut",
                  "notes": "Archive note insert.",
                  "sceneId": "scene-2",
                  "filenameContains": "cover"
                },
                {
                  "sequenceIndex": 12,
                  "durationSeconds": 6,
                  "motionPreset": "slow_pull_out",
                  "transitionIn": "cut",
                  "transitionOut": "fade",
                  "notes": "Final frame accent.",
                  "sceneId": "scene-12",
                  "filenameContains": "outro"
                }
              ]
            }
            """
        case .highEnergyTrailer:
            """
            {
              "schemaVersion": 1,
              "recipeName": "High Energy Trailer",
              "description": "Fast cuts with aggressive motion and punchier timing.",
              "target": {
                "matchMode": "sequenceIndex",
                "sceneRange": {
                  "start": 1,
                  "end": 16
                }
              },
              "globalRenderSettings": {
                "outputWidth": 1920,
                "outputHeight": 1080,
                "fps": 30,
                "defaultSceneDuration": 2.5
              },
              "globalDefaults": {
                "durationSeconds": 2.5,
                "motionPreset": "pan_right",
                "transitionIn": "cut",
                "transitionOut": "cut"
              },
              "sections": [
                {
                  "name": "Cold open",
                  "sceneRange": {
                    "start": 1,
                    "end": 4
                  },
                  "durationSeconds": 2,
                  "motionPreset": "slow_push_in",
                  "transitionIn": "cut",
                  "transitionOut": "cut",
                  "notes": "Stay controlled before the lift."
                },
                {
                  "name": "Main run",
                  "sceneRange": {
                    "start": 5,
                    "end": 12
                  },
                  "durationSeconds": 2.5,
                  "motionPreset": "pan_left",
                  "transitionIn": "cut",
                  "transitionOut": "cut",
                  "notes": "Keep the frame moving."
                },
                {
                  "name": "Finish",
                  "sceneRange": {
                    "start": 13,
                    "end": 16
                  },
                  "durationSeconds": 3,
                  "motionPreset": "pulse_glow",
                  "transitionIn": "cut",
                  "transitionOut": "fade",
                  "notes": "Land the ending with a softer feel."
                }
              ],
              "sceneOverrides": [
                {
                  "sequenceIndex": 4,
                  "durationSeconds": 3,
                  "motionPreset": "pulse_glow",
                  "transitionIn": "cut",
                  "transitionOut": "cut",
                  "notes": "Accent frame.",
                  "sceneId": "scene-4"
                }
              ]
            }
            """
        case .problemImageSafeInsert:
            """
            {
              "schemaVersion": 1,
              "recipeName": "Problem Image Safe Insert",
              "description": "A conservative pass for mixed or problematic assets.",
              "target": {
                "matchMode": "sequenceIndex",
                "sceneRange": {
                  "start": 1,
                  "end": 8
                }
              },
              "globalRenderSettings": {
                "outputWidth": 1920,
                "outputHeight": 1080,
                "fps": 30,
                "defaultSceneDuration": 3
              },
              "globalDefaults": {
                "durationSeconds": 3,
                "motionPreset": "problem_insert",
                "transitionIn": "cut",
                "transitionOut": "cut"
              },
              "sections": [
                {
                  "name": "Safe pass",
                  "sceneRange": {
                    "start": 1,
                    "end": 8
                  },
                  "durationSeconds": 3,
                  "motionPreset": "problem_insert",
                  "transitionIn": "cut",
                  "transitionOut": "cut",
                  "notes": "Prefer stable framing for any odd source frames."
                }
              ],
              "sceneOverrides": [
                {
                  "sequenceIndex": 3,
                  "durationSeconds": 4,
                  "motionPreset": "locked_off",
                  "transitionIn": "fade",
                  "transitionOut": "cut",
                  "notes": "Freeze the most sensitive asset."
                }
              ]
            }
            """
        case .verticalSocialCut:
            """
            {
              "schemaVersion": 1,
              "recipeName": "Vertical Social Cut",
              "description": "Portrait-friendly framing with compact timing.",
              "target": {
                "matchMode": "sequenceIndex",
                "sceneRange": {
                  "start": 1,
                  "end": 10
                }
              },
              "globalRenderSettings": {
                "outputWidth": 1080,
                "outputHeight": 1920,
                "fps": 30,
                "defaultSceneDuration": 2.75
              },
              "globalDefaults": {
                "durationSeconds": 2.75,
                "motionPreset": "gentle_drift",
                "transitionIn": "cut",
                "transitionOut": "cut"
              },
              "sections": [
                {
                  "name": "Hook",
                  "sceneRange": {
                    "start": 1,
                    "end": 3
                  },
                  "durationSeconds": 2,
                  "motionPreset": "slow_push_in",
                  "transitionIn": "cut",
                  "transitionOut": "cut",
                  "notes": "Front-load the strongest scenes."
                },
                {
                  "name": "Middle",
                  "sceneRange": {
                    "start": 4,
                    "end": 8
                  },
                  "durationSeconds": 2.75,
                  "motionPreset": "pan_up",
                  "transitionIn": "cut",
                  "transitionOut": "cut",
                  "notes": "Keep the motion vertical."
                },
                {
                  "name": "Closer",
                  "sceneRange": {
                    "start": 9,
                    "end": 10
                  },
                  "durationSeconds": 3,
                  "motionPreset": "slow_pull_out",
                  "transitionIn": "cut",
                  "transitionOut": "fade",
                  "notes": "Finish cleanly."
                }
              ],
              "sceneOverrides": [
                {
                  "sequenceIndex": 1,
                  "durationSeconds": 3,
                  "motionPreset": "locked_off",
                  "transitionIn": "fade",
                  "transitionOut": "cut",
                  "notes": "Intro card."
                }
              ]
            }
            """
        }
    }
}
