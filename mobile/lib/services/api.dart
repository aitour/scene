import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile/locator.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/models/poem.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/viewmodels/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';

class Api {
  static const host = 'http://pangolinai.net';
  static const cdn = 'http://cdn.pangolinai.net';
  static const poemsUrl = 'https://www.poemist.com/api/v1/randompoems';

  static Dio dio = new Dio(); //the global net access dio
  static CancelToken onlyWifiDioToken = new CancelToken();

  Api() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.wifi) {
        onlyWifiDioToken.cancel();
      }
    });
    dio.options.contentType = ContentType.parse("application/x-www-form-urlencoded");
  }

  Future<UserProfile> associateFacebookToken(String fbToken) async {
    var response = await dio.post("$host/associate/facebook", data: {"access_token": fbToken}); 
    var profile = UserProfile();
    profile.accessToken = response.data['access_token'];
    profile.userId = int.tryParse(response.data['uid'] ?? '-1');
    profile.name = response.data['name'];
    profile.email = response.data['email'];
    profile.avatar = response.data['avatar'] ?? 'https://api.adorable.io/avatars/50/abott@adorable.png';
    profile.favorites = response.data['favorites'] ?? 0;
    profile.comments = response.data['comments'] ?? 0;
    profile.facebookAccessToken = fbToken;
    return profile;
  }

  Future<UserProfile> getUserProfile() async {
    var profile = UserProfile();
    var prefs = await SharedPreferences.getInstance();
    var language = prefs.getString('language_code');
    var script = prefs.getString('script_code');
    var country = prefs.getString('country_code');
    if (language != null || country != null) {
      if (country == "") country = "US";
      profile.locale = Locale.fromSubtags(
          languageCode: language, scriptCode: script, countryCode: country);
    }
    profile.topK = prefs.getInt('topK');
    profile.predictThreshold = prefs.getDouble("threshold");
    profile.predictMode = PredictMode.values[prefs.getInt('predict_mode') ?? 0];
    return profile;
  }

  Future<bool> saveUserProfile(UserProfile profile) async {
    var prefs = await SharedPreferences.getInstance();
    if (profile.locale != null) {
      prefs.setString('language_code', profile.locale.languageCode);
      prefs.setString('script_code', profile.locale.scriptCode);
      prefs.setString('country_code', profile.locale.countryCode);
    }

    prefs.setInt('uid', profile.userId);
    prefs.setString('access_token', profile.accessToken);
    prefs.setString('email', profile.email);
    prefs.setInt('topK', profile.topK);
    prefs.setString('name', profile.name);
    prefs.setString('avatar', profile.avatar);

    prefs.setDouble('threshold', profile.predictThreshold);
    prefs.setInt('predict_mode', profile.predictMode.index);
    return true;
  }

  Future<bool> signOut() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.remove('uid');
    prefs.remove('access_token');
    prefs.remove('email');
    prefs.remove('avatar');
    prefs.remove('name');
    return true;
  }

  Future<bool> signIn(UserProfile profile) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('access_token', profile.accessToken);
    prefs.setString('email', profile.email);
    prefs.setInt('topK', profile.topK);
    prefs.setString('name', profile.name);
    prefs.setString('avatar', profile.avatar);
    return profile.accessToken != "";
  }

  Future<String> getModelList() async {
    var response = await dio.get("$host/model/list",
        options: Options(responseType: ResponseType.plain));
    if (response.statusCode != 200) {
      throw ("download model list error. response status:${response.statusCode}");
    }
    return response.data;
  }

  Future<List<ArtPredict>> predict(List<int> feature, int topK) async {
    var profileModel = locator.get<UserProfileModel>();
    // var response = await http.post(
    //     '$host/predict2?k=$topK&language=${appVars.locale}',
    //     headers: {'Content-Type': 'application/octet-stream'},
    //     body: feature);
    // var results = json.decode(response.body)['results'] as List;
    // return  results.map((item) => ArtPredict.fromJson(item)).toList();
    var response = await dio.post(
      '$host/predict2?k=$topK&language=${profileModel.profile.locale}',
      data: Stream.fromIterable(feature.map((e) => [e])),
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'application/octet-stream',
          HttpHeaders.contentLengthHeader: feature.length, // set content-length
        },
      ),
    );

    if (response.statusCode != 200) {
      throw "predict error. response status: ${response.statusCode}";
    }

    var err = response.data['err'] as String;
    if (err != null && err.isNotEmpty) {
      throw err;
    }

    var results = response.data["results"] as List;
    //print("${response.body}");
    //var results = json.decode(response.body)['results'] as List;
    return results.map((item) => ArtPredict.fromJson(item)).toList();
  }

  Future<void> uploadPhoto(String filePath) async {
    FormData formData = new FormData.from({
      "auth": "135246",
      "files": [
        new UploadFileInfo(new File(filePath), "upload.jpg"),
      ]
    });
    await dio.post("$host/uploadscale", data: formData);
  }

  Future<ArtInfo> fetchArt(int artId) async {
    var language = locator<UserProfileModel>().profile?.locale?.toString() ?? "en";
    var response = await dio.get('$cdn/art/$artId?language=$language');
    if (response.statusCode != 200) {
      throw "fetch art error. response status:${response.statusCode}";
    }

    if (response.data["error"] != null) {
      print('fetch art(id=$artId) error: ${response.data["error"]}');
      return null;
    }
    var artInfo = ArtInfo.fromJson(response.data['results']);
    return artInfo;
  }


  Future<List<Poem>> fetchRandomPoems() async {
    var response = await dio.get('$poemsUrl');
    if (response.statusCode != 200) {
      throw "fetch poems error. response status:${response.statusCode}";
    }
    var poems = (response.data as List)?.map((m) => Poem.fromJson(m))?.toList();
    return poems;
  }
}
