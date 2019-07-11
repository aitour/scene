import 'package:flutter/material.dart';

enum PredictMode {
  TakePhoto,
  Live,
  PickImage,
}

class UserProfile {
  int topK;
  double predictThreshold;
  PredictMode predictMode;
  String accessToken;
  String facebookAccessToken;

  Locale locale;
  int userId;
  String name;
  String firstName;
  String lastName;
  String avatar;
  String email;
  int favorites;
  int comments;

  void clear() {
    accessToken = '';
    facebookAccessToken = '';
    userId = -1;
    name = '';
    avatar = '';
    email = '';
    favorites = 0;
    comments = 0;
  }
}