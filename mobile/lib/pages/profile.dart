import 'package:flutter/material.dart';
import 'package:mobile/generated/i18n.dart';
import 'package:mobile/locator.dart';
import 'package:mobile/widgets/language_list.dart';

class ProfileView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _ProfileViewState();
  }
}

class _ProfileViewState extends State<ProfileView> {
  var appVars = locator<AppVars>();

  static Map<Locale, String> supportedLocales = {
    Locale('en', ''): "English", // English
    Locale('zh', 'CN'): "简体中文", //chinese simplified
    Locale('zh', 'TW'): "繁体中文" //chinese traditional
  };

  @override
  void initState() {
    super.initState();
  }

  void changeLocale(Locale newLocale) async {
    appVars.setLocale(newLocale);
  }

  @override
  Widget build(BuildContext context) {
    var locale = Localizations.localeOf(context) ?? Locale("en", "");

    return Padding(
      padding: EdgeInsets.only(top: 60.0),
      child: Column(
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: new BoxDecoration(
              border: new Border.all(width: 2.0,),
            ),
            width: double.infinity,
            height: 200,
            child: Card(
              elevation: 1,
              //color: Colors.amberAccent,
            ),
          ),
          SizedBox(
            height: 30,
          ),
          ListTile(
            leading: Text(S.of(context).preferedLanguage),
            trailing: Text(supportedLocales[locale]),
            onTap: () async {
              var result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LanguageListWidget(
                          supportedLocales: supportedLocales)));
              locator<AppVars>().setLocale(result);
            },
          ),
          new Divider(height: 2.0,),
        ],
      ),
    );
  }
}
