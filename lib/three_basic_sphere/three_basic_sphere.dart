import 'dart:html';
import 'package:three/three.dart';
import 'package:dart_webgl_tutorials/example.dart';


class ThreeBasicSphere extends AbstractThreeExample {

  CanvasElement _elm;
  ThreeBasicSphere(this._elm);

  init() {
    scene = new Scene();

    renderer = new WebGLRenderer(canvas:_elm);

    camera = new PerspectiveCamera(45.0, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.z = 500.0;

    scene.add(camera);

    var axes = new AxisHelper();
    axes.position.setValues(0.0, 0.0, 0.0);
    axes.scale.scale(0.5);
    scene.add(axes);

    // Sphere
    var material = new MeshBasicMaterial(color: 0x0000FF, side: DoubleSide);
    var geometry = new SphereGeometry(25.0, 16, 16);

    var sphere = new Mesh(geometry, material);
    sphere.position.setValues(0.0, 0.0, 0.0);

    scene.add(sphere);
  }

  render([double time = 0]) {
    renderer.setClearColor(new Color(0xffffff), 1);
    renderer.render(scene, camera);
  }

  shutdown() {
    super.shutdown();
  }

}