shader_type canvas_item;

uniform float curvature : hint_range(0.0, 0.5) = 0.15;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float rgb_offset : hint_range(0.0, 0.01) = 0.002;
uniform float flicker_speed : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec2 uv = UV;

    // --- Curvature (screen bend) ---
    vec2 centered = uv * 2.0 - 1.0;
    centered *= 1.0 + curvature * dot(centered, centered);
    uv = centered * 0.5 + 0.5;

    // --- Mask for screen bounds (no return!) ---
    float mask =
        step(0.0, uv.x) * step(uv.x, 1.0) *
        step(0.0, uv.y) * step(uv.y, 1.0);

    // --- RGB split (chromatic aberration) ---
    float r = texture(TEXTURE, uv + vec2(rgb_offset, 0.0)).r;
    float g = texture(TEXTURE, uv).g;
    float b = texture(TEXTURE, uv - vec2(rgb_offset, 0.0)).b;

    vec3 color = vec3(r, g, b);

    // --- Scanlines ---
    float scan = sin(uv.y * 800.0) * scanline_intensity;
    color -= scan;

    // --- Flicker ---
    float flicker = sin(TIME * flicker_speed) * 0.02;
    color += flicker;

    // --- Vignette ---
    float dist = distance(uv, vec2(0.5));
    float vignette = smoothstep(0.6, 1.0, dist) * vignette_strength;
    color *= (1.0 - vignette);

    // --- Apply mask (cuts off curved edges cleanly) ---
    color *= mask;

    COLOR = vec4(color, 1.0);
}