import Foundation

class SettingsHelper {
    private let indexHotKey = "INDEX_HOT_KEY"
    private let enableAutostart = "ENABLE_AUTOSTART"
    private let firstRunKey = "FIRST_RUN"

    static let shared = SettingsHelper()

    private let store = UserDefaults.standard

    var isAutostartEnable: Bool {
        get { store.object(forKey: enableAutostart) as? Bool ?? false }
        set { store.set(newValue, forKey: enableAutostart) }
    }

    var isFirstRun: Bool {
        get { store.bool(forKey: firstRunKey) }
        set { store.set(newValue, forKey: firstRunKey) }
    }
    
    var checkedHotKeyIndex: Int {
        get { store.object(forKey: indexHotKey) as? Int ?? 2 }
        set { store.set(newValue, forKey: indexHotKey) }
    }

}
