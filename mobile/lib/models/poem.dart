class Poem {
  final String title;
  final String content;
  final String url;
  final String poetName;
  final String poetUrl;

  Poem({this.title, this.content, this.url, this.poetName, this.poetUrl});

  factory Poem.fromJson(Map<String, dynamic> json) {
    return Poem(
        title: json['title'],
        content: json['content'],
        url: json['url'],
        poetName: json['poet']['name'],
        poetUrl: json['poet']['url']);
  }
}
