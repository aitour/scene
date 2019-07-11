import 'dart:async';

//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';
import 'package:mobile/pages/art_list_view.dart';
import 'package:mobile/services/api.dart';
import 'package:mobile/services/db_helper.dart';
import 'package:mobile/services/mfa_service.dart';
import 'package:mobile/services/tfmodel_helper.dart';
import 'package:mobile/viewmodels/art_model.dart';
import 'package:mobile/viewmodels/mfa_model.dart';
import 'package:mobile/viewmodels/profile_model.dart';
import 'package:fluro/fluro.dart';
//import 'package:rxdart/rxdart.dart';

class IconFonts {
  static const IconData faceBook = IconData(0xe600, fontFamily: 'iconfont');
  static const IconData google = IconData(0xe8ff, fontFamily: 'iconfont');
  static const IconData wechart = IconData(0xe698, fontFamily: 'iconfont');
  static const IconData weibo = IconData(0xe60c, fontFamily: 'iconfont');
}

class CupertinoIconsExt {
  static const String fontFamily = 'CupertinoIcons';
  static const String fontPackage = 'cupertino_icons';

  //icons not defined in CupertinoIcons
  static const IconData global = IconData(0xf4d2,
      fontFamily: fontFamily, fontPackage: fontPackage);
  static const IconData gallery = IconData(0xf2e4,
      fontFamily: fontFamily, fontPackage: fontPackage);

  static const IconData threshold = IconData(0xf4a7,
      fontFamily: fontFamily, fontPackage: fontPackage);

  static const IconData topK = IconData(0xf394,
      fontFamily: fontFamily, fontPackage: fontPackage);

  static const IconData predictMode = IconData(0xf4a9,
      fontFamily: fontFamily, fontPackage: fontPackage);

  static const IconData comments = IconData(0xf3f9,
      fontFamily: fontFamily, fontPackage: fontPackage);
}

GetIt locator = GetIt();

void setupLocator() {
  locator.registerLazySingleton(() => AppVars());
  locator.registerLazySingleton(() => Api());
  locator.registerLazySingleton(() => MfaApi());
  locator.registerLazySingleton(() => TfModelHelper());
  locator.registerLazySingleton(() => ArtModel());
  locator.registerLazySingleton(() => MfaModel());
  locator.registerSingleton(DatabaseHelper.instance);
  locator.registerLazySingleton(() => UserProfileModel());
  locator.registerLazySingleton(() => Router());

  //locator.registerFactory<MfaModel>(() => MfaModel());
}

class AppVars {
  String appDocDir;
  //BehaviorSubject<Locale> _locale;
  List<CameraDescription> _cameras;

  //Stream<Locale> get locale => _locale.stream;

  AppVars() {
    //_locale = new BehaviorSubject<Locale>();
  }

  Future<List<CameraDescription>> get cameras async {
    if (_cameras == null) {
      _cameras = await availableCameras();
    }
    return _cameras;
  }

  // setLocale(Locale locale) {
  //   profile.locale = locale;
  //   locator<Api>().saveUserProfile(profile);
  //   _locale.sink.add(locale);
  // }
}

void defineRoutes() {
  var router = locator<Router>();

  router.define(ArtListView.routeName, handler: Handler(handlerFunc:
      (BuildContext context, Map<String, dynamic> params, Object arguments) {
    return ArtListView(predicts: arguments);
  }));
}
