import Cocoa
import SwiftUI
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var arrayHotKeys: [NSEvent.ModifierFlags] = [.function, .option, .control, .command]
    private var menuBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var eventMonitor: Any?
    
    private struct Constants {
        // Launcher application bundle identifier
        static let helperBundleID = "com.triton.layoutswitcherlauncher"
        // Icon image sixe
        static let imageSize = 18.0
        // Key code for a space bar
        static var spaceKeyCode: CGKeyCode = 0x31
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Init application menu and icon
        initMenu()
        
        // Check security access to init event monitor
        if isApplicationHasSecurityAccess() {
            initEventMonitor()
        } else {
            let securityAlert = NSAlert()
            
            securityAlert.messageText = "Need security permissions"
            securityAlert.informativeText = "Please provide security permissions for the application and restart it.\nThis is needed to be able globally monitor shortcuts to switch keyboard layout."
            securityAlert.alertStyle = .critical
            securityAlert.addButton(withTitle: "Settings")
            securityAlert.addButton(withTitle: "Exit")
            
            if securityAlert.runModal() == .alertFirstButtonReturn {
                openPrivacySettings()
            }
            
            // Shutdown the application anyway
            exit(-1)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        deinitEventMonitor()
    }
    
    func initMenu() {
        // Define application's tray icon
        if let menuBarButton = menuBarItem.button {
            menuBarButton.image = #imageLiteral(resourceName: "MenuBarIcon")
            menuBarButton.image?.size = NSSize(width: Constants.imageSize, height: Constants.imageSize)
            menuBarButton.image?.isTemplate = true
            menuBarButton.target = self
        }
        
        // Define hot keys submenu
        let hotkeysSubmenu = NSMenu.init()
        hotkeysSubmenu.addItem(withTitle: "Shift ⇧ + Fn",        action: #selector(applicationChangeHotkey), keyEquivalent: "")
        hotkeysSubmenu.addItem(withTitle: "Shift ⇧ + Option ⌥",  action: #selector(applicationChangeHotkey), keyEquivalent: "")
        hotkeysSubmenu.addItem(withTitle: "Shift ⇧ + Control ⌃", action: #selector(applicationChangeHotkey), keyEquivalent: "")
        hotkeysSubmenu.addItem(withTitle: "Shift ⇧ + Command ⌘", action: #selector(applicationChangeHotkey), keyEquivalent: "")
        
        // Get saved checked hot key from previous start
        hotkeysSubmenu.item(at: SettingsHelper.shared.checkedHotKeyIndex)?.state = .on
        
        // Define main menu
        let statusBarMenu = NSMenu()
        let hotkeysMenu = statusBarMenu.addItem(withTitle: "Layout shortcuts", action: nil, keyEquivalent: "")
        
        // Assign submenu to main menu
        hotkeysMenu.submenu = hotkeysSubmenu
        
        // Define autostart menu and get previos state
        let autostartMenuItem = NSMenuItem(title: "Launch at login", action: #selector(applicationAutostart), keyEquivalent: "s")
        autostartMenuItem.state = SettingsHelper.shared.isAutostartEnable ? .on : .off
        statusBarMenu.addItem(autostartMenuItem)
        
        // Define other menu items
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(withTitle: "About...", action: #selector(applicationAbout), keyEquivalent: "a")
        statusBarMenu.addItem(withTitle: "Quit", action: #selector(applicationQuit), keyEquivalent: "q")
        
        menuBarItem.menu = statusBarMenu
    }
    
    func initEventMonitor() {
        // Get second modifier key, according to menu
        let secondModifierFlag = arrayHotKeys[SettingsHelper.shared.checkedHotKeyIndex]
        
        // Enable key event monitor
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            if (event.modifierFlags.contains(.shift) &&
                event.modifierFlags.contains(secondModifierFlag)) {
                    self.sendDefaultChangeLayoutHotkey()
            }
        }
    }
    
    func deinitEventMonitor() {
        guard eventMonitor != nil else {return}
        NSEvent.removeMonitor(eventMonitor!)
    }
    
    func updateEventMonitor() {
        deinitEventMonitor()
        initEventMonitor()
    }
    
    func isApplicationHasSecurityAccess() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func openPrivacySettings() {
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            .flatMap { _ = NSWorkspace.shared.open($0) }
    }
    
    // TODO: To add some more combinations for different use-cases
    func sendDefaultChangeLayoutHotkey() {
        // Create a native system 'Control + Space' event
        // TODO: maybe better to read system's layout hotkeys instead of hardcoding
        let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let spaceDown = CGEvent(keyboardEventSource: src, virtualKey: Constants.spaceKeyCode, keyDown: true)
        let spaceUp = CGEvent(keyboardEventSource: src, virtualKey: Constants.spaceKeyCode, keyDown: false)
        
        spaceDown?.flags = CGEventFlags.maskAlternate
        spaceUp?.flags = CGEventFlags.maskAlternate
        spaceDown?.flags = CGEventFlags.maskControl
        spaceUp?.flags = CGEventFlags.maskControl

        let loc = CGEventTapLocation.cghidEventTap
        spaceDown?.post(tap: loc)
        spaceUp?.post(tap: loc)
    }
    
    @objc func applicationChangeHotkey(_ sender: NSMenuItem) {
        // Update the checked state of menu item and save it
        sender.state = sender.state == .on ? .off : .on
        SettingsHelper.shared.checkedHotKeyIndex = sender.menu!.index(of: sender)
        
        // Restart eventMonitor with new hot key
        self.updateEventMonitor()
        
        // Set previosly checked item to unchecked
        sender.menu?.items.forEach {
            if ($0 != sender && $0.state == .on) {
                $0.state = sender.state == .on ? .off : .on
            }
        }
    }
    
    @objc func applicationAutostart(_ sender: NSMenuItem) {
        // Update menu item checkbox
        sender.state = sender.state == .on ? .off : .on
        
        // Get the new state based on the menu item checkbox
        let newState = sender.state == .on ? true : false
        
        // Run helping application to enable autostart
        let setupResult = SMLoginItemSetEnabled(Constants.helperBundleID as CFString, newState)
        
        // Save settings if action takes effect
        if setupResult == true {
            SettingsHelper.shared.isAutostartEnable = newState
        } else {
            let securityAlert = NSAlert()
            
            securityAlert.messageText = "Can't perform this operation"
            securityAlert.informativeText = "Please check that application was copied to /Application directory and try again.\nYou can also add it manually Settings -> Users and Groups -> Login Items"
            securityAlert.alertStyle = .warning
            securityAlert.addButton(withTitle: "Ok")
        }
    }
    
    @objc func applicationAbout() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let aboutAlert = NSAlert()
        
        aboutAlert.messageText = "Layout Switcher v." + appVersion!
        aboutAlert.informativeText = "LayoutSwitcher is open-source application that allows you to change keyboard layout using shortcuts that are not alloved by MacOS: Fn + Shift ⇧, Option ⌥ + Shift ⇧, Command ⌘ + Shift ⇧ or Control ⌃ + Shift ⇧. \nIn some sence it an alternative for the Punto Switcher or Karabiner if you are using it for similar purpose, because both are kind of overkill for this."
        aboutAlert.alertStyle = .informational
        aboutAlert.addButton(withTitle: "Ok")
        aboutAlert.runModal()
    }

    @objc func applicationQuit() {
        exit(0)
    }
}

