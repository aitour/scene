import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/widgets/widgets.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/repositories/repositories.dart';
import 'package:mobile/blocs/blocs.dart';

class Predict2Page extends StatefulWidget {
  final TfModelRepository tfModelRepo;

  Predict2Page({Key key, @required this.tfModelRepo})
      : assert(tfModelRepo != null),
        super(key: key);

  @override
  State<Predict2Page> createState() => _Predict2PageState();
}

class _Predict2PageState extends State<Predict2Page> {
  TfModelBloc _tfModelBloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tfModelBloc = TfModelBloc(repo: widget.tfModelRepo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child:BlocBuilder(
          bloc: _tfModelBloc,
          builder: (BuildContext context, TfModelState state) {
            if (state is TfModelEmpty) {
              _tfModelBloc.dispatch(TfModelCheckModelUpdateEvent());
            }
            if (state is TfModelDownloadError) {
              return Text("download error: " + state.error);
            }

            if (state is TfModelDownloading) {
              double percent = state.received / state.total;
               return ProgressDialog(
                    value: percent,
                    msg :  "loading.... ${(percent * 100).toStringAsFixed(0)}%",
                    child: Text(""),
                  );
            }

            if (state is TfModelLoaded) {
              return Text("model loaded:" + state.model.name);
            }

            return Text("update check...");
          }
        )
      ),
    );
  }
}
