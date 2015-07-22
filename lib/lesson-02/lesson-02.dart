library lesson2;

import 'dart:html';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import 'package:dart_webgl_tutorials/example.dart';

/**
 * based on:
 * http://learningwebgl.com/blog/?p=134
 */
class Lesson02 extends AbstractWebGLExample {

  webgl.Program _shaderProgram;
  int _dimensions = 3;
  int _viewportWidth;
  int _viewportHeight;

  webgl.Buffer _triangleVertexPositionBuffer;
  webgl.Buffer _triangleVertexColorBuffer;

  webgl.Buffer _squareVertexPositionBuffer;
  webgl.Buffer _squareVertexColorBuffer;

  Matrix4 _pMatrix;
  Matrix4 _mvMatrix;

  int _aVertexPosition;
  int _aVertexColor;
  webgl.UniformLocation _uPMatrix;
  webgl.UniformLocation _uMVMatrix;

  webgl.Shader _vs;
  webgl.Shader _fs;


  Lesson02(CanvasElement elm) {
    gl = elm.getContext("experimental-webgl");

    _initShaders();
    _initBuffers();

    gl.clearColor(1, 1, 1, 1.0);
    gl.enable(webgl.RenderingContext.DEPTH_TEST);
  }


  _initShaders() {
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
    _vs = gl.createShader(webgl.RenderingContext.VERTEX_SHADER);
    gl.shaderSource(_vs, vsSource);
    gl.compileShader(_vs);

    // fragment shader compilation
    _fs = gl.createShader(webgl.RenderingContext.FRAGMENT_SHADER);
    gl.shaderSource(_fs, fsSource);
    gl.compileShader(_fs);

    // attach shaders to a WebGL program
    _shaderProgram = gl.createProgram();
    gl.attachShader(_shaderProgram, _vs);
    gl.attachShader(_shaderProgram, _fs);
    gl.linkProgram(_shaderProgram);
    gl.useProgram(_shaderProgram);

    /**
     * Check if shaders were compiled properly. This is probably the most painful part
     * since there's no way to "debug" shader compilation
     */
    if (!gl.getShaderParameter(_vs, webgl.RenderingContext.COMPILE_STATUS)) {
      print(gl.getShaderInfoLog(_vs));
    }

    if (!gl.getShaderParameter(_fs, webgl.RenderingContext.COMPILE_STATUS)) {
      print(gl.getShaderInfoLog(_fs));
    }

    if (!gl.getProgramParameter(_shaderProgram, webgl.RenderingContext.LINK_STATUS)) {
      print(gl.getProgramInfoLog(_shaderProgram));
    }

    _aVertexPosition = gl.getAttribLocation(_shaderProgram, "aVertexPosition");
    gl.enableVertexAttribArray(_aVertexPosition);

    _aVertexColor = gl.getAttribLocation(_shaderProgram, "aVertexColor");
    gl.enableVertexAttribArray(_aVertexColor);

    _uPMatrix = gl.getUniformLocation(_shaderProgram, "uPMatrix");
    _uMVMatrix = gl.getUniformLocation(_shaderProgram, "uMVMatrix");
  }

  _initBuffers() {
    // variable to store verticies
    List<double> vertices;

    // create triangle
    _triangleVertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _triangleVertexPositionBuffer);

    // fill "current buffer" with triangle verticies
    vertices = [
       0.0,  1.0,  0.0,
      -1.0, -1.0,  0.0,
       1.0, -1.0,  0.0
    ];
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);

    _triangleVertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _triangleVertexColorBuffer);
    List<double> colors = [
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0
    ];
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(colors), webgl.RenderingContext.STATIC_DRAW);

    //_triangleVertexPositionBuffer.itemSize = 3;
    //_triangleVertexPositionBuffer.numItems = 3;

    // create square
    _squareVertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _squareVertexPositionBuffer);

    // fill "current buffer" with triangle verticies
    vertices = [
         1.0,  1.0,  0.0,
        -1.0,  1.0,  0.0,
         1.0, -1.0,  0.0,
        -1.0, -1.0,  0.0
    ];
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);

    _squareVertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _squareVertexColorBuffer);

    colors = new List();
    for (int i=0; i < 4; i++) {
      colors.addAll([0.5, 0.5, 1.0, 1.0]);
    }
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(colors), webgl.RenderingContext.STATIC_DRAW);
  }

  _setMatrixUniforms() {
    Float32List tmpList = new Float32List(16);

    _pMatrix.copyIntoArray(tmpList);
    gl.uniformMatrix4fv(_uPMatrix, false, tmpList);

    _mvMatrix.copyIntoArray(tmpList);
    gl.uniformMatrix4fv(_uMVMatrix, false, tmpList);
  }

  resize(int width, int height) {
    _viewportWidth = width;
    _viewportHeight = height;

    gl.viewport(0, 0, _viewportWidth, _viewportHeight);

    // field of view is 45°, width-to-height ratio, hide things closer than 0.1 or further than 100
    _pMatrix = makePerspectiveMatrix(radians(45.0), _viewportWidth / _viewportHeight, 0.1, 100.0);
  }

  render([double time = 0]) {
    gl.clear(webgl.RenderingContext.COLOR_BUFFER_BIT | webgl.RenderingContext.DEPTH_BUFFER_BIT);

    // draw triangle
    _mvMatrix = new Matrix4.identity();
    _mvMatrix.translate(new Vector3(-1.5, 0.0, -7.0));

    // verticies
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _triangleVertexPositionBuffer);
    gl.vertexAttribPointer(_aVertexPosition, _dimensions, webgl.RenderingContext.FLOAT, false, 0, 0);
    // color
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _triangleVertexColorBuffer);
    gl.vertexAttribPointer(_aVertexColor, 4, webgl.RenderingContext.FLOAT, false, 0, 0);
    _setMatrixUniforms();
    gl.drawArrays(webgl.RenderingContext.TRIANGLES, 0, 3); // triangles, start at 0, total 3

    // draw square
    _mvMatrix.translate(new Vector3(3.0, 0.0, 0.0));

    // verticies
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _squareVertexPositionBuffer);
    gl.vertexAttribPointer(_aVertexPosition, _dimensions, webgl.RenderingContext.FLOAT, false, 0, 0);
    // color
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _squareVertexColorBuffer);
    gl.vertexAttribPointer(_aVertexColor, 4, webgl.RenderingContext.FLOAT, false, 0, 0);
    _setMatrixUniforms();
    gl.drawArrays(webgl.RenderingContext.TRIANGLE_STRIP, 0, 4); // square, start at 0, total 4
  }

  shutdown() {
    freeBuffers([_triangleVertexPositionBuffer, _triangleVertexColorBuffer, _squareVertexPositionBuffer, _squareVertexColorBuffer]);
    freePrograms([_shaderProgram]);
    freeVertexAttributes(2);
    super.shutdown();
  }

}

main() {
  Lesson02 lesson = new Lesson02(document.querySelector('#drawHere'));
  lesson.render();
}
