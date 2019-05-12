import 'dart:async'; // for Future
import 'dart:io'; //for File
import 'dart:convert'; //for json
import 'dart:isolate';
import 'package:crypto/crypto.dart'; //for md5
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:exif/exif.dart';

import 'package:mobile/repositories/repositories.dart';
import 'package:mobile/models/models.dart';

import '../global.dart';

//event
abstract class TfModelEvent extends Equatable {
  TfModelEvent([List props = const []]) : super(props);
}

class TfModelCheckModelUpdateEvent extends TfModelEvent {}

class TfModelDownloadProgressEvent extends TfModelEvent {
  final TfModelInfo model;
  int received;
  int total;

  TfModelDownloadProgressEvent(
      {@required this.model, @required this.received, @required this.total})
      : super([model, received, total]);
}

class TfDoPredictionEvent extends TfModelEvent {
  final String imagePath;
  TfDoPredictionEvent({@required this.imagePath}) : super([imagePath]);
}

class TfModelErrorEvent extends TfModelEvent {
  final dynamic e;
  TfModelErrorEvent({this.e});
}

//state
abstract class TfState extends Equatable {
  TfState([List props = const []]) : super(props);
}

class TfModelEmpty extends TfState {}

class TfModelDownloading extends TfState {
  final TfModelInfo model;
  int received;
  int total;

  TfModelDownloading(
      {@required this.model, @required this.received, @required this.total})
      : assert(model != null && total > 0),
        super([model, received, total]);
}

class TfModelDownloadError extends TfState {
  final String error;
  TfModelDownloadError({this.error});
}

class TfModelChecking extends TfState {}

class TfModelLoaded extends TfState {
  TfModelInfo model;
  TfModelLoaded({@required this.model})
      : assert(model != null),
        super([model]);
}

class TfPredictionStart extends TfState {}

class TfPredictionResults extends TfState {
  final List<ArtPredict> results;
  TfPredictionResults({@required this.results}) : super([results]);
}

class TfPredictionError extends TfState {
  final String error;
  TfPredictionError({this.error}) : super([error]);
}

class TfPredictionShowingResults extends TfState {}

//bloc
class TfModelBloc extends Bloc<TfModelEvent, TfState> {
  final TfModelRepository repo;
  //StreamSubscription subscription;
  Isolate isolate;
  List<TfModelInfo> models;

  TfModelBloc({@required this.repo}) : assert(repo != null);

  @override
  TfState get initialState => global.tflite == null
      ? TfModelEmpty()
      : TfModelLoaded(model: global.currentModel);

  @override
  void dispose() {
    // TODO: implement dispose
    if (isolate != null) {
      print('killing isolate');
      isolate.kill(priority: Isolate.immediate);
      isolate = null;
    }
  }

  @override
  Stream<TfState> mapEventToState(TfModelEvent event) async* {
    print("mapEvent:$event");
    if (event is TfModelDownloadProgressEvent) {
      yield TfModelDownloading(
          model: event.model, received: event.received, total: event.total);

      if (event.received == event.total) {
        var fw = File('${global.appDocDir}/models/mlist.json')
            .openSync(mode: FileMode.write);
        var map = new Map<String, List<TfModelInfo>>();
        map["models"] = models;
        fw.writeStringSync(json.encode(map));
        fw.closeSync();

        global.tflite =
            const MethodChannel('net.pangolinai.mobile/museum_tflite');

        var modelPath = '${global.appDocDir}/models/${event.model.name}';
        final String result = await global.tflite
            .invokeMethod('loadModel', {'model': '$modelPath'});
        if (result != "success") {
          throw result;
        }
        global.currentModel = event.model;
        yield TfModelLoaded(model: event.model);
      }
    }

    if (event is TfModelCheckModelUpdateEvent) {
      yield TfModelChecking();

      //有本地model， 则先用本地的
      var localModels = await getLocalModel();
      if (localModels.length == 0) {
      } else {
        //check local model info
        if (global.tflite == null) {
          global.tflite =
              const MethodChannel('net.pangolinai.mobile/museum_tflite');
        }
        var modelPath = '${global.appDocDir}/models/${localModels[0].name}';
        final String result = await global.tflite
            .invokeMethod('loadModel', {'model': '$modelPath'});
        if (result != "success") {
          throw result;
        }
        global.currentModel = localModels[0];
        yield TfModelLoaded(model: localModels[0]);
      }

      checkModelUpdate();
    }

    if (event is TfDoPredictionEvent) {
      List<int> feature;
      try {
        feature = await global.tflite
            .invokeMethod('runModelOnImage', <String, dynamic>{
          'path': event.imagePath,
          'inputSize': 224, // wanted input size, defaults to 224
          'numChannels': 3, // wanted input channels, defaults to 3
          'imageMean': 127.5, // defaults to 117.0
          'imageStd': 127.5, // defaults to 1.0
          'numResults': 6, // defaults to 5
          'threshold': 0.05, // defaults to 0.1
          'numThreads': 1, // defaults to 1
        });
      } on PlatformException catch (e) {
        print("$e");
      }

      var response = await http.post(
          '${global.host}/predict2?k=5&language=${global.myLocale}',
          headers: {'Content-Type': 'application/octet-stream'},
          body: feature);
      if (response.statusCode == 200) {
        //print("${response.body}");
        var results = json.decode(response.body)['results'] as List;
        yield TfPredictionResults(
            results: results.map((item) => ArtPredict.fromJson(item)).toList());

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
        FormData formData = new FormData.from({
          "auth": "135246",
          "files": [
            new UploadFileInfo(
                new File(event.imagePath + ".scale"), "upload.jpg"),
          ]
        });
        global.dio.post("${global.host}/uploadscale", data: formData);
      } else {
        yield TfPredictionError(error: 'predict error: ${response.statusCode}');
      }
    }
  }

  //获取本地缓存��model信息
  Future<List<TfModelInfo>> getLocalModel() async {
    List<TfModelInfo> cached;
    var f = File('${global.appDocDir}/models/mlist.json');
    if (await f.exists()) {
      var list = json.decode(await f.readAsString())['models'] as List;
      if (list != null) {
        cached = list.map((m) => TfModelInfo.fromJson(m)).toList();
      }
    }
    return cached;
  }

  Future<void> checkModelUpdate() async {
    try {
      print("get model list");
      final modelList = await repo.getModelList();
      if (modelList.length == 0) {
        throw "download model list error";
      }

      var list = (json.decode(modelList) as Map)['models'] as List;
      if (list == null) {
        throw "invalid model list file";
      }

      models = list.map((m) => TfModelInfo.fromJson(m)).toList();
      if (models.length == 0) {
        throw "tfmodel was not found";
      }

      //删除不同步的本地文件
      var localModels = await getLocalModel();
      for (var mi in localModels) {
        var i = models
            .indexWhere((v) => v.name == mi.name || v.md5Hash != mi.md5Hash);
        if (i < 0) {
          await File('${global.appDocDir}/models/${mi.name}').delete();
        }
      }

      //如果有必要， 下载模型
      for (var mi in models) {
        //await _mergeFile(savePath, savePathTmp, true);
        // subscription?.cancel();
        // subscription = mi.download().listen((tfModelDownloadInfo) {
        //   dispatch(
        //     TfModelDownloadProgressEvent(
        //         model: mi,
        //         received: tfModelDownloadInfo.received,
        //         total: tfModelDownloadInfo.total)
        //         );
        //         });

        ReceivePort receivePort =
            ReceivePort(); //port for this main isolate to receive messages.
        isolate = await Isolate.spawn(downloadIsolate, receivePort.sendPort);
         // The 'echo' isolate sends it's SendPort as the first message
        var sendPort = await receivePort.first;
        sendPort.send(mi);

        receivePort.listen((data) {
          print('RECEIVE: $data');
          if (data is TfModelDownloadProgressEvent) {
            dispatch(data);
          }
        });

        break; //temporarly we download the first model only
      }
    } catch (e) {
      dispatch(TfModelErrorEvent(e: e));
      //yield TfModelDownloadError(error: e);
    }
  }
}

void downloadIsolate(SendPort sendPort) async {
  // Open the ReceivePort for incoming messages.
  var port = new ReceivePort();

  // Notify any other isolates what port this isolate listens to.
  sendPort.send(port.sendPort);

  var mi = await port.first;
  if (mi is TfModelInfo) {
    print("start download");
    StreamSubscription subscription = mi.download().listen((tfModelDownloadInfo) {
      sendPort.send(TfModelDownloadProgressEvent(
          model: mi,
          received: tfModelDownloadInfo.received,
          total: tfModelDownloadInfo.total));
    });
  }
}
