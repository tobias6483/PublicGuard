# Lid-Close Research

PublicGuard should be honest about lid-close behavior. The current implementation uses
`NSWorkspace.willSleepNotification` and `NSWorkspace.didWakeNotification` through
`SleepWakeMonitor`, which is appropriate for the MVP but does not guarantee a live
alarm while a MacBook lid is closed.

## Current Behavior

- While armed, PublicGuard logs `system_will_sleep` when macOS reports sleep.
- While armed, PublicGuard starts the configured response after wake.
- PublicGuard does not claim to keep running during closed-lid sleep.

Apple documents `NSWorkspace.willSleepNotification` as a notification posted before
the device sleeps, and notes that handlers can delay sleep for up to 30 seconds.
Apple also documents `NSWorkspace.didWakeNotification` for wake events.

## Lower-Level Option

`IORegisterForSystemPower` can register for root power domain sleep/wake
notifications. It provides more explicit power lifecycle events than
`NSWorkspace`, including `kIOMessageSystemWillSleep`. Apps must acknowledge some
messages, and Apple notes a 30-second timeout if sleep is not acknowledged.

This may be useful later if PublicGuard needs more precise event logging or manual
QA shows that `NSWorkspace` events are too high-level.

## Power Assertions

IOKit power assertions can request that macOS avoid idle sleep. Apple describes
these as suggestions that the OS honors only when possible; low power or thermal
conditions may still force sleep.

PublicGuard should not hold broad sleep-prevention assertions by default. That
would be surprising for a privacy-first utility and could harm battery life. If a
future version experiments with assertions, it should be explicit, temporary, and
user controlled.

## Recommendation For v0.1

Keep the current sleep/wake trigger and document the limitation clearly:

- PublicGuard can react when the Mac wakes while armed.
- PublicGuard may log that sleep is about to happen.
- PublicGuard does not guarantee alarm playback while the lid remains closed.

Before changing behavior, run a manual hardware QA pass on at least one Apple
silicon MacBook and record whether `willSleep` and `didWake` events are written
reliably when the lid is closed and reopened.

## References

- Apple Developer Documentation: [`NSWorkspace.willSleepNotification`](https://developer.apple.com/documentation/appkit/nsworkspace/willsleepnotification)
- Apple Developer Documentation: [`NSWorkspace.didWakeNotification`](https://developer.apple.com/documentation/appkit/nsworkspace/didwakenotification)
- Apple Developer Documentation: [`IORegisterForSystemPower`](https://developer.apple.com/documentation/iokit/1557114-ioregisterforsystempower)
- Apple Developer Documentation: [`IOPMAssertionTypes`](https://developer.apple.com/documentation/iokit/iopmlib_h/iopmassertiontypes)
