//
//  AppleOneAppDelegate.swift
//  AppleOne
//
//  Created by James Weatherley on 26/11/2025.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
