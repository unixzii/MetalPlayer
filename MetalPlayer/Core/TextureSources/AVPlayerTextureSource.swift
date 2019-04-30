//
//  AVPlayerTextureSource.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/28.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import AVFoundation

extension LogCategory {
    static let avPlayerTextureSource = LogCategory(rawValue: "AVPlayerTextureSource")
}

class AVPlayerTextureSource: TextureSource {
    
    weak var player: AVPlayer!
    weak var textureSink: TextureSink?
    var videoOutput: AVPlayerItemVideoOutput!
    var textureCache: CVMetalTextureCache!
    var streamingQueue: DispatchQueue!
    var started: Bool = false
    
    init(player: AVPlayer, renderTarget: RenderTarget) {
        self.player = player
        
        if let playerItem = player.currentItem {
            self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as NSString as String: kCVPixelFormatType_32BGRA
            ])
            playerItem.add(self.videoOutput)
        } else {
            Logger.shared.warn("Specific player has no items.", category: .avPlayerTextureSource)
            return
        }
        
        guard let device = renderTarget.mtlDevice else {
            Logger.shared.error("Invalid render target: no device.",
                                category: .avPlayerTextureSource)
            return
        }
        
        if CVMetalTextureCacheCreate(
            nil, nil, device, nil, &self.textureCache) != kCVReturnSuccess {
            Logger.shared.warn("Failed to create texture cache", category: .avPlayerTextureSource)
        }
        
        // TODO: Do we need a dedicated thread (to reduce context-switches)
        // instead of a GCD queue?
        self.streamingQueue = DispatchQueue(
            label: "AVPlayerTextureSource Queue",
            qos: .userInteractive,
            attributes: [],
            autoreleaseFrequency: .workItem,
            target: nil)
    }
    
    func start() {
        self.started = true
        self.streamingQueue.async {
            self.pullFrameOnce()
        }
    }
    
    func pause() {
        // TODO: Use a lock instead?
        self.streamingQueue.sync {
            self.started = false
        }
    }
    
    func connectToSink(_ sink: TextureSink) {
        self.textureSink = sink
    }
    
    private func scheduleNextPolling() {
        // TODO: There is no CADisplayLink in macOS, need a way to achieve VSync.
        self.streamingQueue.asyncAfter(deadline: .now() + .milliseconds(16)) {
            if self.started {
                self.pullFrameOnce()
            }
        }
    }
    
    private func pullFrameOnce() {
        guard let player = self.player, let playerItem = player.currentItem else {
            // Player is released or nothing to play.
            return
        }
        
        defer {
            // From now on, any code path will end to scheduling next polling.
            self.scheduleNextPolling()
        }
        
        if player.rate == 0.0 {
            // Player is paused, don't copy pixels.
            //
            // We hasn't been paused yet, this can be caused by a network
            // loading, just keep waiting.
            return
        }
        
        let currentTime = playerItem.currentTime()
        
        guard videoOutput.hasNewPixelBuffer(forItemTime: currentTime) else {
            // There is no new frames to display.
            return
        }
        
        guard let buf = videoOutput.copyPixelBuffer(
            forItemTime: currentTime, itemTimeForDisplay: nil) else {
                // Maybe the buffer is not ready.
                return
        }
        
        let width = CVPixelBufferGetWidth(buf)
        let height = CVPixelBufferGetHeight(buf)
        
        var texture: CVMetalTexture?
        
        CVMetalTextureCacheCreateTextureFromImage(
            nil, self.textureCache, buf, nil, .bgra8Unorm, width, height,
            0, &texture)
        
        if texture == nil {
            return
        }
        
        if let texture = CVMetalTextureGetTexture(texture!) {
            self.textureSink?.consumeTexture(texture)
        }
    }

}
