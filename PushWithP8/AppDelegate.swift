//
//  AppDelegate.swift
//  PushWithP8
//
//  Created by GreyWolf on 2021/8/26.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        NSApp.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.closeWindow), name: NSWindow.willCloseNotification, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func closeWindow() {
        NSApp.terminate(self)
    }
}

