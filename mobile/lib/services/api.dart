import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile/locator.dart';
import 'package:mobile/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';

class Api {
  static const host = 'http://pangolinai.net';
  static const cdn = 'http://cdn.pangolinai.net';

  static Dio dio = new Dio(); //the global net access dio
  static CancelToken onlyWifiDioToken = new CancelToken();

  Api() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.wifi) {
        onlyWifiDioToken.cancel();
      }
    });
  }

  Future<Locale> getLocale() async {
    var prefs = await SharedPreferences.getInstance();
    var language = prefs.getString('language_code');
    var script = prefs.getString('script_code');
    var country = prefs.getString('country_code');
    if (language == null || country == null) return null;
    return Locale.fromSubtags(
        languageCode: language, scriptCode: script, countryCode: country);
  }

  Future<void> saveLocale(Locale locale) async {
    if (locale != null) {
      var prefs = await SharedPreferences.getInstance();
      prefs.setString('language_code', locale.languageCode);
      prefs.setString('script_code', locale.scriptCode);
      prefs.setString('country_code', locale.countryCode);
    }
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
    var appVars = locator.get<AppVars>();
    // var response = await http.post(
    //     '$host/predict2?k=$topK&language=${appVars.locale}',
    //     headers: {'Content-Type': 'application/octet-stream'},
    //     body: feature);
    // var results = json.decode(response.body)['results'] as List;
    // return  results.map((item) => ArtPredict.fromJson(item)).toList();
    var response = await dio.post(
      '$host/predict2?k=$topK&language=${appVars.locale}',
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
    var response = await dio.get('$cdn/art/$artId');
    if (response.statusCode != 200) {
      throw "fetch art error. response status:${response.statusCode}";
    }

    if (response.data["error"] != null) {
      print('fetch art error: ${response.data["error"]}');
      return null;
    }
    var artInfo = ArtInfo.fromJson(response.data['results']);
    return artInfo;
  }
}
