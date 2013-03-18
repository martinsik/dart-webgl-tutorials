library lesson1;

import 'dart:html';
import 'package:vector_math/vector_math.dart';

/**
 * based on:
 * http://learningwebgl.com/blog/?p=28
 */
class Lesson01 {
  
  CanvasElement _canvas;
  WebGLRenderingContext _gl;
  WebGLBuffer _triangleVertexPositionBuffer;
  WebGLBuffer _squareVertexPositionBuffer;
  WebGLProgram _shaderProgram;
  int _dimensions = 3;
  int _viewportWidth;
  int _viewportHeight;
  
  mat4 _pMatrix;
  mat4 _mvMatrix;
  
  int _aVertexPosition;
  WebGLUniformLocation _uPMatrix;
  WebGLUniformLocation _uMVMatrix;
  
  
  Lesson01(CanvasElement canvas) {
    _viewportWidth = canvas.width;
    _viewportHeight = canvas.height;
    _gl = canvas.getContext("experimental-webgl");
        
    _initShaders();
    _initBuffers();
    
    _gl.clearColor(0.0, 0.0, 0.0, 1.0);
    _gl.enable(WebGLRenderingContext.DEPTH_TEST);
  }
  

  void _initShaders() {
    // vertex shader source code. uPosition is our variable that we'll
    // use to create animation
    String vsSource = """
    attribute vec3 aVertexPosition;

    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;

    void main(void) {
        gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
    }
    """;
    
    // fragment shader source code. uColor is our variable that we'll
    // use to animate color
    String fsSource = """
    precision mediump float;

    void main(void) {
        gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
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
    
  }
  
  void _setMatrixUniforms() {
    // I hope this is temporary. Conversion fom mat4 to Float32Array.
    Float32Array tmpFloat32 = new Float32Array(16);
    
    _pMatrix.copyIntoArray(tmpFloat32);
    _gl.uniformMatrix4fv(_uPMatrix, false, tmpFloat32);
    
    _mvMatrix.copyIntoArray(tmpFloat32);
    _gl.uniformMatrix4fv(_uMVMatrix, false, tmpFloat32);
  }
  
  void render() {
    _gl.viewport(0, 0, _viewportWidth, _viewportHeight);
    _gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT | WebGLRenderingContext.DEPTH_BUFFER_BIT);
    
    // field of view is 45°, width-to-height ratio, hide things closer than 0.1 or further than 100
    _pMatrix = makePerspectiveMatrix(radians(45.0), _viewportWidth / _viewportHeight, 0.1, 100.0);
    
    _mvMatrix = new mat4.identity();
    _mvMatrix.translate(new vec3(-1.5, 0.0, -7.0));
    
    // draw triangle
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _triangleVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, _dimensions, WebGLRenderingContext.FLOAT, false, 0, 0);
    _setMatrixUniforms();
    _gl.drawArrays(WebGLRenderingContext.TRIANGLES, 0, 3); // triangles, start at 0, total 3
    
    // draw square
    _mvMatrix.translate(new vec3(3.0, 0.0, 0.0));
    
    _gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, _squareVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, _dimensions, WebGLRenderingContext.FLOAT, false, 0, 0);
    _setMatrixUniforms();
    _gl.drawArrays(WebGLRenderingContext.TRIANGLE_STRIP, 0, 4); // square, start at 0, total 4
    
  }
  
}

void main() {
  Lesson01 lesson = new Lesson01(document.query('#drawHere'));
  lesson.render();
}
