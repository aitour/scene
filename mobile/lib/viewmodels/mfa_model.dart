import 'dart:async';
import 'dart:convert';

import 'package:mobile/locator.dart';
import 'package:mobile/models/index.dart';
import 'package:mobile/services/db_helper.dart';
import 'package:mobile/services/mfa_service.dart';
import 'package:mobile/viewmodels/base_model.dart';

class MfaModel extends BaseModel {
  MfaApi api = locator<MfaApi>();

  List<MfaDepartment> departments;
  static List<int> _objects;
  String query; 

  List<int> get objects  {
    return _objects;
  }

  Future<List<MfaDepartment>> fetchDepartments() async {
    if (departments == null) {
      departments = await api.getDepartments();
    }
    return departments;
  }

  Future<List<int>> fetchMfaObjectsWithImages() async {
    if (_objects == null) {
      setState(ViewState.Busy);
      _objects = await api.getMfaObjectsWithImages();
      setState(ViewState.Idle);
    }
    return _objects;
  }

  Future<Mfaobject> fetchMfaObject(int id) async {
    var db = locator<DatabaseHelper>();
    var content = await db.getMfaObject(id);
    if (content.length > 0) {
      return Mfaobject.fromJson(json.decode(content));
    }
    //fetch from network
    var obj = await api.getMfaObject(id);
    //write to db and cache it
    db.insertMfaObject(obj.objectID, json.encode(obj));

    return obj;
  }

  Future<List<int>> fetchQueryObjects(String query) async {
    setState(ViewState.Busy);
    var results =  await api.getObjectsWithQuery(query);
    setState(ViewState.Idle);
    return results;
  }

  @override
  void dispose() {
    print("MFAModel disposed");
    super.dispose();
  }
}