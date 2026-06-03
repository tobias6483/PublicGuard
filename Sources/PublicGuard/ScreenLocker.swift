import Foundation

struct ScreenLocker {
    struct Command: Equatable {
        var path: String
        var arguments: [String]
    }

    private let commands: [Command]
    private let fileManager: FileManager
    private let runProcess: (Command) throws -> Void

    init(
        commands: [Command] = Self.defaultCommands,
        fileManager: FileManager = .default,
        runProcess: @escaping (Command) throws -> Void = Self.runProcess
    ) {
        self.commands = commands
        self.fileManager = fileManager
        self.runProcess = runProcess
    }

    @discardableResult
    func lock() -> Bool {
        for command in commands where fileManager.isExecutableFile(atPath: command.path) {
            do {
                try runProcess(command)
                return true
            } catch {
                continue
            }
        }

        return false
    }

    func isAvailable() -> Bool {
        commands.contains { fileManager.isExecutableFile(atPath: $0.path) }
    }

    private static let defaultCommands = [
        Command(
            path: "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession",
            arguments: ["-suspend"]
        ),
        Command(path: "/usr/bin/pmset", arguments: ["displaysleepnow"])
    ]

    private static func runProcess(_ command: Command) throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: command.path)
        task.arguments = command.arguments
        try task.run()
    }
}
