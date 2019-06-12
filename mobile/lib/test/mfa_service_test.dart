// Import the test package and Counter class
import 'package:mobile/services/mfa_service.dart';
import 'package:test/test.dart';

void main() {
  test('get mfa department should return departments', () async {
    final api = MfaApi();

    var departments = await api.getDepartments();

    expect(departments.length > 0, true);
    //departments.forEach((dep) => print("${dep.departmentId}, ${dep.displayName}"));
  });

  test('get object should return 1 object', () async {
    final api = MfaApi();

    var obj = await api.getMfaObject(1);

    expect(obj.department.length > 0, true);
    print("$obj");
  });

  
  test('get objects should return 1 object', () async {
    final api = MfaApi();

    var objs = await api.getMfaObjects("2018-10-22", [3,9,12]);

    expect(objs.length > 0, true);
    print("objects size:${objs.length}");
  });
}
