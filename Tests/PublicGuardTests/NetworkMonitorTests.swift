import XCTest
@testable import PublicGuard

final class NetworkMonitorTests: XCTestCase {
    func testChangeClassifiesSSIDChange() {
        let change = NetworkMonitor.change(previous: "Cafe WiFi", current: "Library WiFi")

        XCTAssertEqual(change.previousSSID, "Cafe WiFi")
        XCTAssertEqual(change.currentSSID, "Library WiFi")
        XCTAssertEqual(change.kind, .ssidChanged)
    }

    func testChangeClassifiesDisconnect() {
        let change = NetworkMonitor.change(previous: "Cafe WiFi", current: nil)

        XCTAssertEqual(change.previousSSID, "Cafe WiFi")
        XCTAssertNil(change.currentSSID)
        XCTAssertEqual(change.kind, .disconnected)
    }

    func testChangeClassifiesConnect() {
        let change = NetworkMonitor.change(previous: nil, current: "Cafe WiFi")

        XCTAssertNil(change.previousSSID)
        XCTAssertEqual(change.currentSSID, "Cafe WiFi")
        XCTAssertEqual(change.kind, .connected)
    }
}
