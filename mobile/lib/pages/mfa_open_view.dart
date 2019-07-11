import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:mobile/locator.dart';
//import 'package:flutter/widgets.dart';
import 'package:mobile/models/mfaobject.dart';
import 'package:mobile/pages/base_view.dart';
import 'package:mobile/viewmodels/base_model.dart';
import 'package:mobile/viewmodels/mfa_model.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

// class CustomSearchDelegate extends SearchDelegate {
//   @override
//   List<Widget> buildActions(BuildContext context) {
//     return [
//       IconButton(
//         icon: Icon(Icons.clear),
//         onPressed: () {
//           query = '';
//         },
//       ),
//     ];
//   }

//   @override
//   Widget buildLeading(BuildContext context) {
//     return IconButton(
//       icon: Icon(Icons.arrow_back),
//       onPressed: () {
//         close(context, null);
//       },
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     if (query.length < 3) {
//       return Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           Center(
//             child: Text(
//               "Search term must be longer than two letters.",
//             ),
//           )
//         ],
//       );
//     }

//     var model = locator<MfaModel>();
//     model.fetchQueryObjects(query);
//     close(context, null);
//     //return null;
//     return Column();
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     // This method is called everytime the search term changes.
//     // If you want to add search suggestions as the user enters their search term, this is the place to do that.
//     return Column();
//   }
// }

class MfaArtCard extends StatelessWidget {
  final Mfaobject obj;

  MfaArtCard({Key key, this.obj}) : super(key: key);

  Widget buildArtistInfo() {
    List<String> items = [
      obj.artistPrefix, obj.artistDisplayName,
      //obj.artistDisplayBio,
      obj.artistBeginDate.length > 0
          ? "${obj.artistBeginDate} - ${obj.artistEndDate}"
          : ""
    ];
    items.removeWhere((item) => item.isEmpty);

    return items.isEmpty
        ? Container()
        : Row(children: <Widget>[
            Icon(CupertinoIcons.person),
            Text(items.join(" / ")),
            //Text("${obj.artistBeginDate} - ${obj.artistEndDate}"),
            //Text("${obj.classification}"),
          ]);
  }

  Widget buildArtInfo() {
    List<String> items = [obj.dynasty, obj.period, obj.objectDate];
    items.removeWhere((item) => item.isEmpty);
    return items.isEmpty
        ? Container()
        : Row(children: <Widget>[
            Icon(CupertinoIcons.time),
            Text(items.join(" / "), overflow: TextOverflow.ellipsis)]);
            //Text("${obj.artistBeginDate} - ${obj.artistEndDate}"),
            //Text("${obj.classification}"),
          
  }

  Widget buildTags() {
    if (obj.tags.isEmpty) return Container();
    var tags = <Widget>[Icon(CupertinoIcons.tags)];
    tags.addAll(obj.tags
        .map((tag) => Container(
            margin: EdgeInsets.only(right: 5),
            child: Text("$tag ",
                style: TextStyle(
                  backgroundColor: Colors.black.withAlpha(0x09),
                ))))
        .toList());
    return Row(
      children: tags,
    );
  }

  Widget buildClassification() {
    return Row(
      children: <Widget>[Icon(CupertinoIcons.circle), Text("${obj.classification}")],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: new EdgeInsets.symmetric(vertical: 10.0, horizontal: 0.0),
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          children: <Widget>[
            Text(
              obj.title,
              style: TextStyle(
                //color: Color.fromARGB(255, 150, 150, 150),
                color: Theme.of(context).primaryColorDark,
                fontWeight: FontWeight.w300,
                fontSize: 18.0,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            //Image.network(obj.primaryImageSmall),
            CachedNetworkImage(
              imageUrl: obj.primaryImageSmall,
              // placeholder: (context, url) => new CircularProgressIndicator(),
              // errorWidget: (context, url, error) => new Icon(Icons.error),
            ),
            SizedBox(
              height: 10,
            ),
            new InkWell(
              child: Column(
                children: <Widget>[
                  buildArtistInfo(),
                  buildArtInfo(),
                  Row(children: <Widget>[
                    Icon(CupertinoIcons.location),
                    Text("${obj.repository}"),
                  ]),
                  buildTags(),
                  buildClassification(),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return Scaffold(
                    appBar: AppBar(
                      title: Text("${obj.title}"),
                    ),
                    body: WebView(
                      key: UniqueKey(),
                      javascriptMode: JavascriptMode.unrestricted,
                      initialUrl:
                          "https://www.metmuseum.org/art/collection/search/${obj.objectID}",
                    ),
                  );
                }));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MfaOpenView extends StatefulWidget {
  MfaOpenView({Key key}) : super(key : key);
  @override
  _MfaOpenViewState createState() => _MfaOpenViewState();
}

class _MfaOpenViewState extends State<MfaOpenView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  Widget buildBody(BuildContext context, MfaModel model) {
    if (model.state == ViewState.Busy) {
      return Center(child: CircularProgressIndicator());
    }

    if (model.objects != null && model.objects.length > 0) {
      return Container(
        color: Colors.black.withAlpha(0x03),
        margin: EdgeInsets.only(left:10, right:10),
        child: ListView.builder(
          //key: new PageStorageKey('mfa_list_view'),
          itemCount: model.objects.length,
          itemBuilder: (context, index) {
            return FutureBuilder<Mfaobject>(
              future: model.fetchMfaObject(model.objects[index]),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData)
                  return Container(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()));
                return MfaArtCard(obj: snapshot.data as Mfaobject);
              },
            );
          },
        ),
      );
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BaseView<MfaModel>(
        disposeModel: false,
        onModelReady: (model) => model.fetchMfaObjectsWithImages(),
        builder: (context, model, child) => Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: Text("Metropolitan Museum Collection"),
                textTheme: TextTheme(
          title: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
          )
        ),
                // actions: <Widget>[
                //   IconButton(
                //     icon: Icon(Icons.search),
                //     onPressed: () {
                //       showSearch(
                //         context: context,
                //         delegate: CustomSearchDelegate(),
                //       );
                //     },
                //   ),
                // ],
              ),
              body: buildBody(context, model),
            ));
  }
}
