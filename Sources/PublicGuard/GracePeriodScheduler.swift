import Foundation

@MainActor
final class GracePeriodScheduler {
    private var task: Task<Void, Never>?

    var hasPendingGracePeriod: Bool {
        task != nil
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func schedule(after duration: Duration, action: @escaping @MainActor () -> Void) -> Bool {
        guard task == nil else { return false }

        task = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }
                self.task = nil
                action()
            }
        }

        return true
    }
}
