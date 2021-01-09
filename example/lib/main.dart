import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutterimagetexture/flutterimagetexture.dart';
import 'package:flutterimagetexture/flutter_image_texture_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app6'),
        ),
        body: Center(
          child: FlutterImageTextureWidget(
            url:
                "https://lxq.nmgdj.gov.cn/oss/unsafe/300x300/default/2020102111492926196nepSfY2NU7vVU.jpg",
            width: 300,
            height: 300,
          ),
        ),
      ),
    );
  }
}
