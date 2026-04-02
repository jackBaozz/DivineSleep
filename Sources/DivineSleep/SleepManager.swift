import AppKit
import Combine
import Foundation
import SwiftUI
import UserNotifications

enum TimerMode: String, CaseIterable, Identifiable {
    case pomodoro
    case sleepTimer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pomodoro:
            return L10n.pomodoroTitle
        case .sleepTimer:
            return L10n.sleepTimerTitle
        }
    }

    var subtitle: String {
        switch self {
        case .pomodoro:
            return L10n.pomodoroSubtitle
        case .sleepTimer:
            return L10n.sleepTimerSubtitle
        }
    }

    var icon: String {
        switch self {
        case .pomodoro:
            return "🍅"
        case .sleepTimer:
            return "😴"
        }
    }

    var defaultPreset: Int {
        switch self {
        case .pomodoro:
            return 25
        case .sleepTimer:
            return 30
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            return L10n.themeLight
        case .dark:
            return L10n.themeDark
        case .system:
            return L10n.themeSystem
        }
    }

    var icon: String {
        switch self {
        case .light:
            return "☀️"
        case .dark:
            return "🌙"
        case .system:
            return "💻"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        case .system:
            return nil
        }
    }
}

struct TimerPreset: Identifiable, Hashable {
    let minutes: Int

    var id: Int { minutes }

    var valueText: String {
        if minutes >= 60, minutes % 60 == 0 {
            return "\(minutes / 60)"
        }

        return "\(minutes)"
    }

    var unitText: String {
        if minutes >= 60, minutes % 60 == 0 {
            return L10n.presetUnitHour
        }

        return L10n.presetUnitMinute
    }

    var detailText: String {
        minutes == 1 ? L10n.presetDetailQuickStart : L10n.presetDetailClickToStart
    }
}

enum FeedbackLevel: String {
    case info
    case success
    case warning
    case error
}

struct FeedbackBanner: Identifiable, Equatable {
    let id = UUID()
    let level: FeedbackLevel
    let title: String
    let detail: String
}

enum NotificationPermissionState: Equatable {
    case unknown
    case notDetermined
    case authorized
    case denied
}

protocol SleepAssertionControlling: AnyObject {
    func start() throws
    func stop()
}

struct SleepManagerEnvironment {
    let now: () -> Date
    let isRunningOnBattery: () -> Bool
    let prepareForNotificationRequest: () -> Void
    let fetchNotificationPermission: (@escaping (NotificationPermissionState) -> Void) -> Void
    let requestNotificationPermission: (@escaping (NotificationPermissionState) -> Void) -> Void
    let postNotification: (_ title: String, _ body: String) -> Void
    let sleepNow: () throws -> Void
    let turnOffDisplay: () throws -> Void
    let sleepAssertionController: SleepAssertionControlling

    static func live() -> SleepManagerEnvironment {
        SleepManagerEnvironment(
            now: Date.init,
            isRunningOnBattery: {
                guard let output = try? runCommand("/usr/bin/pmset", arguments: ["-g", "batt"]) else {
                    return false
                }

                return output.contains("Battery Power")
            },
            prepareForNotificationRequest: {
                NSApp.activate(ignoringOtherApps: true)
            },
            fetchNotificationPermission: { completion in
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        completion(mapNotificationPermission(settings.authorizationStatus))
                    }
                }
            },
            requestNotificationPermission: { completion in
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                    center.getNotificationSettings { settings in
                        DispatchQueue.main.async {
                            completion(mapNotificationPermission(settings.authorizationStatus))
                        }
                    }
                }
            },
            postNotification: { title, body in
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )

                UNUserNotificationCenter.current().add(request) { error in
                    if let error {
                        print("Failed to post notification: \(error)")
                    }
                }
            },
            sleepNow: {
                _ = try runCommand("/usr/bin/pmset", arguments: ["sleepnow"])
            },
            turnOffDisplay: {
                _ = try runCommand("/usr/bin/pmset", arguments: ["displaysleepnow"])
            },
            sleepAssertionController: CaffeinateSleepAssertionController()
        )
    }
}

private final class CaffeinateSleepAssertionController: SleepAssertionControlling {
    private var process: Process?

    func start() throws {
        guard process == nil else { return }

        let nextProcess = Process()
        nextProcess.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        nextProcess.arguments = ["-ims"]
        nextProcess.standardOutput = Pipe()
        nextProcess.standardError = Pipe()

        try nextProcess.run()
        process = nextProcess
    }

    func stop() {
        guard let process else { return }

        if process.isRunning {
            process.terminate()
        }

        self.process = nil
    }
}

final class SleepManager: ObservableObject {
    private enum StorageKey {
        static let mode = "settings.mode"
        static let theme = "settings.theme"
        static let batteryNeverSleep = "settings.batteryNeverSleep"
        static let powerNeverSleep = "settings.powerNeverSleep"
        static let pomodoroPreset = "settings.pomodoroPreset"
        static let sleepTimerPreset = "settings.sleepTimerPreset"
        static let activeSessionMode = "session.mode"
        static let activeSessionEndTime = "session.endTime"
        static let activeSessionTotalSeconds = "session.totalSeconds"
        static let activeSessionSelectedMinutes = "session.selectedMinutes"
    }

    @Published var mode: TimerMode = .pomodoro {
        didSet {
            guard !isRestoringState, oldValue != mode else { return }
            defaults.set(mode.rawValue, forKey: StorageKey.mode)
        }
    }

    @Published var theme: AppTheme = .system {
        didSet {
            guard !isRestoringState, oldValue != theme else { return }
            defaults.set(theme.rawValue, forKey: StorageKey.theme)
        }
    }

    @Published var batteryNeverSleep = false {
        didSet {
            guard !isRestoringState, oldValue != batteryNeverSleep else { return }
            defaults.set(batteryNeverSleep, forKey: StorageKey.batteryNeverSleep)
            updateSleepPrevention()
        }
    }

    @Published var powerNeverSleep = false {
        didSet {
            guard !isRestoringState, oldValue != powerNeverSleep else { return }
            defaults.set(powerNeverSleep, forKey: StorageKey.powerNeverSleep)
            updateSleepPrevention()
        }
    }

    @Published var remainingSeconds = 0
    @Published var isTimerRunning = false
    @Published var selectedMinutes = 25 {
        didSet {
            guard !isRestoringState, oldValue != selectedMinutes else { return }
            persistSelectedMinutes(selectedMinutes, for: mode)
        }
    }
    @Published var statusMessage = L10n.statusMessageStartHint
    @Published var banner: FeedbackBanner?
    @Published var notificationPermission: NotificationPermissionState = .unknown

    let focusPresets = [1, 5, 15, 25, 45, 60].map(TimerPreset.init(minutes:))
    let sleepPresets = [10, 20, 30, 45, 60, 90].map(TimerPreset.init(minutes:))

    private let defaults: UserDefaults
    private let environment: SleepManagerEnvironment
    private let startMonitoring: Bool
    private let schedulesTimers: Bool
    private var isRestoringState = true
    private var timer: Timer?
    private var powerMonitorTimer: Timer?
    private var activeTimerTotalSeconds = 0
    private var targetEndDate: Date?
    private var timerActivity: NSObjectProtocol?
    private var sleepPreventionRequestID = 0
    private var screenLockObserver: NSObjectProtocol?
    private var screenUnlockObserver: NSObjectProtocol?
    private var displaySleepWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    var presetItems: [TimerPreset] {
        switch mode {
        case .pomodoro:
            return focusPresets
        case .sleepTimer:
            return sleepPresets
        }
    }

    var selectedDurationText: String {
        format(minutes: selectedMinutes)
    }

    var sleepPreventionSummary: String {
        switch (batteryNeverSleep, powerNeverSleep) {
        case (true, true):
            return L10n.sleepPreventionBoth
        case (true, false):
            return L10n.sleepPreventionBatteryOnly
        case (false, true):
            return L10n.sleepPreventionPowerOnly
        case (false, false):
            return L10n.sleepPreventionOff
        }
    }

    var isSleepPreventionEnabled: Bool {
        batteryNeverSleep || powerNeverSleep
    }

    var timerProgress: Double {
        guard activeTimerTotalSeconds > 0, isTimerRunning else { return 0 }

        let elapsed = activeTimerTotalSeconds - remainingSeconds
        let progress = Double(elapsed) / Double(activeTimerTotalSeconds)
        return min(max(progress, 0), 1)
    }

    init(
        defaults: UserDefaults = .standard,
        environment: SleepManagerEnvironment = .live(),
        startMonitoring: Bool = true,
        schedulesTimers: Bool = true
    ) {
        self.defaults = defaults
        self.environment = environment
        self.startMonitoring = startMonitoring
        self.schedulesTimers = schedulesTimers

        mode = Self.restoreTimerMode(from: defaults)
        theme = Self.restoreTheme(from: defaults)
        batteryNeverSleep = defaults.bool(forKey: StorageKey.batteryNeverSleep)
        powerNeverSleep = defaults.bool(forKey: StorageKey.powerNeverSleep)
        selectedMinutes = mode.defaultPreset
        statusMessage = mode.subtitle

        selectedMinutes = restoredSelectedMinutes(for: mode)
        let restoredActiveSession = restoreActiveSessionIfNeeded()
        if !restoredActiveSession {
            resetSelectionIfNeeded()
        }
        isRestoringState = false
        refreshNotificationPermission()

        LanguageManager.shared.$current
             .dropFirst()
             .receive(on: RunLoop.main)
             .sink { [weak self] _ in
                 self?.refreshLocalizedStrings()
             }
             .store(in: &cancellables)

        if startMonitoring {
            startPowerMonitor()
            setupScreenLockObservers()
        }
    }

    deinit {
        timer?.invalidate()
        powerMonitorTimer?.invalidate()
        endTimerActivityIfNeeded()
        environment.sleepAssertionController.stop()
        
        if let screenLockObserver {
            DistributedNotificationCenter.default().removeObserver(screenLockObserver)
        }
        if let screenUnlockObserver {
            DistributedNotificationCenter.default().removeObserver(screenUnlockObserver)
        }
        displaySleepWorkItem?.cancel()
    }

    func updateMode(_ newMode: TimerMode) {
        guard mode != newMode else { return }

        if isTimerRunning {
            cancelTimer(notify: false)
        }

        mode = newMode
        selectedMinutes = restoredSelectedMinutes(for: newMode)
        statusMessage = newMode.subtitle
        clearNonCriticalBanner()
    }

    func updateTheme(_ newTheme: AppTheme) {
        theme = newTheme
    }

    func startTimer(minutes: Int) {
        selectedMinutes = minutes
        activeTimerTotalSeconds = minutes * 60
        targetEndDate = environment.now().addingTimeInterval(Double(activeTimerTotalSeconds))
        remainingSeconds = remainingSecondsUntilTargetEndDate()
        isTimerRunning = true
        statusMessage = L10n.statusMessageRunning(mode: mode.title)
        clearNonCriticalBanner()

        beginTimerActivityIfNeeded()
        scheduleTimerIfNeeded()
        persistActiveSession()
    }

    func cancelTimer(notify: Bool = true) {
        timer?.invalidate()
        timer = nil
        activeTimerTotalSeconds = 0
        targetEndDate = nil
        isTimerRunning = false
        remainingSeconds = 0
        statusMessage = L10n.statusMessageCancelled
        clearActiveSession()
        endTimerActivityIfNeeded()

        if notify {
            sendNotification(title: L10n.notifTitleCancelled, body: L10n.notifBodyCancelled)
        }
    }

    func sleepNow(showNotification: Bool = true) {
        if showNotification {
            sendNotification(title: L10n.notifTitleSleepNow, body: L10n.notifBodySleepNow)
        }

        do {
            try environment.sleepNow()
        } catch {
            statusMessage = L10n.statusMessageSleepFailed
            presentBanner(
                level: .error,
                title: L10n.bannerSleepFailedTitle,
                detail: L10n.bannerSleepFailedDetail
            )
            print("Sleep command failed: \(error)")
        }
    }

    func formattedRemainingTime() -> String {
        SleepManager.timerFormatter.string(from: TimeInterval(max(0, remainingSeconds))) ?? "00:00"
    }

    func isSelected(_ preset: TimerPreset) -> Bool {
        selectedMinutes == preset.minutes
    }

    func advanceTimerForTesting(by seconds: Int = 1) {
        guard seconds > 0 else { return }

        guard let targetEndDate else { return }

        self.targetEndDate = targetEndDate.addingTimeInterval(-TimeInterval(seconds))
        syncRemainingTimeWithCurrentDate()
    }

    func refreshTimerStateForTesting() {
        syncRemainingTimeWithCurrentDate()
    }

    func dismissBanner() {
        banner = nil
    }

    func refreshNotificationPermission() {
        environment.fetchNotificationPermission { [weak self] status in
            self?.notificationPermission = status
        }
    }

    func requestNotificationPermission() {
        environment.prepareForNotificationRequest()

        environment.requestNotificationPermission { [weak self] status in
            guard let self else { return }
            self.notificationPermission = status

            switch status {
            case .authorized:
                self.presentBanner(
                    level: .success,
                    title: L10n.bannerPermissionEnabledTitle,
                    detail: L10n.bannerPermissionEnabledDetail
                )
            case .denied:
                self.presentBanner(
                    level: .warning,
                    title: L10n.bannerPermissionDisabledTitle,
                    detail: L10n.bannerPermissionDisabledDetail
                )
            case .notDetermined:
                self.presentBanner(
                    level: .warning,
                    title: L10n.bannerPermissionNoPromptTitle,
                    detail: L10n.bannerPermissionNoPromptDetail
                )
            case .unknown:
                self.presentBanner(
                    level: .info,
                    title: L10n.bannerPermissionUnknownTitle,
                    detail: L10n.bannerPermissionUnknownDetail
                )
            }
        }
    }

    private func refreshLocalizedStrings() {
        if isTimerRunning {
            statusMessage = L10n.statusMessageRunning(mode: mode.title)
        } else {
            if remainingSeconds > 0 && targetEndDate == nil {
                statusMessage = L10n.statusMessageSessionRestored(mode: mode.title)
            } else {
                statusMessage = mode.subtitle
            }
        }
    }

    private func resetSelectionIfNeeded() {
        if presetItems.contains(where: { $0.minutes == selectedMinutes }) {
            return
        }

        selectedMinutes = mode.defaultPreset
    }

    private func tick() {
        syncRemainingTimeWithCurrentDate()
    }

    private func scheduleTimerIfNeeded() {
        timer?.invalidate()

        guard schedulesTimers else {
            timer = nil
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func timerFinished() {
        timer?.invalidate()
        timer = nil
        activeTimerTotalSeconds = 0
        targetEndDate = nil
        isTimerRunning = false
        remainingSeconds = 0
        clearActiveSession()
        endTimerActivityIfNeeded()

        switch mode {
        case .pomodoro:
            statusMessage = L10n.statusMessagePomodoroDone
            sendNotification(title: L10n.notifTitlePomodoroDone, body: L10n.notifBodyPomodoroDone)
        case .sleepTimer:
            statusMessage = L10n.statusMessageSleepTimerDone
            sendNotification(title: L10n.notifTitleSleepTimerDone, body: L10n.notifBodySleepTimerDone)
            sleepNow(showNotification: false)
        }
    }

    private func startPowerMonitor() {
        powerMonitorTimer?.invalidate()
        powerMonitorTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateSleepPrevention()
        }
        updateSleepPrevention()
    }

    private func updateSleepPrevention() {
        guard startMonitoring else { return }

        sleepPreventionRequestID += 1
        let requestID = sleepPreventionRequestID

        guard batteryNeverSleep || powerNeverSleep else {
            applySleepPrevention(shouldPreventSleep: false)
            return
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let isOnBattery = self.environment.isRunningOnBattery()

            DispatchQueue.main.async { [weak self] in
                guard let self, self.sleepPreventionRequestID == requestID else { return }
                let shouldPrevent = isOnBattery ? self.batteryNeverSleep : self.powerNeverSleep
                self.applySleepPrevention(shouldPreventSleep: shouldPrevent)
            }
        }
    }

    private func setupScreenLockObservers() {
        screenLockObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenLocked()
        }

        screenUnlockObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenUnlocked()
        }
    }

    private func handleScreenLocked() {
        displaySleepWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            do {
                try self.environment.turnOffDisplay()
            } catch {
                print("Failed to turn off display: \(error)")
            }
        }

        displaySleepWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    private func handleScreenUnlocked() {
        displaySleepWorkItem?.cancel()
        displaySleepWorkItem = nil
    }

    private func applySleepPrevention(shouldPreventSleep: Bool) {
        guard startMonitoring else { return }

        if shouldPreventSleep {
            do {
                try environment.sleepAssertionController.start()
            } catch {
                statusMessage = L10n.statusMessagePreventionFailed
                presentBanner(
                    level: .error,
                    title: L10n.bannerPreventionFailedTitle,
                    detail: L10n.bannerPreventionFailedDetail
                )
                print("Failed to start sleep assertion: \(error)")
            }
        } else {
            environment.sleepAssertionController.stop()
        }
    }

    private func restoreActiveSessionIfNeeded() -> Bool {
        guard
            let storedModeRawValue = defaults.string(forKey: StorageKey.activeSessionMode),
            let storedMode = TimerMode(rawValue: storedModeRawValue)
        else {
            return false
        }

        let endTimeInterval = defaults.double(forKey: StorageKey.activeSessionEndTime)
        let totalSeconds = defaults.integer(forKey: StorageKey.activeSessionTotalSeconds)
        let selectedMinutes = defaults.integer(forKey: StorageKey.activeSessionSelectedMinutes)

        guard endTimeInterval > 0, totalSeconds > 0, selectedMinutes > 0 else {
            clearActiveSession()
            return false
        }

        let endDate = Date(timeIntervalSince1970: endTimeInterval)
        let remaining = Int(ceil(endDate.timeIntervalSince(environment.now())))

        guard remaining > 0 else {
            clearActiveSession()
            statusMessage = L10n.statusMessageSessionExpired
            presentBanner(
                level: .warning,
                title: L10n.bannerSessionExpiredTitle,
                detail: L10n.bannerSessionExpiredDetail
            )
            return false
        }

        mode = storedMode
        activeTimerTotalSeconds = totalSeconds
        targetEndDate = endDate
        remainingSeconds = remaining
        isTimerRunning = true
        self.selectedMinutes = selectedMinutes
        statusMessage = L10n.statusMessageSessionRestored(mode: storedMode.title)
        presentBanner(
            level: .info,
            title: L10n.bannerSessionRestoredTitle,
            detail: L10n.bannerSessionRestoredDetail(mode: storedMode.title)
        )
        beginTimerActivityIfNeeded()
        scheduleTimerIfNeeded()
        return true
    }

    private func persistActiveSession() {
        defaults.set(mode.rawValue, forKey: StorageKey.activeSessionMode)
        defaults.set((targetEndDate ?? environment.now().addingTimeInterval(Double(remainingSeconds))).timeIntervalSince1970, forKey: StorageKey.activeSessionEndTime)
        defaults.set(activeTimerTotalSeconds, forKey: StorageKey.activeSessionTotalSeconds)
        defaults.set(selectedMinutes, forKey: StorageKey.activeSessionSelectedMinutes)
    }

    private func clearActiveSession() {
        defaults.removeObject(forKey: StorageKey.activeSessionMode)
        defaults.removeObject(forKey: StorageKey.activeSessionEndTime)
        defaults.removeObject(forKey: StorageKey.activeSessionTotalSeconds)
        defaults.removeObject(forKey: StorageKey.activeSessionSelectedMinutes)
    }

    private func syncRemainingTimeWithCurrentDate() {
        guard isTimerRunning else { return }

        let remaining = remainingSecondsUntilTargetEndDate()
        remainingSeconds = remaining

        if remaining <= 0 {
            timerFinished()
        }
    }

    private func remainingSecondsUntilTargetEndDate() -> Int {
        guard let targetEndDate else { return 0 }
        return max(0, Int(ceil(targetEndDate.timeIntervalSince(environment.now()))))
    }

    private func presentBanner(level: FeedbackLevel, title: String, detail: String) {
        banner = FeedbackBanner(level: level, title: title, detail: detail)
    }

    private func clearNonCriticalBanner() {
        guard banner?.level != .error else { return }
        banner = nil
    }

    private func sendNotification(title: String, body: String) {
        switch notificationPermission {
        case .authorized:
            environment.postNotification(title, body)
        case .notDetermined:
            presentBanner(
                level: .info,
                title: L10n.bannerSuggestionTitle,
                detail: L10n.bannerSuggestionDetail
            )
        case .denied:
            presentBanner(
                level: .warning,
                title: L10n.bannerDisabledWarningTitle,
                detail: L10n.bannerDisabledWarningDetail
            )
        case .unknown:
            refreshNotificationPermission()
        }
    }

    private func beginTimerActivityIfNeeded() {
        guard timerActivity == nil else { return }

        timerActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep],
            reason: "DivineSleep timer running"
        )
    }

    private func endTimerActivityIfNeeded() {
        guard let timerActivity else { return }

        ProcessInfo.processInfo.endActivity(timerActivity)
        self.timerActivity = nil
    }

    private func restoredSelectedMinutes(for mode: TimerMode) -> Int {
        let savedMinutes = defaults.integer(forKey: storageKey(for: mode))
        let validMinutes = mode == .pomodoro ? focusPresets.map(\.minutes) : sleepPresets.map(\.minutes)

        return validMinutes.contains(savedMinutes) ? savedMinutes : mode.defaultPreset
    }

    private func persistSelectedMinutes(_ minutes: Int, for mode: TimerMode) {
        defaults.set(minutes, forKey: storageKey(for: mode))
    }

    private func storageKey(for mode: TimerMode) -> String {
        switch mode {
        case .pomodoro:
            return StorageKey.pomodoroPreset
        case .sleepTimer:
            return StorageKey.sleepTimerPreset
        }
    }

    private func format(minutes: Int) -> String {
        return L10n.formatDuration(minutes: minutes)
    }

    private static func restoreTimerMode(from defaults: UserDefaults) -> TimerMode {
        guard
            let rawValue = defaults.string(forKey: StorageKey.mode),
            let restoredMode = TimerMode(rawValue: rawValue)
        else {
            return .pomodoro
        }

        return restoredMode
    }

    private static func restoreTheme(from defaults: UserDefaults) -> AppTheme {
        guard
            let rawValue = defaults.string(forKey: StorageKey.theme),
            let restoredTheme = AppTheme(rawValue: rawValue)
        else {
            return .system
        }

        return restoredTheme
    }

    private static let timerFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
}

@discardableResult
private func runCommand(_ launchPath: String, arguments: [String]) throws -> String {
    let process = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    try process.run()
    process.waitUntilExit()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: outputData, as: UTF8.self)
    let errorOutput = String(decoding: errorData, as: UTF8.self)

    guard process.terminationStatus == 0 else {
        throw NSError(
            domain: "DivineSleep.Process",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: errorOutput.isEmpty ? output : errorOutput]
        )
    }

    return output
}

private func mapNotificationPermission(_ status: UNAuthorizationStatus) -> NotificationPermissionState {
    switch status {
    case .notDetermined:
        return .notDetermined
    case .denied:
        return .denied
    case .authorized, .provisional, .ephemeral:
        return .authorized
    @unknown default:
        return .unknown
    }
}
