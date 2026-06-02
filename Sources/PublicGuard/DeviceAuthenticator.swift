import Foundation
import LocalAuthentication

protocol DeviceAuthenticationContext {
    func canEvaluateDeviceOwnerAuthentication(error: inout NSError?) -> Bool
    func evaluateDeviceOwnerAuthentication(reason: String) async throws -> Bool
}

extension LAContext: DeviceAuthenticationContext {
    func canEvaluateDeviceOwnerAuthentication(error: inout NSError?) -> Bool {
        canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func evaluateDeviceOwnerAuthentication(reason: String) async throws -> Bool {
        try await evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }
}

struct DeviceAuthenticator {
    private let makeContext: () -> DeviceAuthenticationContext

    init(makeContext: @escaping () -> DeviceAuthenticationContext = { LAContext() }) {
        self.makeContext = makeContext
    }

    @MainActor
    func authenticate(reason: String) async -> Bool {
        let context = makeContext()
        var error: NSError?

        guard context.canEvaluateDeviceOwnerAuthentication(error: &error) else {
            return false
        }

        do {
            return try await context.evaluateDeviceOwnerAuthentication(reason: reason)
        } catch {
            return false
        }
    }
}
