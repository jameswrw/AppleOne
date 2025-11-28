//
//  WrapToWidthTextView.swift
//  AppleOne
//
//  Created by James Weatherley on 28/11/2025.
//

import SwiftUI

final class WrapToWidthTextView: NSTextView {
    weak var host: AppleOneTextViewCoordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }

        override var acceptsFirstResponder: Bool { true }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            let kVK_Space: UInt16 = 49
            let pageUp: UInt16 = 116
            let pageDown: UInt16 = 121
            let home: UInt16 = 115
            let end: UInt16 = 119
            switch event.keyCode {
            case kVK_Space, pageUp, pageDown, home, end:
                if let chars = event.characters, !chars.isEmpty {
                    host?.handleKeyPress(chars)
                } else if let charsIgnoringMods = event.charactersIgnoringModifiers, !charsIgnoringMods.isEmpty {
                    host?.handleKeyPress(charsIgnoringMods)
                }
                return true
            default:
                return super.performKeyEquivalent(with: event)
            }
        }

        override func keyDown(with event: NSEvent) {
            if let chars = event.characters, !chars.isEmpty {
                host?.handleKeyPress(chars)
                return
            }
            if let charsIgnoringMods = event.charactersIgnoringModifiers, !charsIgnoringMods.isEmpty {
                host?.handleKeyPress(charsIgnoringMods)
                return
            }
        }
    }
