import Cocoa

let delegate = LayoutSwitcherLauncher()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
