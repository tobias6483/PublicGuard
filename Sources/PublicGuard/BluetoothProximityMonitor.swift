import CoreBluetooth
import Foundation

struct LearnedBluetoothDevice: Equatable {
    let identifier: UUID
    let name: String
}

struct BluetoothProximityMonitorSnapshot: Equatable {
    enum ScanState: Equatable {
        case unavailable(String)
        case idle
        case learning(until: Date)
        case monitoring

        var title: String {
            switch self {
            case let .unavailable(reason):
                "Unavailable: \(reason)"
            case .idle:
                "Idle"
            case .learning:
                "Learning"
            case .monitoring:
                "Monitoring"
            }
        }
    }

    let learnedDevice: LearnedBluetoothDevice?
    let lastSeenTargetAt: Date?
    let lostAfterSeconds: TimeInterval
    let hasSeenTarget: Bool
    let hasReportedCurrentLoss: Bool
    let scanState: ScanState
}

final class BluetoothProximityMonitor: NSObject, CBCentralManagerDelegate {
    var onLearningCandidateFound: ((LearnedBluetoothDevice) -> Void)?
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
        configureTarget(identifier: targetIdentifier, name: targetName)

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

    func configureTarget(identifier: String?, name: String?) {
        target = Self.makeDevice(identifier: identifier, name: name)
        lastSeenTargetAt = nil
        hasSeenTarget = false
        hasReportedCurrentLoss = false
    }

    func updateLostAfterSeconds(_ seconds: Int) {
        lostAfterSeconds = TimeInterval(seconds)
    }

    func resetArmedBaseline() {
        lastSeenTargetAt = nil
        hasSeenTarget = false
        hasReportedCurrentLoss = false
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
        beginLearning(at: Date())
        ensureCentral()
        startTimer()
        updateScanState()
    }

    func beginLearning(at date: Date) {
        bestLearningCandidate = nil
        learningEndsAt = date.addingTimeInterval(learnDurationSeconds)
    }

    func recordLearningCandidate(_ device: LearnedBluetoothDevice, rssi: Int) {
        guard learningEndsAt != nil else { return }

        if bestLearningCandidate == nil || rssi > bestLearningCandidate!.rssi {
            bestLearningCandidate = (device, rssi)
        }
    }

    func finishLearningIfNeeded(at date: Date) -> LearnedBluetoothDevice? {
        guard let learningEndsAt, date >= learningEndsAt else { return nil }

        self.learningEndsAt = nil
        defer {
            bestLearningCandidate = nil
            updateScanState()
        }

        return bestLearningCandidate?.device
    }

    func snapshot() -> BluetoothProximityMonitorSnapshot {
        BluetoothProximityMonitorSnapshot(
            learnedDevice: target,
            lastSeenTargetAt: lastSeenTargetAt,
            lostAfterSeconds: lostAfterSeconds,
            hasSeenTarget: hasSeenTarget,
            hasReportedCurrentLoss: hasReportedCurrentLoss,
            scanState: currentScanState()
        )
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
            recordLearningCandidate(device, rssi: RSSI.intValue)
            return
        }

        guard peripheral.identifier == target?.identifier else { return }
        recordTargetAdvertisement(at: Date())
    }

    func recordTargetAdvertisement(at date: Date) {
        lastSeenTargetAt = date
        hasSeenTarget = true
        hasReportedCurrentLoss = false
    }

    func reportOutOfRangeTargetIfNeeded(at date: Date) -> LearnedBluetoothDevice? {
        guard let target, hasSeenTarget, !hasReportedCurrentLoss, let lastSeenTargetAt else { return nil }
        guard date.timeIntervalSince(lastSeenTargetAt) >= lostAfterSeconds else { return nil }

        hasReportedCurrentLoss = true
        return target
    }

    private func ensureCentral() {
        guard central == nil else { return }
        central = CBCentralManager(delegate: self, queue: .main)
    }

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(poll),
            userInfo: nil,
            repeats: true
        )
        timer?.tolerance = 0.2
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

    private func currentScanState() -> BluetoothProximityMonitorSnapshot.ScanState {
        guard let central else {
            return target == nil && learningEndsAt == nil ? .idle : .unavailable("Bluetooth not initialized")
        }

        guard central.state == .poweredOn else {
            return .unavailable(Self.centralStateTitle(central.state))
        }

        if let learningEndsAt {
            return .learning(until: learningEndsAt)
        }

        if target != nil {
            return .monitoring
        }

        return .idle
    }

    @objc private func poll() {
        let now = Date()
        if let candidate = finishLearningIfNeeded(at: now) {
            onLearningCandidateFound?(candidate)
        }

        if let target = reportOutOfRangeTargetIfNeeded(at: now) {
            onDeviceOutOfRange?(target)
        }
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

    private static func centralStateTitle(_ state: CBManagerState) -> String {
        switch state {
        case .unknown:
            "unknown"
        case .resetting:
            "resetting"
        case .unsupported:
            "unsupported"
        case .unauthorized:
            "unauthorized"
        case .poweredOff:
            "powered off"
        case .poweredOn:
            "powered on"
        @unknown default:
            "unknown state"
        }
    }
}
