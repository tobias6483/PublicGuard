import AppKit

@MainActor
final class AlarmPlayer {
    private var timer: Timer?
    private let soundNames = ["Basso", "Sosumi", "Ping"]

    func start() {
        stop()
        playBurst()
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playBurst()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func playBurst() {
        for name in soundNames {
            NSSound(named: NSSound.Name(name))?.play()
        }
    }
}
