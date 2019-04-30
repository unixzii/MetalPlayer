//
//  DefaultShaders.metal
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/28.
//  Copyright © 2019 Cyandev. All rights reserved.
//

#include <metal_stdlib>

#include "ShaderCommon.h"

using namespace metal;

typedef struct {
    float4 pos;
    float2 texCoords;
} VertexData;

vertex RasterizerData
defaultVertexShader(uint vertexID [[vertex_id]],
                    constant VertexData *vertices [[buffer(0)]]) {
    RasterizerData out;
    
    out.pos = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.pos.xy = vertices[vertexID].pos.xy;
    
    out.texCoords = vertices[vertexID].texCoords;
    
    return out;
}

fragment float4
defaultFragmentShader(RasterizerData in [[stage_in]],
                      constant float2 &texCoordsScales [[buffer(0)]],
                      texture2d<float> texture [[texture(0)]]) {
    constexpr sampler samplr(filter::linear, mag_filter::linear, min_filter::linear);
    
    float scaleX = texCoordsScales.x;
    float scaleY = texCoordsScales.y;
    float x = (in.texCoords.x - (1.0 - scaleX) / 2.0) / scaleX;
    float y = (in.texCoords.y - (1.0 - scaleY) / 2.0) / scaleY;
    if (x < 0 || x > 1 || y < 0 || y > 1) {
        return float4(float3(0.0), 1.0);
    }
    float3 color = texture.sample(samplr, float2(x, y)).rgb;
    return float4(color, 1.0);
}
