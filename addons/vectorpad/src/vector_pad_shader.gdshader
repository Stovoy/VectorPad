shader_type canvas_item;

const float HALF = 0.5;
const float MINIMUM_DENOMINATOR = 1e-6;
const float MINIMUM_FILTER_WIDTH = 1.0;

uniform vec2 canvas_size;
uniform vec2 vector_pixels;
uniform float padding_pixels = 6.0;

uniform float grid_divisions = 8.0;
uniform float grid_thickness_pixels = 1.0;
uniform float axis_thickness_pixels = 1.2;
uniform float ring_thickness_pixels = 1.0;
uniform float vector_thickness_pixels = 1.5;
uniform float handle_radius_pixels = 4.0;

uniform vec4 grid_color = vec4(0.20, 0.24, 0.27, 1.0);
uniform vec4 axes_color = vec4(0.60, 0.62, 0.68, 1.0);
uniform vec4 ring_color = vec4(0.50, 0.70, 1.00, 1.0);
uniform vec4 vector_color = vec4(0.90, 0.92, 1.00, 1.0);
uniform vec4 handle_color = vec4(0.90, 0.92, 1.00, 1.0);

float anti_alias_width(float distance_value) {
	return max(fwidth(distance_value), MINIMUM_FILTER_WIDTH);
}

float line_mask(float distance, float thickness){
	float half_width = anti_alias_width(distance) * HALF;
	return 1.0 - smoothstep(thickness - half_width, thickness + half_width, distance);
}

float segment_signed_distance(vec2 point, vec2 segment_start, vec2 segment_end){
	vec2 point_from_start = point - segment_start;
	vec2 segment_vector = segment_end - segment_start;
	float projection_factor = clamp(
		dot(point_from_start, segment_vector) / max(dot(segment_vector, segment_vector), MINIMUM_DENOMINATOR),
		0.0, 1.0
	);
	return length(point_from_start - segment_vector * projection_factor);
}

void fragment(){
	vec2 pixel_position = UV * canvas_size;
	vec2 canvas_center = canvas_size * HALF;
	vec2 position_from_center = pixel_position - canvas_center;
	position_from_center.y *= -1.0;
	float radius = min(canvas_size.x, canvas_size.y) * HALF - padding_pixels;

	float distance_to_center = length(position_from_center);
	if (distance_to_center > radius) {
		discard;
	}

	vec4 color = vec4(0.0);

	float grid_cell_size = (2.0 * radius) / max(grid_divisions, 1.0);
	float grid_cell_half = grid_cell_size * HALF;
	float grid_distance_x = abs(mod(position_from_center.x + grid_cell_half, grid_cell_size) - grid_cell_half);
	float grid_distance_y = abs(mod(position_from_center.y + grid_cell_half, grid_cell_size) - grid_cell_half);
	float grid_line_mask = max(
		line_mask(grid_distance_x, grid_thickness_pixels),
		line_mask(grid_distance_y, grid_thickness_pixels)
	);
	color = mix(color, grid_color, grid_line_mask);

	float axis_x_mask = line_mask(abs(position_from_center.x), axis_thickness_pixels);
	float axis_y_mask = line_mask(abs(position_from_center.y), axis_thickness_pixels);
	color = mix(color, axes_color, max(axis_x_mask, axis_y_mask));

	float ring_mask = line_mask(abs(distance_to_center - radius), ring_thickness_pixels);
	color = mix(color, ring_color, ring_mask);

	vec2 vector_pixels_flipped_y = vector_pixels; vector_pixels_flipped_y.y *= -1.0;
	float vector_length = length(vector_pixels_flipped_y);
	if (vector_length > radius) vector_pixels_flipped_y *= radius / max(vector_length, MINIMUM_DENOMINATOR);
	float vector_segment_mask = line_mask(
		segment_signed_distance(position_from_center, vec2(0.0), vector_pixels_flipped_y),
		vector_thickness_pixels
	);
	color = mix(color, vector_color, vector_segment_mask);

	float handle_mask = line_mask(length(position_from_center - vector_pixels_flipped_y), handle_radius_pixels);
	color = mix(color, handle_color, handle_mask);

	COLOR = color;
}
