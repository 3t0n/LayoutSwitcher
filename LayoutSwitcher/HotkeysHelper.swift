//
//  HotkeysHelper.swift
//  LayoutSwitcher
//
//  Created by Dima Stadub on 24.05.22.
//

import Foundation

struct EditHotKeys: OptionSet {

    let rawValue: Int

    static let UndRedo       = EditHotKeys(rawValue: 1 << 0)
    static let CopyPaste      = EditHotKeys(rawValue: 1 << 1)
    static let Find    = EditHotKeys(rawValue: 1 << 2)
    static let All     = EditHotKeys(rawValue: 1 << 3)
    static let OpenSave       = EditHotKeys(rawValue: 1 << 4)
    static let Print     = EditHotKeys(rawValue: 1 << 5)

    func elements() -> AnySequence<Self> {
        var remainingBits = rawValue
        var bitMask: RawValue = 1
        return AnySequence {
            return AnyIterator {
                while remainingBits != 0 {
                    defer { bitMask = bitMask &* 2 }
                    if remainingBits & bitMask != 0 {
                        remainingBits = remainingBits & ~bitMask
                        return Self(rawValue: bitMask)
                    }
                }
                return nil
            }
        }
    }
}

var editHotkeysValues = [EditHotKeys.UndRedo.rawValue: ["z","y"],
                   EditHotKeys.CopyPaste.rawValue: ["x","c","v"],
                   EditHotKeys.Find.rawValue: ["f"],
                   EditHotKeys.All.rawValue: ["a"],
                   EditHotKeys.OpenSave.rawValue: ["o", "s"],
                   EditHotKeys.Print.rawValue: ["p"]]

