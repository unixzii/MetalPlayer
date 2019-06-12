//
//  DisplayRenderPass.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/30.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import QuartzCore
import Metal
import simd

extension LogCategory {
    static let displayRenderPass = LogCategory(rawValue: "DisplayRenderPass")
}

class DisplayRenderPass: BasicRenderPass {
    
    weak var renderTarget: RenderTarget!
    
    override var pipelineLabel: String {
        return "DisplayRenderPass Pipeline"
    }
    
    override func process(input: MTLTexture, context: RenderPassContext) -> MTLTexture? {
        guard let renderPassDescriptor = self.renderTarget.renderPassDescriptor else {
            Logger.shared.error(
                "Invalid render target state: renderPassDescriptor is nil",
                category: .displayRenderPass)
            return nil
        }
        
        let drawableSize = self.renderTarget.drawableSize
        
        let commandBuffer = context.commandBuffer
        
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor)!
        
        renderCommandEncoder.setViewport(MTLViewport(
            originX: 0.0, originY: 0.0,
            width: Double(drawableSize.width), height: Double(drawableSize.height),
            znear: -1.0, zfar: 1.0))
        
        do {
            var texCoordsScales = simd_float2(x: 1, y: 1)
            var scaleFactor = drawableSize.width / CGFloat(input.width)
            let textureFitHeight = CGFloat(input.height) * scaleFactor
            if textureFitHeight > drawableSize.height {
                scaleFactor = drawableSize.height / CGFloat(input.height)
                let textureFitWidth = CGFloat(input.width) * scaleFactor
                let texCoordsScaleX = textureFitWidth / drawableSize.width
                texCoordsScales.x = Float(texCoordsScaleX)
            } else {
                let texCoordsScaleY = textureFitHeight / drawableSize.height
                texCoordsScales.y = Float(texCoordsScaleY)
            }
            
            renderCommandEncoder.setFragmentBytes(&texCoordsScales,
                                                  length: MemoryLayout<simd_float2>.stride,
                                                  index: 0)
            
            renderCommandEncoder.setFragmentTexture(input, index: 0)
        }
        
        self.encodeDefaultCommands(using: renderCommandEncoder)
        
        renderCommandEncoder.endEncoding()
        
        if let drawable = self.renderTarget.drawable {
            commandBuffer.present(drawable)
        }
        
        return nil
    }
    
}
