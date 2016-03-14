/**
 *
 * RenderPipeline
 *
 * Copyright (c) 2014-2016 tobspr <tobias.springer1@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#version 400

#define USE_GBUFFER_EXTENSIONS
#define USE_MAIN_SCENE_DATA
#pragma include "render_pipeline_base.inc.glsl"
#pragma include "includes/gbuffer.inc.glsl"
#pragma include "includes/transforms.inc.glsl"
#pragma include "includes/color_spaces.inc.glsl"

uniform sampler2D ShadedScene;

out vec4 result;


/*

WORK IN PROGRESS

This code is code in progress and such not formatted very nicely nor commented!

*/


vec3 karis_average(vec3 color) {
  const float sharpness = 0.0;
  return color / (1 + (1 - sharpness) * get_luminance(color));
}

void main() {
  vec2 texcoord = get_texcoord();
  float mid_depth = texture(GBuffer.Depth, texcoord).x;

  vec3 mid_color = texture(ShadedScene, texcoord).xyz;

  vec3 accum = karis_average(mid_color.xyz) * 0;
  float weights = 1.0 * 0.0;

  const float scale = 0.1; // XXX: Todo, make it physically based
  const float focus_plane = 6.0;
  float dist = get_linear_z_from_z(mid_depth);
  float coc = (dist - focus_plane) * scale;

  // Make sure the sun is bright
  if (get_luminance(mid_color) > 20.0) {
    coc = 0;
  }

  coc = clamp(coc, 0.0, 1.0);

  const int kernel_size = 1;
  for (int x = -kernel_size; x <= kernel_size; ++x) {
    for (int y = -kernel_size; y <= kernel_size; ++y) {
      // skip center sample
      // if (x == 0 && y == 0) continue;
      vec2 offcoord = texcoord + vec2(x, y) / SCREEN_SIZE;
      vec3 sample_data = texture(ShadedScene, offcoord).xyz;
      float sample_depth = texture(GBuffer.Depth, offcoord).x;
      sample_data = karis_average(sample_data);

      // float weight = 1 - saturate(abs(mid_depth - sample_depth) / 0.005);
      float weight = 1;
      accum += sample_data * weight;
      weights += weight;

    }
  }

  accum /= max(0.001, weights);
  accum = karis_average(mid_color);
  result = vec4(accum, coc);
}
