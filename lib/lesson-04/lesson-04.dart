library lesson4;

import 'dart:html';
import 'package:vector_math/vector_math.dart';
import 'dart:collection';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';
import '../example.dart';

/**
 * based on:
 * http://learningwebgl.com/blog/?p=370
 */
class Lesson04 extends AbstractWebGLExample {

  CanvasElement _canvas;
  webgl.RenderingContext gl;
  webgl.Program _shaderProgram;
  int _viewportWidth;
  int _viewportHeight;

  webgl.Buffer _pyramidVertexPositionBuffer;
  webgl.Buffer _pyramidVertexColorBuffer;

  webgl.Buffer _cubeVertexPositionBuffer;
  webgl.Buffer _cubeVertexColorBuffer;
  webgl.Buffer _cubeVertexIndexBuffer;

  Matrix4 _pMatrix;
  Matrix4 _mvMatrix;
  Queue<Matrix4> _mvMatrixStack;

  int _aVertexPosition;
  int _aVertexColor;
  webgl.UniformLocation _uPMatrix;
  webgl.UniformLocation _uMVMatrix;

  double _rPyramid = 0.0;
  double _rCube = 0.0;
  double _lastTime = 0.0;


  Lesson04(CanvasElement elm) {
    gl = elm.getContext("experimental-webgl");

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

    gl.clearColor(1, 1, 1, 1.0);
    gl.enable(webgl.RenderingContext.DEPTH_TEST);
  }

  _mvPushMatrix() {
    _mvMatrixStack.addFirst(_mvMatrix.clone());
  }

  _mvPopMatrix() {
    if (0 == _mvMatrixStack.length) {
      throw new Exception("Invalid popMatrix!");
    }
    _mvMatrix = _mvMatrixStack.removeFirst();
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
    webgl.Shader vs = gl.createShader(webgl.RenderingContext.VERTEX_SHADER);
    gl.shaderSource(vs, vsSource);
    gl.compileShader(vs);

    // fragment shader compilation
    webgl.Shader fs = gl.createShader(webgl.RenderingContext.FRAGMENT_SHADER);
    gl.shaderSource(fs, fsSource);
    gl.compileShader(fs);

    // attach shaders to a WebGL program
    _shaderProgram = gl.createProgram();
    gl.attachShader(_shaderProgram, vs);
    gl.attachShader(_shaderProgram, fs);
    gl.linkProgram(_shaderProgram);
    gl.useProgram(_shaderProgram);

    /**
     * Check if shaders were compiled properly. This is probably the most painful part
     * since there's no way to "debug" shader compilation
     */
    if (!gl.getShaderParameter(vs, webgl.RenderingContext.COMPILE_STATUS)) {
      print(gl.getShaderInfoLog(vs));
    }

    if (!gl.getShaderParameter(fs, webgl.RenderingContext.COMPILE_STATUS)) {
      print(gl.getShaderInfoLog(fs));
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
    // variables to store verticies and colors
    List<double> vertices;
//    List<List<double>> colors;

    // create triangle
    _pyramidVertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _pyramidVertexPositionBuffer);

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
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);

    _pyramidVertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _pyramidVertexColorBuffer);
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
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(colors1), webgl.RenderingContext.STATIC_DRAW);


    // create square
    _cubeVertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);

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
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);

    _cubeVertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexColorBuffer);
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
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(unpackedColors), webgl.RenderingContext.STATIC_DRAW);

    _cubeVertexIndexBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    List<int> _cubeVertexIndices = [
         0,  1,  2,    0,  2,  3, // Front face
         4,  5,  6,    4,  6,  7, // Back face
         8,  9, 10,    8, 10, 11, // Top face
        12, 13, 14,   12, 14, 15, // Bottom face
        16, 17, 18,   16, 18, 19, // Right face
        20, 21, 22,   20, 22, 23  // Left face
    ];
    gl.bufferDataTyped(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(_cubeVertexIndices), webgl.RenderingContext.STATIC_DRAW);
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
    _mvMatrix.translate(new Vector3(-1.5, 0.0, -8.0));

    _mvPushMatrix();
    _mvMatrix.rotate(new Vector3(0.0, 1.0, 0.0), radians(_rPyramid));

    // verticies
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _pyramidVertexPositionBuffer);
    gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);
    // color
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _pyramidVertexColorBuffer);
    gl.vertexAttribPointer(_aVertexColor, 4, webgl.RenderingContext.FLOAT, false, 0, 0);

    _setMatrixUniforms();
    gl.drawArrays(webgl.RenderingContext.TRIANGLES, 0, 12); // triangles, start at 0, total 3

    _mvPopMatrix();

    // draw square
    _mvMatrix.translate(new Vector3(3.0, 0.0, 0.0));

    _mvPushMatrix();
    _mvMatrix.rotate(new Vector3(1.0, 1.0, 1.0), radians(_rCube));

    // verticies
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);
    // color
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexColorBuffer);
    gl.vertexAttribPointer(_aVertexColor, 4, webgl.RenderingContext.FLOAT, false, 0, 0);

    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    _setMatrixUniforms();
    gl.drawElements(webgl.RenderingContext.TRIANGLES, 36, webgl.RenderingContext.UNSIGNED_SHORT, 0);

    _mvPopMatrix();

    // rotate
    double animationStep = time - _lastTime;
    _rPyramid += (90 * animationStep) / 1000.0;
    _rCube += (75 * animationStep) / 1000.0;
    _lastTime = time;
  }

  shutdown() {
    freeBuffers([_pyramidVertexPositionBuffer, _pyramidVertexColorBuffer, _cubeVertexPositionBuffer, _cubeVertexColorBuffer, _cubeVertexIndexBuffer]);
    freePrograms([_shaderProgram]);
    freeVertexAttributes(2);
    super.shutdown();
  }

}

main() {
  Lesson04 lesson = new Lesson04(document.querySelector('#drawHere'));
  lesson.start();
}
