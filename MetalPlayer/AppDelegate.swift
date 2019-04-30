//
//  AppDelegate.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/28.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var playerWindowController: NSWindowController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
        playerWindowController = mainStoryboard
            .instantiateInitialController() as? NSWindowController
        playerWindowController.showWindow(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

