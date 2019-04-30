//
//  GaussianBlurShaders.metal
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/30.
//  Copyright © 2019 Cyandev. All rights reserved.
//

#include <metal_stdlib>

#include "ShaderCommon.h"

using namespace metal;

constant float weight[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

fragment float4
gaussianBlurFragmentShader(RasterizerData in [[stage_in]],
                           constant bool &horizontal [[buffer(0)]],
                           constant float &radius [[buffer(1)]],
                           texture2d<float> texture [[texture(0)]]) {
    constexpr sampler samplr(filter::linear, mag_filter::linear, min_filter::linear);
    
    float2 texOffset = float2(1.0 / texture.get_width(), 1.0 / texture.get_height());
    float3 color = texture.sample(samplr, float2(in.texCoords.x, in.texCoords.y)).rgb * weight[0];
    if (horizontal) {
        for (int i = 1; i < 5; ++i) {
            color += texture.sample(samplr, float2(in.texCoords.x + texOffset.x * i * radius / 10.0, in.texCoords.y)).rgb * weight[i];
            color += texture.sample(samplr, float2(in.texCoords.x - texOffset.x * i * radius / 10.0, in.texCoords.y)).rgb * weight[i];
        }
    } else {
        for (int i = 1; i < 5; ++i) {
            color += texture.sample(samplr, float2(in.texCoords.x, in.texCoords.y + texOffset.y * i * radius / 10.0)).rgb * weight[i];
            color += texture.sample(samplr, float2(in.texCoords.x, in.texCoords.y - texOffset.x * i * radius / 10.0)).rgb * weight[i];
        }
    }
    return float4(color, 1.0);
}
