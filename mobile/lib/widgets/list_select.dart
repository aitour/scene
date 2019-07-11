import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListSelectWidget extends StatelessWidget {
  final String title;
  final List<String> items;
  final int selectedIndex;

  ListSelectWidget({this.title, this.items, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        children: items
            .map((text) => Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(text),
                      selected: text == items[selectedIndex],
                      trailing:
                          selectedIndex != -1 && text == items[selectedIndex]
                              ? Icon(
                                  Icons.done,
                                  color: Colors.blue,
                                )
                              : null,
                      onTap: () {
                        Navigator.pop(context, items.indexOf(text));
                      },
                    ),
                    Divider(),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
