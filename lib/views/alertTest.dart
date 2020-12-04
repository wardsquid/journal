import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
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
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('I found these tags for you!'),
          content: Tags(
            key: _globalKey,
            itemCount: localList.length,
            columns: 6,
            itemBuilder: (index) {
              final Item currentItem = localList[index];

              return ItemTags(
                index: index,
                title: currentItem.title,
                active: false,
                customData: currentItem.customData,
                textStyle: TextStyle(fontSize: 14),
                combine: ItemTagsCombine.withTextBefore,
                onPressed: (i) => {
                  if (currentItem.active != true)
                    {selectedTagsList.add(currentItem.title)}
                  else
                    {selectedTagsList.removeAt(index)}
                },
              );
            },
          ),
          actions: <Widget>[
            MaterialButton(
              elevation: 5.0,
              child: Text('Ok!'),
              onPressed: () {
                print(selectedTagsList);
                selectedTagsList.forEach((selectedTag) {
                  selectedTagsString += selectedTag;
                });
                Navigator.of(context).pop(selectedTagsString);
                print('afternavigator ${selectedTagsList}.');
              },
            )
          ],
        );
      });
}

// class TestAlertView extends StatefulWidget {
//   @override
//   _TestAlertViewState createState() => _TestAlertViewState();
// }

// class _TestAlertViewState extends State<TestAlertView> {
//   //@override
//   List tags = new List();
//   List mlTags = new List.from(
//       ['hello', 'goodbye']); //list we will import from generatedText

//   mlTagConverter(mlList) {
//     mlList.forEach((mlListItem) {
//       setState(() {
//         tags.add(Item(title: mlListItem));
//       });
//     });
//     //mlTags = List.from([]);
//   }

//   final GlobalKey<TagsState> _globalKey = GlobalKey<TagsState>();

//   createTagAlert(BuildContext context, List localList) {
//     return showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: Text('I found these tags for you!'),
//             content: Tags(
//               key: _globalKey,
//               itemCount: localList.length,
//               columns: 6,
//               textField: TagsTextField(
//                 textStyle: TextStyle(fontSize: 14),
//                 onSubmitted: (string) {
//                   setState(() {
//                     tags.add(Item(title: string));
//                   });
//                 },
//               ),
//               itemBuilder: (index) {
//                 final Item currentItem = localList[index];

//                 return ItemTags(
//                   index: index,
//                   title: currentItem.title,
//                   active: false,
//                   customData: currentItem.customData,
//                   textStyle: TextStyle(fontSize: 14),
//                   combine: ItemTagsCombine.withTextBefore,
//                   onPressed: (i) => print(i.title),
//                   // onLongPressed: (i) => print(i),
//                   // removeButton: ItemTagsRemoveButton(
//                   //   onRemoved: () {
//                   //     setState(() {
//                   //       tags.removeAt(index);
//                   //     });
//                   //     return true;
//                   //   },
//                   // ),
//                 );
//               },
//             ),
//           );
//         });
//   }

//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Alert Test'),
//       ),
//       body: Builder(
//         builder: (context) {
//           return Container(
//             child: Center(
//               child: FlatButton(
//                 padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.0)),
//                 color: Colors.deepOrange,
//                 textColor: Colors.white,
//                 onPressed: () {
//                   print('MLtags: ${mlTags}');
//                   print('tags: ${tags}');
//                   mlTagConverter(mlTags);
//                   print('MLtags: ${mlTags}');
//                   print(tags);
//                   createTagAlert(context, tags);
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // return showDialog(
// //     context: context,
// //     builder: (context) {
// //       return AlertDialog(
// //           title: Text("I found these tags for you!"),
// //           content: TextField(controller: addNewTagsController),
// //           actions: <Widget>[
// //             MaterialButton(
// //               elevation: 5.0,
// //               child: Text('Ok'),
// //               onPressed: () {},
// //             )
// //           ]);
// //     });
// //)
