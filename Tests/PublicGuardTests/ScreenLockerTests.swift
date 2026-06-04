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
            return 0
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
            return 0
        }

        XCTAssertTrue(locker.lock())
        XCTAssertEqual(ranCommands, [fallbackCommand])
    }

    func testLockReturnsFalseWhenNoCommandCanRun() {
        let locker = ScreenLocker(commands: [
            ScreenLocker.Command(path: "/missing/PublicGuard/CGSession", arguments: ["-suspend"])
        ]) { _ in
            XCTFail("Missing commands should not be run")
            return 1
        }

        XCTAssertFalse(locker.lock())
    }

    func testLockFallsBackWhenExecutableCommandExitsNonZero() {
        let failingCommand = ScreenLocker.Command(path: "/usr/bin/false", arguments: ["first"])
        let fallbackCommand = ScreenLocker.Command(path: "/usr/bin/true", arguments: ["fallback"])
        var ranCommands: [ScreenLocker.Command] = []
        let locker = ScreenLocker(commands: [
            failingCommand,
            fallbackCommand
        ]) { command in
            ranCommands.append(command)
            return command == failingCommand ? 1 : 0
        }

        XCTAssertTrue(locker.lock())
        XCTAssertEqual(ranCommands, [failingCommand, fallbackCommand])
    }

    func testLockReturnsFalseWhenExecutableCommandsExitNonZero() {
        let command = ScreenLocker.Command(path: "/usr/bin/false", arguments: ["fail"])
        var ranCommands: [ScreenLocker.Command] = []
        let locker = ScreenLocker(commands: [
            command
        ]) { command in
            ranCommands.append(command)
            return 1
        }

        XCTAssertFalse(locker.lock())
        XCTAssertEqual(ranCommands, [command])
    }

    func testAvailabilityReflectsExecutableCommands() {
        let availableLocker = ScreenLocker(commands: [
            ScreenLocker.Command(path: "/usr/bin/true", arguments: [])
        ])
        let unavailableLocker = ScreenLocker(commands: [
            ScreenLocker.Command(path: "/missing/PublicGuard/CGSession", arguments: ["-suspend"])
        ])

        XCTAssertTrue(availableLocker.isAvailable())
        XCTAssertFalse(unavailableLocker.isAvailable())
    }
}
