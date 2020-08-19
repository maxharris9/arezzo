//
//  Shaders.metal
//  BareMetal
//
//  Created by Max Harris on 6/26/20.
//  Copyright © 2020 Max Harris. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position[[position]];
    float4 color;
};

struct Uniforms {
    float width;
    float height;
    float4x4 modelViewMatrix;
};

vertex VertexOut basic_vertex(
    constant packed_float3* vertex_array[[buffer(0)]],
    constant float4 *allParams[[buffer(1)]],
    constant Uniforms &uniforms[[buffer(2)]],
    unsigned int vid[[vertex_id]],
    const uint instanceId [[instance_id]]
) {
    VertexOut vo;

    const float4 color = allParams[instanceId];
    const float3 vert = vertex_array[vid];
    const float4 clipPosition(
        (2.0f * vert.x / uniforms.width) - 2.0,
        (-2.0f * vert.y / uniforms.height) + 2.0f,
        0.0f,
        1.0f
    );

    vo.position = uniforms.modelViewMatrix * clipPosition;
    vo.color = color;
    
    return vo;
}

fragment half4 basic_fragment(VertexOut params[[stage_in]])
{
    return half4(params.color);
}
