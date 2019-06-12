import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile/locator.dart';
import 'package:mobile/pages/art_list_view.dart';
import 'package:mobile/services/tfmodel_helper.dart';
import 'package:provider/provider.dart';
import 'package:mobile/generated/i18n.dart';

class DownloadProgressIndicator extends StatelessWidget {
  final FileDownloadProgress progress;

  DownloadProgressIndicator({this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
            '${progress.file != null ? progress.file.name : "downloading model"}'),
        SizedBox(
          height: 10.0,
        ),
        Text("${progress.received} / ${progress.total}"),
        SizedBox(
          height: 10.0,
        ),
        LinearProgressIndicator(
            value: progress != null && progress.total > 0
                ? progress.received / progress.total
                : 0.0)
      ],
    );
  }
}

class PredictView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PredictViewState();
  }
}

class _PredictViewState extends State<PredictView> {
  CameraController controller;
  AppVars appVars = locator<AppVars>();
  TfModelHelper tfHelper = locator<TfModelHelper>();
  List<Stream<FileDownloadProgress>> downloadProgressStream;
  String modelLoadMsg = "";
  bool isPredicting = false;
  bool isLivePredict = false;

  void updateUi() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    tfHelper.checkUpdate(true).then((progress) {
      downloadProgressStream = progress;
      if (progress == null || progress.length == 0) {
        appVars.cameras.then((cameras) {
          controller = CameraController(cameras[0], ResolutionPreset.medium);
          controller.initialize().then((_) {
            updateUi();
          });
        });
      }
      updateUi();
    });

    tfHelper.modelLoadComplete.future.then((result) {
      modelLoadMsg = result;
      updateUi();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void showError(String err) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(S.of(context).predictError),
          content: new Text(err),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text(S.of(context).close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildCamera(BuildContext context, CameraController controller) {
    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  Future takePictureAndPredict(BuildContext context) async {
    if (!controller.value.isInitialized) {
      print('Error: select a camera first.');
      return null;
    }

    setState(() {
      isPredicting = true;
    });

    final String dirPath = '${appVars.appDocDir}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      showError(e.toString());
      return null;
    }

    tfHelper.predict(filePath).then((results) {
      setState(() {
        isPredicting = false;
      });
      Navigator.pushNamed(context, ArtListView.routeName, arguments: results);
    }).catchError((e) {
      showError(e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (modelLoadMsg.length == 0) {
      if (this.downloadProgressStream != null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: this
                  .downloadProgressStream
                  .map((stream) => StreamProvider<FileDownloadProgress>.value(
                      stream: stream,
                      initialData: FileDownloadProgress(
                          file: null, received: 0, total: 1),
                      child: Container(
                          padding: EdgeInsets.all(10.0),
                          child: Consumer<FileDownloadProgress>(
                            builder: (context, progress, _) =>
                                DownloadProgressIndicator(progress: progress),
                          ))))
                  .toList(),
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).takePhotoAndPredict),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(
                height: 20,
              ),
              Text(S.of(context).loadingModel),
            ],
          ),
        ),
      );
    }

    if (modelLoadMsg != "success") {
      return Container(child: Text(modelLoadMsg));
    }

    if (isPredicting) {
      return Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(
                height: 20,
              ),
              Text(S.of(context).calculating),
            ],
          ),
        ),
      );
    }

    if (controller != null && controller.value.isInitialized) {
      return Scaffold(
        body: buildCamera(context, controller),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.camera),
          onPressed: () {
            isLivePredict = !isLivePredict;
            if (isLivePredict) {
              controller?.startImageStream((CameraImage image) async {
                if (!isPredicting) {
                  isPredicting = true;
                  var results = await tfHelper.predictOnImage(image);
                  print("$results");
                  isPredicting = false;
                }
                //if (isLivePredict) {}
              });
            } else {
              controller?.stopImageStream();
            }

            //takePictureAndPredict(context);
          },
        ),
      );
    }

    return Container(child: Text("something gona error"));
  }
}
