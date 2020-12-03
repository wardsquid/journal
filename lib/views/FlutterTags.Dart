import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tags/flutter_tags.dart';

class FlutterTagPage extends StatefulWidget {
  FlutterTagPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _FlutterTagPageState createState() => _FlutterTagPageState();
}

class _FlutterTagPageState extends State<FlutterTagPage> {
  List tags = new List();
  final GlobalKey<TagsState> _globalKey = GlobalKey<TagsState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Tags(
            key: _globalKey,
            itemCount: tags.length,
            columns: 6,
            textField: TagsTextField(
              textStyle: TextStyle(fontSize: 14),
              onSubmitted: (string) {
                setState(() {
                  tags.add(Item(title: string));
                });
              },
            ),
            itemBuilder: (index) {
              final Item currentItem = tags[index];

              return ItemTags(
                index: index,
                title: currentItem.title,
                customData: currentItem.customData,
                textStyle: TextStyle(fontSize: 14),
                combine: ItemTagsCombine.withTextBefore,
                onPressed: (i) => print(i),
                onLongPressed: (i) => print(i),
                removeButton: ItemTagsRemoveButton(
                  onRemoved: () {
                    setState(() {
                      tags.removeAt(index);
                    });
                    return true;
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
