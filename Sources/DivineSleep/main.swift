import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let sleepManager = SleepManager()
    private let popover = NSPopover()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configurePopover()
        bindState()
        updateMenuBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cancellables.removeAll()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        button.imagePosition = .imageLeft
    }

    private func configurePopover() {
        let rootView = MenuView(sleepManager: sleepManager)
        let hostingController = NSHostingController(rootView: rootView)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 430, height: 700)
        popover.contentViewController = hostingController
        popover.appearance = sleepManager.theme.appearance
    }

    private func bindState() {
        sleepManager.$remainingSeconds
            .combineLatest(sleepManager.$isTimerRunning, sleepManager.$mode)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)

        sleepManager.$theme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                self?.popover.appearance = theme.appearance
            }
            .store(in: &cancellables)

        LanguageManager.shared.$current
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)
    }

    @objc
    private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        if sleepManager.isTimerRunning {
            menu.addItem(
                withTitle: L10n.contextMenuCancelTimer,
                action: #selector(cancelTimerFromMenu),
                keyEquivalent: ""
            )
            menu.addItem(.separator())
        }

        menu.addItem(
            withTitle: popover.isShown ? L10n.contextMenuCollapsePanel : L10n.contextMenuExpandPanel,
            action: #selector(togglePopoverFromMenu),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: L10n.contextMenuSleepNow,
            action: #selector(sleepNowFromMenu),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: L10n.contextMenuQuit,
            action: #selector(quit),
            keyEquivalent: "q"
        )

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc
    private func togglePopoverFromMenu() {
        guard let button = statusItem.button else { return }
        togglePopover(button)
    }

    @objc
    private func cancelTimerFromMenu() {
        sleepManager.cancelTimer()
    }

    @objc
    private func sleepNowFromMenu() {
        sleepManager.sleepNow()
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func updateMenuBar() {
        guard let button = statusItem.button else { return }

        if sleepManager.isTimerRunning {
            let prefix = sleepManager.mode == .pomodoro ? "🍅" : "🌙"
            button.title = "\(prefix) \(sleepManager.formattedRemainingTime())"
        } else {
            button.title = "☾ DivineSleep"
        }

        button.toolTip = sleepManager.isTimerRunning
            ? "\(sleepManager.mode.title)：\(sleepManager.formattedRemainingTime())"
            : L10n.appTitle
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
