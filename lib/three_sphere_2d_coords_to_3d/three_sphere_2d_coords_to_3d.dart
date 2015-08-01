library three_sphere_2d_coords_to_3d;

import 'dart:html';
import 'dart:async';
import 'package:three/three.dart';
import 'package:vector_math/vector_math.dart';
import 'package:dart_webgl_tutorials/example.dart';
import 'package:dart_webgl_tutorials/three_sphere_light_shadow/three_sphere_light_shadow.dart';

/**
 * This is a followup to three_sphere_light_shadow.
 *
 * Examples in this series:
 * 1. three_basic_sphere
 * 2. three_sphere_light_shadow
 * 3. three_sphere_2d_coords_to_3d
 */

class ThreeSphere2dCoordsTo3d extends ThreeSphereLightShadow {

  Mesh tmpMesh;

  ThreeSphere2dCoordsTo3d(var elm): super(elm);
  StreamSubscription _mouseSub;
  Projector projector;

  init() {
    super.init();

    tmpMesh = new Mesh(new PlaneGeometry(1000.0, 1000.0));
    tmpMesh.position.setZero();
    scene.add(tmpMesh);

    projector = new Projector();
    light.target = largeSphere;

    _mouseSub = window.onMouseMove.listen((MouseEvent e) {
      var x = ((e.client.x - offsetWidth) / width) * 2 - 1;
      var y = - ((e.client.y - offsetHeight) / height) * 2 + 1;

      var vector = projector.unprojectVector(new Vector3(x, y, 0.0), camera);
      vector.sub(camera.position).normalize();

      Ray ray = new Ray(camera.position, vector);
      List<Intersect> intersects = ray.intersectObject(tmpMesh);

//      print(intersects.length);
      largeSphere.position = intersects[0].point;
    });

  }

  shutdown() {
    _mouseSub.cancel();
    super.shutdown();
  }

}