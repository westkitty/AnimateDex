import Foundation

enum MotionPreset: String, Codable, Sendable, CaseIterable, Identifiable {
    case lockedOff = "locked_off"
    case slowPushIn = "slow_push_in"
    case slowPullOut = "slow_pull_out"
    case panLeft = "pan_left"
    case panRight = "pan_right"
    case panUp = "pan_up"
    case panDown = "pan_down"
    case gentleDrift = "gentle_drift"
    case pulseGlow = "pulse_glow"
    case problemInsert = "problem_insert"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lockedOff: "Locked Off"
        case .slowPushIn: "Slow Push In"
        case .slowPullOut: "Slow Pull Out"
        case .panLeft: "Pan Left"
        case .panRight: "Pan Right"
        case .panUp: "Pan Up"
        case .panDown: "Pan Down"
        case .gentleDrift: "Gentle Drift"
        case .pulseGlow: "Pulse Glow"
        case .problemInsert: "Problem Insert"
        }
    }

    var shortDescription: String {
        switch self {
        case .lockedOff: "No motion. Useful as a stable fallback."
        case .slowPushIn: "Slow zoom toward the center."
        case .slowPullOut: "Slow zoom away from the center."
        case .panLeft: "Move the frame left."
        case .panRight: "Move the frame right."
        case .panUp: "Move the frame up."
        case .panDown: "Move the frame down."
        case .gentleDrift: "Small diagonal drift with a mild zoom."
        case .pulseGlow: "Soft pulse effect; may fall back to gentle drift."
        case .problemInsert: "Safe fallback for irregular or problematic assets."
        }
    }

    var safeForIrregularImages: Bool {
        switch self {
        case .lockedOff, .problemInsert, .gentleDrift:
            true
        case .pulseGlow:
            true
        case .slowPushIn, .slowPullOut, .panLeft, .panRight, .panUp, .panDown:
            false
        }
    }
}
