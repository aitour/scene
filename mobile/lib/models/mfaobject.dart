import 'package:json_annotation/json_annotation.dart';

part 'mfaobject.g.dart';

@JsonSerializable()
class Mfaobject {
    Mfaobject();

    num objectID;
    bool isHighlight;
    String accessionNumber;
    bool isPublicDomain;
    String primaryImage;
    String primaryImageSmall;
    List additionalImages;
    List constituents;
    String department;
    String objectName;
    String title;
    String culture;
    String period;
    String dynasty;
    String reign;
    String portfolio;
    String artistRole;
    String artistPrefix;
    String artistDisplayName;
    String artistDisplayBio;
    String artistSuffix;
    String artistAlphaSort;
    String artistNationality;
    String artistBeginDate;
    String artistEndDate;
    String objectDate;
    num objectBeginDate;
    num objectEndDate;
    String medium;
    String dimensions;
    String creditLine;
    String geographyType;
    String city;
    String state;
    String county;
    String country;
    String region;
    String subregion;
    String locale;
    String locus;
    String excavation;
    String river;
    String classification;
    String rightsAndReproduction;
    String linkResource;
    String metadataDate;
    String repository;
    String objectURL;
    List tags;

    int imgWidth;
    int imgHeight;
    
    factory Mfaobject.fromJson(Map<String,dynamic> json) => _$MfaobjectFromJson(json);
    Map<String, dynamic> toJson() => _$MfaobjectToJson(this);
}


// class MfaConstituent {
//   String role;
//   String name;

//   MfaConstituent();
//   factory MfaConstituent.fromJson(Map<String, dynamic> json) {
//     return MfaConstituent()
//     ..role = json["role"] as String 
//     ..name = json["name"] as String;
//   }
// }


class MfaDepartment {
  int departmentId;
  String displayName;

  MfaDepartment();

  factory MfaDepartment.fromJson(Map<String, dynamic> json) {
    return MfaDepartment()
    ..departmentId = json["departmentId"] as int
    ..displayName = json["displayName"] as String;
  }
}