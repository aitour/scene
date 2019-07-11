import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/viewmodels/base_model.dart';
import 'package:mobile/services/api.dart';
import 'package:mobile/locator.dart';

class UserProfileModel extends BaseModel{
  Api api = locator.get<Api>();
  UserProfile profile;

  Future<UserProfile> fetchUserProfile() async {
    if (profile != null) return profile;
    setState(ViewState.Busy);
    profile = await api.getUserProfile();
    setState(ViewState.Idle);
    return profile;
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    setState(ViewState.Busy);
    var ok = await api.saveUserProfile(profile);
    setState(ViewState.Idle);
    return ok;
  }

  Future<bool> setLocale(Locale locale) async {
    profile.locale = locale;
    var ok = await api.saveUserProfile(profile);
    notifyListeners();
    return ok;
  }

  Future<bool> setTopK(int topK) async {
    profile.topK = topK;
    var ok = await api.saveUserProfile(profile);
    return ok;
  }


  Future<bool> setPredictThreshold(double threshold) async {
    profile.predictThreshold = threshold;
    var ok = await api.saveUserProfile(profile);
    return ok;
  }

    Future<bool> setPredictMode(PredictMode mode) async {
    profile.predictMode = mode;
    var ok = await api.saveUserProfile(profile);
    return ok;
  }
}