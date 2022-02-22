import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var arrayHotKeys: [NSEvent.ModifierFlags] = [.function, .option, .control, .command]
    var menuBar: NSStatusBar  = NSStatusBar()
    var menuBarItem: NSStatusItem
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initMenu()
        
        //if SettingsHelper.shared.isFirstRun {
        let accessEnabled = isApplicationHasSecurityAccess()
        print("Access: ", accessEnabled)
        
        // TODO: add a timer loop to check when access will be present
        if accessEnabled {
            initEventMonitor()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        deinitEventMonitor()
    }
    
    override init() {
        self.menuBarItem = menuBar.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
    }
    
    func initMenu() {
        // Define application's tray icon
        if let menuBarButton = menuBarItem.button {
            menuBarButton.image = #imageLiteral(resourceName: "MenuBarIcon")
            menuBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
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
        let hotkeysMenu = statusBarMenu.addItem(withTitle: "Layout hot keys", action: nil, keyEquivalent: "")
        
        // Assign submenu to main menu
        hotkeysMenu.submenu = hotkeysSubmenu
        
        // Define autostart menu and get previos state
        let autostartMenuItem = NSMenuItem(title: "Start with system", action: #selector(applicationAutostart), keyEquivalent: "a")
        autostartMenuItem.state = SettingsHelper.shared.isAutostartEnable ? .on : .off
        statusBarMenu.addItem(autostartMenuItem)
        
        // Define other menu items
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(withTitle: "About...", action: #selector(applicationQuit), keyEquivalent: "a")
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
                    self.sendSystemDefaultChangeLayoutHotkey()
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
    
    func sendSystemDefaultChangeLayoutHotkey() {
        // Create a native system 'Control + Space' event
        // TODO: maybe better to read system's layout hotkeys instead of hardcoding
        let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let spaceDown = CGEvent(keyboardEventSource: src, virtualKey: 0x31, keyDown: true)
        let spaceUp = CGEvent(keyboardEventSource: src, virtualKey: 0x31, keyDown: false)
        
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
        sender.state = sender.state == .on ? .off : .on
        SettingsHelper.shared.isAutostartEnable = sender.state == .on ? true : false
        
        // TODO: implement adding to the user's autostart
    }
    
    @objc func applicationAbout() {
        // TODO: upload to the github and add link to the README
        print("applicationAbout")
    }

    @objc func applicationQuit() {
        exit(0)
    }
}

