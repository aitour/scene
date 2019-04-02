import 'package:equatable/equatable.dart';


class TfModelInfo extends Equatable {
  final String name;
  final String md5Hash;
  final int size;
  final String downloadPath;

  TfModelInfo({this.name, this.md5Hash, this.size, this.downloadPath}):
  super([name, md5Hash, size, downloadPath]);

  factory TfModelInfo.fromJson(Map<String, dynamic> json) {
    return TfModelInfo(
      name: json['Name'],
      md5Hash: json["Md5Hash"],
      size: json["FileSizeInBytes"],
      downloadPath: json["DownloadPath"],
    );
  }


  // Future<File> get localFile async {
  //   var appDoc = (await getApplicationDocumentsDirectory()).path;
  //   var savePath = '$appDoc/models/$name';
  //   return File(savePath);
  // }
}