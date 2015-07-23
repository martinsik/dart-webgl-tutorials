import 'dart:web_gl' as webgl;
import 'dart:async';
import 'dart:html';
import 'package:three/three.dart';
//import 'package:three/src/cameras/Camera.dart';
//import 'package:three/src/core/ThreeMath.dart';


abstract class AbstractExample {
  String options = "";
  bool _stop = false;
  int _animFrameId;
  double _elapsedTime;
  Completer shutdownCompleter;
  int _width, _height;
  int _offsetWidth, _offsetHeight;

  int get width => _width;
  int get height => _height;
  int get offsetWidth => _offsetWidth;
  int get offsetHeight => _offsetHeight;

  init();
  render([double time = 0]);
  shutdown();


  start() {
    _renderFrame();
  }

  resize(int width, int height) {
    _width = width;
    _height = height;
    _offsetWidth = window.innerWidth - width;
    _offsetHeight = window.innerHeight - height;
  }

  _renderFrame() {
    if (_stop) {
      window.cancelAnimationFrame(_animFrameId);
      shutdown();
    } else {
      _animFrameId = window.requestAnimationFrame((double time) {
        if (_elapsedTime == null) {
          _elapsedTime = time;
        }
        render(time - _elapsedTime);
        _elapsedTime = time;
        _renderFrame();
      });
    }
  }

  Future stop() {
    _stop = true;
    shutdownCompleter = new Completer();
    return shutdownCompleter.future;
  }

}

abstract class AbstractWebGLExample extends AbstractExample {
  webgl.RenderingContext gl;
  Completer shutdownCompleter;

  shutdown() {
    gl.bindBuffer(webgl.ARRAY_BUFFER, null);
    gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, null);
    gl.bindRenderbuffer(webgl.RENDERBUFFER, null);
    gl.bindFramebuffer(webgl.FRAMEBUFFER, null);
    shutdownCompleter.complete();
  }

  freeBuffers(List<webgl.Buffer> buffers) {
    buffers.forEach((var buf) => gl.deleteBuffer(buf));
  }

  freePrograms(List<webgl.Program> programs) {
    programs.forEach((var prog) => gl.deleteProgram(prog));
  }

  freeTextures(List<webgl.Texture> textures) {
    for (int i=0; i < textures.length; i++) {
      var tex = textures[i];
      gl.activeTexture(webgl.TEXTURE0 + i);
      gl.bindTexture(webgl.TEXTURE_2D, null);
      gl.bindTexture(webgl.TEXTURE_CUBE_MAP, null);
      gl.deleteTexture(tex);
    }
  }

  freeVertexAttributes(int attribs) {
    for (int i = 0; i < attribs; i++) {
      gl.disableVertexAttribArray(i);
    }
  }

  freeShaders(List<webgl.Shader> shaders) {
    shaders.forEach((var shader) => gl.deleteShader(shader));
  }

  init() async {
    var dummyCompleter = new Completer();
    dummyCompleter.complete();
    return dummyCompleter.future;
  }

}

abstract class AbstractThreeExample extends AbstractExample {
  Scene scene;
  Camera camera;
  WebGLRenderer renderer;
  CanvasElement _elm;

  AbstractThreeExample(this._elm);


  resize(int width, int height) {
    super.resize(width, height);

    camera.aspect = width.toDouble() / height.toDouble();
    camera.updateProjectionMatrix();

    renderer.setSize(width, height);
  }

  shutdown() {
    shutdownCompleter.complete();
  }

  init() {
    scene = new Scene();
    renderer = new WebGLRenderer(canvas:_elm);
    camera = new PerspectiveCamera(45.0, window.innerWidth / window.innerHeight, 0.1, 1000);
    scene.add(camera);
  }

  render([double time = 0]) {
    renderer.setClearColor(new Color(0xffffff), 1);
    renderer.render(scene, camera);
  }

}
