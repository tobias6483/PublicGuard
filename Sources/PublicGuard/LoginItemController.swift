import Foundation
import ServiceManagement

struct LoginItemController {
    var canManageLaunchAtLogin: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) throws {
        guard canManageLaunchAtLogin else {
            throw LoginItemError.requiresAppBundle
        }

        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

enum LoginItemError: Error {
    case requiresAppBundle
}
