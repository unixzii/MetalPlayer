//
//  SimpleRenderer.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/28.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Metal
import simd

extension LogCategory {
    static let simpleRenderer = LogCategory(rawValue: "SimpleRenderer")
}

fileprivate let maxInflightCommandBuffers = 3

class SimpleRenderer: Renderer, TextureSink {
    
    var textureSource: TextureSource? {
        willSet {
            self.textureSource?.pause()
        }
        didSet {
            self.textureSource?.connectToSink(self)
            self.textureSource?.start()
        }
    }
    
    fileprivate var renderPasses = [RenderPass]()
    fileprivate weak var renderTarget: RenderTarget?
    fileprivate var synchronizationSem: DispatchSemaphore!
    fileprivate var commandQueue: MTLCommandQueue!
    fileprivate var currentTexture: MTLTexture?
    fileprivate var hasError = false  // TODO:
    
    init() {
        self.synchronizationSem = DispatchSemaphore(value: maxInflightCommandBuffers)
        self.renderPasses.append(DisplayRenderPass())
    }
    
    deinit {
        // Workaround:
        // DispatchSemaphore crashes the app intentionally if its value
        // is less than the initial value, which is fine in this case.
        for _ in 0..<maxInflightCommandBuffers {
            self.synchronizationSem.signal()
        }
    }
    
    func addRenderPass(_ renderPass: RenderPass) {
        self.renderPasses.insert(renderPass, at: self.renderPasses.count - 1)
        
        if let device = self.renderTarget?.mtlDevice {
            renderPass.prepare(with: device)
        }
    }
    
    func renderTargetDidChange(_ target: RenderTarget?) {
        self.renderTarget = target
        prepare()
    }
    
    func renderTargetDrawableSizeDidChange(_ size: CGSize) {
        // No-op.
    }
    
    func renderFrame() {
        guard var texture = self.currentTexture else {
            // No textures to draw.
            return
        }
        
        guard let buffer = commandQueue.makeCommandBuffer() else {
            Logger.shared.error("Failed to make command buffer.", category: .simpleRenderer)
            self.textureSource?.pause()
            self.hasError = true
            return
        }
        
        buffer.label = "SimpleRenderer Render Command"
        
        let renderPassContext = SimpleRenderPassContext(
            device: self.renderTarget!.mtlDevice!, commandBuffer: buffer)
        self.renderPasses.forEach { renderPass in
            let displayRenderPass: Bool
            if renderPass is DisplayRenderPass {
                (renderPass as! DisplayRenderPass).renderTarget = self.renderTarget
                displayRenderPass = true
            } else {
                displayRenderPass = false
            }
            
            if let nextTexture = renderPass.process(input: texture, context: renderPassContext) {
                texture = nextTexture
            } else if !displayRenderPass {
                Logger.shared.error(
                    "Errors occurred in render pass: \(renderPass)",
                    category: .simpleRenderer)
            }
        }
        
        buffer.addCompletedHandler { [weak self] _ in
            self?.synchronizationSem.signal()
        }
        buffer.commit()
    }
    
    func consumeTexture(_ texture: MTLTexture) {
        // TODO: Add a buffer.
        
        // Perform synchronization here, because the texture source is push-style,
        // we want it to slow down to prevent backpressure.
        self.synchronizationSem.wait()
        
        self.currentTexture = texture
        self.renderTarget?.scheduleFrame()
    }
    
    private func prepare() {
        guard let device = renderTarget?.mtlDevice else {
            Logger.shared.fatal("Invalid render target: no device.", category: .simpleRenderer)
        }
        
        self.commandQueue = device.makeCommandQueue()
        
        self.renderPasses.forEach { $0.prepare(with: device) }
    }
    
}

fileprivate struct SimpleRenderPassContext: RenderPassContext {
    
    var device: MTLDevice
    var commandBuffer: MTLCommandBuffer
    
}
