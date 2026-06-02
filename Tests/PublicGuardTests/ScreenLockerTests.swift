import XCTest
@testable import PublicGuard

final class ScreenLockerTests: XCTestCase {
    func testLockRunsFirstExecutableCommand() {
        let expectedCommand = ScreenLocker.Command(path: "/usr/bin/true", arguments: ["first"])
        var ranCommands: [ScreenLocker.Command] = []
        let locker = ScreenLocker(commands: [
            expectedCommand,
            ScreenLocker.Command(path: "/usr/bin/false", arguments: ["second"])
        ]) { command in
            ranCommands.append(command)
        }

        XCTAssertTrue(locker.lock())
        XCTAssertEqual(ranCommands, [expectedCommand])
    }

    func testLockFallsBackWhenFirstCommandIsMissing() {
        let fallbackCommand = ScreenLocker.Command(path: "/usr/bin/true", arguments: ["fallback"])
        var ranCommands: [ScreenLocker.Command] = []
        let locker = ScreenLocker(commands: [
            ScreenLocker.Command(path: "/missing/PublicGuard/CGSession", arguments: ["-suspend"]),
            fallbackCommand
        ]) { command in
            ranCommands.append(command)
        }

        XCTAssertTrue(locker.lock())
        XCTAssertEqual(ranCommands, [fallbackCommand])
    }

    func testLockReturnsFalseWhenNoCommandCanRun() {
        let locker = ScreenLocker(commands: [
            ScreenLocker.Command(path: "/missing/PublicGuard/CGSession", arguments: ["-suspend"])
        ]) { _ in
            XCTFail("Missing commands should not be run")
        }

        XCTAssertFalse(locker.lock())
    }
}
