library three_basic_sphere;

import 'dart:html';
import 'package:three/three.dart';
import 'package:dart_webgl_tutorials/example.dart';


class ThreeBasicSphere extends AbstractThreeExample {

  ThreeBasicSphere(var elm): super(elm);

  init() {
    super.init();

    camera.position.z = 500.0;

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

}