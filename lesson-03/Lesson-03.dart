#import('dart:html');
#import('../gl-matrix-dart/gl-matrix.dart');

/**
 * based on:
 * http://learningwebgl.com/blog/?p=239
 */
class Lesson03 {
  
  CanvasElement _canvas;
  WebGLRenderingContext _gl;
  WebGLProgram _shaderProgram;
  int _dimensions = 3;
  int _viewportWidth;
  int _viewportHeight;
  
  WebGLBuffer _triangleVertexPositionBuffer;
  WebGLBuffer _triangleVertexColorBuffer;
  
  WebGLBuffer _squareVertexPositionBuffer;
  WebGLBuffer _squareVertexColorBuffer;
  
  Matrix4 _pMatrix;
  Matrix4 _mvMatrix;
  Queue<Matrix4> _mvMatrixStack;
  
  int _aVertexPosition;
  int _aVertexColor;
  WebGLUniformLocation _uPMatrix;
  WebGLUniformLocation _uMVMatrix;
  
  double _rTri = 0.0;
  double _rSquare = 0.0;
  int _lastTime = 0;
  
  var _requestAnimationFrame;
  
  
  Lesson03(CanvasElement canvas) {
    _viewportWidth = canvas.width;
    _viewportHeight = canvas.height;
    _gl = canvas.getContext("experimental-webgl");
    
    _mvMatrix = new Matrix4();
    _pMatrix = new Matrix4();
    _mvMatrixStack = new Queue();
    
    _initShaders();
    _initBuffers();
    
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
  }
  
  void _mvPushMatrix() {
    _mvMatrixStack.addFirst(_mvMatrix.clone());
  }

  void _mvPopMatrix() {
    if (0 == _mvMatrixStack.length) {
      throw new Exception("Invalid popMatrix!");
    }
    _mvMatrix = _mvMatrixStack.removeFirst();
  }
  

  void _initShaders() {
    // vertex shader source code. uPosition is our variable that we'll
    // use to create animation
    String vsSource = """
    attribute vec3 aVertexPosition;
    attribute vec4 aVertexColor;
  
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
  
    varying vec4 vColor;
  
    void main(void) {
      gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
      vColor = aVertexColor;
    }
    """;
    
    // fragment shader source code. uColor is our variable that we'll
    // use to animate color
    String fsSource = """
    precision mediump float;

    varying vec4 vColor;

    void main(void) {
      gl_FragColor = vColor;
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
    
    _aVertexColor = _gl.getAttribLocation(_shaderProgram, "aVertexColor");
    _gl.enableVertexAttribArray(_aVertexColor);
    
    _uPMatrix = _gl.getUniformLocation(_shaderProgram, "uPMatrix");
    _uMVMatrix = _gl.getUniformLocation(_shaderProgram, "uMVMatrix");

  }
  
  void _initBuffers() {
    // variable to store verticies
    List<double> vertices;
    
    // create triangle
    _triangleVertexPositionBuffer = _gl.createBuffer();
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _triangleVertexPositionBuffer);
    
    // fill "current buffer" with triangle verticies
    vertices = [
       0.0,  1.0,  0.0,
      -1.0, -1.0,  0.0,
       1.0, -1.0,  0.0
    ];
    _gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, new Float32Array.fromList(vertices), WebGLRenderingContext.STATIC_DRAW);
     
    _triangleVertexColorBuffer = _gl.createBuffer();
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _triangleVertexColorBuffer);
    List<double> colors = [
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0
    ];
    _gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, new Float32Array.fromList(colors), WebGLRenderingContext.STATIC_DRAW);
    
    //_triangleVertexPositionBuffer.itemSize = 3;
    //_triangleVertexPositionBuffer.numItems = 3;
    
    // create square
    _squareVertexPositionBuffer = _gl.createBuffer();
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _squareVertexPositionBuffer);
        
    // fill "current buffer" with triangle verticies
    vertices = [
         1.0,  1.0,  0.0,
        -1.0,  1.0,  0.0,
         1.0, -1.0,  0.0,
        -1.0, -1.0,  0.0
    ];
    _gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, new Float32Array.fromList(vertices), WebGLRenderingContext.STATIC_DRAW);
    
    _squareVertexColorBuffer = _gl.createBuffer();
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _squareVertexColorBuffer);
    
    colors = new List();
    for (int i=0; i < 4; i++) {
      colors.addAll([0.5, 0.5, 1.0, 1.0]);
    }
    _gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, new Float32Array.fromList(colors), WebGLRenderingContext.STATIC_DRAW);
    
  }
  
  void _setMatrixUniforms() {
    _gl.uniformMatrix4fv(_uPMatrix, false, _pMatrix.array);
    _gl.uniformMatrix4fv(_uMVMatrix, false, _mvMatrix.array);
  }
  
  void render(int time) {
    _gl.viewport(0, 0, _viewportWidth, _viewportHeight);
    _gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT | WebGLRenderingContext.DEPTH_BUFFER_BIT);
    
    // field of view is 45°, width-to-height ratio, hide things closer than 0.1 or further than 100
    Matrix4.perspective(45, _viewportWidth / _viewportHeight, 0.1, 100.0, _pMatrix);
    
    // draw triangle
    _mvMatrix.identity();
    _mvMatrix.translate(new Vector3.fromList([-1.5, 0.0, -7.0]));
    
    _mvPushMatrix();
    _mvMatrix.rotate(_degToRad(_rTri), new Vector3.fromList([0, 1, 0]));
    
    // verticies
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _triangleVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, _dimensions, WebGLRenderingContext.FLOAT, false, 0, 0);
    // color
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _triangleVertexColorBuffer);
    _gl.vertexAttribPointer(_aVertexColor, 4, WebGLRenderingContext.FLOAT, false, 0, 0);

    _setMatrixUniforms();
    _gl.drawArrays(WebGLRenderingContext.TRIANGLES, 0, 3); // triangles, start at 0, total 3
    
    _mvPopMatrix();
    
    //print(_gl.getError());
    // draw square
    _mvMatrix.translate(new Vector3.fromList([3.0, 0.0, 0.0]));
    
    _mvPushMatrix();
    _mvMatrix.rotate(_degToRad(_rSquare), new Vector3.fromList([1, 0, 0]));
    
    // verticies
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _squareVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, _dimensions, WebGLRenderingContext.FLOAT, false, 0, 0);
    // color
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _squareVertexColorBuffer);
    _gl.vertexAttribPointer(_aVertexColor, 4, WebGLRenderingContext.FLOAT, false, 0, 0);

    _setMatrixUniforms();
    _gl.drawArrays(WebGLRenderingContext.TRIANGLE_STRIP, 0, 4); // square, start at 0, total 4
    
    _mvPopMatrix();
    
    // rotate
    int duration = time - _lastTime;
    _rTri += (90 * duration) / 1000.0;
    _rSquare += (75 * duration) / 1000.0;
    _lastTime = time;
    
    // keep drawing
    window.webkitRequestAnimationFrame(this.render);
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
  Lesson03 lesson = new Lesson03(document.query('#drawHere'));
  lesson.start();
}
