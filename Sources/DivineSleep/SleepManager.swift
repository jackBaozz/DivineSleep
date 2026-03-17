import AppKit
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
            return "番茄时钟"
        case .sleepTimer:
            return "睡眠倒计时"
        }
    }

    var subtitle: String {
        switch self {
        case .pomodoro:
            return "保持专注，结束后轻提醒"
        case .sleepTimer:
            return "倒计时结束后让 Mac 进入睡眠"
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
            return "亮色"
        case .dark:
            return "暗黑"
        case .system:
            return "跟随系统"
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
            return "小时"
        }

        return "分钟"
    }

    var detailText: String {
        minutes == 1 ? "快速开始" : "单击开始"
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
        nextProcess.arguments = ["-dimsu"]
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
    @Published var statusMessage = "点选一个时长卡片就会立即开始。"
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
            return "电池和电源模式都保持唤醒"
        case (true, false):
            return "仅电池模式保持唤醒"
        case (false, true):
            return "仅电源模式保持唤醒"
        case (false, false):
            return "防睡眠未启用"
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

        if startMonitoring {
            startPowerMonitor()
        }
    }

    deinit {
        timer?.invalidate()
        powerMonitorTimer?.invalidate()
        endTimerActivityIfNeeded()
        environment.sleepAssertionController.stop()
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
        statusMessage = "正在进行\(mode.title)。"
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
        statusMessage = "计时已取消。"
        clearActiveSession()
        endTimerActivityIfNeeded()

        if notify {
            sendNotification(title: "DivineSleep", body: "当前倒计时已取消。")
        }
    }

    func sleepNow(showNotification: Bool = true) {
        if showNotification {
            sendNotification(title: "DivineSleep", body: "Mac 即将进入睡眠。")
        }

        do {
            try environment.sleepNow()
        } catch {
            statusMessage = "无法让系统进入睡眠，请检查权限。"
            presentBanner(
                level: .error,
                title: "立即睡眠失败",
                detail: "系统拒绝了睡眠请求。请确认当前环境允许执行 pmset，或从完整的 .app 包启动。"
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
                    title: "通知已启用",
                    detail: "计时结束和系统操作结果会通过通知提醒你。"
                )
            case .denied:
                self.presentBanner(
                    level: .warning,
                    title: "通知未开启",
                    detail: "请到系统设置 > 通知 > DivineSleep 中开启提醒，再点这里重新检测。"
                )
            case .notDetermined:
                self.presentBanner(
                    level: .warning,
                    title: "授权窗口没有出现",
                    detail: "这通常是因为当前运行的不是签名后的 .app，或系统没有把授权面板带到前台。请重新打开最新打包产物后再试。"
                )
            case .unknown:
                self.presentBanner(
                    level: .info,
                    title: "通知状态未确认",
                    detail: "你可以稍后再次尝试授权，或手动在系统设置里检查。"
                )
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
            statusMessage = "专注阶段结束，记得活动一下。"
            sendNotification(title: "专注结束", body: "你的番茄时钟已经完成。")
        case .sleepTimer:
            statusMessage = "倒计时结束，准备进入睡眠。"
            sendNotification(title: "睡眠倒计时结束", body: "DivineSleep 正在让 Mac 进入睡眠。")
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

        if powerNeverSleep {
            applySleepPrevention(shouldPreventSleep: true)
            return
        }

        guard batteryNeverSleep else {
            applySleepPrevention(shouldPreventSleep: false)
            return
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let isRunningOnBattery = self.environment.isRunningOnBattery()

            DispatchQueue.main.async { [weak self] in
                guard let self, self.sleepPreventionRequestID == requestID else { return }
                self.applySleepPrevention(shouldPreventSleep: isRunningOnBattery)
            }
        }
    }

    private func applySleepPrevention(shouldPreventSleep: Bool) {
        guard startMonitoring else { return }

        if shouldPreventSleep {
            do {
                try environment.sleepAssertionController.start()
            } catch {
                statusMessage = "无法开启防睡眠保护。"
                presentBanner(
                    level: .error,
                    title: "防睡眠启动失败",
                    detail: "DivineSleep 无法启动 caffeinate。请确认应用有权限调用系统命令。"
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
            statusMessage = "上次未完成的计时已过期。"
            presentBanner(
                level: .warning,
                title: "上次计时未恢复",
                detail: "检测到旧会话，但它已经过期，所以已自动清理。"
            )
            return false
        }

        mode = storedMode
        activeTimerTotalSeconds = totalSeconds
        targetEndDate = endDate
        remainingSeconds = remaining
        isTimerRunning = true
        self.selectedMinutes = selectedMinutes
        statusMessage = "已恢复上次未完成的\(storedMode.title)。"
        presentBanner(
            level: .info,
            title: "已恢复上次计时",
            detail: "继续之前未完成的\(storedMode.title)，你可以直接继续或取消。"
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
                title: "建议启用系统通知",
                detail: "这样在计时结束或执行睡眠操作时，你能立即收到提醒。"
            )
        case .denied:
            presentBanner(
                level: .warning,
                title: "通知已关闭",
                detail: "请到系统设置 > 通知 > DivineSleep 中开启提醒，避免错过完成提示。"
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
        if minutes >= 60, minutes % 60 == 0 {
            return "\(minutes / 60) 小时"
        }

        return "\(minutes) 分钟"
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
