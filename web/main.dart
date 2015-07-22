import 'dart:html';
import 'dart:mirrors';
import 'package:dart_webgl_tutorials/lesson-01/lesson-01.dart';
import 'package:dart_webgl_tutorials/lesson-02/lesson-02.dart';
import 'package:dart_webgl_tutorials/lesson-03/lesson-03.dart';
import 'package:dart_webgl_tutorials/lesson-04/lesson-04.dart';
import 'package:dart_webgl_tutorials/lesson-05/lesson-05.dart';
import 'package:dart_webgl_tutorials/lesson-06/lesson-06.dart';
import 'package:dart_webgl_tutorials/lesson-07/lesson-07.dart';
import 'package:dart_webgl_tutorials/three_basic_sphere/three_basic_sphere.dart';



ClassMirror findClassMirror(String name) {
  for (var lib in currentMirrorSystem().libraries.values) {
    var mirror = lib.declarations[MirrorSystem.getSymbol(name)];
    if (mirror != null) return mirror;
  }
  throw new ArgumentError("Class $name does not exist");
}


main() {
  var menuElm = querySelector('#menu');
  var optionsElm = querySelector('#options');
  var menuWidth = menuElm.offsetWidth;
  var canvasElm = document.querySelector('#drawHere');
//  var context = canvasElm.getContext("experimental-webgl");
  var lesson = null;

  resize([_]) {
    var width = window.innerWidth - menuWidth;
    var height = window.innerHeight;
    canvasElm.setAttribute('width', width.toString() + 'px');
    canvasElm.setAttribute('height', height.toString() + 'px');
    canvasElm.style.width = width.toString() + 'px';
    canvasElm.style.height = height.toString() + 'px';

    lesson.resize(width, height);
    lesson.render();
  }

  loadExample(var className) async {
    window.location.hash = className;
    if (lesson != null) {
      await lesson.stop();
    }
    var clsMirror = findClassMirror(className);
    var instMirror = clsMirror.newInstance(MirrorSystem.getSymbol(''), [canvasElm]);
    lesson = instMirror.reflectee;

    optionsElm.innerHtml = lesson.options;
    if (lesson.options.length > 0) {
      optionsElm.style.display = 'block';
    } else {
      optionsElm.style.display = 'none';
    }

    await lesson.init();
    resize();
    lesson.start();
  }

  menuElm.querySelectorAll('li > a').onClick.listen((e) {
    e.preventDefault();
    loadExample((e.target as Element).getAttribute('href').substring(1));
  });

  var hash = window.location.hash;
  loadExample(hash.length > 1 ? hash.substring(1) : 'Lesson01');

  window.onResize.listen(resize);

}