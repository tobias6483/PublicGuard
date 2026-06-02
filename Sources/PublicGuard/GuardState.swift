import Foundation

@MainActor
final class GuardState {
    private(set) var isArmed = false
    private(set) var isAlarmActive = false

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

    func markAlarmInactive() {
        isAlarmActive = false
    }
}

enum GuardTrigger {
    case chargerDisconnected
    case networkChanged(NetworkChange)
    case bluetoothDeviceOutOfRange(name: String)
    case idleTimeout(seconds: Int)
    case systemWillSleep
    case systemDidWake
}
