//
//  PlayerWindowController.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/29.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Cocoa

class PlayerWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        (NSApp.delegate as! AppDelegate).playerWindowController = nil
    }

}
