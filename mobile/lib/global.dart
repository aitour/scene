library aitour.globals;


import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'model.dart';


String gAppDocDir;
ConnectivityResult gConnectivityResult = ConnectivityResult.none;
bool gIsLoggedIn = false;

var dio = new Dio();
var modelManager = new TfLiteModelManager();

Locale gMyLocale = null;
//const host = 'http://192.168.0.220:8081';
const host = 'http://pangolinai.net';
const cdn = 'http://cdn.pangolinai.net';
//const host = 'http://192.168.1.8:8081';


