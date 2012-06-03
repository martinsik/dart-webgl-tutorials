#import('dart:html');

#import('../gl-matrix-dart/gl-matrix.dart');


/**
 * based on:
 * http://learningwebgl.com/blog/?p=571
 *
 * NOTE: To run this example you have to open in on a webserver (url starting with http:// NOT file:///)!
 */
class Lesson06 {
  
  CanvasElement _canvas;
  WebGLRenderingContext _gl;
  WebGLProgram _shaderProgram;
  int _viewportWidth, _viewportHeight;
  
  List<WebGLTexture> _textures;
  
  WebGLBuffer _cubeVertexTextureCoordBuffer;
  WebGLBuffer _cubeVertexPositionBuffer;
  WebGLBuffer _cubeVertexIndexBuffer;
  
  Matrix4 _pMatrix;
  Matrix4 _mvMatrix;
  Queue<Matrix4> _mvMatrixStack;
  
  int _aVertexPosition;
  int _aTextureCoord;
  WebGLUniformLocation _uPMatrix;
  WebGLUniformLocation _uMVMatrix;
  WebGLUniformLocation _samplerUniform;
  
  double _xRot = 0.0, _xSpeed = 0.0,
         _yRot = 0.0, _ySpeed = 0.0,
         _zPos = -5.0;
  
  int _filter = 0;
  int _lastTime = 0;
  
  List<bool> _currentlyPressedKeys;
  
  var _requestAnimationFrame;
  
  
  Lesson06(CanvasElement canvas) {
    // weird, but without specifying size this array throws exception on []
    _currentlyPressedKeys = new List<bool>(128);
    _viewportWidth = canvas.width;
    _viewportHeight = canvas.height;
    _gl = canvas.getContext("experimental-webgl");
    
    _mvMatrix = new Matrix4();
    _pMatrix = new Matrix4();
    _textures = new List<WebGLTexture>(3);
    
    _initShaders();
    _initBuffers();
    _initTexture();
    
    /*if (window.dynamic['requestAnimationFrame']) {
      _requestAnimationFrame = window.requestAnimationFrame;
    } else if (window.dynamic['webkitRequestAnimationFrame']) {
      _requestAnimationFrame = window.webkitRequestAnimationFrame;
    } else if (window.dynamic['mozRequestAnimationFrame']) {
      _requestAnimationFrame = window.mozRequestAnimationFrame;
    }*/
    //_requestAnimationFrame = window.webkitRequestAnimationFrame;
    
    _gl.clearColor(0.0, 0.0, 0.0, 1.0);
    _gl.enable(WebGLRenderingContext.DEPTH_TEST);
    
    document.on.keyDown.add(this._handleKeyDown);
    document.on.keyUp.add(this._handleKeyUp);
    
  }
  

  void _initShaders() {
    // vertex shader source code. uPosition is our variable that we'll
    // use to create animation
    String vsSource = """
    attribute vec3 aVertexPosition;
    attribute vec2 aTextureCoord;
  
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
  
    varying vec2 vTextureCoord;
  
    void main(void) {
      gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
      vTextureCoord = aTextureCoord;
    }
    """;
    
    // fragment shader source code. uColor is our variable that we'll
    // use to animate color
    String fsSource = """
    precision mediump float;

    varying vec2 vTextureCoord;

    uniform sampler2D uSampler;

    void main(void) {
      gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
    }
    """;
    
    // vertex shader compilation
    WebGLShader vs = _gl.createShader(WebGLRenderingContext.VERTEX_SHADER);
    _gl.shaderSource(vs, vsSource);
    _gl.compileShader(vs);
    
    // fragment shader compilation
    WebGLShader fs = _gl.createShader(WebGLRenderingContext.FRAGMENT_SHADER);
    _gl.shaderSource(fs, fsSource);
    _gl.compileShader(fs);
    
    // attach shaders to a WebGL program
    _shaderProgram = _gl.createProgram();
    _gl.attachShader(_shaderProgram, vs);
    _gl.attachShader(_shaderProgram, fs);
    _gl.linkProgram(_shaderProgram);
    _gl.useProgram(_shaderProgram);
    
    /**
     * Check if shaders were compiled properly. This is probably the most painful part
     * since there's no way to "debug" shader compilation
     */
    if (!_gl.getShaderParameter(vs, WebGLRenderingContext.COMPILE_STATUS)) { 
      print(_gl.getShaderInfoLog(vs));
    }
    
    if (!_gl.getShaderParameter(fs, WebGLRenderingContext.COMPILE_STATUS)) { 
      print(_gl.getShaderInfoLog(fs));
    }
    
    if (!_gl.getProgramParameter(_shaderProgram, WebGLRenderingContext.LINK_STATUS)) { 
      print(_gl.getProgramInfoLog(_shaderProgram));
    }
    
    _aVertexPosition = _gl.getAttribLocation(_shaderProgram, "aVertexPosition");
    _gl.enableVertexAttribArray(_aVertexPosition);
    
    _aTextureCoord = _gl.getAttribLocation(_shaderProgram, "aTextureCoord");
    _gl.enableVertexAttribArray(_aTextureCoord);
    
    _uPMatrix = _gl.getUniformLocation(_shaderProgram, "uPMatrix");
    _uMVMatrix = _gl.getUniformLocation(_shaderProgram, "uMVMatrix");
    _samplerUniform = _gl.getUniformLocation(_shaderProgram, "uSampler");

  }
  
  void _initBuffers() {
    // variables to store verticies, tecture coordinates and colors
    List<double> vertices, textureCoords, colors;
    
    
    // create square
    _cubeVertexPositionBuffer = _gl.createBuffer();
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    // fill "current buffer" with triangle verticies
    vertices = [
        // Front face
        -1.0, -1.0,  1.0,
         1.0, -1.0,  1.0,
         1.0,  1.0,  1.0,
        -1.0,  1.0,  1.0,
        
        // Back face
        -1.0, -1.0, -1.0,
        -1.0,  1.0, -1.0,
         1.0,  1.0, -1.0,
         1.0, -1.0, -1.0,
        
        // Top face
        -1.0,  1.0, -1.0,
        -1.0,  1.0,  1.0,
         1.0,  1.0,  1.0,
         1.0,  1.0, -1.0,
        
        // Bottom face
        -1.0, -1.0, -1.0,
         1.0, -1.0, -1.0,
         1.0, -1.0,  1.0,
        -1.0, -1.0,  1.0,
        
        // Right face
         1.0, -1.0, -1.0,
         1.0,  1.0, -1.0,
         1.0,  1.0,  1.0,
         1.0, -1.0,  1.0,
        
        // Left face
        -1.0, -1.0, -1.0,
        -1.0, -1.0,  1.0,
        -1.0,  1.0,  1.0,
        -1.0,  1.0, -1.0,
    ];
    _gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, new Float32Array.fromList(vertices), WebGLRenderingContext.STATIC_DRAW);
    
    _cubeVertexTextureCoordBuffer = _gl.createBuffer();
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _cubeVertexTextureCoordBuffer);
    textureCoords = [
        // Front face
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
      
        // Back face
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
      
        // Top face
        0.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
      
        // Bottom face
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
      
        // Right face
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
      
        // Left face
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
    ];
    _gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, new Float32Array.fromList(textureCoords), WebGLRenderingContext.STATIC_DRAW);
    
    _cubeVertexIndexBuffer = _gl.createBuffer();
    _gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    List<int> _cubeVertexIndices = [
         0,  1,  2,    0,  2,  3, // Front face
         4,  5,  6,    4,  6,  7, // Back face
         8,  9, 10,    8, 10, 11, // Top face
        12, 13, 14,   12, 14, 15, // Bottom face
        16, 17, 18,   16, 18, 19, // Right face
        20, 21, 22,   20, 22, 23  // Left face
    ];
    _gl.bufferData(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16Array.fromList(_cubeVertexIndices), WebGLRenderingContext.STATIC_DRAW);
  }
  
  void _initTexture() {
    for (var i=0; i < 3; i++) {
      _textures[i] = _gl.createTexture();
    }
    ImageElement image = new Element.tag('img');
    image.on.load.add((e) {
      _handleLoadedTexture(_textures, image);
    });
    image.src = "./crate.gif";
  }
  
  void _handleLoadedTexture(List<WebGLTexture> textures, ImageElement img) {
    _gl.pixelStorei(WebGLRenderingContext.UNPACK_FLIP_Y_WEBGL, 1); // second argument must be an int (no boolean)
    
    _gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, textures[0]);
    _gl.texImage2D(WebGLRenderingContext.TEXTURE_2D, 0, WebGLRenderingContext.RGBA, WebGLRenderingContext.RGBA, WebGLRenderingContext.UNSIGNED_BYTE, img);
    _gl.texParameteri(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_MAG_FILTER, WebGLRenderingContext.NEAREST);
    _gl.texParameteri(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_MIN_FILTER, WebGLRenderingContext.NEAREST);
    
    _gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, textures[1]);
    _gl.texImage2D(WebGLRenderingContext.TEXTURE_2D, 0, WebGLRenderingContext.RGBA, WebGLRenderingContext.RGBA, WebGLRenderingContext.UNSIGNED_BYTE, img);
    _gl.texParameteri(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_MAG_FILTER, WebGLRenderingContext.LINEAR);
    _gl.texParameteri(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_MIN_FILTER, WebGLRenderingContext.LINEAR);

    _gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, textures[2]);
    _gl.texImage2D(WebGLRenderingContext.TEXTURE_2D, 0, WebGLRenderingContext.RGBA, WebGLRenderingContext.RGBA, WebGLRenderingContext.UNSIGNED_BYTE, img);
    _gl.texParameteri(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_MAG_FILTER, WebGLRenderingContext.LINEAR);
    _gl.texParameteri(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_MIN_FILTER, WebGLRenderingContext.LINEAR_MIPMAP_NEAREST);
    _gl.generateMipmap(WebGLRenderingContext.TEXTURE_2D);
    
    _gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, null);
  }
  
  void _setMatrixUniforms() {
    _gl.uniformMatrix4fv(_uPMatrix, false, _pMatrix.array);
    _gl.uniformMatrix4fv(_uMVMatrix, false, _mvMatrix.array);
  }
  
  bool render(int time) {
    _gl.viewport(0, 0, _viewportWidth, _viewportHeight);
    _gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT | WebGLRenderingContext.DEPTH_BUFFER_BIT);
    
    // field of view is 45°, width-to-height ratio, hide things closer than 0.1 or further than 100
    Matrix4.perspective(45, _viewportWidth / _viewportHeight, 0.1, 100.0, _pMatrix);
    
    // draw triangle
    _mvMatrix.identity();

    _mvMatrix.translate(new Vector3.fromList([0.0, 0.0, _zPos]));

    _mvMatrix.rotate(_degToRad(_xRot), new Vector3.fromList([1, 0, 0]));
    _mvMatrix.rotate(_degToRad(_yRot), new Vector3.fromList([0, 1, 0]));
    //_mvMatrix.rotate(_degToRad(_zRot), new Vector3.fromList([0, 0, 1]));
    
    // verticies
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, 3, WebGLRenderingContext.FLOAT, false, 0, 0);
    
    // texture
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _cubeVertexTextureCoordBuffer);
    _gl.vertexAttribPointer(_aTextureCoord, 2, WebGLRenderingContext.FLOAT, false, 0, 0);

    _gl.activeTexture(WebGLRenderingContext.TEXTURE0);
    _gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, _textures[_filter]);
    _gl.uniform1i(_samplerUniform, 0);

    
    _gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    _setMatrixUniforms();
    _gl.drawElements(WebGLRenderingContext.TRIANGLES, 36, WebGLRenderingContext.UNSIGNED_SHORT, 0);
    
    // rotate
    _animate(time);
    _handleKeys();
    
    // keep drawing
    window.webkitRequestAnimationFrame(this.render);
  }
  
  void _handleKeyDown(KeyboardEvent event) {
    if ("F".charCodes()[0] == event.keyCode) {
      _filter++;
      if (_filter == 3) {
        _filter = 0;
      }
    } else {
      _currentlyPressedKeys[event.keyCode] = true;
    }
  }
  
  void _handleKeyUp(KeyboardEvent event) {
    _currentlyPressedKeys[event.keyCode] = false;
  }
  
  void _animate(int timeNow) {
    if (_lastTime != 0) {
        int elapsed = timeNow - _lastTime;

        _xRot += (_xSpeed * elapsed) / 1000.0;
        _yRot += (_ySpeed * elapsed) / 1000.0;
    }
    _lastTime = timeNow;
  }
  
  void _handleKeys() {
    if (_currentlyPressedKeys[33]) {
      // Page Up
      _zPos -= 0.05;
    }
    if (_currentlyPressedKeys[34]) {
      // Page Down
      _zPos += 0.05;
    }
    if (_currentlyPressedKeys[37]) {
      // Left cursor key
      _ySpeed -= 1;
    }
    if (_currentlyPressedKeys[39]) {
      // Right cursor key
      _ySpeed += 1;
    }
    if (_currentlyPressedKeys[38]) {
      // Up cursor key
      _xSpeed -= 1;
    }
    if (_currentlyPressedKeys[40]) {
      // Down cursor key
      _xSpeed += 1;
    }
  }
  
  double _degToRad(double degrees) {
    return degrees * Math.PI / 180;
  }
  
  void start() {
    _lastTime = (new Date.now()).value;
    window.webkitRequestAnimationFrame(this.render);
  }
  
}

void main() {
  Lesson06 lesson = new Lesson06(document.query('#drawHere'));
  lesson.start();
}
