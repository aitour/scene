import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile/locator.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/pages/art_list_view.dart';
import 'package:mobile/services/tfmodel_helper.dart';
import 'package:mobile/viewmodels/profile_model.dart';
import 'package:mobile/widgets/time_elapsed.dart';
import 'package:provider/provider.dart';
import 'package:mobile/generated/i18n.dart';
import 'package:fluro/fluro.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class DownloadProgressIndicator extends StatelessWidget {
  final FileDownloadProgress progress;
  final bool showPercent;

  DownloadProgressIndicator({this.progress, this.showPercent = true});

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
        Text(showPercent
            ? "${(progress.received / progress.total.toDouble() * 100).toInt()}%"
            : "${progress.received} / ${progress.total}"),
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
  PredictView({Key key}) : super(key: key);
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
  int orientation = 0; //default PortraintUp
  bool isPredicting = false;
  bool isLivePredict = false;
  Timer liveTimer;

  GlobalKey _predictButtonKey = GlobalKey();

  void updateUi() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // appVars.cameras.then((cameras) {
    //   controller = CameraController(cameras[0], ResolutionPreset.medium);
    //   controller.initialize().then((_) {
    //     updateUi();
    //   });
    // });

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
      appVars.cameras.then((cameras) {
        controller = CameraController(cameras[0], ResolutionPreset.medium);
        controller.initialize().then((_) {
          updateUi();
        });
      });
      //updateUi();
    });

    var profile = locator<UserProfileModel>().profile;
    if (profile != null && profile.locale == null) {
      profile.locale = Localizations.localeOf(context);
    }
  }

  @override
  void dispose() {
    if (controller != null) {
      if (controller.value.isStreamingImages) controller.stopImageStream();
      controller.dispose();
    }

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

  void startStream(Function fn) async {
    NativeDeviceOrientationCommunicator().resume().then((Void) {
      controller?.startImageStream(fn);
    });
  }

  void stopStream() async {
    NativeDeviceOrientationCommunicator().pause().then((Void) {
      controller?.stopImageStream();
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  Future pickImageAndPredict(BuildContext context) async {
    var filePath = await ImagePicker.pickImage(source: ImageSource.gallery);
    print(filePath);
    if (filePath == null) return;

    var profile = locator<UserProfileModel>().profile;

    setState(() {
      isPredicting = true;
    });
    tfHelper
        .predictOnImage(filePath.path, 0, profile?.topK ?? 5,
            profile?.predictThreshold ?? 0.8)
        .then((results) {
      setState(() {
        isPredicting = false;
      });
      results.forEach((r) => print("score:${r.score}, id:${r.id}"));
      Navigator.pushNamed(context, ArtListView.routeName, arguments: results);
    }).catchError((e) {
      showError(e.toString());
    });
  }

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

    var profile = locator<UserProfileModel>().profile;
    tfHelper
        .predictOnImage(
            filePath, 0, profile?.topK ?? 5, profile?.predictThreshold ?? 0.8)
        .then((results) {
      setState(() {
        isPredicting = false;
      });
      results.forEach((r) => print(r.score));
      //Navigator.pushNamed(context, ArtListView.routeName, arguments: results);
      locator<Router>()
          .navigateTo(context, ArtListView.routeName, arguments: results);
    }).catchError((e) {
      showError(e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (modelLoadMsg.length == 0) {
      //loading or downloading model
      if (this.downloadProgressStream != null &&
          this.downloadProgressStream.length > 0) {
        var downloadingWidgets = <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(S.of(context).downloading),
            ],
          ),
          SizedBox(
            height: 20.0,
          ),
        ];

        downloadingWidgets.addAll(this.downloadProgressStream.map((stream) =>
            StreamProvider<FileDownloadProgress>.value(
                value: stream,
                initialData:
                    FileDownloadProgress(file: null, received: 0, total: 1),
                child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Consumer<FileDownloadProgress>(
                      builder: (context, progress, _) =>
                          DownloadProgressIndicator(progress: progress),
                    )))));

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: downloadingWidgets,
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
      //model load failed. show error
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
      var profile = locator<UserProfileModel>().profile;

      return Scaffold(
        body: buildCamera(context, controller),
        floatingActionButton: FloatingActionButton(
          key: _predictButtonKey,
          child: (controller?.value?.isStreamingImages ?? false)
              ? TimeElapsedWidget(
                  totalTicks: 10,
                  foreColor: Colors.white,
                  bgColor: Colors.red,
                  width: IconTheme.of(context)?.size?.round() ?? 24,
                  onTimeout: () {
                    if (controller?.value?.isStreamingImages ?? false) {
                      controller?.stopImageStream();
                    }

                    Fluttertoast.showToast(
                      msg: S.of(context).predictNoMatch,
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIos: 1,
                      //backgroundColor: Colors.red,
                      //textColor: Colors.white,
                      //fontSize: 16.0,
                    );
                    setState(() {
                      isPredicting = false;
                    });
                  },
                )
              : Icon(profile.predictMode == PredictMode.TakePhoto
                  ? CupertinoIcons.photo_camera
                  : profile.predictMode == PredictMode.PickImage
                      ? CupertinoIconsExt.gallery
                      : CupertinoIcons.video_camera),
          onPressed: () {
            if (profile.predictMode == PredictMode.TakePhoto) {
              takePictureAndPredict(context);
            } else if (profile.predictMode == PredictMode.PickImage) {
              pickImageAndPredict(context);
            } else {
              if (controller?.value?.isStreamingImages ?? true) {
                controller?.stopImageStream()?.then((void v) {
                  NativeDeviceOrientationCommunicator().pause();
                });
              } else {
                NativeDeviceOrientationCommunicator().resume().then((void v) {
                  controller?.startImageStream((CameraImage image) async {
                    if (isPredicting) return;
                    isPredicting = true;

                    NativeDeviceOrientationCommunicator()
                        .orientation(useSensor: true)
                        .then((orientation) async {
                      this.orientation = orientation.index;
                      print('orientation: $orientation');

                      var results = await tfHelper.predictOnImage(
                          image,
                          this.orientation,
                          profile?.topK ?? 5,
                          profile?.predictThreshold ?? 0.8);
                      if (results.length > 0) {
                        if (controller.value.isStreamingImages) {
                          await controller.stopImageStream();
                        }
                        isPredicting = false;
                        Navigator.pushNamed(context, ArtListView.routeName,
                            arguments: results);
                      }
                      print("results: $results");
                      isPredicting = false;
                    });
                  })?.then((val) {
                    setState(() {});
                  });
                });
              }
            }
          },
        ),
      );
    }

    //return Container(child: Center(child: Text("something gona error")));
    return Container(
      child: Text(""),
    );
  }
}
