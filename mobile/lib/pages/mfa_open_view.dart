import 'package:flutter/material.dart';
import 'package:mobile/locator.dart';
//import 'package:flutter/widgets.dart';
import 'package:mobile/models/mfaobject.dart';
import 'package:mobile/pages/base_view.dart';
import 'package:mobile/viewmodels/base_model.dart';
import 'package:mobile/viewmodels/mfa_model.dart';
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

class MfaOpenView extends StatelessWidget {
  Widget buildObject(BuildContext context, Mfaobject obj) {
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
                fontWeight: FontWeight.w700,
                fontSize: 22.0,
              ),
            ),
            SizedBox(
              height: 10,
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
            Column(
              children: <Widget>[
                Row(children: <Widget>[
                  Icon(Icons.access_time),
                  Text("${obj.artistBeginDate} - ${obj.artistEndDate}"),
                ]),
                Text("${obj.repository}"),
                Text("${obj.tags}"),
                new InkWell(
                  child: new Text('open browser'),
                  //onTap: () => launch("https://www.metmuseum.org/art/collection/search/${obj.objectID}"),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
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
            )
          ],
        ),
      ),
    );
  }

  Widget buildBody(BuildContext context, MfaModel model) {
    if (model.state == ViewState.Busy) {
      return Center(child: CircularProgressIndicator());
    }

    if (model.objects != null && model.objects.length > 0) {
      return Container(
        color: Color.fromARGB(0xFF, 0xf1, 0xf1, 0xf1),
        child: ListView.builder(
          itemCount: model.objects.length,
          itemBuilder: (context, index) {
            return FutureBuilder<Mfaobject>(
              future: model.fetchMfaObject(model.objects[index]),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData)
                  return Center(
                      child: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: CircularProgressIndicator()));
                return buildObject(context, snapshot.data);
              },
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<MfaModel>(
        onModelReady: (model) => model.fetchMfaObjectsWithImages(),
        builder: (context, model, child) => Scaffold(
              appBar: AppBar(
                title: Text("Mfa open"),
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
