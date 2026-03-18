# DivineSleep

[中文说明](./README.zh-CN.md)

DivineSleep is a lightweight macOS menu bar utility for focus sessions, sleep countdowns, wake-lock control, and quick sleep actions.

## Features

- Pomodoro mode and sleep timer mode
- Preset duration cards for quick start
- Battery-mode and power-mode wake prevention
- Immediate sleep action from the panel or menu bar menu
- Fast display sleep within 10 seconds of locking the screen while wake prevention is active
- Light, dark, and system theme support
- Session restore after relaunch if a timer was still running
- In-app notification permission status and request flow
- Automated tests for core state and timer behavior

## Requirements

- macOS 12.0 or later
- Xcode / Command Line Tools with Swift 5.7+ support

## Run

```bash
swift run DivineSleep
```

The app runs as a menu bar utility and does not appear as a normal Dock app.

## Build

Debug build:

```bash
swift build
```

Release app bundle:

```bash
./build_app.sh
```

Release DMG:

```bash
./build_dmg.sh
```

The packaging script resolves paths from its own location, so it can also be invoked from another working directory, for example:

```bash
/path/to/DivineSleep/build_app.sh
```

Generated app:

```text
.build/release-app/DivineSleep.app
```

Generated DMG:

```text
DivineSleep-<CFBundleShortVersionString>-macos-<arch>.dmg
```

## Test

```bash
swift test
```

Current tests cover:

- preference persistence
- per-mode preset restore
- active timer restore after relaunch
- expired session cleanup
- wake prevention toggles
- notification permission flow
- timer completion behavior

## Notifications

DivineSleep uses macOS User Notifications for timer completion and system action feedback.

If notifications are disabled:

1. Open `System Settings`
2. Go to `Notifications`
3. Find `DivineSleep`
4. Enable alerts and sounds

You can also refresh or request notification access from inside the app panel.

## Notes

- Wake prevention uses `caffeinate`
- Sleep actions and fast display sleep use `pmset`
- The packaged app version is defined in [`Info.plist`](./Info.plist)
