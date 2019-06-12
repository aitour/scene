import 'dart:async';

import 'package:mobile/locator.dart';
import 'package:mobile/models/art.dart';
import 'package:mobile/services/api.dart';
import 'package:mobile/viewmodels/base_model.dart';

class ArtModel extends BaseModel {
  Api api = locator.get<Api>();

  List<ArtInfo> arts = <ArtInfo>[];

  Future fetchArt(List<ArtPredict> predicts) async {
    setState(ViewState.Busy);
    for (var pred in predicts) {
      var artItem = await api.fetchArt(pred.id);
        if (artItem != null) {
        artItem.predictScore = pred.score;
        arts.add(artItem);
        arts.sort((a, b) => a.predictScore > b.predictScore ? -1 : 1);
        setState(ViewState.PartReady);
      }
    }
    
    setState(ViewState.Idle);
  }
}