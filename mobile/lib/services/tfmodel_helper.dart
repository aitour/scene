import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:mobile/locator.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/models/fileinfo.dart';

import 'api.dart';

class FileDownloadProgress {
  FileInfo file;
  int received;
  int total;
  FileDownloadProgress({this.file, this.received, this.total});
}

class TfModelHelper {
  static String syncList;
  static MethodChannel tflite;
  Completer<String> modelLoadComplete = new Completer();
  var appVars = locator.get<AppVars>();
  var api = locator.get<Api>();
  var _updateChecked = false; //update check只在第一次调用的时候执行
  static int _downloadTasks = 0;

  Future<List<Stream<FileDownloadProgress>>> checkUpdate(
      bool deleteExpired) async {
    if (_updateChecked) return null;

    syncList = await api.getModelList();
    var list = (json.decode(syncList) as Map)['models'] as List;
    var models = list.map((m) => FileInfo.fromJson(m)).toList();

    var localModels = await _getLocalModel();
    if (localModels != null && models.length > 0 && deleteExpired) {
      for (var mi in localModels) {
        var i = models
            .indexWhere((v) => v.name == mi.name && v.md5Hash == mi.md5Hash);
        if (i < 0) {
          var f = File('${appVars.appDocDir}/models/${mi.name}');
          if (f.existsSync()) {
            f.deleteSync();
          }
        }
      }
    }

    // var tfLiteModels =
    //     models.where((fi) => fi.name.endsWith("tflite")).toList();
    // tfLiteModels.sort(([f1, f2]) {
    //   var i = f1.name.lastIndexOf('_');
    //   var dim1 =
    //       int.tryParse(f1.name.substring(i + 1, f1.name.indexOf('.', i)));
    //   i = f2.name.lastIndexOf('_');
    //   var dim2 =
    //       int.tryParse(f2.name.substring(i + 1, f2.name.indexOf('.', i)));
    //   return dim1 < dim2 ? 1 : -1;
    // });

    if (localModels != null) {
      models.removeWhere((v) =>
          localModels.indexWhere(
              (lv) => lv.name == v.name && lv.md5Hash == v.md5Hash) >=
          0);
    }

    var progress = new List<Stream<FileDownloadProgress>>();
    if (models.length > 0) {
      _downloadTasks = models.length;
      models.forEach((fi) {
        var stream = _downloadFile(fi);
        progress.add(stream);
        stream.listen((progress) {
          if (progress.received == progress.total) {
            if (--_downloadTasks == 0) {
              _saveModelListFile(syncList);
              _loadModel();
            }
          }
        });
      });
    } else {
      _loadModel();
    }
    _updateChecked = true;
    return progress;
  }

  Future<List<ArtPredict>> predict(String imagePath) async {
    List<int> feature =
        await tflite.invokeMethod('runModelOnImage', <String, dynamic>{
      'path': imagePath,
      'inputSize': 224, // wanted input size, defaults to 224
      'numChannels': 3, // wanted input channels, defaults to 3
      'imageMean': 127.5, // defaults to 117.0
      'imageStd': 127.5, // defaults to 1.0
      'numResults': 6, // defaults to 5
      'threshold': 0.05, // defaults to 0.1
      'numThreads': 1, // defaults to 1
    });

    var results = api.predict(feature, 5);
    // var scaledImage = event.imagePath + ".scale";
    // Map<String, IfdTag> data =
    //     await readExifFromBytes(await new File(scaledImage).readAsBytes());
    // if (data == null || data.isEmpty) {
    //   print("No EXIF information found");
    // } else {
    //   for (String key in data.keys) {
    //     print("$key (${data[key].tagType}): ${data[key]}");
    //   }
    // }

    //upload the scaled image
    api.uploadPhoto(imagePath + ".scale");

    return results;
  }

  Future<List<ArtPredict>> predictOnImage(CameraImage image) async {
    List<int> scores =
        await tflite.invokeMethod('runModelOnImageOffline', <String, dynamic>{
      'bytesList': image.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      'rotation': 0,
      'imageHeight': image.height,
      'imageWidth': image.width,
      'inputSize': 224, // wanted input size, defaults to 224
      'numChannels': 3, // wanted input channels, defaults to 3
      'imageMean': 127.5, // defaults to 117.0
      'imageStd': 127.5, // defaults to 1.0
      'numResults': 6, // defaults to 5
      'threshold': 0.05, // defaults to 0.1
      'numThreads': 1, // defaults to 1
      'k': 5, //top 5
    });

    //var results = api.predict(feature, 5);

    List<ArtPredict> results = new List();
    int count = scores[0].toDouble().toInt();
    for (int i = 0; i < count; i++) {
      results.add(ArtPredict(
          id: scores[i * 2 + 1].toDouble().toInt(),
          score: scores[i * 2 + 2].toDouble()));
    }

    return results;
  }

  Future<bool> _loadModel() async {
    if (tflite == null) {
      tflite = const MethodChannel('net.pangolinai.mobile/museum_tflite');
    }
    var localModels = await _getLocalModel();
    if (localModels.length == 0) return false;
    var lowDimModel =
        localModels.firstWhere((model) => model.name.endsWith("_512.tflite"));
    var lowDimIndex = localModels
        .firstWhere((model) => model.name.endsWith("_512.tflite.dat"));

    if (lowDimModel != null && lowDimIndex != null) {
      var modelPath = '${appVars.appDocDir}/models/${lowDimModel.name}';
      var indexPath = '${appVars.appDocDir}/models/${lowDimIndex.name}';
      final String result = await tflite.invokeMethod(
          'loadModel', {'model': '$modelPath', 'index': '$indexPath'});

      if (result != "success") {
        modelLoadComplete.complete(result);        
      }
    }
    modelLoadComplete.complete("success");
    return true;
  }

  Future<List<FileInfo>> _getLocalModel() async {
    List<FileInfo> cached;
    var f = File('${appVars.appDocDir}/models/mlist.json');
    if (await f.exists()) {
      var list = json.decode(await f.readAsString())['models'] as List;
      if (list != null) {
        cached = list.map((m) => FileInfo.fromJson(m)).toList();
      }
    }
    return cached;
  }

  Future _saveModelListFile(String content) async {
    var f = File('${appVars.appDocDir}/models/mlist.json');
    var writer = f.openSync(mode: FileMode.write);
    await writer.writeString(content);
    await writer.close();
  }

  Stream<FileDownloadProgress> _downloadFile(FileInfo model) {
    StreamController<FileDownloadProgress> controller;

    Future<int> _mergeFile(
        String mergeTo, String mergeFrom, bool deleteFromAfterMerge) async {
      var f = File(mergeFrom);
      var t = File(mergeTo);
      int mergeLen = 0;
      if (f.existsSync()) {
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

    Future<void> startDownload() async {
      //var docDir = (await getApplicationDocumentsDirectory()).path;
      var savePath = '${appVars.appDocDir}/models/${model.name}';
      var savePathTmp = '$savePath.tmp';
      var startRange = 0;

      await _mergeFile(savePath, savePathTmp, true);

      var f = File(savePath);
      if (f.existsSync()) {
        var digest = md5.convert(f.readAsBytesSync());
        if ('$digest' == model.md5Hash) {
          controller.add(FileDownloadProgress(
              file: model, received: model.size, total: model.size));
          controller.close();
          return null;
        }
        startRange = await f.length();
      }

      //download the file
      if (startRange != model.size) {
        var url = model.downloadPath.startsWith("/")
            ? '${Api.cdn}${model.downloadPath}'
            : '${Api.cdn}/${model.downloadPath}';

        try {
          Api.dio.download(
            url, savePathTmp,
            // Listen the download progress.
            onReceiveProgress: (received, total) async {
              print(((startRange + received) / model.size * 100)
                      .toStringAsFixed(0) +
                  "%");

              if (received == total) {
                await _mergeFile(savePath, savePathTmp, true);
              }

              controller.add(FileDownloadProgress(
                  file: model,
                  received: startRange + received,
                  total: model.size));

              if (received == total) {
                //note: 等待merge完毕了， 再关闭stream
                controller.close();
              }
            },
            options: Options(
              headers: {"range": "bytes=$startRange-"}, //指定请求的内容区间
            ),
            cancelToken: Api.onlyWifiDioToken,
          );
        } catch (e) {
          print(e);
          controller.close();
          File(savePath).deleteSync();
        }
      }
    }

    controller =
        StreamController<FileDownloadProgress>(onListen: startDownload);
    return controller.stream.asBroadcastStream();
  }
}
