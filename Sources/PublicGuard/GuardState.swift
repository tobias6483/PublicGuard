import Foundation

@MainActor
final class GuardState {
    private(set) var isArmed = false
    private(set) var isAlarmActive = false
    let gracePeriodSeconds: Duration = .seconds(5)

    func arm() {
        isArmed = true
        isAlarmActive = false
    }

    func disarm() {
        isArmed = false
        isAlarmActive = false
    }

    func markAlarmActive() {
        isAlarmActive = true
    }
}

enum GuardTrigger {
    case chargerDisconnected
    case systemWillSleep
    case systemDidWake
}
