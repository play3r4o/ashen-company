shader_type canvas_item;
render_mode unshaded;

uniform float quality_strength : hint_range(0.0, 1.0) = 0.55;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.12;
uniform float warmth_strength : hint_range(0.0, 1.0) = 0.05;
// Picture-editor controls. Neutral values (brightness 0, contrast/saturation
// 1, everything else 0 or gamma 1) leave the source image unchanged.
uniform float brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float hue_shift_degrees : hint_range(-180.0, 180.0) = 0.0;
uniform float exposure : hint_range(-2.0, 2.0) = 0.0;
uniform float gamma : hint_range(0.25, 4.0) = 1.0;
uniform float temperature : hint_range(-1.0, 1.0) = 0.0;
uniform float tint : hint_range(-1.0, 1.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 rotate_hue(vec3 color, float degrees) {
	float angle = radians(degrees);
	vec3 axis = normalize(vec3(1.0));
	float luma = dot(color, axis);
	vec3 chroma = color - axis * luma;
	vec3 rotated = chroma * cos(angle) + cross(axis, chroma) * sin(angle);
	return max(vec3(0.0), axis * luma + rotated);
}

vec3 grade_color(vec3 color) {
	color *= exp2(exposure);
	color += vec3(brightness);
	color = (color - vec3(0.5)) * contrast + vec3(0.5);
	float gray = luminance(color);
	color = mix(vec3(gray), color, saturation);
	color = rotate_hue(color, hue_shift_degrees);
	color *= vec3(1.0 + temperature * 0.12, 1.0, 1.0 - temperature * 0.12);
	color *= vec3(1.0 + tint * 0.08, 1.0 - tint * 0.08, 1.0 + tint * 0.08);
	color = pow(max(color, vec3(0.0)), vec3(1.0 / max(gamma, 0.25)));
	return clamp(color, vec3(0.0), vec3(1.0));
}

void fragment() {
	// Filter the rendered world behind WorldTint instead of multiplying the
	// nearly-black ColorRect RGB. This keeps the authored alpha as the blend
	// amount while making the Inspector controls visibly useful.
	vec4 source = textureLod(screen_texture, SCREEN_UV, 0.0);
	vec3 graded = grade_color(source.rgb);
	vec2 centered = UV * 2.0 - vec2(1.0);
	float edge = smoothstep(0.28, 1.0, dot(centered, centered));
	float strength = clamp(quality_strength, 0.0, 1.0);
	float blend = clamp(COLOR.a * strength, 0.0, 1.0);
	vec3 warm_tint = mix(vec3(1.0), vec3(1.0, 0.84, 0.62), clamp(warmth_strength, 0.0, 1.0) * strength);
	vec3 shaded = graded * warm_tint;
	shaded *= 1.0 - edge * clamp(vignette_strength, 0.0, 1.0) * strength;
	COLOR = vec4(mix(source.rgb, shaded, blend), 1.0);
}
