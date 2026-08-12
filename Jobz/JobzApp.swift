//
//  JobzApp.swift
//  Jobz
//
//  Created by Tyler Yang on 8/11/26.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconImage = NSImage(named: "AppIcon") ?? NSImage(contentsOfFile: Bundle.main.path(forResource: "AppIcon", ofType: "icns") ?? "") {
            NSApp.applicationIconImage = iconImage
        }
    }
}

@main
struct JobzApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Window("About Jobz & Licenses", id: "about-licenses") {
            AboutView()
                .frame(minWidth: 550, minHeight: 550)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Jobz & Licenses") {
                    openWindow(id: "about-licenses")
                }
            }
        }
    }
}

