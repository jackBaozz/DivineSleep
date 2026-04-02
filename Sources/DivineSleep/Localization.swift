import Foundation

struct L10n {
    private static var lang: AppLanguage {
        LanguageManager.shared.current
    }

    // MARK: - Header
    static var appTitle: String {
        switch lang {
        case .en: return "DivineSleep"
        case .zhHans: return "DivineSleep"
        case .zhHant: return "DivineSleep"
        }
    }

    static var appSubtitle: String {
        switch lang {
        case .en: return "A menu bar tool for focus and sleep control"
        case .zhHans: return "更适合放在菜单栏里的专注与睡眠控制器"
        case .zhHant: return "更適合放在選單列中的專注與睡眠控制器"
        }
    }

    // MARK: - Theme & Language Sections
    static var themeSectionTitle: String {
        switch lang {
        case .en: return "Theme"
        case .zhHans: return "主题"
        case .zhHant: return "主題"
        }
    }

    static var languageSectionTitle: String {
        switch lang {
        case .en: return "Language"
        case .zhHans: return "语言"
        case .zhHant: return "語言"
        }
    }

    // MARK: - AppTheme
    static var themeLight: String {
        switch lang {
        case .en: return "Light"
        case .zhHans: return "亮色"
        case .zhHant: return "亮色"
        }
    }

    static var themeDark: String {
        switch lang {
        case .en: return "Dark"
        case .zhHans: return "暗黑"
        case .zhHant: return "暗黑"
        }
    }

    static var themeSystem: String {
        switch lang {
        case .en: return "System"
        case .zhHans: return "跟随系统"
        case .zhHant: return "跟隨系統"
        }
    }

    // MARK: - SleepControl Section
    static var sleepControlSectionTitle: String {
        switch lang {
        case .en: return "Sleep Control"
        case .zhHans: return "睡眠控制"
        case .zhHant: return "睡眠控制"
        }
    }

    static var batteryNeverSleepTitle: String {
        switch lang {
        case .en: return "Prevent sleep on battery"
        case .zhHans: return "电池模式下禁止睡眠"
        case .zhHant: return "電池模式下禁止睡眠"
        }
    }

    static var batteryNeverSleepSubtitle: String {
        switch lang {
        case .en: return "Keep awake only on battery power, suitable for short absences."
        case .zhHans: return "仅在电池供电时保持唤醒，适合短时离开。"
        case .zhHant: return "僅在電池供電時保持喚醒，適合短暫離開。"
        }
    }

    static var powerNeverSleepTitle: String {
        switch lang {
        case .en: return "Prevent sleep on power adapter"
        case .zhHans: return "电源模式下禁止睡眠"
        case .zhHant: return "電源模式下禁止睡眠"
        }
    }

    static var powerNeverSleepSubtitle: String {
        switch lang {
        case .en: return "Keep awake when plugged in, suitable for downloads and long tasks."
        case .zhHans: return "接电源时持续保持唤醒，适合下载和长任务。"
        case .zhHant: return "接上電源時持續保持喚醒，適合下載與長時間任務。"
        }
    }

    static var sleepNowButtonTitle: String {
        switch lang {
        case .en: return "Sleep Now"
        case .zhHans: return "立即睡眠"
        case .zhHant: return "立即睡眠"
        }
    }

    // MARK: - ModeSelector Section
    static var modeSelectorSectionTitle: String {
        switch lang {
        case .en: return "Work Mode"
        case .zhHans: return "工作模式"
        case .zhHant: return "工作模式"
        }
    }

    // MARK: - TimerMode
    static var pomodoroTitle: String {
        switch lang {
        case .en: return "Pomodoro Timer"
        case .zhHans: return "番茄时钟"
        case .zhHant: return "番茄時鐘"
        }
    }

    static var pomodoroSubtitle: String {
        switch lang {
        case .en: return "Stay focused, get a light reminder when done"
        case .zhHans: return "保持专注，结束后轻提醒"
        case .zhHant: return "保持專注，結束後輕提醒"
        }
    }

    static var sleepTimerTitle: String {
        switch lang {
        case .en: return "Sleep Timer"
        case .zhHans: return "睡眠倒计时"
        case .zhHant: return "睡眠倒數"
        }
    }

    static var sleepTimerSubtitle: String {
        switch lang {
        case .en: return "Put Mac to sleep when timer ends"
        case .zhHans: return "倒计时结束后让 Mac 进入睡眠"
        case .zhHant: return "倒數結束後讓 Mac 進入睡眠"
        }
    }

    // MARK: - Hero Section
    static var timerStatusRunning: String {
        switch lang {
        case .en: return "Running"
        case .zhHans: return "进行中"
        case .zhHant: return "進行中"
        }
    }

    static var timerStatusWaiting: String {
        switch lang {
        case .en: return "Waiting"
        case .zhHans: return "待开始"
        case .zhHant: return "待開始"
        }
    }

    static var remainingTimeLabel: String {
        switch lang {
        case .en: return "Remaining Time"
        case .zhHans: return "剩余时间"
        case .zhHant: return "剩餘時間"
        }
    }

    static var selectedDurationLabel: String {
        switch lang {
        case .en: return "Selected Duration"
        case .zhHans: return "当前选中时长"
        case .zhHant: return "當前選中時長"
        }
    }

    static var cancelButtonTitle: String {
        switch lang {
        case .en: return "Cancel"
        case .zhHans: return "取消"
        case .zhHant: return "取消"
        }
    }

    static var progressLabel: String {
        switch lang {
        case .en: return "Progress"
        case .zhHans: return "进度"
        case .zhHant: return "進度"
        }
    }

    static var statusChipDuration: String {
        switch lang {
        case .en: return "Selected Time"
        case .zhHans: return "已选时长"
        case .zhHant: return "已選時長"
        }
    }

    static var statusChipPreventionOn: String {
        switch lang {
        case .en: return "Prevention ON"
        case .zhHans: return "防睡眠已开"
        case .zhHant: return "防睡眠已開"
        }
    }

    static var statusChipPrevention: String {
        switch lang {
        case .en: return "Sleep Prevention"
        case .zhHans: return "防睡眠"
        case .zhHant: return "防睡眠"
        }
    }

    // MARK: - PresetGrid Section
    static var presetGridPomodoroTitle: String {
        switch lang {
        case .en: return "Select Pomodoro Duration"
        case .zhHans: return "选择番茄工作法时长"
        case .zhHant: return "選擇番茄工作法時長"
        }
    }

    static var presetGridSleepTimerTitle: String {
        switch lang {
        case .en: return "Select Sleep Timer Duration"
        case .zhHans: return "选择睡眠倒计时时长"
        case .zhHant: return "選擇睡眠倒數時長"
        }
    }

    static var clickToStartHint: String {
        switch lang {
        case .en: return "Click card to start"
        case .zhHans: return "点击卡片立即开始"
        case .zhHant: return "點擊卡片立即開始"
        }
    }

    // MARK: - TimerPreset
    static var presetUnitHour: String {
        switch lang {
        case .en: return "h"
        case .zhHans: return "小时"
        case .zhHant: return "小時"
        }
    }

    static var presetUnitMinute: String {
        switch lang {
        case .en: return "m"
        case .zhHans: return "分钟"
        case .zhHant: return "分鐘"
        }
    }

    static var presetDetailQuickStart: String {
        switch lang {
        case .en: return "Quick Start"
        case .zhHans: return "快速开始"
        case .zhHant: return "快速開始"
        }
    }

    static var presetDetailClickToStart: String {
        switch lang {
        case .en: return "Click to Start"
        case .zhHans: return "单击开始"
        case .zhHant: return "單擊開始"
        }
    }

    static var presetCountingDown: String {
        switch lang {
        case .en: return "Counting down"
        case .zhHans: return "倒计时中"
        case .zhHant: return "倒數中"
        }
    }

    // MARK: - Notification Section
    static var notificationSectionTitle: String {
        switch lang {
        case .en: return "Notifications"
        case .zhHans: return "提醒"
        case .zhHant: return "提醒"
        }
    }

    static var notificationAuthorizedTitle: String {
        switch lang {
        case .en: return "Notifications Enabled"
        case .zhHans: return "系统通知已开启"
        case .zhHant: return "系統通知已開啟"
        }
    }

    static var notificationAuthorizedDetail: String {
        switch lang {
        case .en: return "You will be notified for timer completion, session restoration, and sleep actions."
        case .zhHans: return "计时结束、恢复会话和执行睡眠操作时都会通过系统通知提醒你。"
        case .zhHant: return "計時結束、恢復會話及執行睡眠操作時都會透過系統通知提醒你。"
        }
    }

    static var notificationNotDeterminedTitle: String {
        switch lang {
        case .en: return "Notifications Not Authorized"
        case .zhHans: return "还没有通知授权"
        case .zhHant: return "尚未授予通知權限"
        }
    }

    static var notificationNotDeterminedDetail: String {
        switch lang {
        case .en: return "It's recommended to enable notifications so you won't miss reminders when the timer ends."
        case .zhHans: return "建议开启通知，这样倒计时结束时就不会只停留在菜单栏里。"
        case .zhHant: return "建議開啟通知，這樣倒數結束時就不會只停留在選單列中。"
        }
    }

    static var notificationDeniedTitle: String {
        switch lang {
        case .en: return "Notifications Disabled"
        case .zhHans: return "系统通知已关闭"
        case .zhHant: return "系統通知已關閉"
        }
    }

    static var notificationDeniedDetail: String {
        switch lang {
        case .en: return "Please enable notifications for DivineSleep in Settings > Notifications, then click \"Recheck\"."
        case .zhHans: return "请到系统设置 > 通知 > DivineSleep 中开启提醒，然后回来点“重新检测”。"
        case .zhHant: return "請到系統設定 > 通知 > DivineSleep 中開啟提醒，再回來點擊「重新檢測」。"
        }
    }

    static var notificationUnknownTitle: String {
        switch lang {
        case .en: return "Checking notification status"
        case .zhHans: return "正在检测通知状态"
        case .zhHant: return "正在檢測通知狀態"
        }
    }

    static var notificationUnknownDetail: String {
        switch lang {
        case .en: return "DivineSleep is reading notification permissions. You can also refresh manually."
        case .zhHans: return "DivineSleep 正在读取当前通知权限，你也可以手动刷新一次。"
        case .zhHant: return "DivineSleep 正在讀取目前通知權限，您也可以手動重新整理。"
        }
    }

    static var notificationActionRefresh: String {
        switch lang {
        case .en: return "Refresh"
        case .zhHans: return "刷新状态"
        case .zhHant: return "重新整理"
        }
    }

    static var notificationActionEnable: String {
        switch lang {
        case .en: return "Enable Notifications"
        case .zhHans: return "启用通知"
        case .zhHant: return "啟用通知"
        }
    }

    static var notificationActionRecheck: String {
        switch lang {
        case .en: return "Recheck"
        case .zhHans: return "重新检测"
        case .zhHant: return "重新檢測"
        }
    }

    // MARK: - Footer Section
    static var footerHint: String {
        switch lang {
        case .en: return "Click the menu bar icon anytime to open the control panel"
        case .zhHans: return "点击菜单栏图标可随时呼出控制面板"
        case .zhHant: return "點擊選單列圖示可隨時呼叫控制面板"
        }
    }

    static var footerQuit: String {
        switch lang {
        case .en: return "Quit"
        case .zhHans: return "退出"
        case .zhHant: return "退出"
        }
    }

    // MARK: - Context Menu
    static var contextMenuCancelTimer: String {
        switch lang {
        case .en: return "Cancel Current Timer"
        case .zhHans: return "取消当前计时"
        case .zhHant: return "取消當前計時"
        }
    }

    static var contextMenuCollapsePanel: String {
        switch lang {
        case .en: return "Collapse Panel"
        case .zhHans: return "收起面板"
        case .zhHant: return "收起面板"
        }
    }

    static var contextMenuExpandPanel: String {
        switch lang {
        case .en: return "Expand Panel"
        case .zhHans: return "展开面板"
        case .zhHant: return "展開面板"
        }
    }

    static var contextMenuSleepNow: String {
        switch lang {
        case .en: return "Sleep Now"
        case .zhHans: return "立即睡眠"
        case .zhHant: return "立即睡眠"
        }
    }

    static var contextMenuQuit: String {
        switch lang {
        case .en: return "Quit DivineSleep"
        case .zhHans: return "退出 DivineSleep"
        case .zhHant: return "退出 DivineSleep"
        }
    }

    // MARK: - Status Messages & Formats
    static var statusMessageStartHint: String {
        switch lang {
        case .en: return "Click a duration card to start."
        case .zhHans: return "点选一个时长卡片就会立即开始。"
        case .zhHant: return "點選一個時長卡片就會立即開始。"
        }
    }

    static func statusMessageRunning(mode: String) -> String {
        switch lang {
        case .en: return "\(mode) is running."
        case .zhHans: return "正在进行\(mode)。"
        case .zhHant: return "正在進行\(mode)。"
        }
    }

    static var statusMessageCancelled: String {
        switch lang {
        case .en: return "Timer cancelled."
        case .zhHans: return "计时已取消。"
        case .zhHant: return "計時已取消。"
        }
    }

    static var statusMessagePomodoroDone: String {
        switch lang {
        case .en: return "Focus session done, remember to take a break."
        case .zhHans: return "专注阶段结束，记得活动一下。"
        case .zhHant: return "專注階段結束，記得活動一下。"
        }
    }

    static var statusMessageSleepTimerDone: String {
        switch lang {
        case .en: return "Timer ended. Mac is going to sleep."
        case .zhHans: return "倒计时结束，准备进入睡眠。"
        case .zhHant: return "倒數結束，準備進入睡眠。"
        }
    }

    static var statusMessageSleepFailed: String {
        switch lang {
        case .en: return "Could not put Mac to sleep. Check permissions."
        case .zhHans: return "无法让系统进入睡眠，请检查权限。"
        case .zhHant: return "無法讓系統進入睡眠，請檢查權限。"
        }
    }

    static var statusMessagePreventionFailed: String {
        switch lang {
        case .en: return "Could not start sleep prevention."
        case .zhHans: return "无法开启防睡眠保护。"
        case .zhHant: return "無法開啟防睡眠保護。"
        }
    }

    static var statusMessageSessionExpired: String {
        switch lang {
        case .en: return "Your previous unfinished timer has expired."
        case .zhHans: return "上次未完成的计时已过期。"
        case .zhHant: return "上次未完成的計時已過期。"
        }
    }

    static func statusMessageSessionRestored(mode: String) -> String {
        switch lang {
        case .en: return "Restored unfinished \(mode)."
        case .zhHans: return "已恢复上次未完成的\(mode)。"
        case .zhHant: return "已恢復上次未完成的\(mode)。"
        }
    }

    static func formatDuration(minutes: Int) -> String {
        if minutes >= 60, minutes % 60 == 0 {
            let hours = minutes / 60
            switch lang {
            case .en: return "\(hours) h"
            case .zhHans: return "\(hours) 小时"
            case .zhHant: return "\(hours) 小時"
            }
        }
        switch lang {
        case .en: return "\(minutes) m"
        case .zhHans: return "\(minutes) 分钟"
        case .zhHant: return "\(minutes) 分鐘"
        }
    }

    static var sleepPreventionBoth: String {
        switch lang {
        case .en: return "Always Awake"
        case .zhHans: return "电池和电源模式都保持唤醒"
        case .zhHant: return "電池和電源模式都保持喚醒"
        }
    }

    static var sleepPreventionBatteryOnly: String {
        switch lang {
        case .en: return "Battery Only"
        case .zhHans: return "仅电池模式保持唤醒"
        case .zhHant: return "僅電池模式保持喚醒"
        }
    }

    static var sleepPreventionPowerOnly: String {
        switch lang {
        case .en: return "Power Adapter Only"
        case .zhHans: return "仅电源模式保持唤醒"
        case .zhHant: return "僅電源模式保持喚醒"
        }
    }

    static var sleepPreventionOff: String {
        switch lang {
        case .en: return "Off"
        case .zhHans: return "防睡眠未启用"
        case .zhHant: return "防睡眠未啟用"
        }
    }

    // MARK: - Notifications
    static var notifTitleCancelled: String {
        switch lang {
        case .en: return "DivineSleep"
        case .zhHans: return "DivineSleep"
        case .zhHant: return "DivineSleep" // App name usually unlocalized
        }
    }

    static var notifBodyCancelled: String {
        switch lang {
        case .en: return "Timer has been cancelled."
        case .zhHans: return "当前倒计时已取消。"
        case .zhHant: return "當前倒數已取消。"
        }
    }

    static var notifTitleSleepNow: String {
        switch lang {
        case .en: return "DivineSleep"
        case .zhHans: return "DivineSleep"
        case .zhHant: return "DivineSleep"
        }
    }

    static var notifBodySleepNow: String {
        switch lang {
        case .en: return "Mac is going to sleep."
        case .zhHans: return "Mac 即将进入睡眠。"
        case .zhHant: return "Mac 即將進入睡眠。"
        }
    }

    static var notifTitlePomodoroDone: String {
        switch lang {
        case .en: return "Focus Complete"
        case .zhHans: return "专注结束"
        case .zhHant: return "專注結束"
        }
    }

    static var notifBodyPomodoroDone: String {
        switch lang {
        case .en: return "Your Pomodoro session is complete."
        case .zhHans: return "你的番茄时钟已经完成。"
        case .zhHant: return "你的番茄時鐘已經完成。"
        }
    }

    static var notifTitleSleepTimerDone: String {
        switch lang {
        case .en: return "Sleep Timer Complete"
        case .zhHans: return "睡眠倒计时结束"
        case .zhHant: return "睡眠倒數結束"
        }
    }

    static var notifBodySleepTimerDone: String {
        switch lang {
        case .en: return "DivineSleep is putting your Mac to sleep."
        case .zhHans: return "DivineSleep 正在让 Mac 进入睡眠。"
        case .zhHant: return "DivineSleep 正在讓 Mac 進入睡眠。"
        }
    }

    // MARK: - Banners
    static var bannerSleepFailedTitle: String {
        switch lang {
        case .en: return "Sleep Failed"
        case .zhHans: return "立即睡眠失败"
        case .zhHant: return "立即睡眠失敗"
        }
    }

    static var bannerSleepFailedDetail: String {
        switch lang {
        case .en: return "System denied the sleep request. Make sure pmset works in your environment."
        case .zhHans: return "系统拒绝了睡眠请求。请确认当前环境允许执行 pmset，或从完整的 .app 包启动。"
        case .zhHant: return "系統拒絕了睡眠請求。請確認目前環境允許執行 pmset，或從完整的 .app 開啟。"
        }
    }

    static var bannerPermissionEnabledTitle: String {
        switch lang {
        case .en: return "Notifications Enabled"
        case .zhHans: return "通知已启用"
        case .zhHant: return "通知已啟用"
        }
    }

    static var bannerPermissionEnabledDetail: String {
        switch lang {
        case .en: return "You will be reminded via notifications when timer ends or actions complete."
        case .zhHans: return "计时结束和系统操作结果会通过通知提醒你。"
        case .zhHant: return "計時結束和系統操作結果會透過通知提醒你。"
        }
    }

    static var bannerPermissionDisabledTitle: String {
        switch lang {
        case .en: return "Notifications Disabled"
        case .zhHans: return "通知未开启"
        case .zhHant: return "通知未開啟"
        }
    }

    static var bannerPermissionDisabledDetail: String {
        switch lang {
        case .en: return "Please go to Settings > Notifications to enable alerts, then recheck."
        case .zhHans: return "请到系统设置 > 通知 > DivineSleep 中开启提醒，再点这里重新检测。"
        case .zhHant: return "請到系統設定 > 通知 > DivineSleep 中開啟提醒，再點擊重新檢測。"
        }
    }

    static var bannerPermissionNoPromptTitle: String {
        switch lang {
        case .en: return "Authorization Prompt Missing"
        case .zhHans: return "授权窗口没有出现"
        case .zhHant: return "授權視窗沒有出現"
        }
    }

    static var bannerPermissionNoPromptDetail: String {
        switch lang {
        case .en: return "This usually happens when not running from a signed .app. Try running the packaged app."
        case .zhHans: return "这通常是因为当前运行的不是签名后的 .app，或系统没有把授权面板带到前台。请重新打开最新打包产物后再试。"
        case .zhHant: return "這通常是因為當前跑的不是簽名後的 .app，或是系統沒把授權對話框拉到最前。請重新開啟打包後的 app 再試。"
        }
    }

    static var bannerPermissionUnknownTitle: String {
        switch lang {
        case .en: return "Notification Status Unconfirmed"
        case .zhHans: return "通知状态未确认"
        case .zhHant: return "通知狀態未確認"
        }
    }

    static var bannerPermissionUnknownDetail: String {
        switch lang {
        case .en: return "You can try authorizing later or check System Settings manually."
        case .zhHans: return "你可以稍后再次尝试授权，或手动在系统设置里检查。"
        case .zhHant: return "你可以稍後再次嘗試授權，或手動在系統設定裡檢查。"
        }
    }

    static var bannerPreventionFailedTitle: String {
        switch lang {
        case .en: return "Prevention Failed"
        case .zhHans: return "防睡眠启动失败"
        case .zhHant: return "防睡眠啟動失敗"
        }
    }

    static var bannerPreventionFailedDetail: String {
        switch lang {
        case .en: return "Could not launch caffeinate. Check app permissions."
        case .zhHans: return "DivineSleep 无法启动 caffeinate。请确认应用有权限调用系统命令。"
        case .zhHant: return "DivineSleep 無法啟動 caffeinate。請確認應用程式有權限呼叫系統命令。"
        }
    }

    static var bannerSessionExpiredTitle: String {
        switch lang {
        case .en: return "Session Not Restored"
        case .zhHans: return "上次计时未恢复"
        case .zhHant: return "上次計時未恢復"
        }
    }

    static var bannerSessionExpiredDetail: String {
        switch lang {
        case .en: return "Found a previous session, but it already expired, so it was cleared."
        case .zhHans: return "检测到旧会话，但它已经过期，所以已自动清理。"
        case .zhHant: return "檢測到舊會話，但它已經過期，所以已自動清理。"
        }
    }

    static var bannerSessionRestoredTitle: String {
        switch lang {
        case .en: return "Session Restored"
        case .zhHans: return "已恢复上次计时"
        case .zhHant: return "已恢復上次計時"
        }
    }

    static func bannerSessionRestoredDetail(mode: String) -> String {
        switch lang {
        case .en: return "Continuing your unfinished \(mode). You can cancel at any time."
        case .zhHans: return "继续之前未完成的\(mode)，你可以直接继续或取消。"
        case .zhHant: return "繼續之前未完成的\(mode)，你可以直接繼續或取消。"
        }
    }

    static var bannerSuggestionTitle: String {
        switch lang {
        case .en: return "Enable Notifications"
        case .zhHans: return "建议启用系统通知"
        case .zhHant: return "建議啟用系統通知"
        }
    }

    static var bannerSuggestionDetail: String {
        switch lang {
        case .en: return "Get instant reminders when timers complete or sleep actions fire."
        case .zhHans: return "这样在计时结束或执行睡眠操作时，你能立即收到提醒。"
        case .zhHant: return "這樣在計時結束或執行睡眠操作時，你能立即收到提醒。"
        }
    }

    static var bannerDisabledWarningTitle: String {
        switch lang {
        case .en: return "Notifications Disabled"
        case .zhHans: return "通知已关闭"
        case .zhHant: return "通知已關閉"
        }
    }

    static var bannerDisabledWarningDetail: String {
        switch lang {
        case .en: return "Please go to Settings > Notifications to turn on alerts to avoid missing reminders."
        case .zhHans: return "请到系统设置 > 通知 > DivineSleep 中开启提醒，避免错过完成提示。"
        case .zhHant: return "請到系統設定 > 通知 > DivineSleep 中開啟提醒，避免錯過完成提示。"
        }
    }
}
