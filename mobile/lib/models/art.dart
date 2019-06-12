
class ArtPredict {
  final int id;
  final double score;

  ArtPredict({this.id, this.score});

  factory ArtPredict.fromJson(Map<String, dynamic> json) {
    return ArtPredict(id: json['ArtID'], score: json['Score']);
  }
}

class ArtInfo {
  final int id;
  final int museumId;
  final int artistId;
  final int displayNumber;
  final String creationYear;
  final int price;
  final String title;
  final String category;
  final String location;
  final List<String> images;
  final List<String> audios;
  final String text;
  final String material;
  final String museumName;
  final String museumCity;
  final String museumCountry;
  
  double predictScore = 0;

  ArtInfo(
      {this.id,
      this.museumId,
      this.artistId,
      this.displayNumber,
      this.creationYear,
      this.price,
      this.title,
      this.category,
      this.location,
      this.images,
      this.audios,
      this.text,
      this.material,
      this.museumName,
      this.museumCity,
      this.museumCountry});

  factory ArtInfo.fromJson(Map<String, dynamic> json) {
    return ArtInfo(
      id: json["ArtID"],
      museumId: json["MuseumID"],
      artistId: json["ArtistID"],
      displayNumber: json["DisplayNumber"],
      creationYear: json["CreationYear"],
      price: json["Price"],
      title: json["Title"],
      category: json["Category"],
      location: json["Location"],
      images: json["Images"] == null ? null : json["Images"].cast<String>(),
      audios: json["Audios"] == null ? null : json["Audios"].cast<String>(),
      text: json["Text"],
      material: json["Material"],
      museumName: json["MuseumName"],
      museumCity: json["MuseumCity"],
      museumCountry: json["MuseumCountry"],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };
}
