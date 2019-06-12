import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/locator.dart';

class LanguageListWidget extends StatelessWidget {
  Map<Locale, String> supportedLocales;

  LanguageListWidget({this.supportedLocales});

  @override
  Widget build(BuildContext context) {
    var appVars = locator<AppVars>();
    var currentLocale = Localizations.localeOf(context);
    print("current locale:$currentLocale");

    return Scaffold(
      appBar: AppBar(
        title: Text("Select language"),
      ),
      body: ListView(
        children: supportedLocales.keys
            .map((locale) => ListTile(
                  title: Text(supportedLocales[locale]),
                  trailing: locale == currentLocale
                      ? IconButton(
                          icon: Icon(
                            Icons.done,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            appVars.setLocale(locale);
                          },
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context, locale);
                  },
                ))
            .toList(),
      ),
    );
  }
}
