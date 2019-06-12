//
//  DreamEffectRenderPass.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/30.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Metal
import simd

class DreamEffectRenderPass: BasicRenderPass {
    
    fileprivate var cachedTexture: MTLTexture?
    fileprivate var time: Double = 0
    
    override var fragmentShaderFunctionName: String {
        return "dreamEffectFragmentShader"
    }
    
    override var pipelineLabel: String {
        return "DreamEffectRenderPass Pipeline"
    }
    
    override func process(input: MTLTexture, context: RenderPassContext) -> MTLTexture? {
        let width = input.width
        let height = input.height
        
        if self.cachedTexture == nil {
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.textureType = .type2D
            textureDescriptor.width = width
            textureDescriptor.height = height
            textureDescriptor.pixelFormat = input.pixelFormat
            textureDescriptor.storageMode = .private
            textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
            guard let texture = context.device.makeTexture(descriptor: textureDescriptor) else {
                return input
            }
            self.cachedTexture = texture
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = self.cachedTexture!
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
            width: Double(width), height: Double(height),
            znear: -1.0, zfar: 1.0))
        
        renderCommandEncoder.setFragmentTexture(input, index: 0)
        renderCommandEncoder.setFragmentTexture(self.cachedTexture!, index: 1)
        
        time += 1
        var _time = simd_float1(exactly: time)
        renderCommandEncoder.setFragmentBytes(
            &_time, length: MemoryLayout<simd_float1>.size, index: 0)
        
        self.encodeDefaultCommands(using: renderCommandEncoder)
        
        renderCommandEncoder.endEncoding()
        
        return self.cachedTexture!
    }
    
}
