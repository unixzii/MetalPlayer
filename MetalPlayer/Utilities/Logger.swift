//
//  Logger.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/28.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Foundation
import os

struct LogCategory: RawRepresentable {
    
    typealias RawValue = String
    
    var rawValue: String
    
    init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
}

extension LogCategory {
    static let `default` = LogCategory(rawValue: "")
}

struct Logger {

    static let shared = Logger()
    
    init() {
        // Stub
    }
    
    func info(_ message: String, category: LogCategory?) {
        logInternal("💬 \(message)", category: category)
    }
    
    func warn(_ message: String, category: LogCategory?) {
        logInternal("⚠️ \(message)", category: category)
    }
    
    func error(_ message: String, category: LogCategory?) {
        logInternal("❗️ \(message)", category: category)
    }

    func fatal(_ message: String, category: LogCategory?) -> Never {
        fatalError(message)
    }
    
    private func logInternal(_ message: String, category: LogCategory?) {
        os_log("[%s] %s", category?.rawValue ?? "-", message)
    }
    
}
