shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float strength : hint_range(0.0, 1.0) = 0.4;
uniform float speed : hint_range(0.0, 5.0) = 1.5;
uniform float blur_amount : hint_range(0.0, 0.01) = 0.003;
uniform float chroma : hint_range(0.0, 0.01) = 0.002;

void fragment() {
    vec2 uv = SCREEN_UV;
    float t = TIME * speed;

    // Wobble
    uv.x += sin(uv.y * 10.0 + t) * 0.01 * strength;
    uv.y += cos(uv.x * 8.0 + t * 1.3) * 0.01 * strength;

    // Rotation
    vec2 center = vec2(0.5);
    vec2 offset = uv - center;
    float angle = sin(t * 0.7) * 0.05 * strength;
    float s = sin(angle);
    float c = cos(angle);
    uv = center + vec2(
        offset.x * c - offset.y * s,
        offset.x * s + offset.y * c
    );

    // Blur (using textureLod)
    vec4 col = textureLod(SCREEN_TEXTURE, uv, 0.0) * 0.4;
    col += textureLod(SCREEN_TEXTURE, uv + vec2(blur_amount, 0.0), 0.0) * 0.15;
    col += textureLod(SCREEN_TEXTURE, uv - vec2(blur_amount, 0.0), 0.0) * 0.15;
    col += textureLod(SCREEN_TEXTURE, uv + vec2(0.0, blur_amount), 0.0) * 0.15;
    col += textureLod(SCREEN_TEXTURE, uv - vec2(0.0, blur_amount), 0.0) * 0.15;

    // Chromatic aberration
    float r = textureLod(SCREEN_TEXTURE, uv + vec2(chroma, 0.0), 0.0).r;
    float g = textureLod(SCREEN_TEXTURE, uv, 0.0).g;
    float b = textureLod(SCREEN_TEXTURE, uv - vec2(chroma, 0.0), 0.0).b;

    vec3 final_col = mix(col.rgb, vec3(r, g, b), strength);

    COLOR = vec4(final_col, 1.0);
}