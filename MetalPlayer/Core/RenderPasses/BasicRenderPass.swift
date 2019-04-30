//
//  BasicRenderPass.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/30.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Metal
import simd

extension LogCategory {
    static let basicRenderPass = LogCategory(rawValue: "BasicRenderPass")
}

fileprivate struct VertexData {
    let pos: simd_float4
    let texCoords: simd_float2
}

class BasicRenderPass: RenderPass {
    
    fileprivate var pipelineState: MTLRenderPipelineState!
    fileprivate var verticesBuffer: MTLBuffer!
    
    var vertexShaderFunctionName: String {
        return "defaultVertexShader"
    }
    
    var fragmentShaderFunctionName: String {
        return "defaultFragmentShader"
    }
    
    var pipelineLabel: String {
        return "BasicRenderPass Pipeline"
    }
    
    func prepare(with device: MTLDevice) {
        guard let library = device.makeDefaultLibrary() else {
            Logger.shared.fatal("Failed to make default library.", category: .displayRenderPass)
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = self.pipelineLabel
        pipelineDescriptor.vertexFunction =  library.makeFunction(name: self.vertexShaderFunctionName)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: self.fragmentShaderFunctionName)
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            Logger.shared.fatal(
                "Failed to make render pipeline state: \(error.localizedDescription)",
                category: .displayRenderPass)
        }
        
        let vertices: [VertexData] = [
            VertexData(pos: simd_float4(x: -1, y: -1, z: 0, w: 1),
                       texCoords: simd_float2(x: 0, y: 1)),
            VertexData(pos: simd_float4(x: 1, y: -1, z: 0, w: 1),
                       texCoords: simd_float2(x: 1, y: 1)),
            VertexData(pos: simd_float4(x: -1, y: 1, z: 0, w: 1),
                       texCoords: simd_float2(x: 0, y: 0)),
            VertexData(pos: simd_float4(x: 1, y: 1, z: 0, w: 1),
                       texCoords: simd_float2(x: 1, y: 0)),
            ]
        self.verticesBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<VertexData>.stride * vertices.count,
            options: [])
    }
    
    func process(input: MTLTexture, context: RenderPassContext) -> MTLTexture? {
        // Subclasses override.
        return nil
    }
    
    func encodeDefaultCommands(using encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(self.pipelineState)
        encoder.setVertexBuffer(self.verticesBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
    
}
