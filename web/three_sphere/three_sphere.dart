import 'dart:html';
import '../../packages/three/three.dart';
//import 'package:three/src/scenes/Scene.dart';
//import 'package:three/src/cameras/Camera.dart';
//import 'package:three/src/cameras/Camera.dart';


main() {
  var scene = new Scene();
  var camera = new PerspectiveCamera(35, window.innerWidth / window.innerHeight, 0.1, 1000);

  var renderer = new WebGLRenderer(antialias: true, alpha: true);
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMapEnabled = true;
  document.body.appendChild(renderer.domElement);

  var axes = new AxisHelper(60);
  axes.position.set(0, 0, 0);
  scene.add(axes);

  // Sphere
  var sphereMaterial = new THREE.MeshLambertMaterial({ color: 0x0000ff });
  var sphereGeometry =  new THREE.SphereGeometry(25, 16, 16);
  var sphereMesh = new THREE.Mesh(sphereGeometry, sphereMaterial);
  //var sphere = THREE.SceneUtils.createMultiMaterialObject(earthGeometry, multiMaterial);
  sphereMesh.position.set(0, 0, 0);
}