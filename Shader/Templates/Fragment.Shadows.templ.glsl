#version 430

%DEFINES%

#define IS_SHADOW_SHADER 1

#pragma include "Includes/Configuration.inc.glsl"
#pragma include "Includes/Structures/VertexOutput.struct.glsl"

%INCLUDES%
%INOUT%

layout(location=0) in VertexOutput vOutput;

#ifdef OPT_ALPHA_TESTING
uniform sampler2D p3d_Texture0;
#endif

void main() {
    #ifdef OPT_ALPHA_TESTING
        // Alpha tested shadows. This seems to be quite expensive, so we are
        // only doing this for the objects which really need it (like trees)
        float sampled_alpha = texture(p3d_Texture0, vOutput.texcoord).w;
        if (sampled_alpha < 0.1) discard;
    #endif
}
