import CoreBluetooth
import Foundation

struct LearnedBluetoothDevice: Equatable {
    let identifier: UUID
    let name: String
}

final class BluetoothProximityMonitor: NSObject, CBCentralManagerDelegate {
    var onDeviceLearned: ((LearnedBluetoothDevice) -> Void)?
    var onDeviceOutOfRange: ((LearnedBluetoothDevice) -> Void)?

    private var lostAfterSeconds: TimeInterval
    private let learnDurationSeconds: TimeInterval
    private var central: CBCentralManager?
    private var target: LearnedBluetoothDevice?
    private var lastSeenTargetAt: Date?
    private var hasSeenTarget = false
    private var hasReportedCurrentLoss = false
    private var bestLearningCandidate: (device: LearnedBluetoothDevice, rssi: Int)?
    private var learningEndsAt: Date?
    private var timer: Timer?

    init(lostAfterSeconds: TimeInterval = 30, learnDurationSeconds: TimeInterval = 12) {
        self.lostAfterSeconds = lostAfterSeconds
        self.learnDurationSeconds = learnDurationSeconds
    }

    func start(targetIdentifier: String?, targetName: String?) {
        target = Self.makeDevice(identifier: targetIdentifier, name: targetName)
        lastSeenTargetAt = nil
        hasSeenTarget = false
        hasReportedCurrentLoss = false

        if target == nil {
            timer?.invalidate()
            timer = nil
            central?.stopScan()
            return
        }

        ensureCentral()
        startTimer()
        updateScanState()
    }

    func updateLostAfterSeconds(_ seconds: Int) {
        lostAfterSeconds = TimeInterval(seconds)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        central?.stopScan()
        central?.delegate = nil
        central = nil
        learningEndsAt = nil
        bestLearningCandidate = nil
    }

    func learnNearbyDevice() {
        bestLearningCandidate = nil
        learningEndsAt = Date().addingTimeInterval(learnDurationSeconds)
        ensureCentral()
        startTimer()
        updateScanState()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateScanState()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard RSSI.intValue != 127 else { return }

        let deviceName = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? "Unknown BLE Device"
        let device = LearnedBluetoothDevice(identifier: peripheral.identifier, name: deviceName)

        if learningEndsAt != nil {
            if bestLearningCandidate == nil || RSSI.intValue > bestLearningCandidate!.rssi {
                bestLearningCandidate = (device, RSSI.intValue)
            }
            return
        }

        guard peripheral.identifier == target?.identifier else { return }
        lastSeenTargetAt = Date()
        hasSeenTarget = true
        hasReportedCurrentLoss = false
    }

    private func ensureCentral() {
        guard central == nil else { return }
        central = CBCentralManager(delegate: self, queue: .main)
    }

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(
            timeInterval: 2,
            target: self,
            selector: #selector(poll),
            userInfo: nil,
            repeats: true
        )
    }

    private func updateScanState() {
        guard central?.state == .poweredOn else { return }

        if learningEndsAt != nil || target != nil {
            central?.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        } else {
            central?.stopScan()
        }
    }

    @objc private func poll() {
        if let learningEndsAt, Date() >= learningEndsAt {
            self.learningEndsAt = nil
            if let candidate = bestLearningCandidate {
                target = candidate.device
                lastSeenTargetAt = Date()
                hasSeenTarget = true
                hasReportedCurrentLoss = false
                onDeviceLearned?(candidate.device)
            }
            bestLearningCandidate = nil
            updateScanState()
        }

        guard let target, hasSeenTarget, !hasReportedCurrentLoss, let lastSeenTargetAt else { return }
        guard Date().timeIntervalSince(lastSeenTargetAt) >= lostAfterSeconds else { return }

        hasReportedCurrentLoss = true
        onDeviceOutOfRange?(target)
    }

    private static func makeDevice(identifier: String?, name: String?) -> LearnedBluetoothDevice? {
        guard
            let identifier,
            let uuid = UUID(uuidString: identifier)
        else {
            return nil
        }

        return LearnedBluetoothDevice(identifier: uuid, name: name ?? "Bluetooth Device")
    }
}
