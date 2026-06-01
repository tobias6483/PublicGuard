import AppKit

@MainActor
final class AlarmPlayer {
    private var timer: Timer?
    private var fileSound: NSSound?
    private var sound = GuardSettings.AlarmSound.appleAlarm

    func start(sound: GuardSettings.AlarmSound) {
        stop()
        self.sound = sound

        if let resource = sound.bundledResource, startBundledSound(named: resource.name, extension: resource.extension) {
            return
        }

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
        fileSound?.stop()
        fileSound = nil
    }

    private func startBundledSound(named name: String, extension fileExtension: String) -> Bool {
        guard let url = Bundle.module.url(forResource: name, withExtension: fileExtension),
              let sound = NSSound(contentsOf: url, byReference: false)
        else {
            return false
        }

        sound.loops = true
        fileSound = sound
        return sound.play()
    }

    private func playBurst() {
        for name in sound.systemSoundNames {
            NSSound(named: NSSound.Name(name))?.play()
        }
    }
}
