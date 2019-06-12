
import 'dart:async';

import 'package:mobile/models/index.dart';
import 'package:mobile/models/mfaobject.dart';
import 'package:mobile/services/api.dart';

class MfaApi {
  static String host = "https://collectionapi.metmuseum.org";

  Future<List<MfaDepartment>> getDepartments() async {
    var response = await Api.dio.get("$host/public/collection/v1/departments");
    return (response.data["departments"] as List).map((dep) => MfaDepartment.fromJson(dep)).toList();
  }

  Future<Mfaobject> getMfaObject(int objectID) async {
    var response = await Api.dio.get("$host/public/collection/v1/objects/$objectID");
    return Mfaobject.fromJson(response.data);
  }

  Future<List<int>> getMfaObjects(String metadataDate, List<int> departments) async {
    String query = "";
    if (metadataDate != null && metadataDate.length > 0) {
      query += "metadataDate=$metadataDate";
    }
    if (departments.length > 0) {
      if (query.length>0) query += "&";
      query += "departments="+departments.join("|");
    }
    var response = await Api.dio.get("$host/public/collection/v1/objects?$query");
    return response.data["objectIDs"].cast<int>();
  }

  Future<List<int>> getMfaObjectsWithImages() async {
    return getObjectsWithQuery("primaryImageSmall");
  }

  Future<List<int>> getObjectsWithQuery(String query) async {
    var response = await Api.dio.get("$host/public/collection/v1/search?q=$query");
    return response.data["objectIDs"].cast<int>();
  }
}