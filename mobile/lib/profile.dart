import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './global.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _ProfilePageState();
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale.fromSubtags(
        languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
  ];

  @override
  void initState() {
    super.initState();
    asyncInit();
  }

  void asyncInit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString("locale");
    if (locale != null) {
      final lanSscriptCountry = locale.split("_");
      global.myLocale = Locale.fromSubtags(
          languageCode: lanSscriptCountry[0],
          scriptCode: lanSscriptCountry[1],
          countryCode: lanSscriptCountry[2]);
      setState(() {});
    }
  }

  void changeLocale(Locale newLocale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("locale", newLocale.toString());
    global.myLocale = newLocale;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 60.0),
      child: Form(
        key: _formKey,
        child: Column(
          //crossAxisAlignment: CrossAxisAlignment.start,

          children: <Widget>[
            Text("My prefered language"),
            DropdownButton<Locale>(
              items: supportedLocales
                  .map((Locale l) => new DropdownMenuItem<Locale>(
                        value: l,
                        child: Text(l.toString()),
                      ))
                  .toList(),
              value: supportedLocales.indexOf(global.myLocale) >= 0
                  ? global.myLocale
                  : supportedLocales[0],
              onChanged: changeLocale,
            ),
          ],
        ),
      ),
    );
  }
}
