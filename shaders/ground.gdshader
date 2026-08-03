shader_type spatial;
render_mode cull_back, diffuse_burley;

// Procedural grid so the ground reads as a surface you're moving across.
uniform vec3 base_color : source_color = vec3(0.44, 0.56, 0.38);
uniform vec3 line_color : source_color = vec3(0.33, 0.44, 0.29);
uniform float cell_size = 2.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz / cell_size;
	// Distance to the nearest grid line, in pixels, so lines stay ~1px wide.
	vec2 grid = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
	float line = 1.0 - min(min(grid.x, grid.y), 1.0);
	ALBEDO = mix(base_color, line_color, line);
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
