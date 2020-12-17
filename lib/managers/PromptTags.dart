import 'package:flutter/material.dart';
import 'package:flutter_tags/flutter_tags.dart';

mlTagConverter(mlList) {
  List tags = new List();
  mlList.forEach((mlListItem) {
    tags.add(Item(title: mlListItem));
  });
  return tags;
}

final GlobalKey<TagsState> _globalKey = GlobalKey<TagsState>();

Future<String> createTagAlert(BuildContext context, List localList) {
  List selectedTagsList = [];
  String selectedTagsString = '';
  if (localList.length == 0) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Sorry, I couldn`t find any prompts!'),
            actions: <Widget>[
              MaterialButton(
                elevation: 5.0,
                child: Text('All Set!'),
                onPressed: () {
                  selectedTagsString += '';
                  Navigator.of(context).pop('');
                },
              )
            ],
          );
        });
  } else {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('I found these prompts to get you started!'),
            content: Tags(
              key: _globalKey,
              itemCount: localList.length,
              columns: 6,
              itemBuilder: (index) {
                Item currentItem = localList[index];
                return ItemTags(
                  index: index,
                  title: currentItem.title,
                  active: false,
                  customData: currentItem.customData,
                  textStyle: TextStyle(fontSize: 14),
                  combine: ItemTagsCombine.withTextBefore,
                  onPressed: (i) => {
                    if (!selectedTagsList.contains(currentItem.title))
                      {
                        selectedTagsList.add(currentItem.title),
                      }
                    else if (selectedTagsList.contains(currentItem.title))
                      {selectedTagsList.remove(currentItem.title)}
                  },
                );
              },
            ),
            actions: <Widget>[
              MaterialButton(
                elevation: 5.0,
                child: Text('All Set!'),
                onPressed: () {
                  selectedTagsList.forEach((selectedTag) {
                    selectedTagsString += '$selectedTag\n\n';
                  });
                  Navigator.of(context).pop(selectedTagsString);
                },
              )
            ],
          );
        });
  }
}
