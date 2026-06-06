import AppKit

@MainActor
final class AlarmPlayer {
    private var timer: Timer?
    private var fileSound: NSSound?
    private let systemOutputVolume: SystemOutputVolumeControlling
    private var systemOutputVolumeSnapshot: SystemOutputVolumeSnapshot?
    private var sound = GuardSettings.AlarmSound.appleAlarm
    private var volume = GuardSettings.AlarmVolume.normal

    init(systemOutputVolume: SystemOutputVolumeControlling = SystemOutputVolumeController()) {
        self.systemOutputVolume = systemOutputVolume
    }

    func start(sound: GuardSettings.AlarmSound, volume: GuardSettings.AlarmVolume) {
        stop()
        self.sound = sound
        self.volume = volume
        if volume.raisesSystemOutputVolume {
            systemOutputVolumeSnapshot = systemOutputVolume.maximizeOutputVolume()
        }

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
        if let snapshot = systemOutputVolumeSnapshot {
            systemOutputVolume.restoreOutputVolume(snapshot)
            systemOutputVolumeSnapshot = nil
        }
    }

    private func startBundledSound(named name: String, extension fileExtension: String) -> Bool {
        guard let url = Bundle.module.url(forResource: name, withExtension: fileExtension),
              let sound = NSSound(contentsOf: url, byReference: false)
        else {
            return false
        }

        sound.loops = true
        sound.volume = volume.soundVolume
        fileSound = sound
        return sound.play()
    }

    private func playBurst() {
        for name in sound.systemSoundNames {
            let systemSound = NSSound(named: NSSound.Name(name))
            systemSound?.volume = volume.soundVolume
            systemSound?.play()
        }
    }
}
