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
    }
}
