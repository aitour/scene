import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/generated/i18n.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/pages/base_view.dart';
import 'package:mobile/viewmodels/art_model.dart';
import 'package:mobile/viewmodels/base_model.dart';
import 'package:mobile/widgets/art_card.dart';

class ArtListView extends StatelessWidget {
  static String routeName = "art_list_page";
  final List<ArtPredict> predicts;

  ArtListView({this.predicts});

  List<Widget> buildArtList(ArtModel model) {
    var widgets = <Widget>[];
    widgets.add(Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20.0),
        itemCount: model.arts.length,
        itemBuilder: (context, index) => ArtCard(art: model.arts[index]),
      ),
    ));

    if (model.state == ViewState.PartReady) {
      widgets.add(SizedBox(
        height: 15,
      ));
      widgets.add(Center(
        child: CircularProgressIndicator(),
      ));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<ArtModel>(
      onModelReady: (model) => model.fetchArt(predicts),
      builder: (context, model, child) => Scaffold(
            appBar: AppBar(
              title: Text(S.of(context).predictResult),
            ),
            body: model.state == ViewState.Busy
                ? Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: buildArtList(model),
                  ),
          ),
    );
  }
}
