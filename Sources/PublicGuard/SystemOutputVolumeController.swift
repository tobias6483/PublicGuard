import CoreAudio
import Foundation

struct SystemOutputVolumeSnapshot: Equatable {
    var deviceID: AudioDeviceID
    var volumeByChannel: [UInt32: Float32]
    var muteByChannel: [UInt32: UInt32]
}

protocol SystemOutputVolumeControlling {
    func maximizeOutputVolume() -> SystemOutputVolumeSnapshot?
    func restoreOutputVolume(_ snapshot: SystemOutputVolumeSnapshot)
}

struct SystemOutputVolumeController: SystemOutputVolumeControlling {
    private let channels: [UInt32] = [0, 1, 2]

    func maximizeOutputVolume() -> SystemOutputVolumeSnapshot? {
        guard let deviceID = defaultOutputDeviceID else {
            return nil
        }

        var volumeByChannel: [UInt32: Float32] = [:]
        var muteByChannel: [UInt32: UInt32] = [:]

        for channel in channels {
            if let mute = getUInt32(deviceID: deviceID, selector: kAudioDevicePropertyMute, channel: channel) {
                muteByChannel[channel] = mute
                setUInt32(deviceID: deviceID, selector: kAudioDevicePropertyMute, channel: channel, value: 0)
            }
            if let volume = getFloat32(deviceID: deviceID, selector: kAudioDevicePropertyVolumeScalar, channel: channel) {
                volumeByChannel[channel] = volume
                setFloat32(deviceID: deviceID, selector: kAudioDevicePropertyVolumeScalar, channel: channel, value: 1.0)
            }
        }

        guard !volumeByChannel.isEmpty || !muteByChannel.isEmpty else {
            return nil
        }

        return SystemOutputVolumeSnapshot(
            deviceID: deviceID,
            volumeByChannel: volumeByChannel,
            muteByChannel: muteByChannel
        )
    }

    func restoreOutputVolume(_ snapshot: SystemOutputVolumeSnapshot) {
        for (channel, volume) in snapshot.volumeByChannel {
            setFloat32(
                deviceID: snapshot.deviceID,
                selector: kAudioDevicePropertyVolumeScalar,
                channel: channel,
                value: volume
            )
        }
        for (channel, mute) in snapshot.muteByChannel {
            setUInt32(
                deviceID: snapshot.deviceID,
                selector: kAudioDevicePropertyMute,
                channel: channel,
                value: mute
            )
        }
    }

    private var defaultOutputDeviceID: AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr, deviceID != kAudioObjectUnknown else {
            return nil
        }

        return deviceID
    }

    private func getFloat32(deviceID: AudioDeviceID, selector: AudioObjectPropertySelector, channel: UInt32) -> Float32? {
        withReadableProperty(deviceID: deviceID, selector: selector, channel: channel) { address in
            var value: Float32 = 0
            var size = UInt32(MemoryLayout<Float32>.size)
            let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
            return status == noErr ? value : nil
        }
    }

    private func setFloat32(deviceID: AudioDeviceID, selector: AudioObjectPropertySelector, channel: UInt32, value: Float32) {
        withSettableProperty(deviceID: deviceID, selector: selector, channel: channel) { address in
            var mutableValue = value
            let size = UInt32(MemoryLayout<Float32>.size)
            AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &mutableValue)
        }
    }

    private func getUInt32(deviceID: AudioDeviceID, selector: AudioObjectPropertySelector, channel: UInt32) -> UInt32? {
        withReadableProperty(deviceID: deviceID, selector: selector, channel: channel) { address in
            var value: UInt32 = 0
            var size = UInt32(MemoryLayout<UInt32>.size)
            let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
            return status == noErr ? value : nil
        }
    }

    private func setUInt32(deviceID: AudioDeviceID, selector: AudioObjectPropertySelector, channel: UInt32, value: UInt32) {
        withSettableProperty(deviceID: deviceID, selector: selector, channel: channel) { address in
            var mutableValue = value
            let size = UInt32(MemoryLayout<UInt32>.size)
            AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &mutableValue)
        }
    }

    private func withReadableProperty<T>(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        channel: UInt32,
        perform: (inout AudioObjectPropertyAddress) -> T?
    ) -> T? {
        var address = outputAddress(selector: selector, channel: channel)
        guard AudioObjectHasProperty(deviceID, &address) else {
            return nil
        }

        return perform(&address)
    }

    private func withSettableProperty(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        channel: UInt32,
        perform: (inout AudioObjectPropertyAddress) -> Void
    ) {
        var address = outputAddress(selector: selector, channel: channel)
        var isSettable = DarwinBoolean(false)
        guard AudioObjectHasProperty(deviceID, &address),
              AudioObjectIsPropertySettable(deviceID, &address, &isSettable) == noErr,
              isSettable.boolValue
        else {
            return
        }

        perform(&address)
    }

    private func outputAddress(selector: AudioObjectPropertySelector, channel: UInt32) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: channel
        )
    }
}
