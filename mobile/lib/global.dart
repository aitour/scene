//library aitour.globals;
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:mobile/models/models.dart';

class Global {
  String appDocDir;
  ConnectivityResult connectivityResult = ConnectivityResult.none;
  MethodChannel tflite;
  TfModelInfo currentModel;
  bool isLoggedIn = false;

  Locale myLocale;
  List<CameraDescription> cameras;
  final dio = new Dio();
  final onlyWifiDioToken = new CancelToken();

//const host = 'http://192.168.0.220:8081';
  final host = 'http://pangolinai.net';
  final cdn = 'http://cdn.pangolinai.net';
}

var global = Global();
