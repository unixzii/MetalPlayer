//
//  Renderer.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/28.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Metal

/// An object that performs the main rendering operations.
protocol Renderer: class {
    
    /// Called when the render target is changed or updated its configurations.
    ///
    /// Receivers should invalidate its resources (such as buffers, states)
    /// and recreate them for the new render target object.
    ///
    /// - Parameter target: The new render target object.
    func renderTargetDidChange(_ target: RenderTarget?)
    
    /// Called when the drawable size of the render target is changed.
    ///
    /// - Parameter size: The new drawable size.
    func renderTargetDrawableSizeDidChange(_ size: CGSize)
    
    /// Called when the render target needs update its content.
    ///
    /// Receivers should commit a new command buffer to render
    /// a new frame. This method should not be called directly.
    func renderFrame()
    
}

/// An object that represents the target for renderers to render to.
protocol RenderTarget: class {
    
    var mtlDevice: MTLDevice? { get }
    var drawableSize: CGSize { get }
    var colorPixelFormat: MTLPixelFormat { get }
    var drawable: MTLDrawable? { get }
    var renderPassDescriptor: MTLRenderPassDescriptor? { get }
    
    /// Makes the receiver redraw its content immediately.
    ///
    /// This method can be called by renderers when they want to
    /// render a new frame.
    func scheduleFrame()
    
}

/// Consumer end of textures.
protocol TextureSink: class {
    
    /// Called by the texture source when there is a new texture available.
    ///
    /// - Parameter texture: The texture to consume.
    func consumeTexture(_ texture: MTLTexture)
    
}

/// Push-style producer end of textures.
protocol TextureSource {
    
    /// Starts pushing the textures.
    func start()
    
    func pause()
    
    /// Sets the sink object.
    ///
    /// This method is called by a sink object and the receiver should
    /// then send textures to it.
    ///
    /// - Parameter sink: The sink object.
    func connectToSink(_ sink: TextureSink)
    
}

protocol RenderPassContext {
    
    var device: MTLDevice { get }
    var commandBuffer: MTLCommandBuffer { get }
    
}

/// An object that represents a render pass.
protocol RenderPass {
    
    /// Notifies the render pass object to create all resources it needs.
    ///
    /// Receivers can create the resources related to the given device, which
    /// can be used later in `process(input:, context:)` method to reduce costs.
    ///
    /// - Parameter device: A Metal device object.
    func prepare(with device: MTLDevice)
    
    /// Processes the given input texture.
    ///
    /// Receivers should issue render commands, create new textures and return
    /// the final texture to the next render pass.
    ///
    /// - Parameters:
    ///   - input: The input texture.
    ///   - context: An object that encapsulates the context information.
    /// - Returns: The result texture.
    func process(input: MTLTexture, context: RenderPassContext) -> MTLTexture?
    
}
