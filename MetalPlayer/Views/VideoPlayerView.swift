//
//  VideoPlayerView.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/28.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import MetalKit

extension LogCategory {
    static let playerView = LogCategory(rawValue: "PlayerView")
}

class VideoPlayerView: MTKView, MTKViewDelegate, RenderTarget {
    
    var renderer: Renderer? {
        didSet {
            if let renderer = renderer {
                renderer.renderTargetDidChange(self)
            }
        }
    }
    
    var drawable: MTLDrawable? {
        return self.currentDrawable
    }
    
    var renderPassDescriptor: MTLRenderPassDescriptor? {
        return self.currentRenderPassDescriptor
    }
    
    var mtlDevice: MTLDevice? {
        return self.device
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Logger.shared.fatal("Failed to create default device", category: .playerView)
        }
        
        Logger.shared.info("Device created: \(device.name)", category: .playerView)
        
        self.device = device
        self.delegate = self
        
        // Let renderers control the frame scheduling.
        self.isPaused = true
        self.enableSetNeedsDisplay = false
    }
    
    func scheduleFrame() {
        DispatchQueue.main.async {
            self.draw()
        }
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.renderer?.renderTargetDrawableSizeDidChange(size)
    }
    
    func draw(in view: MTKView) {
        self.renderer?.renderFrame()
    }
    
}
