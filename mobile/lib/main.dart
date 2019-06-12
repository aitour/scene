import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/art.dart';
import 'package:mobile/pages/art_list_view.dart';
import 'package:mobile/pages/mfa_open_view.dart';
import 'package:mobile/pages/predict_view.dart';
import 'package:mobile/pages/profile.dart';
import 'package:mobile/services/api.dart';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile/generated/i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  int _tabIndex = 0;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    var api = locator<Api>();
    api.getLocale().then((locator<AppVars>().setLocale));
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget buildHome(BuildContext context) {
    if (_tabController == null) {
      _tabController = TabController(vsync: this, length: 3);
      _tabController.addListener(() {
        //if (!_tabController.indexIsChanging) {
        setState(() {
          _tabIndex = _tabController.index;
        });
        //}
      });
    }

    return MultiProvider(
      providers: [
        StreamProvider.value(stream: Connectivity().onConnectivityChanged),
      ],
      child: Scaffold(
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            MfaOpenView(),
            PredictView(),
            ProfileView(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tabIndex, // this will be set when a new tab is tapped
          onTap: (index) {
            setState(() {
              _tabIndex = index;
            });
            _tabController.animateTo(index,
                duration: Duration(milliseconds: 50));
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text(S.of(context).tabHome),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.aspect_ratio),
              title: Text(S.of(context).tabTour),
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), title: Text(S.of(context).tabProfile))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: locator<AppVars>().locale,
      builder: (context, AsyncSnapshot<Locale> snapshot) {
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
          locale: snapshot?.data,
          debugShowCheckedModeBanner: false,
          routes: {'/': (context) => buildHome(context)},
          onGenerateRoute: (settings) {
            if (settings.name == ArtListView.routeName) {
              final List<ArtPredict> predicts = settings.arguments;
              return MaterialPageRoute(
                builder: (context) {
                  return ArtListView(
                    predicts: predicts,
                  );
                },
              );
            }
          },
        );
      },
    );
  }
}
