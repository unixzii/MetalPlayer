//
//  DreamEffectShaders.metal
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/30.
//  Copyright © 2019 Cyandev. All rights reserved.
//

#include <metal_stdlib>

#include "ShaderCommon.h"

using namespace metal;

fragment float4
dreamEffectFragmentShader(RasterizerData in [[stage_in]],
                          texture2d<float> texture [[texture(0)]],
                          texture2d<float> last_texture [[texture(1)]],
                          constant float &time [[buffer(0)]]) {
    constexpr sampler samplr(filter::linear, mag_filter::linear, min_filter::linear);
    
    float progress = sin(time / 100.0);
    float scale = 1.0 - progress / 100.0;
    float offset = 0.005 * progress;
    
    float3 color = texture.sample(samplr, float2(in.texCoords.x, in.texCoords.y)).rgb;
    float3 last_color = last_texture.sample(samplr, float2(in.texCoords.x * scale + offset, in.texCoords.y * scale + offset)).rgb;
    
    color.r = color.r * 0.05 + last_color.r * 0.95;
    color.g = color.g * 0.2 + last_color.g * 0.8;
    
    return float4(color, 1.0);
}
