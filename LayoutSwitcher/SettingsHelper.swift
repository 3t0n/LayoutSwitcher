import Foundation

class SettingsHelper {
    private let indexHotKey = "INDEX_HOT_KEY"
    private let enableAutostart = "ENABLE_AUTOSTART"

    static let shared = SettingsHelper()

    private let store = UserDefaults.standard

    var isAutostartEnable: Bool {
        get { store.object(forKey: enableAutostart) as? Bool ?? false }
        set { store.set(newValue, forKey: enableAutostart) }
    }
    
    var checkedHotKeyIndex: Int {
        get { store.object(forKey: indexHotKey) as? Int ?? 2 }
        set { store.set(newValue, forKey: indexHotKey) }
    }

}
