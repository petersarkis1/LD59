shader_type canvas_item;

uniform float pixel_size = 32.0;

void fragment() {
    vec2 size = vec2(textureSize(TEXTURE, 0));
    vec2 uv = UV;

    uv = floor(uv * size / pixel_size) * pixel_size / size;

    COLOR = texture(TEXTURE, uv);
}