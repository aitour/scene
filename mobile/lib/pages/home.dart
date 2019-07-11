import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:mobile/locator.dart';
import 'package:mobile/models/poem.dart';
import 'package:mobile/services/api.dart';
import 'package:mobile/generated/i18n.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}):super(key:key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  List<Poem> poems = <Poem>[];
  RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: true);
  }

  // don't forget to dispose refreshController
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    /*.  after the data return,
        use _refreshController.refreshComplete() or refreshFailed() to end refreshing
   */
    locator<Api>().fetchRandomPoems().then((poems) {
      poems == null
          ? _refreshController.refreshFailed()
          : _refreshController.refreshCompleted();
      setState(() {
        if (poems != null) {
          this.poems = poems;
        }
      });
    });
  }

  void _onLoading() {
    /*
        use _refreshController.loadComplete() or loadNoData(),loadFailed() to end loading
   */
    locator<Api>().fetchRandomPoems().then((poems) {
      if (poems == null) {
        _refreshController.loadFailed();
      } else if (poems.length == 0) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
      }
      setState(() {
        if (poems != null) {
          this.poems.addAll(poems);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        //elevation: 0.0, 
        title: Text(S.of(context).welcome),
      ),
      body: Container(
        color: Colors.black.withAlpha(0x03),
        child: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: Theme.of(context).platform == TargetPlatform.iOS
              ? WaterDropHeader()
              : WaterDropMaterialHeader(),
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: poems == null ? Container() : poemsWidget(poems),
        ),
      ),
    );
  }

  Widget poemsWidget(List<Poem> poems) {
    return ListView.builder(
      itemCount: poems.length,
      itemBuilder: (context, i) {
        return Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
          margin: EdgeInsets.only(left: 5, right: 5, bottom: 45),
          child: Column(
            children: <Widget>[
              Text(
                "${poems[i].title}",
                style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    fontSize: 20.0),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text("by\t\t"),
                  InkWell(
                    child: Text(
                      "${poems[i].poetName}",
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16.0,
                          letterSpacing: 2,
                          decorationStyle: TextDecorationStyle.wavy),
                    ),
                    //onTap: () => launch("https://www.metmuseum.org/art/collection/search/${obj.objectID}"),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return Scaffold(
                          appBar: AppBar(
                            title: Text("${poems[i].poetName}"),
                          ),
                          body: WebView(
                            key: UniqueKey(),
                            javascriptMode: JavascriptMode.unrestricted,
                            initialUrl: "${poems[i].poetUrl}",
                          ),
                        );
                      }));
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 40,
              ),
              Text("${poems[i].content}",
                  style: TextStyle(
                    height: 1.5,
                    wordSpacing: 1.5,
                    fontFamily: 'Raleway',
                    //letterSpacing: 1.5,
                    fontSize: 16.0,
                    //decoration: TextDecoration.underline,
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
