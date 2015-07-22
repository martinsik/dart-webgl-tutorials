import 'dart:web_gl' as webgl;
import 'dart:async';
import 'dart:html';
import 'package:three/three.dart';
//import 'package:three/src/cameras/Camera.dart';
//import 'package:three/src/core/ThreeMath.dart';


abstract class AbstractExample {
  String options = "";
  int _animFrameId;

  init();
  resize(int width, int height);
  render([double time = 0]);
  shutdown();


  start() {
    _renderFrame();
  }

  _renderFrame() {
    if (_stop) {
      window.cancelAnimationFrame(_animFrameId);
      shutdown();
    } else {
      _animFrameId = window.requestAnimationFrame((var time) {
        render(time);
        _renderFrame();
      });
    }
  }

}

abstract class AbstractWebGLExample extends AbstractExample {
  webgl.RenderingContext gl;
  bool _stop = false;
  Completer _shutdownCompleter;


  shutdown() {
    gl.bindBuffer(webgl.ARRAY_BUFFER, null);
    gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, null);
    gl.bindRenderbuffer(webgl.RENDERBUFFER, null);
    gl.bindFramebuffer(webgl.FRAMEBUFFER, null);
    _shutdownCompleter.complete();
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

  Future stop() {
    _stop = true;
    _shutdownCompleter = new Completer();
    return _shutdownCompleter.future;
  }

}

abstract class AbstractThreeExample {
  Scene scene;
  Camera camera;
  WebGLRenderer renderer;

  resize(double width, double height) {
    camera.aspect = width / height;
    camera.updateProjectionMatrix();

    renderer.setSize(width, height);
  }

  shutdown() {

  }

}
