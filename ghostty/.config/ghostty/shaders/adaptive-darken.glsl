// adaptive-darken.glsl
//
// Attempts to simulate increased background-opacity by boosting the alpha
// channel on bright/washed-out pixels. On macOS with Metal, this asks the
// compositor to treat these pixels as more opaque — bleeding less of the
// backdrop through.
//
// This only works if Ghostty passes the output alpha back to the OS
// compositor. If it has no effect, the compositor is ignoring shader alpha.
//
// Tuning:
//   LUMA_THRESHOLD  - brightness level where alpha boost starts (0.0–1.0)
//   LUMA_RANGE      - transition width (smaller = harder edge)
//   MAX_ALPHA_BOOST - max alpha increase applied at full effect (0.0–1.0)
//                     1.0 means fully opaque at brightest pixels

#define LUMA_THRESHOLD  0.20
#define LUMA_RANGE      0.40
#define MAX_ALPHA_BOOST 0.80

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);

    float l = luma(color.rgb);

    // How far past the brightness threshold are we?
    float excess = smoothstep(LUMA_THRESHOLD, LUMA_THRESHOLD + LUMA_RANGE, l);

    // Boost alpha on bright pixels — asks compositor to let less backdrop through
    float newAlpha = min(1.0, color.a + excess * MAX_ALPHA_BOOST);

    fragColor = vec4(color.rgb, newAlpha);
}
