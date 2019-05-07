import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';

import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import './widgets/predict2.dart';
import 'package:mobile/repositories/repositories.dart';
import 'package:mobile/generated/i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './home.dart';
import './profile.dart';
import './global.dart';

import 'package:mobile/blocs/blocs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AitourApp extends StatefulWidget {
  AitourApp({Key key}) : super(key: key);

  @override
  _AitourAppState createState() => _AitourAppState();
}

class _AitourAppState extends State<AitourApp> {
  static final TfModelBloc _tfModelBloc = TfModelBloc(repo: TfModelRepository(host: global.cdn));
  Locale _locale;

  int _selectedIndex = 1;
  final _widgetOptions = [
    HomePage(),
    //ArtPredictPage(),
    BlocProvider<TfModelBloc>(
        bloc: _tfModelBloc,
        child: Predict2Page()),
    ProfilePage(),
  ];

  Future<Locale> _fetchLocale() async {
    var prefs = await SharedPreferences.getInstance();
    var language = prefs.getString('language_code');
    var country = prefs.getString('country_code');
    if (language == null || country == null) return null;
    return Locale(language, country);
  }

  @override
  void initState() {
    super.initState();
    _fetchLocale().then((Locale locale) {
      setState(() {
        _locale = locale;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      localeResolutionCallback:
          S.delegate.resolution(fallback: new Locale("en", "")),
      locale: _locale,
      home: Builder(builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).applicationName),
          ),
          body: Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), title: Text(S.of(context).tabHome)),
              BottomNavigationBarItem(
                  icon: Icon(Icons.business),
                  title: Text(S.of(context).tabTour)),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  title: Text(S.of(context).tabProfile)),
            ],
            currentIndex: _selectedIndex,
            fixedColor: Colors.deepPurple,
            onTap: _onItemTapped,
          ),
        );
      }),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

void main() async {
  Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    global.connectivityResult = result;
    if (result != ConnectivityResult.wifi) {
      global.onlyWifiDioToken.cancel();
    }
  });

  global.cameras = await availableCameras();
  global.appDocDir = (await getApplicationDocumentsDirectory()).path;
  await Directory('${global.appDocDir}/models').create(recursive: true);

  //debugPaintSizeEnabled = true;
  runApp(AitourApp());
}
