import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/generated/i18n.dart';
import 'package:mobile/locator.dart';
import 'package:mobile/models/user_profile.dart';
//import 'package:mobile/widgets/language_list.dart';
import 'package:mobile/widgets/list_select.dart';
//import 'package:mobile/pages/base_view.dart';
import 'package:mobile/viewmodels/profile_model.dart';
import 'package:mobile/widgets/threshold_setting.dart';
import 'package:mobile/services/api.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileView extends StatefulWidget {
  ProfileView({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return new _ProfileViewState();
  }
}

class _ProfileViewState extends State<ProfileView> {
  //var appVars = locator<AppVars>();
  var model = locator<UserProfileModel>();
  //Object avatarTag;

  static Map<Locale, String> supportedLocales = {
    Locale('en', 'US'): "English", // English
    Locale('zh', 'CN'): "简体中文", //chinese simplified
    Locale('zh', 'TW'): "繁体中文" //chinese traditional
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
        //elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white.withAlpha(0x03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              buildHeader(),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                height: 10.0,
              ),
              buildFavsRow(),
              SizedBox(
                height: 15,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(15.0, 5.0, 10.0, 0.0),
                child: Text(
                  S.of(context).settings.toUpperCase(),
                  style: TextStyle(fontSize: 12.0),
                ),
              ),
              SizedBox(height: 10.0),
              buildLanguageSettingRow(),
              Divider(height: 0.5),
              buildTopKSettingRow(),
              Divider(height: 0.5),
              buildPredictThresholdSettingRow(),
              Divider(height: 0.5),
              buildPredictModeKSettingRow(),
              Divider(height: 0.5),
              SizedBox(
                height: 20.0,
              ),
              buildDonateRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    // var linearGradient = const BoxDecoration(
    //   gradient: const LinearGradient(
    //     begin: FractionalOffset.centerRight,
    //     end: FractionalOffset.bottomLeft,
    //     colors: <Color>[
    //       const Color(0xFF413070),
    //       const Color(0xFF2B264A),
    //     ],
    //   ),
    // );

    return Container(
      //decoration: linearGradient,
      //height: 200.0,
      //padding: EdgeInsets.only(bottom: 30.0),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0, bottom: 20.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: ClipOval(
                    child: CachedNetworkImage(
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      imageUrl: model.profile.avatar ??
                          'https://api.adorable.io/avatars/50/abott@adorable.png',
                      //placeholder: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 30.0,
            ),
            (model.profile?.userId ?? 0) > 0
                ? buildUserInfoRow()
                : buildLoginRow(),
          ],
        ),
      ),
    );
  }

  Widget buildFavsRow() {
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          ListTile(
            //leading: Text(S.of(context).preferedLanguage),
            leading: Icon(
              CupertinoIconsExt.comments,
            ),
            title: Text(S.of(context).comments),
            trailing: Text('${model.profile.comments ?? 0}'),
            onTap: () async {},
          ),
          Divider(
            height: 0.5,
          ),
          ListTile(
            //leading: Text(S.of(context).preferedLanguage),
            leading: Icon(CupertinoIcons.heart),
            title: Text(S.of(context).favorite),
            trailing: Text('${model.profile.favorites ?? 0}'),
            onTap: () async {},
          ),
          Divider(
            height: 0.5,
          ),
        ],
      ),
    );
  }

  Widget buildUserInfoRow() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("${model.profile.name ?? model.profile.email}"),
        new OutlineButton(
            child: new Text(S.of(context).signOut),
            onPressed: () {
              locator<Api>().signOut().then((ok) {
                if (mounted)
                  setState(() {
                    model.profile.clear();
                  });
              });
            },
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)))
      ],
    );
  }

  Widget buildLoginRow() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(S.of(context).signInWith.toUpperCase()),
        SizedBox(
          height: 10.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InkWell(
              child: Icon(IconFonts.faceBook, size: 35.0, color: Colors.blue),
              onTap: () async {
                final facebookLogin = FacebookLogin();
                final result =
                    await facebookLogin.logInWithReadPermissions(['email']);
                switch (result.status) {
                  case FacebookLoginStatus.loggedIn:
                    var token = result.accessToken.token;
                    //print('fb login success:$token');
                    try {
                      // final graphResponse = await Api.dio.get(
                      //     'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email&access_token=$token');
                      // if (graphResponse.data is String) {
                      //   graphResponse.data =
                      //       jsonDecode(graphResponse.data as String);
                      // }
                      // //final profile = JSON.decode(graphResponse.body);
                      // model.profile.email = graphResponse.data['email'];
                      // model.profile.name = graphResponse.data['name'];
                      // model.profile.facebookAccessToken = token;
                    } catch (e) {
                      print(e);
                    }

                    if (true) {
                      var api = locator<Api>();
                      var asProfile = await api.associateFacebookToken(token);
                      model.profile.userId = asProfile.userId;
                      model.profile.name = asProfile.name;
                      model.profile.accessToken = asProfile.accessToken;
                      model.profile.avatar = asProfile.avatar;
                      model.profile.email = asProfile.email;
                      model.profile.favorites = asProfile.favorites;
                      model.profile.comments = asProfile.comments;

                      api.signIn(model.profile).then((ok) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    }
                    break;
                  case FacebookLoginStatus.cancelledByUser:
                    //_showCancelledMessage();
                    print('fb login cancel');
                    break;
                  case FacebookLoginStatus.error:
                    //_showErrorOnUI(result.errorMessage);
                    print('fb login error:${result.errorMessage}');
                    break;
                }
              },
            ),
            SizedBox(
              width: 10.0,
            ),
            InkWell(
              child: Icon(IconFonts.google, size: 35.0),
            )
          ],
        )
      ],
    );
  }

  Widget buildDonateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: MaterialButton(
            minWidth: 40.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            //height: 42.0,
            onPressed: () {},
            color: Colors.lightBlueAccent.withOpacity(0.5),
            child: Text(
              S.of(context).aboutUs,
              style: TextStyle(color: Colors.white, letterSpacing: 1.5),
            ),
          ),
        ),
        SizedBox(
          width: 10.0,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: MaterialButton(
            minWidth: 40.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            //height: 42.0,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  // return object of type Dialog
                  return AlertDialog(
                    title: new Text("Thank you"),
                    content: new Text("We are not ready to accept donates"),
                    actions: <Widget>[
                      // usually buttons at the bottom of the dialog
                      new FlatButton(
                        child: new Text("Close"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            color: Colors.lightBlueAccent.withOpacity(0.5),
            child: Text(
              S.of(context).donate,
              style: TextStyle(color: Colors.white, letterSpacing: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLanguageSettingRow() {
    var locale = model.profile.locale ?? Localizations.localeOf(context);
    return Container(
      color: Colors.white,
      child: ListTile(
        //leading: Text(S.of(context).preferedLanguage),
        leading: Icon(CupertinoIconsExt.global),
        title: Text(S.of(context).preferedLanguage),
        trailing: Text(supportedLocales[locale]),
        onTap: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ListSelectWidget(
                        title: S.of(context).preferedLanguage,
                        items: supportedLocales.values.toList(),
                        selectedIndex:
                            supportedLocales.keys.toList().indexOf(locale),
                      ))).then((index) {
            if (index != null) {
              model.setLocale(supportedLocales.keys.toList()[index]);
              //Navigator.
            }
          });
        },
      ),
    );
  }

  Widget buildTopKSettingRow() {
    var topKs = ['5', '6', '7', '8', '9', '10'];
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(CupertinoIconsExt.topK),
        title: Text(S.of(context).topK),
        trailing: Text("${model.profile.topK ?? 5}"),
        onTap: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ListSelectWidget(
                        title: S.of(context).topK,
                        items: topKs,
                        selectedIndex:
                            topKs.indexOf('${model.profile.topK ?? 5}'),
                      ))).then((index) {
            if (index != null) {
              model.setTopK(int.parse(topKs[index]));
            }
          });
        },
      ),
    );
  }

  Widget buildPredictThresholdSettingRow() {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(CupertinoIconsExt.threshold),
        title: Text(S.of(context).threshold),
        trailing: Text(
            "${(model.profile.predictThreshold ?? 0.9).toStringAsFixed(2)}"),
        onTap: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ThresholdSettingView(
                        rangeStart: 0.8,
                        rangeEnd: 0.99,
                        threshold: model.profile.predictThreshold ?? 0.9,
                      ))).then((threshold) {
            if (threshold != null) {
              model.setPredictThreshold(threshold);
            }
          });
        },
      ),
    );
  }

  Widget buildPredictModeKSettingRow() {
    var modes = [
      S.of(context).predictMethodTakePhoto,
      S.of(context).predictMethodLive,
      S.of(context).predictMethodImages,
    ];
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(CupertinoIconsExt.predictMode),
        title: Text(S.of(context).predictMethod),
        trailing: Text(
            "${modes[model.profile.predictMode != null ? model.profile.predictMode.index : 0]}"),
        onTap: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListSelectWidget(
                    title: S.of(context).predictMethod,
                    items: modes,
                    selectedIndex: model.profile.predictMode?.index),
              )).then((index) {
            if (index != null) {
              model.setPredictMode(PredictMode.values[index]);
            }
          });
        },
      ),
    );
  }
}
