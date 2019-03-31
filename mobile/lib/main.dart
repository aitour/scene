import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
import 'package:connectivity/connectivity.dart';

import 'package:path_provider/path_provider.dart';

import './home.dart';
import './predict.dart';
import './profile.dart';
import './global.dart' as globals;

void main() {
  //debugPaintSizeEnabled = true;
  asyncInit();
  runApp(AitourApp());
}

void asyncInit() async {
  globals.gAppDocDir = (await getApplicationDocumentsDirectory()).path;
  await Directory('${globals.gAppDocDir}/models').create(recursive: true);

  // var connectivityResult = await (new Connectivity().checkConnectivity());
  // if (connectivityResult == ConnectivityResult.wifi) {
  //   await globals.modelManager.getTfLiteModel();
  // }
}

class AitourApp extends StatefulWidget {
  AitourApp({Key key}) : super(key: key);

  @override
  _AitourAppState createState() => _AitourAppState();
}

class _AitourAppState extends State<AitourApp> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  int _selectedIndex = 1;
  final _widgetOptions = [
    HomePage(),
    ArtPredictPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) async {
      globals.gConnectivityResult = result;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Aitour'),
        ),
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.home), title: Text('Home')),
            BottomNavigationBarItem(
                icon: Icon(Icons.business), title: Text('Tour')),
            BottomNavigationBarItem(
                icon: Icon(Icons.school), title: Text('Profile')),
          ],
          currentIndex: _selectedIndex,
          fixedColor: Colors.deepPurple,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
