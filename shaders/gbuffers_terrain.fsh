#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D colortex14;

uniform ivec2 atlasSize;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

// from https://community.khronos.org/t/mipmap-level-calculation-using-dfdx-dfdy/67480
float mip_map_level(in vec2 texture_coordinate) {
    // The OpenGL Graphics System: A Specification 4.2
    //  - chapter 3.9.11, equation 3.21


    vec2  dx_vtc        = dFdx(texture_coordinate);
    vec2  dy_vtc        = dFdy(texture_coordinate);
    float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));


    //return max(0.0, 0.5 * log2(delta_max_sqr) - 1.0); // == log2(sqrt(delta_max_sqr));
    return 0.5 * log2(delta_max_sqr); // == log2(sqrt(delta_max_sqr));
}


void main() {
	vec4 color = texture2D(texture, texcoord);
	color.rgb *= glcolor.rgb;

	if (atlasSize.x != 0 && atlasSize.y != 0) {
		float mipMap = -mip_map_level(texcoord);
		vec2 uv = fract(texcoord * vec2(atlasSize));
		vec3 oldColor = color.rgb;
		float level = mipMap * 0.25 - 1.5;
		level = min(level, 6.1);
		for (int i = 0; i < int(floor(level)); i++) {
			oldColor = color.rgb;
			color.rgb *= 0.999;
			float v = color.g * 8.0;
			float u = fract(v * 8.0);
			v = floor(v) / 8.0;
			u = floor(u) / 8.0;
			u += floor(color.r * 8.0) / 64.0;
			v += floor(color.b * 8.0) / 64.0;
			color.rgb = texture2D(colortex14, vec2(u, v) + uv / 256.0).rgb;
			uv = fract(uv * 16.0);
		}
		color.rgb = mix(oldColor, color.rgb, fract(level));
	}

	color.rgb *= glcolor.a;
	color *= texture2D(lightmap, lmcoord);

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}