//import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/art.dart';
import 'package:mobile/services/api.dart';
import 'package:mobile/widgets/audio_player.dart';

class ArtCard extends StatelessWidget {
  final ArtInfo art;

  ArtCard({this.art});
  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = new List<Widget>();

    widgets.add(ListTile(
      leading: const Icon(Icons.album),
      title: Text('The ${art.title}'),
      subtitle: Text('${art.museumName} / ${art.category}'),
    ));

    // art.images.forEach((url) {
    //   widgets.add(CachedNetworkImage(
    //     //imageUrl: "http://via.placeholder.com/350x150",
    //     imageUrl: art.images[0].startsWith("/")
    //         ? "${Api.cdn}${art.images[0]}"
    //         : "${Api.cdn}/${art.images[0]}",
    //     placeholder: new CircularProgressIndicator(),
    //     errorWidget: new Icon(Icons.broken_image),
    //   ));
    // });

    art.audios.forEach((url) {
      widgets.add(AudioPlayerWidget(
          url: url.startsWith("/")
              ? "${Api.cdn}$url"
              : "${Api.cdn}/$url"));
    });

    widgets.add(Padding(
      child: Text(art.text, style: TextStyle(letterSpacing: 2),),
      padding: new EdgeInsets.all(15.0),
    ));

    widgets.add(new ButtonTheme.bar(
        // make buttons use the appropriate styles for cards
        child: new ButtonBar(children: <Widget>[
      new FlatButton(
        child: Icon(Icons.favorite_border, size: 16),
        onPressed: () {/* ... */},
      ),
      new FlatButton(
        child: Icon(Icons.comment, size: 16),
        onPressed: () {/* ... */},
      )
    ])));

    return new Card(
      child: Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: widgets),
      ),
    );
  }
}