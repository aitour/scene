import 'dart:async'; // for Future
import 'dart:io'; //for File
import 'dart:convert'; //for json
import 'package:crypto/crypto.dart'; //for md5
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import 'package:mobile/repositories/repositories.dart';
import 'package:mobile/models/models.dart';

import '../global.dart';

//event
abstract class TfModelEvent extends Equatable {
  TfModelEvent([List props = const []]) : super(props);
}

class TfModelCheckModelUpdateEvent extends TfModelEvent {}

// class TfModelDownloadEvent extends TfModelEvent {
//   final String url;
//   TfModelDownloadEvent({@required this.url})
//       : assert(url != null),
//         super([url]);
// }

class TfModelDownloadProgressEvent extends TfModelEvent {
  final TfModelInfo model;
  int received;
  int total;

  TfModelDownloadProgressEvent(
      {@required this.model,
      @required this.received,
      @required this.total})
      : super([model, received, total]);
}

//state
abstract class TfModelState extends Equatable {
  TfModelState([List props = const []]) : super(props);
}

class TfModelEmpty extends TfModelState {}

class TfModelDownloading extends TfModelState {
  final TfModelInfo model;
  int received;
  int total;

  TfModelDownloading(
      {@required this.model,
      @required this.received,
      @required this.total})
      : assert(model != null && total > 0),
        super([model, received, total]);
}

class TfModelDownloadError extends TfModelState {
  final String error;
  TfModelDownloadError({this.error});
}

class TfModelChecking extends TfModelState {}

class TfModelLoaded extends TfModelState {
  TfModelInfo model;
  TfModelLoaded({@required this.model})
      : assert(model != null),
        super([model]);
}

//bloc
class TfModelBloc extends Bloc<TfModelEvent, TfModelState> {
  final TfModelRepository repo;

  TfModelBloc({@required this.repo}) : assert(repo != null);

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

  @override
  TfModelState get initialState => TfModelEmpty();

  @override
  Stream<TfModelState> mapEventToState(TfModelEvent event) async* {
    if (event is TfModelDownloadProgressEvent) {
      yield TfModelDownloading(
          model: event.model,
          received: event.received,
          total: event.total);

      if (event.received == event.total) {
        yield TfModelLoaded(model: event.model);
      }
    }

    if (event is TfModelCheckModelUpdateEvent) {
      yield TfModelChecking();
      try {
        final modelList = await repo.getModelList();
        if (modelList.length == 0) {
          throw "download model list error";
        }

        var list = (json.decode(modelList) as Map)['models'] as List;
        if (list == null) {
          throw "invalid model list file";
        }

        var models = list.map((m) => TfModelInfo.fromJson(m)).toList();
        if (models.length == 0) {
          throw "tfmodel was not found";
        }

        //删除不同步的本地文件
        var docDir = (await getApplicationDocumentsDirectory()).path;
        List<TfModelInfo> cached;
        var f = File('$docDir/models/mlist.json');
        if (await f.exists()) {
          var list = json.decode(await f.readAsString())['models'] as List;
          if (list != null) {
            cached = list.map((m) => TfModelInfo.fromJson(m)).toList();

            for (var mi in cached) {
              var i = models.indexWhere(
                  (v) => v.name == mi.name || v.md5Hash != mi.md5Hash);
              if (i < 0) {
                await File('$docDir/models/${mi.name}').delete();
              }
            }
          }
        }

        //如果有必要， 下载模型
        for (var mi in models) {
          var savePath = '$docDir/models/${mi.name}';
          var savePathTmp = '$savePath.tmp';
          var startRange = 0;

          await _mergeFile(savePath, savePathTmp, true);

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
                ? '$cdn${mi.downloadPath}'
                : '$cdn/${mi.downloadPath}';

            try {
              dio.download(
                url, savePathTmp,
                // Listen the download progress.
                onReceiveProgress: (received, total) async {
                  print(((startRange + received) / mi.size * 100)
                          .toStringAsFixed(0) +
                      "%");

                  dispatch(TfModelDownloadProgressEvent(
                      model:mi,
                      received: startRange + received,
                      total: mi.size));

                  // yield TfModelDownloading(
                  //     url: mi.downloadPath,
                  //     localPath: savePath,
                  //     received: startRange + received,
                  //     total: mi.size);
                  // _downloadWatchers.forEach((f) {
                  //   f(savePath, startRange + received, mi.size);
                  // });

                  if (received == total) {
                    await _mergeFile(savePath, savePathTmp, true);

                    var fw = File('$docDir/models/mlist.json')
                        .openSync(mode: FileMode.write);
                    fw.writeStringSync(modelList);
                    fw.closeSync();

                    
                  }
                },
                options: Options(
                  headers: {"range": "bytes=$startRange-"}, //指定请求的内容区间
                ),
              );
            } catch (e) {
              yield TfModelDownloadError(error: e);
              print(e);
              File(savePath).deleteSync();
              continue;
            }
          }

          //await _mergeFile(savePath, savePathTmp, true);
          break; //temporarly we download the first model only
        }

        // var fw =
        //     File('$docDir/models/mlist.json').openSync(mode: FileMode.write);
        // fw.writeStringSync(modelList);
        // fw.closeSync();

        
      } catch (e) {
        yield TfModelDownloadError(error: e);
      }
    }
  }
}
