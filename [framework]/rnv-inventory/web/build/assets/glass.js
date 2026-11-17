// Glass blur: draws the live game, blurred, behind every element with data-hlsl (CSS can't blur the game).
// From gtasnail/fivem-glsl gamerender.js (MIT, Kypos). Changes: elements are looked up every frame (Vue adds and
// removes panels), nothing is drawn while none exist, and element backgrounds are left alone (tint them in CSS).
(() => {
    const config = { resolutionScale: 0.5, defaultBlurStrength: 8, maxBlurSize: 20 };

    const fragmentShaderSrc = `
  precision mediump float;
  varying vec2 v_texcoord;
  uniform sampler2D u_texture;
  uniform vec4 u_shape;
  uniform float u_borderRadius;
  uniform vec2 u_resolution;
  uniform float u_blurStrength;
  const int blurSizing = ${config.maxBlurSize};
  float roundedBoxSDF(vec2 centerPosition, vec2 size, float radius) {
    return length(max(abs(centerPosition) - size + radius, 0.0)) - radius;
  }
  float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma)) / (sqrt(2.0 * 3.14159) * sigma);
  }
  void main() {
    vec2 centerPosition = gl_FragCoord.xy - u_shape.xy;
    float distance = u_shape.w == 0.0 ? length(centerPosition) - u_shape.z : roundedBoxSDF(centerPosition, u_shape.zw, u_borderRadius);
    if (distance > 0.0) discard;
    vec4 blurredColor = vec4(0.0);
    float totalWeight = 0.0;
    float sigma = u_blurStrength / 3.0;
    for (int x = -blurSizing; x <= blurSizing; x++) {
      for (int y = -blurSizing; y <= blurSizing; y++) {
        if (float(x * x + y * y) > u_blurStrength * u_blurStrength) continue;
        vec2 offset = vec2(float(x), float(y)) / u_resolution;
        float weight = gaussian(length(offset), sigma);
        blurredColor += texture2D(u_texture, v_texcoord + offset) * weight;
        totalWeight += weight;
      }
    }
    gl_FragColor = blurredColor / totalWeight;
  }`;

    const vertexShaderSrc = `
  attribute vec2 a_position;
  attribute vec2 a_texcoord;
  varying vec2 v_texcoord;
  void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);
    v_texcoord = a_texcoord;
  }`;

    function makeShader(gl, type, src) {
        const shader = gl.createShader(type);
        gl.shaderSource(shader, src);
        gl.compileShader(shader);
        const infoLog = gl.getShaderInfoLog(shader);
        if (infoLog) console.error(infoLog);
        return shader;
    }

    // FiveM puts the game frame into a texture made exactly like this. Keep it byte for byte.
    function createTexture(gl) { //thanks fxdk
        const tex = gl.createTexture();
        const texPixels = new Uint8Array([0, 0, 255, 255]);
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, texPixels);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        return tex;
    }

    const canvas = document.createElement('canvas');
    Object.assign(canvas.style, { position: 'fixed', left: '0', top: '0', width: '100%', height: '100%', pointerEvents: 'none', zIndex: '-1' });
    document.body.insertBefore(canvas, document.body.firstChild);

    const gl = canvas.getContext('webgl', { antialias: false, depth: false, stencil: false, alpha: true, preserveDrawingBuffer: true, failIfMajorPerformanceCaveat: false });
    const tex = createTexture(gl);
    const program = gl.createProgram();
    gl.attachShader(program, makeShader(gl, gl.VERTEX_SHADER, vertexShaderSrc));
    gl.attachShader(program, makeShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSrc));
    gl.linkProgram(program);
    gl.useProgram(program);
    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.uniform1i(gl.getUniformLocation(program, 'u_texture'), 0);

    function buffer(data, attrib) {
        const buf = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, buf);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW);
        const loc = gl.getAttribLocation(program, attrib);
        gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(loc);
    }
    buffer([-1, -1, 1, -1, -1, 1, 1, 1], 'a_position');
    buffer([0, 0, 1, 0, 0, 1, 1, 1], 'a_texcoord');

    const u = {
        shape: gl.getUniformLocation(program, 'u_shape'),
        radius: gl.getUniformLocation(program, 'u_borderRadius'),
        resolution: gl.getUniformLocation(program, 'u_resolution'),
        strength: gl.getUniformLocation(program, 'u_blurStrength'),
    };

    function resize() {
        canvas.width = Math.ceil(window.innerWidth * config.resolutionScale);
        canvas.height = Math.ceil(window.innerHeight * config.resolutionScale);
        gl.viewport(0, 0, canvas.width, canvas.height);
    }
    resize();
    window.addEventListener('resize', resize);
    gl.clearColor(0, 0, 0, 0);

    function render() {
        gl.clear(gl.COLOR_BUFFER_BIT);
        const s = config.resolutionScale;
        document.querySelectorAll('[data-hlsl]').forEach((el) => {
            const rect = el.getBoundingClientRect();
            if (rect.width === 0 || rect.height === 0) return;
            const w = Math.ceil(rect.width * s) + 2, h = Math.ceil(rect.height * s) + 2;
            const left = Math.floor(rect.left * s) - 1, top = Math.floor(rect.top * s) - 1;
            const style = getComputedStyle(el);
            const radius = parseFloat(style.borderRadius) || 0;
            const circle = style.borderRadius.includes('%') && radius >= 50;
            gl.uniform4f(u.shape, left + w / 2, canvas.height - (top + h / 2), w / 2, circle ? 0 : h / 2);
            gl.uniform1f(u.radius, circle ? 0 : radius * s);
            gl.uniform2f(u.resolution, canvas.width, canvas.height);
            gl.uniform1f(u.strength, parseFloat(el.dataset.blurStrength) || config.defaultBlurStrength);
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
        });
        requestAnimationFrame(render);
    }
    render();
})();
