import SwiftUI

struct MenuView: View {
    @ObservedObject var sleepManager: SleepManager
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var languageManager = LanguageManager.shared

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var palette: MenuPalette {
        colorScheme == .dark ? .dark : .light
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                HeaderSection(palette: palette, versionText: AppMetadata.versionDisplay)

                ThemeSection(
                    selectedTheme: sleepManager.theme,
                    palette: palette,
                    onSelect: sleepManager.updateTheme
                )

                LanguageSection(
                    selectedLanguage: languageManager.current,
                    palette: palette,
                    onSelect: { languageManager.update($0) }
                )

                SleepControlSection(
                    batteryNeverSleep: $sleepManager.batteryNeverSleep,
                    powerNeverSleep: $sleepManager.powerNeverSleep,
                    palette: palette,
                    onSleepNow: { sleepManager.sleepNow() }
                )

                if let banner = sleepManager.banner {
                    FeedbackBannerView(
                        banner: banner,
                        palette: palette,
                        onDismiss: { sleepManager.dismissBanner() }
                    )
                }

                ModeSelectorSection(
                    selectedMode: sleepManager.mode,
                    palette: palette,
                    onSelect: sleepManager.updateMode
                )

                HeroSection(
                    mode: sleepManager.mode,
                    isTimerRunning: sleepManager.isTimerRunning,
                    timeText: sleepManager.isTimerRunning ? sleepManager.formattedRemainingTime() : formattedSelectedPreset(),
                    statusMessage: sleepManager.statusMessage,
                    selectedDuration: sleepManager.selectedDurationText,
                    preventionSummary: sleepManager.sleepPreventionSummary,
                    isSleepProtectionEnabled: sleepManager.isSleepPreventionEnabled,
                    progress: sleepManager.timerProgress,
                    palette: palette,
                    onCancel: { sleepManager.cancelTimer() }
                )

                PresetGridSection(
                    title: sleepManager.mode == .pomodoro ? L10n.presetGridPomodoroTitle : L10n.presetGridSleepTimerTitle,
                    presets: sleepManager.presetItems,
                    selectedMinutes: sleepManager.selectedMinutes,
                    isTimerRunning: sleepManager.isTimerRunning,
                    mode: sleepManager.mode,
                    palette: palette,
                    columns: columns,
                    onSelect: { sleepManager.startTimer(minutes: $0) }
                )

                NotificationSection(
                    permission: sleepManager.notificationPermission,
                    palette: palette,
                    onRequest: { sleepManager.requestNotificationPermission() },
                    onRefresh: { sleepManager.refreshNotificationPermission() }
                )

                FooterSection(palette: palette)
            }
            .padding(16)
            .id(languageManager.current.rawValue)
        }
        .frame(width: 430, height: 700)
        .background(palette.background)
        .preferredColorScheme(sleepManager.theme.colorScheme)
    }

    private func formattedSelectedPreset() -> String {
        if sleepManager.selectedMinutes >= 60, sleepManager.selectedMinutes % 60 == 0 {
            return "\(sleepManager.selectedMinutes / 60)h"
        }

        return "\(sleepManager.selectedMinutes)m"
    }
}

private struct HeaderSection: View {
    let palette: MenuPalette
    let versionText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text(L10n.appTitle)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(palette.primaryText)

                Spacer()

                Text(versionText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(palette.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(palette.controlFill)
                    )
            }

            Divider()
                .overlay(palette.divider)
        }
    }
}

private struct ModeSelectorSection: View {
    let selectedMode: TimerMode
    let palette: MenuPalette
    let onSelect: (TimerMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: L10n.modeSelectorSectionTitle, palette: palette)

            HStack(spacing: 10) {
                ForEach(TimerMode.allCases) { mode in
                    Button {
                        onSelect(mode)
                    } label: {
                        HStack(spacing: 8) {
                            Text(mode.icon)
                            Text(mode.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(selectedMode == mode ? .white : palette.primaryText)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selectedMode == mode ? AnyShapeStyle(mode.accentGradient) : AnyShapeStyle(palette.controlFill))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(selectedMode == mode ? Color.white.opacity(0.18) : palette.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .pointingCursor()
                }
            }
        }
    }
}

private struct HeroSection: View {
    let mode: TimerMode
    let isTimerRunning: Bool
    let timeText: String
    let statusMessage: String
    let selectedDuration: String
    let preventionSummary: String
    let isSleepProtectionEnabled: Bool
    let progress: Double
    let palette: MenuPalette
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(palette.primaryText)

                    Text(statusMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(palette.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Text(isTimerRunning ? L10n.timerStatusRunning : L10n.timerStatusWaiting)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isTimerRunning ? .white : palette.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isTimerRunning ? AnyShapeStyle(mode.accentGradient) : AnyShapeStyle(palette.controlFill))
                    )
            }

            HStack(alignment: .bottom, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeText)
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(palette.primaryText)
                        .monospacedDigit()

                    Text(isTimerRunning ? L10n.remainingTimeLabel : L10n.selectedDurationLabel)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(palette.secondaryText)
                }

                Spacer()

                if isTimerRunning {
                    Button(L10n.cancelButtonTitle) {
                        onCancel()
                    }
                    .buttonStyle(PillButtonStyle(fill: palette.controlFill, foreground: palette.primaryText))
                }
            }

            if isTimerRunning {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(L10n.progressLabel)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(palette.secondaryText)

                        Spacer()

                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(mode.accentColor)
                    }

                    ProgressView(value: progress)
                        .tint(mode.accentColor)
                }
            }

            HStack(spacing: 10) {
                StatusChip(
                    title: L10n.statusChipDuration,
                    value: selectedDuration,
                    tint: mode.accentColor.opacity(0.14),
                    foreground: palette.primaryText
                )

                StatusChip(
                    title: isSleepProtectionEnabled ? L10n.statusChipPreventionOn : L10n.statusChipPrevention,
                    value: preventionSummary,
                    tint: isSleepProtectionEnabled ? Color.teal.opacity(0.16) : palette.controlFill,
                    foreground: palette.primaryText
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

private struct PresetGridSection: View {
    let title: String
    let presets: [TimerPreset]
    let selectedMinutes: Int
    let isTimerRunning: Bool
    let mode: TimerMode
    let palette: MenuPalette
    let columns: [GridItem]
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionLabel(title: title, palette: palette)
                Spacer()
                Text(L10n.clickToStartHint)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(palette.secondaryText)
            }

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(presets) { preset in
                    PresetCard(
                        preset: preset,
                        mode: mode,
                        isSelected: preset.minutes == selectedMinutes,
                        isRunning: isTimerRunning && preset.minutes == selectedMinutes,
                        palette: palette,
                        onTap: { onSelect(preset.minutes) }
                    )
                }
            }
        }
    }
}

private struct PresetCard: View {
    let preset: TimerPreset
    let mode: TimerMode
    let isSelected: Bool
    let isRunning: Bool
    let palette: MenuPalette
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(preset.valueText)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(palette.primaryText)

                    Text(preset.unitText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(palette.secondaryText)
                }
                
                if isRunning {
                    Circle()
                        .fill(mode.accentColor)
                        .frame(width: 4, height: 4)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(mode.surfaceColor(for: palette)) : AnyShapeStyle(palette.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? mode.accentColor : palette.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .pointingCursor()
    }
}

private struct SleepControlSection: View {
    @Binding var batteryNeverSleep: Bool
    @Binding var powerNeverSleep: Bool
    let palette: MenuPalette
    let onSleepNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(title: L10n.sleepControlSectionTitle, palette: palette)

            SettingTile(
                title: L10n.batteryNeverSleepTitle,
                subtitle: L10n.batteryNeverSleepSubtitle,
                icon: "battery.100.bolt",
                accent: .orange,
                isOn: $batteryNeverSleep,
                palette: palette
            )

            SettingTile(
                title: L10n.powerNeverSleepTitle,
                subtitle: L10n.powerNeverSleepSubtitle,
                icon: "powerplug.fill",
                accent: .teal,
                isOn: $powerNeverSleep,
                palette: palette
            )

            Button(action: onSleepNow) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                    Text(L10n.sleepNowButtonTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(FilledActionStyle(fill: MenuPalette.sleepButtonGradient))
        }
    }
}

private struct ThemeSection: View {
    let selectedTheme: AppTheme
    let palette: MenuPalette
    let onSelect: (AppTheme) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(title: L10n.themeSectionTitle, palette: palette)

            HStack(spacing: 10) {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        onSelect(theme)
                    } label: {
                        HStack(spacing: 8) {
                            Text(theme.icon)
                            Text(theme.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(selectedTheme == theme ? .white : palette.primaryText)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selectedTheme == theme ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(palette.controlFill))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(selectedTheme == theme ? Color.white.opacity(0.18) : palette.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .pointingCursor()
                }
            }
        }
    }
}

private struct LanguageSection: View {
    let selectedLanguage: AppLanguage
    let palette: MenuPalette
    let onSelect: (AppLanguage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(title: L10n.languageSectionTitle, palette: palette)

            HStack(spacing: 10) {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        onSelect(language)
                    } label: {
                        Text(language.displayName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(selectedLanguage == language ? .white : palette.primaryText)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(selectedLanguage == language ? AnyShapeStyle(AppTheme.system.accentGradient) : AnyShapeStyle(palette.controlFill))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(selectedLanguage == language ? Color.white.opacity(0.18) : palette.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .pointingCursor()
                }
            }
        }
    }
}

private struct NotificationSection: View {
    let permission: NotificationPermissionState
    let palette: MenuPalette
    let onRequest: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(title: L10n.notificationSectionTitle, palette: palette)

            HStack(alignment: .top, spacing: 14) {
                Image(systemName: permission.symbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(permission.accentColor)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(permission.accentColor.opacity(0.14))
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(permission.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(palette.primaryText)

                    Text(permission.detail)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button(permission.primaryActionTitle) {
                    if permission == .notDetermined {
                        onRequest()
                    } else {
                        onRefresh()
                    }
                }
                .buttonStyle(PillButtonStyle(fill: palette.controlFill, foreground: palette.primaryText))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

private struct FooterSection: View {
    let palette: MenuPalette

    var body: some View {
        VStack(spacing: 16) {
            Divider()
                .overlay(palette.divider)

            HStack {
                Spacer()

                Button(L10n.footerQuit) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(PillButtonStyle(fill: palette.controlFill, foreground: palette.primaryText))
            }
        }
    }
}

private struct SectionLabel: View {
    let title: String
    let palette: MenuPalette

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(palette.secondaryText)
    }
}

private struct StatusChip: View {
    let title: String
    let value: String
    let tint: Color
    let foreground: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(foreground.opacity(0.65))

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(foreground)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint)
        )
    }
}

private struct FeedbackBannerView: View {
    let banner: FeedbackBanner
    let palette: MenuPalette
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: banner.level.symbolName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(banner.level.accentColor)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(banner.level.accentColor.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(banner.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(palette.primaryText)

                Text(banner.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(palette.secondaryText)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(palette.controlFill)
                    )
            }
            .buttonStyle(.plain)
            .pointingCursor()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(banner.level.backgroundColor(for: palette))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(banner.level.accentColor.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct SettingTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    @Binding var isOn: Bool
    let palette: MenuPalette

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(palette.primaryText)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .pointingCursor()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

private struct PillButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.84 : 1))
            )
            .pointingCursor()
    }
}

private struct FilledActionStyle: ButtonStyle {
    let fill: LinearGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.88 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .pointingCursor()
    }
}

private struct MenuPalette {
    let background: LinearGradient
    let surface: Color
    let controlFill: Color
    let border: Color
    let divider: Color
    let primaryText: Color
    let secondaryText: Color

    static let light = MenuPalette(
        background: LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.96, blue: 0.93),
                Color(red: 0.95, green: 0.97, blue: 1.00),
                Color(red: 0.98, green: 0.94, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surface: Color.white.opacity(0.84),
        controlFill: Color.white.opacity(0.74),
        border: Color.black.opacity(0.08),
        divider: Color.black.opacity(0.08),
        primaryText: Color(red: 0.13, green: 0.15, blue: 0.22),
        secondaryText: Color(red: 0.35, green: 0.38, blue: 0.47)
    )

    static let dark = MenuPalette(
        background: LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.14),
                Color(red: 0.11, green: 0.14, blue: 0.22),
                Color(red: 0.06, green: 0.08, blue: 0.13)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surface: Color.white.opacity(0.08),
        controlFill: Color.white.opacity(0.10),
        border: Color.white.opacity(0.10),
        divider: Color.white.opacity(0.08),
        primaryText: Color.white,
        secondaryText: Color.white.opacity(0.70)
    )

    static let sleepButtonGradient = LinearGradient(
        colors: [
            Color(red: 0.48, green: 0.43, blue: 0.86),
            Color(red: 0.32, green: 0.24, blue: 0.78)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private enum AppMetadata {
    static var versionDisplay: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version ?? "dev"
    }
}

private extension TimerMode {
    var accentColor: Color {
        switch self {
        case .pomodoro:
            return Color(red: 0.92, green: 0.33, blue: 0.30)
        case .sleepTimer:
            return Color(red: 0.22, green: 0.53, blue: 0.96)
        }
    }

    var accentGradient: LinearGradient {
        switch self {
        case .pomodoro:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.42, blue: 0.29),
                    Color(red: 0.99, green: 0.21, blue: 0.43)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sleepTimer:
            return LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.39, blue: 0.94),
                    Color(red: 0.33, green: 0.63, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    func surfaceColor(for palette: MenuPalette) -> Color {
        switch self {
        case .pomodoro:
            return palette == .dark
                ? Color(red: 0.96, green: 0.42, blue: 0.29).opacity(0.16)
                : Color(red: 0.99, green: 0.95, blue: 0.94)
        case .sleepTimer:
            return palette == .dark
                ? Color(red: 0.22, green: 0.53, blue: 0.96).opacity(0.16)
                : Color(red: 0.93, green: 0.96, blue: 1.00)
        }
    }
}

private extension AppTheme {
    var accentGradient: LinearGradient {
        switch self {
        case .light:
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.72, blue: 0.16),
                    Color(red: 0.98, green: 0.52, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.17, green: 0.20, blue: 0.36),
                    Color(red: 0.30, green: 0.34, blue: 0.56)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .system:
            return LinearGradient(
                colors: [
                    Color(red: 0.17, green: 0.65, blue: 0.58),
                    Color(red: 0.19, green: 0.50, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private extension FeedbackLevel {
    var symbolName: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .info:
            return Color(red: 0.18, green: 0.52, blue: 0.94)
        case .success:
            return Color(red: 0.16, green: 0.65, blue: 0.44)
        case .warning:
            return Color(red: 0.91, green: 0.58, blue: 0.16)
        case .error:
            return Color(red: 0.91, green: 0.31, blue: 0.33)
        }
    }

    func backgroundColor(for palette: MenuPalette) -> Color {
        switch self {
        case .info:
            return accentColor.opacity(palette == .dark ? 0.16 : 0.11)
        case .success:
            return accentColor.opacity(palette == .dark ? 0.16 : 0.11)
        case .warning:
            return accentColor.opacity(palette == .dark ? 0.18 : 0.12)
        case .error:
            return accentColor.opacity(palette == .dark ? 0.18 : 0.12)
        }
    }
}

private extension NotificationPermissionState {
    var title: String {
        switch self {
        case .authorized:
            return L10n.notificationAuthorizedTitle
        case .notDetermined:
            return L10n.notificationNotDeterminedTitle
        case .denied:
            return L10n.notificationDeniedTitle
        case .unknown:
            return L10n.notificationUnknownTitle
        }
    }

    var detail: String {
        switch self {
        case .authorized:
            return L10n.notificationAuthorizedDetail
        case .notDetermined:
            return L10n.notificationNotDeterminedDetail
        case .denied:
            return L10n.notificationDeniedDetail
        case .unknown:
            return L10n.notificationUnknownDetail
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .authorized:
            return L10n.notificationActionRefresh
        case .notDetermined:
            return L10n.notificationActionEnable
        case .denied:
            return L10n.notificationActionRecheck
        case .unknown:
            return L10n.notificationActionRefresh
        }
    }

    var symbolName: String {
        switch self {
        case .authorized:
            return "bell.badge.fill"
        case .notDetermined:
            return "bell.circle"
        case .denied:
            return "bell.slash.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var accentColor: Color {
        switch self {
        case .authorized:
            return Color(red: 0.16, green: 0.65, blue: 0.44)
        case .notDetermined:
            return Color(red: 0.18, green: 0.52, blue: 0.94)
        case .denied:
            return Color(red: 0.91, green: 0.58, blue: 0.16)
        case .unknown:
            return Color(red: 0.43, green: 0.49, blue: 0.60)
        }
    }
}

extension MenuPalette: Equatable {
    static func == (lhs: MenuPalette, rhs: MenuPalette) -> Bool {
        lhs.primaryText == rhs.primaryText && lhs.secondaryText == rhs.secondaryText
    }
}

extension View {
    func pointingCursor() -> some View {
        self.onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
