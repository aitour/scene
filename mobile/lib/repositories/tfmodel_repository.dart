import 'dart:async';

import 'package:meta/meta.dart';
import 'package:dio/dio.dart';
import '../global.dart';

class TfModelRepository {
  final String host;

  TfModelRepository({@required this.host}) : assert(host != null);

  Future<String> getModelList() async {
    var response = await global.dio.get("$host/model/list",
        options: Options(responseType: ResponseType.plain));
    if (response.statusCode != 200) {
      print("error download model list");
      return "";
    }
    return response.data;
  }
}
