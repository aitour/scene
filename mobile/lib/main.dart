import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/pages/mfa_open_view.dart';
import 'package:mobile/pages/predict_view.dart';
import 'package:mobile/pages/profile.dart';
import 'package:mobile/pages/home.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/viewmodels/profile_model.dart';

import 'package:path_provider/path_provider.dart';
import 'package:mobile/generated/i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluro/fluro.dart';
import './locator.dart';

void main() async {
  //debugPaintSizeEnabled = true;

  setupLocator();

  var appVars = locator<AppVars>();
  appVars.appDocDir = (await getApplicationDocumentsDirectory()).path;
  await Directory('${appVars.appDocDir}/models').create(recursive: true);

  runApp(AitourApp());
}

class AitourApp extends StatefulWidget {
  AitourApp({Key key}) : super(key: key);

  @override
  _AitourAppState createState() => _AitourAppState();
}

class _AitourAppState extends State<AitourApp>
    with SingleTickerProviderStateMixin {
  List<Widget> pages = <Widget>[
    HomePage(),
    PredictView(),
    MfaOpenView(),
    ProfileView(),
  ];

  int _pageIndex = 1;

  @override
  void initState() {
    super.initState();
    defineRoutes();
    locator<UserProfileModel>().addListener(() {
      setState(() {});
    });
    Connectivity().onConnectivityChanged.listen((status) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildHome(BuildContext context) {
    return Scaffold(
      //body: _currentPage,
      body: IndexedStack(
        index: _pageIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _pageIndex, // this will be set when a new tab is tapped
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            title: Text(S.of(context).tabHome),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.photo_camera),
            title: Text(S.of(context).tabTour),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            title: Text(S.of(context).tabOpen),
          ),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.gear),
              title: Text(S.of(context).settings))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: locator<UserProfileModel>().fetchUserProfile(),
      builder: (context, AsyncSnapshot<UserProfile> snapshot) {
        if (!snapshot.hasData) return Container();
        //print('main - locale: ${snapshot.data.locale}');

        return MaterialApp(
          title: "AiTour", //S.of(context).applicationName,
          theme: new ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.redAccent[300],
            accentColor: Colors.red[300],
          ),
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate
          ],
          supportedLocales: S.delegate.supportedLocales,
          localeResolutionCallback:
              S.delegate.resolution(fallback: new Locale("en", "")),
          locale: snapshot?.data?.locale,
          debugShowCheckedModeBanner: false,
          routes: {'/': (context) => buildHome(context)},
          onGenerateRoute: locator<Router>().generator,
        );
      },
    );
  }
}
