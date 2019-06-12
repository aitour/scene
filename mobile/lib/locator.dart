import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';
import 'package:mobile/services/api.dart';
import 'package:mobile/services/mfa_service.dart';
import 'package:mobile/services/tfmodel_helper.dart';
import 'package:mobile/viewmodels/art_model.dart';
import 'package:mobile/viewmodels/mfa_model.dart';
import 'package:rxdart/rxdart.dart';

GetIt locator = GetIt();

void setupLocator() {
  locator.registerLazySingleton(() => AppVars());
  locator.registerLazySingleton(() => Api());
  locator.registerLazySingleton(() => MfaApi());
  locator.registerLazySingleton(() => TfModelHelper());
  locator.registerFactory(() => ArtModel());
  locator.registerLazySingleton(() => MfaModel());
}

class AppVars {
  String appDocDir;
  BehaviorSubject<Locale> _locale;
  List<CameraDescription> _cameras;

  Stream<Locale> get locale => _locale.stream;

  AppVars() {
    _locale = new BehaviorSubject<Locale>();
    locator<Api>().getLocale().then((l) {
      setLocale(l);
    });
  }

  Future<List<CameraDescription>> get cameras async {
    if (_cameras == null) {
      _cameras = await availableCameras();
    }
    return _cameras;
  }

  setLocale(Locale locale) {
    locator<Api>().saveLocale(locale);
    _locale.sink.add(locale);
  }
}
