import 'dart:async';

import 'package:mobile/locator.dart';
import 'package:mobile/models/index.dart';
import 'package:mobile/services/mfa_service.dart';
import 'package:mobile/viewmodels/base_model.dart';

class MfaModel extends BaseModel {
  MfaApi api = locator<MfaApi>();

  List<MfaDepartment> departments;
  List<int> objects;
  String query;

  Future<List<MfaDepartment>> fetchDepartments() async {
    if (departments == null) {
      departments = await api.getDepartments();
    }
    return departments;
  }

  Future<List<int>> fetchMfaObjectsWithImages() async {
    if (objects == null) {
      setState(ViewState.Busy);
      objects = await api.getMfaObjectsWithImages();
      setState(ViewState.Idle);
    }
    return objects;
  }

  Future<Mfaobject> fetchMfaObject(int id) async {
    return await api.getMfaObject(id);
  }

  Future<List<int>> fetchQueryObjects(String query) async {
    setState(ViewState.Busy);
    var results =  await api.getObjectsWithQuery(query);
    setState(ViewState.Idle);
    return results;
  }
}