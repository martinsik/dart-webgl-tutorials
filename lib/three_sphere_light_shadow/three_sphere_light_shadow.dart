library three_sphere_light_shadow;

import 'dart:math';
import 'package:three/three.dart';
import 'package:dart_webgl_tutorials/example.dart';

/**
 * This is a followup to three_basic_sphere.
 *
 * Examples in this series:
 * 1. three_basic_sphere
 * 2. three_sphere_light_shadow
 * 3. three_sphere_2d_coords_to_3d
 */

class ThreeSphereLightShadow extends AbstractThreeExample {

  double dist = 75.0;
  double radY = -0.5;
  double radZ = 0.0;
  Mesh smallSphere;
  Mesh largeSphere;
  SpotLight light;

  ThreeSphereLightShadow(var elm): super(elm);

  init() {
    super.init();

    renderer.shadowMapEnabled = true;
//    renderer.shadowMapType = PCFSoftShadowMap;
    camera.position.z = 500.0;

    var axes = new AxisHelper();
    axes.position.setValues(0.0, 0.0, 0.0);
    axes.scale.scale(0.5);
    scene.add(axes);

    // light
    light = new SpotLight(0xffffff);
    light.position.setValues(100.0, 50.0, 300.0);
    light.castShadow = true;
    light.shadowCameraVisible = true;
    scene.add(light);

    // Large sphere
    largeSphere = new Mesh(new SphereGeometry(25.0, 16, 16), new MeshLambertMaterial(color: 0xffffff, side: DoubleSide));
    largeSphere.position.setValues(0.0, 0.0, 0.0);
    largeSphere.receiveShadow = true;
    largeSphere.castShadow = true;
    scene.add(largeSphere);

    // Small sphere
    smallSphere = new Mesh(new SphereGeometry(10.0, 8, 8), new MeshLambertMaterial(color: 0xffffff, side: DoubleSide));
    smallSphere.position.setValues(dist, 0.0, 0.0);
    smallSphere.receiveShadow = true;
    smallSphere.castShadow = true;
    scene.add(smallSphere);
  }

  render([double time = 0]) {
    radY += PI * (time / 1000.0) * 0.5;
    radZ += PI * (time / 1000.0) * 0.015;

    var x = dist * cos(radZ) * sin(radY);
    var y = dist * sin(radZ) * sin(radY);
    var z = dist * cos(radY);

    smallSphere.position.setValues(x + largeSphere.position.x, y + largeSphere.position.y, z);

    super.render(time);
  }

}