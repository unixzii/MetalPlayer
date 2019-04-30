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
        return "InvertColorRenderPass Pipeline"
    }
    
    override func process(input: MTLTexture, context: RenderPassContext) -> MTLTexture? {
        let width = input.width
        let height = input.height
        
        func makeTexture() -> MTLTexture? {
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.textureType = .type2D
            textureDescriptor.width = width / 4
            textureDescriptor.height = height / 4
            textureDescriptor.pixelFormat = input.pixelFormat
            textureDescriptor.storageMode = .managed
            textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
            guard let texture = context.device.makeTexture(descriptor: textureDescriptor) else {
                return nil
            }
            return texture
        }
        
        if self.cachedTexture1 == nil {
            self.cachedTexture1 = makeTexture()
        }
        
        if self.cachedTexture2 == nil {
            self.cachedTexture2 = makeTexture()
        }
        
        if self.cachedTexture1 == nil || self.cachedTexture2 == nil {
            return input
        }
        
        var readTexture = input
        var writeTexture = self.cachedTexture1!
        
        for i in 0..<8 {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = writeTexture
            renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].clearColor =
                MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            guard let renderCommandEncoder = context.commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor) else {
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
            
            let t = readTexture
            readTexture = writeTexture
            writeTexture = t
            
            if writeTexture === input {
                // Swap out the original input texture.
                writeTexture = self.cachedTexture2!
            }
        }
        
        return readTexture
    }
    
}
