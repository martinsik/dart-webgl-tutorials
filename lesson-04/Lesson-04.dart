library lesson4;

import 'dart:html';
import 'package:vector_math/vector_math.dart';
import 'dart:collection';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';

/**
 * based on:
 * http://learningwebgl.com/blog/?p=370
 */
class Lesson04 {
  
  CanvasElement _canvas;
  webgl.RenderingContext _gl;
  webgl.Program _shaderProgram;
  int _viewportWidth;
  int _viewportHeight;
  
  webgl.Buffer _pyramidVertexPositionBuffer;
  webgl.Buffer _pyramidVertexColorBuffer;
  
  webgl.Buffer _cubeVertexPositionBuffer;
  webgl.Buffer _cubeVertexColorBuffer;
  webgl.Buffer _cubeVertexIndexBuffer;
  
  mat4 _pMatrix;
  mat4 _mvMatrix;
  Queue<mat4> _mvMatrixStack;
  
  int _aVertexPosition;
  int _aVertexColor;
  webgl.UniformLocation _uPMatrix;
  webgl.UniformLocation _uMVMatrix;
  
  double _rPyramid = 0.0;
  double _rCube = 0.0;
  double _lastTime = 0.0;
  
  
  Lesson04(CanvasElement canvas) {
    _viewportWidth = canvas.width;
    _viewportHeight = canvas.height;
    _gl = canvas.getContext("experimental-webgl");
    
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
    _gl.enable(webgl.RenderingContext.DEPTH_TEST);
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
    webgl.Shader vs = _gl.createShader(webgl.RenderingContext.VERTEX_SHADER);
    _gl.shaderSource(vs, vsSource);
    _gl.compileShader(vs);
    
    // fragment shader compilation
    webgl.Shader fs = _gl.createShader(webgl.RenderingContext.FRAGMENT_SHADER);
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
    if (!_gl.getShaderParameter(vs, webgl.RenderingContext.COMPILE_STATUS)) { 
      print(_gl.getShaderInfoLog(vs));
    }
    
    if (!_gl.getShaderParameter(fs, webgl.RenderingContext.COMPILE_STATUS)) { 
      print(_gl.getShaderInfoLog(fs));
    }
    
    if (!_gl.getProgramParameter(_shaderProgram, webgl.RenderingContext.LINK_STATUS)) { 
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
    // variables to store verticies and colors
    List<double> vertices;
//    List<List<double>> colors;
    
    // create triangle
    _pyramidVertexPositionBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _pyramidVertexPositionBuffer);
    
    // fill "current buffer" with triangle verticies
    vertices = [
        // Front face
        0.0,  1.0,  0.0,
       -1.0, -1.0,  1.0,
        1.0, -1.0,  1.0,
        // Right face
        0.0,  1.0,  0.0,
        1.0, -1.0,  1.0,
        1.0, -1.0, -1.0,
        // Back face
        0.0,  1.0,  0.0,
        1.0, -1.0, -1.0,
       -1.0, -1.0, -1.0,
        // Left face
        0.0,  1.0,  0.0,
       -1.0, -1.0, -1.0,
       -1.0, -1.0,  1.0
    ];
    _gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);
     
    _pyramidVertexColorBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _pyramidVertexColorBuffer);
    List<double> colors1 = [
        // Front face
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        // Right face
        1.0, 0.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        // Back face
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        // Left face
        1.0, 0.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        0.0, 1.0, 0.0, 1.0
    ];
    _gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(colors1), webgl.RenderingContext.STATIC_DRAW);
    
    
    // create square
    _cubeVertexPositionBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
        
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
    _gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);
    
    _cubeVertexColorBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexColorBuffer);
    List<List<double>> colors2 = [
        [1.0, 0.0, 0.0, 1.0],     // Front face
        [1.0, 1.0, 0.0, 1.0],     // Back face
        [0.0, 1.0, 0.0, 1.0],     // Top face
        [1.0, 0.5, 0.5, 1.0],     // Bottom face
        [1.0, 0.0, 1.0, 1.0],     // Right face
        [0.0, 0.0, 1.0, 1.0],     // Left face
    ];
    // each cube face (6 faces for one cube) consists of 4 points of the same color where each color has 4 components RGBA
    // therefore I need 4 * 4 * 6 long list of doubles
    List<double> unpackedColors = new List.generate(4 * 4 * colors2.length, (int index) {
      // index ~/ 16 returns 0-5, that's color index
      // index % 4 returns 0-3 that's color component for each color
      return colors2[index ~/ 16][index % 4];
    }, growable: false);
    _gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(unpackedColors), webgl.RenderingContext.STATIC_DRAW);
    
    _cubeVertexIndexBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    List<int> _cubeVertexIndices = [
         0,  1,  2,    0,  2,  3, // Front face
         4,  5,  6,    4,  6,  7, // Back face
         8,  9, 10,    8, 10, 11, // Top face
        12, 13, 14,   12, 14, 15, // Bottom face
        16, 17, 18,   16, 18, 19, // Right face
        20, 21, 22,   20, 22, 23  // Left face
    ];
    _gl.bufferDataTyped(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(_cubeVertexIndices), webgl.RenderingContext.STATIC_DRAW);
  }
  
  void _setMatrixUniforms() {
    Float32List tmpList = new Float32List(16);
    
    _pMatrix.copyIntoArray(tmpList);
    _gl.uniformMatrix4fv(_uPMatrix, false, tmpList);
    
    _mvMatrix.copyIntoArray(tmpList);
    _gl.uniformMatrix4fv(_uMVMatrix, false, tmpList);

  }
  
  
  bool render(double time) {
    _gl.viewport(0, 0, _viewportWidth, _viewportHeight);
    _gl.clear(webgl.RenderingContext.COLOR_BUFFER_BIT | webgl.RenderingContext.DEPTH_BUFFER_BIT);
    
    // field of view is 45°, width-to-height ratio, hide things closer than 0.1 or further than 100
    _pMatrix = makePerspectiveMatrix(radians(45.0), _viewportWidth / _viewportHeight, 0.1, 100.0);
    
    // draw triangle
    _mvMatrix = new mat4.identity();
    _mvMatrix.translate(new vec3(-1.5, 0.0, -8.0));
    
    _mvPushMatrix();
    _mvMatrix.rotate(new vec3(0, 1, 0), radians(_rPyramid));
    
    // verticies
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _pyramidVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);
    // color
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _pyramidVertexColorBuffer);
    _gl.vertexAttribPointer(_aVertexColor, 4, webgl.RenderingContext.FLOAT, false, 0, 0);

    _setMatrixUniforms();
    _gl.drawArrays(webgl.RenderingContext.TRIANGLES, 0, 12); // triangles, start at 0, total 3
    
    _mvPopMatrix();
    
    // draw square
    _mvMatrix.translate(new vec3(3.0, 0.0, 0.0));
    
    _mvPushMatrix();
    _mvMatrix.rotate(new vec3(1, 1, 1), radians(_rCube));
    
    // verticies
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);
    // color
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexColorBuffer);
    _gl.vertexAttribPointer(_aVertexColor, 4, webgl.RenderingContext.FLOAT, false, 0, 0);

    _gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    _setMatrixUniforms();
    _gl.drawElements(webgl.RenderingContext.TRIANGLES, 36, webgl.RenderingContext.UNSIGNED_SHORT, 0);
    
    _mvPopMatrix();
    
    // rotate
    double animationStep = time - _lastTime;
    _rPyramid += (90 * animationStep) / 1000.0;
    _rCube += (75 * animationStep) / 1000.0;
    _lastTime = time;
    
    // keep drawing
    this._renderFrame();
  }
  
  
  void start() {
    this._renderFrame();
  }
  
  void _renderFrame() {
    window.requestAnimationFrame((num time) { this.render(time); });
  }
  
}

void main() {
  Lesson04 lesson = new Lesson04(document.query('#drawHere'));
  lesson.start();
}
