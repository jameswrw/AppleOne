//
//  AppleOneApp.swift
//  AppleOne
//
//  Created by James Weatherley on 26/11/2025.
//

import SwiftUI

@main
struct AppleOneApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppleOneView()
        }
        // Pick an initial size that matches your content’s ideal size.
        // The terminal is 445x600; allow for the bottom controls and padding.
        .defaultSize(width: 480, height: 720)
        // Make the window track the view’s content size (non-resizable).
        .windowResizability(.contentSize)
    }
}
