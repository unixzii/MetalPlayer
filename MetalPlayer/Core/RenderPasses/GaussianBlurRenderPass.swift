//
//  GaussianBlurRenderPass.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/30.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Metal
import simd

// -
// This is a quick & dirty prototype!
// -

class GaussianBlurRenderPass: BasicRenderPass {
    
    fileprivate var cachedTexture1: MTLTexture?
    fileprivate var cachedTexture2: MTLTexture?
    
    override var fragmentShaderFunctionName: String {
        return "gaussianBlurFragmentShader"
    }
    
    override var pipelineLabel: String {
        return "GaussianBlurRenderPass Pipeline"
    }
    
    fileprivate func prepareTexturesIfNecessary(for input: MTLTexture, context: RenderPassContext) {
        let textureWidth = input.width / 4
        let textureHeight = input.height / 4
        
        if cachedTexture1 != nil
            && cachedTexture1!.width == textureWidth
            && cachedTexture1!.height == textureHeight {
            return
        }
        
        func makeTexture() -> MTLTexture? {
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.textureType = .type2D
            textureDescriptor.width = textureWidth
            textureDescriptor.height = textureHeight
            textureDescriptor.pixelFormat = input.pixelFormat
            textureDescriptor.storageMode = .private
            textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
            guard let texture = context.device.makeTexture(descriptor: textureDescriptor) else {
                return nil
            }
            return texture
        }
        
        cachedTexture1 = makeTexture()
        cachedTexture2 = makeTexture()
    }
    
    override func process(input: MTLTexture, context: RenderPassContext) -> MTLTexture? {
        prepareTexturesIfNecessary(for: input, context: context)
        if self.cachedTexture1 == nil || self.cachedTexture2 == nil {
            return input
        }
        
        var readTexture = input
        var writeTexture = self.cachedTexture1!
        
        func makeRenderPassDescriptor(for texture: MTLTexture) -> MTLRenderPassDescriptor {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].clearColor =
                MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            return renderPassDescriptor
        }
        
        var currentRenderPassDescriptor = makeRenderPassDescriptor(for: cachedTexture1!)
        var nextRenderPassDescriptor = makeRenderPassDescriptor(for: cachedTexture2!)
        
        let width = input.width
        let height = input.height
        
        for i in 0..<8 {
            guard let renderCommandEncoder = context.commandBuffer.makeRenderCommandEncoder(
                descriptor: currentRenderPassDescriptor) else {
                    return input
            }
            
            renderCommandEncoder.setViewport(MTLViewport(
                originX: 0, originY: 0,
                width: Double(width) / 4.0, height: Double(height) / 4.0,
                znear: -1.0, zfar: 1.0))
            
            renderCommandEncoder.setFragmentTexture(readTexture, index: 0)
            
            var horizontal = simd_bool(i % 2 == 0)
            renderCommandEncoder.setFragmentBytes(&horizontal,
                                                  length: MemoryLayout<simd_bool>.size,
                                                  index: 0)
            
            var radius = simd_float1(exactly: 10 + (1.0 - pow(Double(i) / 8.0, 2)) * Double(48))
            renderCommandEncoder.setFragmentBytes(&radius,
                                                  length: MemoryLayout<simd_float1>.size,
                                                  index: 1)
            
            self.encodeDefaultCommands(using: renderCommandEncoder)
            
            renderCommandEncoder.endEncoding()
            
            swap(&writeTexture, &readTexture)
            
            if writeTexture === input {
                // Swap out the original input texture.
                writeTexture = self.cachedTexture2!
            }
            
            swap(&currentRenderPassDescriptor, &nextRenderPassDescriptor)
        }
        
        return readTexture
    }
    
}
