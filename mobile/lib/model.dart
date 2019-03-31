import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';
import 'global.dart';

class TfLiteModelManager {
  List<ModelInfo> _models = new List<ModelInfo>();
  bool _isSyncing = false;
  List<Function> _downloadWatchers = new List<Function>();

  void addDownloadWatcher(Function f) {
    if (_downloadWatchers.indexOf(f) < 0) {
      _downloadWatchers.add(f);
    }
  }

  void removeDownloadWatcher(Function f) {
    _downloadWatchers.remove(f);
  }

  Future<ModelInfo> getTfLiteModel() async {
    if (gConnectivityResult ==ConnectivityResult.none) {
      gConnectivityResult = await (new Connectivity().checkConnectivity());
    }
    if (gConnectivityResult == ConnectivityResult.wifi) {
      if (!_isSyncing) {
        _isSyncing = true;
        await _startSync();
        _isSyncing = false;
        return _models.length > 0 ? _models[0] : null;
      }
    } 
    return null;
  }

  Future<int> mergeFile(String mergeTo, String mergeFrom, bool deleteFromAfterMerge) async {
    var f = File(mergeFrom);
    var t = File(mergeTo);
    int mergeLen = 0;
    if  (f.existsSync()) {
      mergeLen = await f.length();
      IOSink ioSink = t.openWrite(mode: FileMode.writeOnlyAppend);
      await ioSink.addStream(f.openRead());
      await ioSink.flush();
      await ioSink.close();
      if (deleteFromAfterMerge) {
        await f.delete();
      }
    }
    return mergeLen;
  }

  Future<void> _startSync() async {
    var appDoc = (await getApplicationDocumentsDirectory()).path;

    var response = await dio.get("$host/model/list");
    if (response.statusCode != 200) {
      print("error download model list");
      return;
    }
    if (!(response.data  is Map)) {
      print("error model list format");
      return;
    }

    var listFileBody = json.encode(response.data);
    var list = (response.data as Map)['models'] as List;
    if (list != null) {
      _models = list.map((m) => ModelInfo.fromJson(m)).toList();
    }

    List<ModelInfo> cached;
    var f = File('$appDoc/models/mlist.json');
    if (await f.exists()) {
      var list = json.decode(await f.readAsString())['models'] as List;
      if (list != null) {
        cached = list.map((m) => ModelInfo.fromJson(m)).toList();
        //删除不同步的文件
        for (var mi in cached) {
          var i = _models
              .indexWhere((v) => v.name == mi.name || v.md5Hash != mi.md5Hash);
          if (i < 0) {
            await File('$appDoc/models/${mi.name}').delete();
          }
        }
      }
    }

    //如果有必要， 下载模型
    var downloadError = false;
    for (var mi in _models) {
      var savePath = '$appDoc/models/${mi.name}';
      var savePathTmp = '${savePath}.tmp';
      var startRange = 0;

      await mergeFile(savePath, savePathTmp, true);

      var f = File(savePath);
      if (f.existsSync()) {
        var digest = md5.convert(f.readAsBytesSync());
        if ('$digest' == mi.md5Hash) {
          continue;
        }
        startRange = await f.length();
      }

      //download the file
      if (startRange != mi.size) {
        var url = mi.downloadPath.startsWith("/")
            ? '$host${mi.downloadPath}'
            : '$host/${mi.downloadPath}';

        try {
          await dio.download(
            url, savePathTmp,
            // Listen the download progress.
            onReceiveProgress: (received, total) {
              _downloadWatchers.forEach((f) {
                f(savePath, startRange + received, mi.size);
              });
              print(((startRange + received) / mi.size * 100).toStringAsFixed(0) +
                  "%");
            },
            options: Options(
              headers: {"range": "bytes=$startRange-"}, //指定请求的内容区间
            ),
          );
        } catch (e) {
          print(e);
          File(savePath).deleteSync();
          continue;
        }
      }

      await mergeFile(savePath, savePathTmp, true);
      f = await mi.localFile;
      if (!f.existsSync()) {
        downloadError = true;
        break;
      }
    }

    if (!downloadError) {
      var fw = File('$appDoc/models/mlist.json').openSync(mode: FileMode.write);
      fw.writeStringSync(listFileBody);
      fw.closeSync();
    }
  }
}

class ModelInfo {
  final String name;
  final String md5Hash;
  final int size;
  final String downloadPath;

  ModelInfo({this.name, this.md5Hash, this.size, this.downloadPath});

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      name: json['Name'],
      md5Hash: json["Md5Hash"],
      size: json["FileSizeInBytes"],
      downloadPath: json["DownloadPath"],
    );
  }

  Future<File> get localFile async {
    var appDoc = (await getApplicationDocumentsDirectory()).path;
    var savePath = '$appDoc/models/$name';
    return File(savePath);
  }
}

class ArtPredict {
  final int id;
  final double score;

  ArtPredict({this.id, this.score});

  factory ArtPredict.fromJson(Map<String, dynamic> json) {
    return ArtPredict(id: json['ArtID'], score: json['Score']);
  }
}

class ArtInfo {
  final int id;
  final int museumId;
  final int artistId;
  final int displayNumber;
  final String creationYear;
  final int price;
  final String title;
  final String category;
  final String location;
  final List<String> images;
  final List<String> audios;
  final String text;
  final String material;
  final String museumName;
  final String museumCity;
  final String museumCountry;

  double _score;

  set score(double v) {
    _score = v;
  }

  double get score => _score;

  ArtInfo(
      {this.id,
      this.museumId,
      this.artistId,
      this.displayNumber,
      this.creationYear,
      this.price,
      this.title,
      this.category,
      this.location,
      this.images,
      this.audios,
      this.text,
      this.material,
      this.museumName,
      this.museumCity,
      this.museumCountry});

  factory ArtInfo.fromJson(Map<String, dynamic> json) {
    return ArtInfo(
      id: json["ArtID"],
      museumId: json["MuseumID"],
      artistId: json["ArtistID"],
      displayNumber: json["DisplayNumber"],
      creationYear: json["CreationYear"],
      price: json["Price"],
      title: json["Title"],
      category: json["Category"],
      location: json["Location"],
      images: json["Images"] == null ? null : json["Images"].cast<String>(),
      audios: json["Audios"] == null ? null : json["Audios"].cast<String>(),
      text: json["Text"],
      material: json["Material"],
      museumName: json["MuseumName"],
      museumCity: json["MuseumCity"],
      museumCountry: json["MuseumCountry"],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };
}
