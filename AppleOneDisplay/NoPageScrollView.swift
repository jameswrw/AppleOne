//
//  NoPageScrollView.swift
//  AppleOne
//
//  Created by James Weatherley on 28/11/2025.
//

import SwiftUI

    final class NoPageScrollView: NSScrollView {
        override func keyDown(with event: NSEvent) {
            let kVK_Space: UInt16 = 49
            if event.keyCode == kVK_Space { return }
            super.keyDown(with: event)
        }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            let kVK_Space: UInt16 = 49
            if event.keyCode == kVK_Space { return true }
            return super.performKeyEquivalent(with: event)
        }
    }
