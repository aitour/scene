
class FileInfo {
  final String name;
  final String md5Hash;
  final int size;
  final String downloadPath;

  FileInfo({this.name, this.md5Hash, this.size, this.downloadPath});

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      name: json['Name'],
      md5Hash: json["Md5Hash"],
      size: json["FileSizeInBytes"],
      downloadPath: json["DownloadPath"],
    );
  }

  Map<String, dynamic> toJson() => {
        'Name': name,
        'Md5Hash': md5Hash,
        'FileSizeInBytes': size,
        'DownloadPath': downloadPath
      };
}
