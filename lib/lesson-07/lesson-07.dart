library lesson7;

import 'dart:async';
import 'dart:html';
import 'dart:collection';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import '../example.dart';


/**
 * based on:
 * http://learningwebgl.com/blog/?p=684
 *
 * NOTE: To run this example you have to open in on a webserver (url starting with http:// NOT file:///)!
 */
class Lesson07 extends AbstractWebGLExample {

  webgl.RenderingContext gl;
  webgl.Program _shaderProgram;
  int _viewportWidth, _viewportHeight;

  webgl.Texture _texture;

  webgl.Buffer _cubeVertexTextureCoordBuffer;
  webgl.Buffer _cubeVertexPositionBuffer;
  webgl.Buffer _cubeVertexIndexBuffer;
  webgl.Buffer _cubeVertexNormalBuffer;

  Matrix4 _pMatrix;
  Matrix4 _mvMatrix;

  int _aVertexPosition;
  int _aTextureCoord;
  int _aVertexNormal;
  webgl.UniformLocation _uPMatrix;
  webgl.UniformLocation _uMVMatrix;
  webgl.UniformLocation _uNMatrix;
  webgl.UniformLocation _uUseLighting;
  webgl.UniformLocation _uLightingDirection;
  webgl.UniformLocation _uAmbientColor;
  webgl.UniformLocation _uDirectionalColor;

  InputElement _elmLighting;
  InputElement _elmAmbientR, _elmAmbientG, _elmAmbientB;
  InputElement _elmLightDirectionX, _elmLightDirectionY, _elmLightDirectionZ;
  InputElement _elmDirectionalR, _elmDirectionalG, _elmDirectionalB;

  double _xRot = 0.0,
      _xSpeed = 0.0,
      _yRot = 0.0,
      _ySpeed = 0.0,
      _zPos = -5.0;

  double _lastTime = 0.0;

  List<bool> _currentlyPressedKeys;

  String options = """
    <input type="checkbox" id="lighting" checked><label for="lighting">Use lighting</label><br>

    <input type="range" id="ambientR" min="0" max="100"><label>Ambiant red</label><br>
    <input type="range" id="ambientG" min="0" max="100"><label>Ambiant green</label><br>
    <input type="range" id="ambientB" min="0" max="100"><label>Ambian blue</label><br>

    <input type="range" id="lightDirectionX" min="0" max="100"><label>Light direct x</label><br>
    <input type="range" id="lightDirectionY" min="0" max="100"><label>Light direction y</label><br>
    <input type="range" id="lightDirectionZ" min="0" max="100"><label>Light direction z</label><br>

    <input type="range" id="directionalR" min="0" max="100"><label>Directional light red</label><br>
    <input type="range" id="directionalG" min="0" max="100"><label>Directional light green</label><br>
    <input type="range" id="directionalB" min="0" max="100"><label>Directional light blue</label><br>
  """;


  Lesson07(CanvasElement elm) {
    gl = elm.getContext("experimental-webgl");

    // weird, but without specifying size this array throws exception on []
    _currentlyPressedKeys = new List<bool>(128);

    _mvMatrix = new Matrix4.identity();
    _pMatrix = new Matrix4.identity();

    gl.clearColor(1, 1, 1, 1.0);
    gl.enable(webgl.RenderingContext.DEPTH_TEST);

    document.onKeyDown.listen(this._handleKeyDown);
    document.onKeyUp.listen(this._handleKeyUp);
  }

  init() async {
    _initShaders();
    _initBuffers();
    await _initTexture();

    _elmLighting = document.querySelector("#lighting");
    _elmAmbientR = document.querySelector("#ambientR");
    _elmAmbientG = document.querySelector("#ambientG");
    _elmAmbientB = document.querySelector("#ambientB");
    _elmLightDirectionX = document.querySelector("#lightDirectionX");
    _elmLightDirectionY = document.querySelector("#lightDirectionY");
    _elmLightDirectionZ = document.querySelector("#lightDirectionZ");
    _elmDirectionalR = document.querySelector("#directionalR");
    _elmDirectionalG = document.querySelector("#directionalG");
    _elmDirectionalB = document.querySelector("#directionalB");
  }

  _initShaders() {
    // vertex shader source code. uPosition is our variable that we'll
    // use to create animation
    String vsSource = """
    attribute vec3 aVertexPosition;
    attribute vec3 aVertexNormal;
    attribute vec2 aTextureCoord;
  
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
    uniform mat3 uNMatrix;
  
    uniform vec3 uAmbientColor;
  
    uniform vec3 uLightingDirection;
    uniform vec3 uDirectionalColor;
  
    uniform bool uUseLighting;
  
    varying vec2 vTextureCoord;
    varying vec3 vLightWeighting;
  
    void main(void) {
      gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
      vTextureCoord = aTextureCoord;
  
      if (!uUseLighting) {
        vLightWeighting = vec3(1.0, 1.0, 1.0);
      } else {
        vec3 transformedNormal = uNMatrix * aVertexNormal;
        float directionalLightWeighting = max(dot(transformedNormal, uLightingDirection), 0.0);
        vLightWeighting = uAmbientColor + uDirectionalColor * directionalLightWeighting;
      }
    }""";

    // fragment shader source code. uColor is our variable that we'll
    // use to animate color
    String fsSource = """
    precision mediump float;
    
    varying vec2 vTextureCoord;
    varying vec3 vLightWeighting;
    
    uniform sampler2D uSampler;
    
    void main(void) {
       vec4 textureColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
       gl_FragColor = vec4(textureColor.rgb * vLightWeighting, textureColor.a);
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

    // attach shaders to a webgl. program
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

    _aVertexNormal = gl.getAttribLocation(_shaderProgram, "aVertexNormal");
    gl.enableVertexAttribArray(_aVertexNormal);

    _uPMatrix = gl.getUniformLocation(_shaderProgram, "uPMatrix");
    _uMVMatrix = gl.getUniformLocation(_shaderProgram, "uMVMatrix");
    _uNMatrix = gl.getUniformLocation(_shaderProgram, "uNMatrix");
//    _uSampler = gl.getUniformLocation(_shaderProgram, "uSampler");
    _uUseLighting = gl.getUniformLocation(_shaderProgram, "uUseLighting");
    _uAmbientColor = gl.getUniformLocation(_shaderProgram, "uAmbientColor");
    _uLightingDirection = gl.getUniformLocation(_shaderProgram, "uLightingDirection");
    _uDirectionalColor = gl.getUniformLocation(_shaderProgram, "uDirectionalColor");
  }

  _initBuffers() {
    // variables to store verticies, tecture coordinates and colors
    List<double> vertices, textureCoords, vertexNormals;

    // create square
    _cubeVertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    // fill "current buffer" with triangle verticies
    vertices = [// Front face
      -1.0, -1.0,  1.0,  1.0, -1.0,  1.0,  1.0,  1.0,  1.0, -1.0,  1.0,  1.0, // Back face
      -1.0, -1.0, -1.0, -1.0,  1.0, -1.0,  1.0,  1.0, -1.0,  1.0, -1.0, -1.0, // Top face
      -1.0,  1.0, -1.0, -1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0, -1.0, // Bottom face
      -1.0, -1.0, -1.0,  1.0, -1.0, -1.0,  1.0, -1.0,  1.0, -1.0, -1.0,  1.0, // Right face
       1.0, -1.0, -1.0,  1.0,  1.0, -1.0,  1.0,  1.0,  1.0,  1.0, -1.0,  1.0, // Left face
      -1.0, -1.0, -1.0, -1.0, -1.0,  1.0, -1.0,  1.0,  1.0, -1.0,  1.0, -1.0,];
    gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);

    _cubeVertexTextureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexTextureCoordBuffer);
    textureCoords = [// Front face
      0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, // Back face
      1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, // Top face
      0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, // Bottom face
      1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, // Right face
      1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, // Left face
      0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0,];
    gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(textureCoords), webgl.RenderingContext.STATIC_DRAW);

    _cubeVertexIndexBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    List<int> _cubeVertexIndices = [0, 1, 2, 0, 2, 3, // Front face
      4,   5,  6,  4,  6,  7, // Back face
      8,   9, 10,  8, 10, 11, // Top face
      12, 13, 14, 12, 14, 15, // Bottom face
      16, 17, 18, 16, 18, 19, // Right face
      20, 21, 22, 20, 22, 23  // Left face
    ];
    gl.bufferData(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(_cubeVertexIndices), webgl.RenderingContext.STATIC_DRAW);


    _cubeVertexNormalBuffer = gl.createBuffer();
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexNormalBuffer);
    vertexNormals = [// Front face
       0.0,  0.0,  1.0,  0.0,  0.0,  1.0,  0.0,  0.0,  1.0,  0.0,  0.0,  1.0, // Back face
       0.0,  0.0, -1.0,  0.0,  0.0, -1.0,  0.0,  0.0, -1.0,  0.0,  0.0, -1.0, // Top face
       0.0,  1.0,  0.0,  0.0,  1.0,  0.0,  0.0,  1.0,  0.0,  0.0,  1.0,  0.0, // Bottom face
       0.0, -1.0,  0.0,  0.0, -1.0,  0.0,  0.0, -1.0,  0.0,  0.0, -1.0,  0.0, // Right face
       1.0,  0.0,  0.0,  1.0,  0.0,  0.0,  1.0,  0.0,  0.0,  1.0,  0.0,  0.0, // Left face
      -1.0,  0.0,  0.0, -1.0,  0.0,  0.0, -1.0,  0.0,  0.0, -1.0,  0.0,  0.0,];
    gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertexNormals), webgl.RenderingContext.STATIC_DRAW);

  }

  _initTexture() async {
    var textureLoaded = new Completer();

    _texture = gl.createTexture();
    ImageElement image = new Element.tag('img');
    image.onLoad.listen((e) {
      _handleLoadedTexture(_texture, image);
      textureLoaded.complete();
    });
    image.src = "/images/crate.gif";

    return textureLoaded.future;
  }

  _handleLoadedTexture(webgl.Texture texture, ImageElement img) {
    gl.pixelStorei(webgl.RenderingContext.UNPACK_FLIP_Y_WEBGL, 1); // second argument must be an int (no boolean)

    gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, texture);
    gl.texImage2D(webgl.RenderingContext.TEXTURE_2D, 0, webgl.RenderingContext.RGBA, webgl.RenderingContext.RGBA, webgl.RenderingContext.UNSIGNED_BYTE, img);
    gl.texParameteri(webgl.RenderingContext.TEXTURE_2D, webgl.RenderingContext.TEXTURE_MAG_FILTER, webgl.RenderingContext.LINEAR);
    gl.texParameteri(webgl.RenderingContext.TEXTURE_2D, webgl.RenderingContext.TEXTURE_MIN_FILTER, webgl.RenderingContext.LINEAR_MIPMAP_NEAREST);
    gl.generateMipmap(webgl.RenderingContext.TEXTURE_2D);

    gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, null);
  }

  _setMatrixUniforms() {
    gl.uniformMatrix4fv(_uPMatrix, false, _pMatrix.storage);
    gl.uniformMatrix4fv(_uMVMatrix, false, _mvMatrix.storage);

    //Matrix3 normalMatrix = _mvMatrix.toInverseMat3();
    Matrix3 normalMatrix = _mvMatrix.getRotation();
    normalMatrix.transpose();
    gl.uniformMatrix3fv(_uNMatrix, false, normalMatrix.storage);
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

    _mvMatrix.translate(new Vector3(0.0, 0.0, _zPos));

    _mvMatrix.rotate(new Vector3(1.0, 0.0, 0.0), _degToRad(_xRot));
    _mvMatrix.rotate(new Vector3(0.0, 1.0, 0.0), _degToRad(_yRot));
    //_mvMatrix.rotate(_degToRad(_zRot), new Vector3.fromList([0, 0, 1]));

    // verticies
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);

    // texture
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexTextureCoordBuffer);
    gl.vertexAttribPointer(_aTextureCoord, 2, webgl.RenderingContext.FLOAT, false, 0, 0);

    // light
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexNormalBuffer);
    gl.vertexAttribPointer(_aVertexNormal, 3, webgl.RenderingContext.FLOAT, false, 0, 0);


    gl.activeTexture(webgl.RenderingContext.TEXTURE0);
    gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, _texture);
//    gl.uniform1i(_uSamplerUniform, 0);

    // draw lighting?
    gl.uniform1i(_uUseLighting, _elmLighting.checked ? 1 : 0); // must be int, not bool

    if (_elmLighting.checked) {
      gl.uniform3f(_uAmbientColor, _elmAmbientR.valueAsNumber / 100, _elmAmbientG.valueAsNumber / 100, _elmAmbientB.valueAsNumber / 100);

      Vector3 lightingDirection = new Vector3(_elmLightDirectionX.valueAsNumber / 100, _elmLightDirectionY.valueAsNumber / 100, _elmLightDirectionZ.valueAsNumber / 100);
      Vector3 adjustedLD = lightingDirection.normalize();
      gl.uniform3fv(_uLightingDirection, adjustedLD.storage);
      gl.uniform3f(_uDirectionalColor, _elmDirectionalR.valueAsNumber / 100, _elmDirectionalG.valueAsNumber / 100, _elmDirectionalB.valueAsNumber / 100);
    }

    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    _setMatrixUniforms();
    gl.drawElements(webgl.RenderingContext.TRIANGLES, 36, webgl.RenderingContext.UNSIGNED_SHORT, 0);

    // rotate
    _animate(time);
    _handleKeys();
  }

  _handleKeyDown(KeyboardEvent event) {
    _currentlyPressedKeys[event.keyCode] = true;
  }

  _handleKeyUp(KeyboardEvent event) {
    _currentlyPressedKeys[event.keyCode] = false;
  }

  _animate(double time) {
    _xRot += (_xSpeed * time) / 1000.0;
    _yRot += (_ySpeed * time) / 1000.0;
  }

  _handleKeys() {
    if (_currentlyPressedKeys.elementAt(33) != null && _currentlyPressedKeys.elementAt(33)) {
      // Page Up
      _zPos -= 0.05;
    }
    if (_currentlyPressedKeys.elementAt(34) != null && _currentlyPressedKeys.elementAt(34)) {
      // Page Down
      _zPos += 0.05;
    }
    if (_currentlyPressedKeys.elementAt(37) != null && _currentlyPressedKeys.elementAt(37)) {
      // Left cursor key
      _ySpeed -= 1;
    }
    if (_currentlyPressedKeys.elementAt(39) != null && _currentlyPressedKeys.elementAt(39)) {
      // Right cursor key
      _ySpeed += 1;
    }
    if (_currentlyPressedKeys.elementAt(38) != null && _currentlyPressedKeys.elementAt(38)) {
      // Up cursor key
      _xSpeed -= 1;
    }
    if (_currentlyPressedKeys.elementAt(40) != null && _currentlyPressedKeys.elementAt(40)) {
      // Down cursor key
      _xSpeed += 1;
    }
  }

  double _degToRad(double degrees) {
    return degrees * math.PI / 180;
  }

  shutdown() {
    freeBuffers([_cubeVertexTextureCoordBuffer, _cubeVertexPositionBuffer, _cubeVertexIndexBuffer, _cubeVertexNormalBuffer]);
    freePrograms([_shaderProgram]);
    freeTextures([_texture]);
    freeVertexAttributes(3);
    super.shutdown();
  }

}

main() {
  Lesson07 lesson = new Lesson07(document.querySelector('#drawHere'));
  lesson.start();
}
