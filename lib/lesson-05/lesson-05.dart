library lesson5;

import 'dart:html';
import 'dart:async';
import 'package:vector_math/vector_math.dart';
import 'dart:collection';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';
import '../example.dart';

/**
 * based on:
 * http://learningwebgl.com/blog/?p=507
 *
 * NOTE: To run this example you have to open in on a webserver (url starting with http:// NOT file:///)!
 */
class Lesson05 extends AbstractWebGLExample {

  CanvasElement _canvas;
  webgl.RenderingContext gl;
  webgl.Program _shaderProgram;
  int _viewportWidth, _viewportHeight;

  webgl.Texture _neheTexture;

  webgl.Buffer _cubeVertexTextureCoordBuffer;
  webgl.Buffer _cubeVertexPositionBuffer;
  webgl.Buffer _cubeVertexIndexBuffer;

  Matrix4 _pMatrix;
  Matrix4 _mvMatrix;
  Queue<Matrix4> _mvMatrixStack;

  int _aVertexPosition;
  int _aTextureCoord;
  webgl.UniformLocation _uPMatrix;
  webgl.UniformLocation _uMVMatrix;
  webgl.UniformLocation _samplerUniform;

  double _xRot = 0.0;
  double _yRot = 0.0;
  double _zRot = 0.0;
  double _lastTime = 0.0;


  Lesson05(CanvasElement elm) {
    gl = elm.getContext("experimental-webgl");

    gl.clearColor(1, 1, 1, 1.0);
    gl.enable(webgl.RenderingContext.DEPTH_TEST);
  }

  init() async {
    _initShaders();
    _initBuffers();
    await _initTexture();
  }

  _initShaders() {
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

    _aTextureCoord = gl.getAttribLocation(_shaderProgram, "aTextureCoord");
    gl.enableVertexAttribArray(_aTextureCoord);

    _uPMatrix = gl.getUniformLocation(_shaderProgram, "uPMatrix");
    _uMVMatrix = gl.getUniformLocation(_shaderProgram, "uMVMatrix");
    _samplerUniform = gl.getUniformLocation(_shaderProgram, "uSampler");
  }

  _initBuffers() {
    // variables to store verticies, tecture coordinates and colors
    List<double> vertices, textureCoords, colors;

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

    _cubeVertexTextureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexTextureCoordBuffer);
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
    gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(textureCoords), webgl.RenderingContext.STATIC_DRAW);

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

  _initTexture() async {
    var textureLoaded = new Completer();

    _neheTexture = gl.createTexture();
    ImageElement image = new Element.tag('img');
    image.onLoad.listen((e) {
      _handleLoadedTexture(_neheTexture, image);
      textureLoaded.complete();
    });
    image.src = "images/nehe.gif";

    return textureLoaded.future;
  }

  _handleLoadedTexture(webgl.Texture texture, ImageElement img) {
    gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, texture);
    gl.pixelStorei(webgl.RenderingContext.UNPACK_FLIP_Y_WEBGL, 1); // second argument must be an int
    gl.texImage2DImage(webgl.RenderingContext.TEXTURE_2D, 0, webgl.RenderingContext.RGBA, webgl.RenderingContext.RGBA, webgl.RenderingContext.UNSIGNED_BYTE, img);
    gl.texParameteri(webgl.RenderingContext.TEXTURE_2D, webgl.RenderingContext.TEXTURE_MAG_FILTER, webgl.RenderingContext.NEAREST);
    gl.texParameteri(webgl.RenderingContext.TEXTURE_2D, webgl.RenderingContext.TEXTURE_MIN_FILTER, webgl.RenderingContext.NEAREST);
    gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, null);
    gl.uniform1i(_samplerUniform, 0);
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

    _mvMatrix = new Matrix4.identity();
    _mvMatrix.translate(new Vector3(0.0, 0.0, -5.0));

    _mvMatrix.rotate(new Vector3(1.0, 0.0, 0.0), radians(_xRot));
    _mvMatrix.rotate(new Vector3(0.0, 1.0, 0.0), radians(_yRot));
    _mvMatrix.rotate(new Vector3(0.0, 0.0, 1.0), radians(_zRot));

    // verticies
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);

    // texture
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexTextureCoordBuffer);
    gl.vertexAttribPointer(_aTextureCoord, 2, webgl.RenderingContext.FLOAT, false, 0, 0);

    gl.activeTexture(webgl.RenderingContext.TEXTURE0);
    gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, _neheTexture);

    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    _setMatrixUniforms();
    gl.drawElements(webgl.RenderingContext.TRIANGLES, 36, webgl.RenderingContext.UNSIGNED_SHORT, 0);

    // rotate
    _animate(time);
  }

  _animate(double time) {
    if (_lastTime != 0) {
        double animationStep = time - _lastTime;

        _xRot += (90 * animationStep) / 1000.0;
        _yRot += (90 * animationStep) / 1000.0;
        _zRot += (90 * animationStep) / 1000.0;
    }
    _lastTime = time;
  }

  shutdown() {
    freeBuffers([_cubeVertexPositionBuffer, _cubeVertexTextureCoordBuffer, _cubeVertexIndexBuffer]);
    freePrograms([_shaderProgram]);
    freeTextures([_neheTexture]);
    freeVertexAttributes(2);
    super.shutdown();
  }

}

main() {
  Lesson05 lesson = new Lesson05(document.querySelector('#drawHere'));
//  lesson.start();
}
