import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en
    case zhHans
    case zhHant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en:
            return "English"
        case .zhHans:
            return "简体中文"
        case .zhHant:
            return "繁體中文"
        }
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private enum StorageKey {
        static let language = "settings.language"
    }

    @Published var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: StorageKey.language)
        }
    }

    private init() {
        if let savedLanguageValue = UserDefaults.standard.string(forKey: StorageKey.language),
           let savedLanguage = AppLanguage(rawValue: savedLanguageValue) {
            self.current = savedLanguage
        } else {
            // Default to system language, fallback to English
            let preferredLanguage = Locale.preferredLanguages.first ?? ""

            if preferredLanguage.hasPrefix("zh-Hans") {
                self.current = .zhHans
            } else if preferredLanguage.hasPrefix("zh-Hant") || preferredLanguage.hasPrefix("zh-HK") || preferredLanguage.hasPrefix("zh-TW") {
                self.current = .zhHant
            } else {
                self.current = .en
            }
        }
    }

    func update(_ language: AppLanguage) {
        guard current != language else { return }
        current = language
    }
}
