import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
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
          body: SingleChildScrollView(
            child: Column(
              children: [
                FlutterImageTextureWidget(
                    url:
                        "https://img.alicdn.com/imgextra/i4/217101303/O1CN01rV12Qg1LUok76BR8F_!!217101303.jpg"),
                FlutterImageTextureWidget(
                    url:
                        "https://img.alicdn.com/imgextra/i4/217101303/O1CN01rV12Qg1LUok76BR8F_!!217101303.jpg")
              ],
            ),
          )),
    );
  }
}
