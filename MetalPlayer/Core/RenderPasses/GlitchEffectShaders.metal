//
//  GlitchEffectShaders.metal
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/30.
//  Copyright © 2019 Cyandev. All rights reserved.
//

// This is a shader translated from:
// https://www.shadertoy.com/view/ls3Xzf

#include <metal_stdlib>

#include "ShaderCommon.h"

using namespace metal;

float rand(float time) {
    return fract(sin(time) * 1e4);
}

fragment float4
glitchEffectFragmentShader(RasterizerData in [[stage_in]],
                           texture2d<float> texture [[texture(0)]],
                           constant float &time [[buffer(0)]]) {
    constexpr sampler samplr(filter::linear, mag_filter::linear, min_filter::linear);
    
    float2 uv = in.texCoords;
    float2 uvR = uv;
    float2 uvB = uv;
    
    float randVal = rand(time);
    
    uvR.x = uv.x * 1.0 - randVal * 0.02 * 0.8;
    uvB.y = uv.y * 1.0 + randVal * 0.02 * 0.8;
    
    if (uv.y < randVal && uv.y > randVal -0.1 && sin(time) < 0.0)
    {
        uv.x = (uv + 0.02 * randVal).x;
    }
    
    float3 color;
    color.r = texture.sample(samplr, uvR).r;
    color.g = texture.sample(samplr, uv).g;
    color.b = texture.sample(samplr, uvB).b;
    
    float scanline = sin(uv.y * 800.0 * randVal) / 30.0;
    color *= 1.0 - scanline;
    
    float vegDist = length(0.5 - uv);
    color *= 1.0 - vegDist * 0.6;
    
    return float4(color, 1.0);
}
