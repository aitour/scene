import 'dart:async';
import 'dart:io';
import 'dart:convert'; //for json
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //for PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/scheduler.dart';
import 'package:mobile/widgets/widgets.dart';

import 'package:mobile/models/models.dart';
import 'package:mobile/repositories/repositories.dart';
import 'package:mobile/blocs/blocs.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/global.dart';

import './artlist.dart';

class Predict2Page extends StatefulWidget {
  Predict2Page({Key key}) : super(key: key);

  @override
  State<Predict2Page> createState() => _Predict2PageState();
}

class _Predict2PageState extends State<Predict2Page> {
  //TfModelBloc _tfModelBloc;
  CameraController controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _cameraInitialized = false;

  @override
  void initState() {
    super.initState();

    controller = CameraController(global.cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        print('camera was initialized');
        _cameraInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _cameraWidget() {
    return GestureDetector(
        onTap: onCameraPreviewPressed, child: CameraPreview(controller));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: BlocListener(
        bloc: BlocProvider.of<TfModelBloc>(context),
        listener: (BuildContext context, TfState state) {
          if (state is TfPredictionResults) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ArtListView(predicts: state.results)));
          }
          else if (state is TfPredictionError) {
            _showInSnackBar(state.error);
          }
        },
        child: BlocBuilder(
            bloc: BlocProvider.of<TfModelBloc>(context),
            builder: (BuildContext context, TfState state) {
              print("state:$state");
              if (state is TfModelEmpty) {
                BlocProvider.of<TfModelBloc>(context)
                    .dispatch(TfModelCheckModelUpdateEvent());
                return Center(child:Text("loading model..."));
              }
              else if (state is TfModelDownloadError) {
                return Text("model download error: " + state.error);
              }
              else if (state is TfModelDownloading) {
                double percent = state.received / state.total;
                return ProgressDialog(
                  value: percent,
                  msg: "loading.... ${(percent * 100).toStringAsFixed(0)}%",
                  child: Text(""),
                );
              }
              else if (state is TfPredictionStart) {
                return CircularProgressIndicator();
              } 

              return _cameraInitialized ? _cameraWidget() : Center(child:Text("wating for camera"));
            }),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            child: Icon(Icons.camera),
            onPressed: onCameraPreviewPressed,
          ),
        ],
      ),
    );
  }

  void onCameraPreviewPressed() {
    if (global.tflite == null) {
      _showInSnackBar('Error: model was not loaded');
      return;
    }

    _takePicture().then((String filePath) async {
      if (mounted) {
        BlocProvider.of<TfModelBloc>(context)
            .dispatch(TfDoPredictionEvent(imagePath: filePath));
      }
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void _showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> _takePicture() async {
    if (!controller.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return null;
    }

    final String dirPath = '${global.appDocDir}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    var msg = 'Error: ${e.code}\n${e.description}';
    print(msg);
    _showInSnackBar(msg);
  }
}
