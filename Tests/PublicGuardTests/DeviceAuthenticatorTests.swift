import XCTest
@testable import PublicGuard

final class DeviceAuthenticatorTests: XCTestCase {
    func testAuthenticateFailsClosedWhenPolicyCannotBeEvaluated() async {
        let authenticator = DeviceAuthenticator {
            StubDeviceAuthenticationContext(canEvaluate: false, evaluationResult: true)
        }

        let allowed = await authenticator.authenticate(reason: "Disarm PublicGuard")

        XCTAssertFalse(allowed)
    }

    func testAuthenticateReturnsPolicyEvaluationResult() async {
        let authenticator = DeviceAuthenticator {
            StubDeviceAuthenticationContext(canEvaluate: true, evaluationResult: false)
        }

        let allowed = await authenticator.authenticate(reason: "Disarm PublicGuard")

        XCTAssertFalse(allowed)
    }

    func testAuthenticateFailsWhenPolicyEvaluationThrows() async {
        let authenticator = DeviceAuthenticator {
            StubDeviceAuthenticationContext(canEvaluate: true, evaluationError: AuthenticationStubError.failed)
        }

        let allowed = await authenticator.authenticate(reason: "Disarm PublicGuard")

        XCTAssertFalse(allowed)
    }
}

private struct StubDeviceAuthenticationContext: DeviceAuthenticationContext {
    let canEvaluate: Bool
    var evaluationResult = true
    var evaluationError: Error?

    func canEvaluateDeviceOwnerAuthentication(error: inout NSError?) -> Bool {
        canEvaluate
    }

    func evaluateDeviceOwnerAuthentication(reason: String) async throws -> Bool {
        if let evaluationError {
            throw evaluationError
        }

        return evaluationResult
    }
}

private enum AuthenticationStubError: Error {
    case failed
}
