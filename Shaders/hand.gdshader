shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 128.0) = 16.0;

void fragment() {
    vec2 pixel_uv = floor(UV * pixel_size) / pixel_size;
    COLOR = texture(TEXTURE, pixel_uv);
}