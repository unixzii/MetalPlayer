//
//  InvertColorShaders.metal
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/29.
//  Copyright © 2019 Cyandev. All rights reserved.
//

#include <metal_stdlib>

#include "ShaderCommon.h"

using namespace metal;

fragment float4
invertColorFragmentShader(RasterizerData in [[stage_in]],
                          texture2d<float> texture [[texture(0)]]) {
    constexpr sampler samplr(filter::linear, mag_filter::linear, min_filter::linear);
    
    float3 color = texture.sample(samplr, float2(in.texCoords.x, in.texCoords.y)).rgb;
    return float4(1.0 - color, 1.0);
}
