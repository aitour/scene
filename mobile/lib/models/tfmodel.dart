import 'dart:io';
import 'dart:async';
import 'package:crypto/crypto.dart'; //for md5
import 'package:path_provider/path_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../global.dart';

class TfModelDownloadInfo extends Equatable {
  final TfModelInfo tfModel;
  final int received;
  final int total;
  TfModelDownloadInfo({this.tfModel, this.received, this.total})
      : super([tfModel, received, total]);
}

class TfModelInfo extends Equatable {
  final String name;
  final String md5Hash;
  final int size;
  final String downloadPath;

  TfModelInfo({this.name, this.md5Hash, this.size, this.downloadPath})
      : super([name, md5Hash, size, downloadPath]);

  factory TfModelInfo.fromJson(Map<String, dynamic> json) {
    return TfModelInfo(
      name: json['Name'],
      md5Hash: json["Md5Hash"],
      size: json["FileSizeInBytes"],
      downloadPath: json["DownloadPath"],
    );
  }

  Map<String, dynamic> toJson() => {
        'Name': name,
        'Md5Hash': md5Hash,
        'FileSizeInBytes': size,
        'DownloadPath': downloadPath
      };

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

  Stream<TfModelDownloadInfo> download() {
    StreamController<TfModelDownloadInfo> controller;

    Future<void> startDownload() async {
      var docDir = (await getApplicationDocumentsDirectory()).path;
      var savePath = '$docDir/models/$name';
      var savePathTmp = '$savePath.tmp';
      var startRange = 0;

      await _mergeFile(savePath, savePathTmp, true);

      var f = File(savePath);
      if (f.existsSync()) {
        var digest = md5.convert(f.readAsBytesSync());
        if ('$digest' == md5Hash) {
          controller.add(
              TfModelDownloadInfo(tfModel: this, received: size, total: size));
          controller.close();
          return null;
        }
        startRange = await f.length();
      }

      //download the file
      if (startRange != size) {
        var url = downloadPath.startsWith("/")
            ? '${global.cdn}$downloadPath'
            : '${global.cdn}/$downloadPath';

        try {
          global.dio.download(
            url, savePathTmp,
            // Listen the download progress.
            onReceiveProgress: (received, total) async {
              print(((startRange + received) / size * 100).toStringAsFixed(0) +
                  "%");

              if (received == total) {
                await _mergeFile(savePath, savePathTmp, true);
              }

              controller.add(TfModelDownloadInfo(
                  tfModel: this,
                  received: (startRange + received),
                  total: size));

              if (received == total) {
                //note: 等待merge完毕了， 再关闭stream
                controller.close();
              }
            },
            options: Options(
              headers: {"range": "bytes=$startRange-"}, //指定请求的内容区间
            ),
            cancelToken: global.onlyWifiDioToken,
          );
        } catch (e) {
          print(e);
          controller.close();
          File(savePath).deleteSync();
        }
      }
    }

    controller = StreamController<TfModelDownloadInfo>(onListen: startDownload);

    return controller.stream;
  }

  // Future<File> get localFile async {
  //   var appDoc = (await getApplicationDocumentsDirectory()).path;
  //   var savePath = '$appDoc/models/$name';
  //   return File(savePath);
  // }
}
