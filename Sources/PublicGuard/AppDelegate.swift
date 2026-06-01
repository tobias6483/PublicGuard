import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: PublicGuardController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = PublicGuardController()
        controller?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }
}
