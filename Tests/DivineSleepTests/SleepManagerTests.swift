import XCTest
@testable import DivineSleep

final class SleepManagerTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()

        suiteName = "DivineSleepTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil

        super.tearDown()
    }

    func testRestoresSavedPreferencesAcrossInstances() {
        let initialManager = makeManager(startMonitoring: false)

        initialManager.updateTheme(.dark)
        initialManager.startTimer(minutes: 45)
        initialManager.batteryNeverSleep = true
        initialManager.powerNeverSleep = true
        initialManager.updateMode(.sleepTimer)
        initialManager.startTimer(minutes: 90)

        let restoredManager = makeManager(startMonitoring: false)

        XCTAssertEqual(restoredManager.theme, .dark)
        XCTAssertEqual(restoredManager.mode, .sleepTimer)
        XCTAssertEqual(restoredManager.selectedMinutes, 90)
        XCTAssertTrue(restoredManager.batteryNeverSleep)
        XCTAssertTrue(restoredManager.powerNeverSleep)
    }

    func testSwitchingModesRestoresLastPresetForEachMode() {
        let manager = makeManager(startMonitoring: false)

        manager.startTimer(minutes: 45)
        manager.updateMode(.sleepTimer)
        XCTAssertEqual(manager.selectedMinutes, 30)

        manager.startTimer(minutes: 90)
        manager.updateMode(.pomodoro)
        XCTAssertEqual(manager.selectedMinutes, 45)

        manager.updateMode(.sleepTimer)
        XCTAssertEqual(manager.selectedMinutes, 90)
    }

    func testPowerNeverSleepTogglesAssertionImmediately() {
        let controller = RecordingSleepAssertionController()
        let manager = makeManager(controller: controller, startMonitoring: true)
        let initialStopCount = controller.stopCount

        manager.powerNeverSleep = true
        XCTAssertEqual(controller.startCount, 1)

        manager.powerNeverSleep = false
        XCTAssertEqual(controller.stopCount, initialStopCount + 1)
    }

    func testPomodoroCompletionUpdatesProgressAndNotifies() {
        let notifications = NotificationRecorder()
        let sleeper = SleepActionRecorder()
        let manager = makeManager(
            notifications: notifications,
            sleeper: sleeper,
            startMonitoring: false
        )

        manager.startTimer(minutes: 1)
        manager.advanceTimerForTesting(by: 30)

        XCTAssertEqual(manager.remainingSeconds, 30)
        XCTAssertEqual(manager.timerProgress, 0.5, accuracy: 0.001)
        XCTAssertTrue(manager.isTimerRunning)

        manager.advanceTimerForTesting(by: 30)

        XCTAssertFalse(manager.isTimerRunning)
        XCTAssertEqual(manager.statusMessage, "专注阶段结束，记得活动一下。")
        XCTAssertEqual(notifications.messages.map(\.title), ["专注结束"])
        XCTAssertEqual(sleeper.callCount, 0)
    }

    func testSleepTimerCompletionTriggersSleepAction() {
        let notifications = NotificationRecorder()
        let sleeper = SleepActionRecorder()
        let manager = makeManager(
            notifications: notifications,
            sleeper: sleeper,
            startMonitoring: false
        )

        manager.updateMode(.sleepTimer)
        manager.startTimer(minutes: 1)
        manager.advanceTimerForTesting(by: 60)

        XCTAssertFalse(manager.isTimerRunning)
        XCTAssertEqual(manager.statusMessage, "倒计时结束，准备进入睡眠。")
        XCTAssertEqual(notifications.messages.map(\.title), ["睡眠倒计时结束"])
        XCTAssertEqual(sleeper.callCount, 1)
    }

    func testTimerUsesAbsoluteEndDateAfterClockJump() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
        let manager = makeManager(
            clock: clock,
            startMonitoring: false
        )

        manager.startTimer(minutes: 1)
        clock.now = clock.now.addingTimeInterval(45)
        manager.refreshTimerStateForTesting()

        XCTAssertEqual(manager.remainingSeconds, 15)
        XCTAssertEqual(manager.timerProgress, 0.75, accuracy: 0.001)
        XCTAssertTrue(manager.isTimerRunning)
    }

    func testRestoresActiveTimerAfterRelaunch() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 10_000))
        let initialManager = makeManager(
            clock: clock,
            startMonitoring: false
        )

        initialManager.startTimer(minutes: 25)
        clock.now = clock.now.addingTimeInterval(300)

        let restoredManager = makeManager(
            clock: clock,
            startMonitoring: false
        )

        XCTAssertTrue(restoredManager.isTimerRunning)
        XCTAssertEqual(restoredManager.mode, .pomodoro)
        XCTAssertEqual(restoredManager.selectedMinutes, 25)
        XCTAssertEqual(restoredManager.remainingSeconds, 1_200)
        XCTAssertEqual(restoredManager.timerProgress, 0.2, accuracy: 0.001)
        XCTAssertEqual(restoredManager.statusMessage, "已恢复上次未完成的番茄时钟。")
        XCTAssertEqual(restoredManager.banner?.level, .info)
        XCTAssertEqual(restoredManager.banner?.title, "已恢复上次计时")
    }

    func testExpiredSessionShowsWarningBanner() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 10_000))
        let initialManager = makeManager(
            clock: clock,
            startMonitoring: false
        )

        initialManager.startTimer(minutes: 1)
        clock.now = clock.now.addingTimeInterval(120)

        let restoredManager = makeManager(
            clock: clock,
            startMonitoring: false
        )

        XCTAssertFalse(restoredManager.isTimerRunning)
        XCTAssertEqual(restoredManager.statusMessage, "上次未完成的计时已过期。")
        XCTAssertEqual(restoredManager.banner?.level, .warning)
        XCTAssertEqual(restoredManager.banner?.title, "上次计时未恢复")
    }

    func testSleepFailurePublishesErrorBanner() {
        let sleeper = SleepActionRecorder()
        sleeper.error = NSError(domain: "Test", code: 1)
        let manager = makeManager(
            sleeper: sleeper,
            startMonitoring: false
        )

        manager.sleepNow()

        XCTAssertEqual(manager.statusMessage, "无法让系统进入睡眠，请检查权限。")
        XCTAssertEqual(manager.banner?.level, .error)
        XCTAssertEqual(manager.banner?.title, "立即睡眠失败")
    }

    func testRequestNotificationPermissionUpdatesStateAndBanner() {
        let notificationPermission = NotificationPermissionHarness(status: .notDetermined)
        notificationPermission.requestResult = .authorized
        let manager = makeManager(
            notificationPermission: notificationPermission,
            startMonitoring: false
        )

        XCTAssertEqual(manager.notificationPermission, .notDetermined)

        manager.requestNotificationPermission()

        XCTAssertEqual(manager.notificationPermission, .authorized)
        XCTAssertEqual(manager.banner?.level, .success)
        XCTAssertEqual(manager.banner?.title, "通知已启用")
        XCTAssertEqual(notificationPermission.requestCount, 1)
    }

    func testDeniedNotificationPermissionShowsWarningInsteadOfPosting() {
        let notifications = NotificationRecorder()
        let notificationPermission = NotificationPermissionHarness(status: .denied)
        let manager = makeManager(
            notificationPermission: notificationPermission,
            notifications: notifications,
            startMonitoring: false
        )

        manager.startTimer(minutes: 1)
        manager.advanceTimerForTesting(by: 60)

        XCTAssertEqual(notifications.messages.count, 0)
        XCTAssertEqual(manager.banner?.level, .warning)
        XCTAssertEqual(manager.banner?.title, "通知已关闭")
    }

    func testRequestNotificationPermissionWithoutPromptShowsGuidanceBanner() {
        let notificationPermission = NotificationPermissionHarness(status: .notDetermined)
        notificationPermission.requestResult = .notDetermined
        let manager = makeManager(
            notificationPermission: notificationPermission,
            startMonitoring: false
        )

        manager.requestNotificationPermission()

        XCTAssertEqual(manager.notificationPermission, .notDetermined)
        XCTAssertEqual(manager.banner?.level, .warning)
        XCTAssertEqual(manager.banner?.title, "授权窗口没有出现")
    }

    private func makeManager(
        controller: RecordingSleepAssertionController = RecordingSleepAssertionController(),
        batteryState: BatteryState = BatteryState(),
        clock: TestClock = TestClock(),
        notificationPermission: NotificationPermissionHarness = NotificationPermissionHarness(),
        notifications: NotificationRecorder = NotificationRecorder(),
        sleeper: SleepActionRecorder = SleepActionRecorder(),
        startMonitoring: Bool,
        schedulesTimers: Bool = false
    ) -> SleepManager {
        let environment = SleepManagerEnvironment(
            now: { clock.now },
            isRunningOnBattery: { batteryState.isOnBattery },
            prepareForNotificationRequest: {},
            fetchNotificationPermission: { completion in
                completion(notificationPermission.status)
            },
            requestNotificationPermission: { completion in
                notificationPermission.requestCount += 1
                notificationPermission.status = notificationPermission.requestResult
                completion(notificationPermission.status)
            },
            postNotification: { title, body in
                notifications.messages.append((title: title, body: body))
            },
            sleepNow: {
                sleeper.callCount += 1
                if let error = sleeper.error {
                    throw error
                }
            },
            sleepAssertionController: controller
        )

        return SleepManager(
            defaults: defaults,
            environment: environment,
            startMonitoring: startMonitoring,
            schedulesTimers: schedulesTimers
        )
    }
}

private final class RecordingSleepAssertionController: SleepAssertionControlling {
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() throws {
        startCount += 1
    }

    func stop() {
        stopCount += 1
    }
}

private final class NotificationRecorder {
    var messages: [(title: String, body: String)] = []
}

private final class NotificationPermissionHarness {
    var status: NotificationPermissionState
    var requestResult: NotificationPermissionState
    var requestCount = 0

    init(status: NotificationPermissionState = .authorized) {
        self.status = status
        self.requestResult = status
    }
}

private final class SleepActionRecorder {
    var callCount = 0
    var error: Error?
}

private final class BatteryState {
    var isOnBattery = false
}

private final class TestClock {
    var now: Date

    init(now: Date = Date(timeIntervalSince1970: 0)) {
        self.now = now
    }
}
