// dart imports
import 'dart:io';
import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
// import dependencies
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
// import managers
import '../managers/Firebase.dart';
import '../managers/pageView.dart';
import '../managers/LocationInfo.dart';
import '../managers/GoogleMLKit.dart';
// import Firebase for Class definitions
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

String DateDisplay(DateTime date) {
  const List weekday = [null, 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const List months = [
    null,
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  String toBeDisplayed = weekday[date.weekday] +
      ', ' +
      date.day.toString() +
      ' ' +
      months[date.month] +
      ' ' +
      date.year.toString();
  return toBeDisplayed;
}

class DiaryEntryView extends StatefulWidget {
  DateTime activeDate;
  String documentId = "";
  DiaryEntryView({this.documentId, this.activeDate});
  @override
  _DiaryEntryViewState createState() => _DiaryEntryViewState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  bool _isEditingText = false;
  String buttonText = "Edit";
  List<double> _coordinates;
  // Controllers
  TextEditingController _textEditingController;
  TextEditingController _titleEditingController;

  String entryText = "";
  String titleText = "";
  File _image;
  String _bucketUrl = '';
  // Firebase Related initializations (via managers/Firebase.dart)
  final User _user = checkUserLoginStatus();
  final CollectionReference entries = getFireStoreEntriesDB();
  final FirebaseStorage _storage = getStorage();
  final FirebaseFunctions _functions = getFunction();
  // Future<DocumentSnapshot> _currentDoc;

  //
  Map<String, dynamic> entryInfo = {
    "doc_id": "",
    "title": "",
    "timestamp": "",
    "content": {"image": false, "text": ""},
  };
  final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'teamwardsquid@gmail.com',
      queryParameters: {'subject': 'Report:'});

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: entryText);
    _titleEditingController = TextEditingController(text: titleText);
    if (widget.documentId != "") {
      // _currentDoc =
      readEntry(widget.documentId); //as DocumentSnapshot;
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> downloadURLImage() async {
    String setUrl = await _storage
        .ref("${_user.uid}/${widget.documentId}")
        .getDownloadURL();
    setState(() {
      _bucketUrl = setUrl;
    });
    print(_bucketUrl);
  }

  Future<void> readEntry(String documentId) async {
    print('called');
    entries.doc(documentId).get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        print('Document data: ${documentSnapshot.data()}');
        // return documentSnapshot;
      } else {
        print('Document does not exist on the database');
      }
      if (documentSnapshot.data()["content"]["image"] == true) {
        downloadURLImage();
      } else {
        _bucketUrl = '';
      }
      setState(() {
        titleText = documentSnapshot.data()["title"];
        entryText = documentSnapshot.data()["content"]["text"];
        _isEditingText = false;
        _textEditingController = TextEditingController(text: entryText);
        _titleEditingController = TextEditingController(text: titleText);
      });
    });
  }

  Widget _entryText() {
    if (_isEditingText) {
      return Column(
        children: <Widget>[
          TextField(
            controller: _titleEditingController,
            decoration: InputDecoration(hintText: 'Title is...'),
            onChanged: (text) {
              titleText = text;
            },
            autofocus: true,
          ),
          TextField(
            decoration: InputDecoration(hintText: 'Dear diary...'),
            onChanged: (text) {
              entryText = text;
            },
            autofocus: false,
            controller: _textEditingController,
          )
        ],
      );
    }
    if (entryText == "" && titleText == "") {
      return Text(
        "Write an entry",
        style: TextStyle(
          color: Colors.black,
          fontSize: 18.0,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titleText,
          style: TextStyle(
            color: Colors.black,
            fontSize: 24.0,
          ),
        ),
        SizedBox(height: 15),
        Text(
          entryText,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.0,
          ),
        )
      ],
    );
  }

  Widget _getFloatingButton() {
    if (_isEditingText == true ||
        _image == null && titleText == "" && entryText == "") {
      return Container();
// =======
//     // if (_isEditingText == true ||
//     //     _image == null && titleText == "" && entryText == "") {
//     //   return Container();
//     // } else {
//     return FloatingActionButton.extended(
//       onPressed: () => {
//         if (_isEditingText && widget.documentId != "")
//           {
//             setState(() {
//               _isEditingText = false;
//               buttonText = "Edit";
//               titleText = tempTitleText;
//               entryText = tempEntryText;
//               _image = tempImage;
//               _textEditingController = TextEditingController(text: entryText);
//               _titleEditingController = TextEditingController(text: titleText);
//             })
//           }
//         else
//           {
//             MainView.of(context).documentIdReference = "",
//             widget.documentId = "",
//             setState(() {
//               titleText = '';
//               entryText = '';
//               _textEditingController = TextEditingController(text: entryText);
//               _titleEditingController = TextEditingController(text: titleText);
//               _image = null;
//               buttonText = "Edit";
//               _isEditingText = false;
//             })
//           },
//       },
//       label: _isEditingText ? Text("Cancel") : Text("New"),
//       backgroundColor: Colors.pink,
//       icon: _isEditingText ? Icon(Icons.cancel) : Icon(Icons.add),
//     );
//     // }
//   }

//   _addNewEntry() {
//     String img64;
//     if (_image != null) {
//       final bytes = _image.readAsBytesSync();
//       img64 = base64Encode(bytes);
// >>>>>>> 2e32b9f4020da84dc377d9572fc0dbdf586fb984
    } else {
      return FloatingActionButton.extended(
        onPressed: () => {
          MainView.of(context).documentIdReference = "",
          widget.documentId = "",
          setState(() {
            _bucketUrl = '';
            titleText = '';
            entryText = '';
            _textEditingController = TextEditingController(text: entryText);
            _titleEditingController = TextEditingController(text: titleText);
            _image = null;
            entryInfo["doc_id"] = "";
            _isEditingText = true;
          })
        },
        tooltip: 'Another New Entry',
        label: Text("New"),
        backgroundColor: Colors.pink,
        icon: Icon(Icons.add),
      );
    }
  }

  Future<void> _addNewEntry() {
    return entries
        .add({
          'user_id': _user.uid,
          'title': titleText,
          'timestamp': DateTime.now(),
          'content': {
            'image': (_image != null) ? true : false,
            'text': entryText
          }
        })
        .then((value) => {
              if (_image != null)
                {
                  _storage
                      .ref("${_user.uid}/${value.id}")
                      .putFile(_image)
                      .then((value) => print("Photo Uploaded Successfully"))
                      .catchError(
                          (error) => print("Failed to upload photo: $error"))
                },
              print(value.id),
            })
        .catchError((error) => print("Failed to add entry: $error"));
  }

  Future<void> _overwriteEntry() {
    return entries
        .doc(widget.documentId)
        .update({
          'title': titleText,
          'content': {
            'image': (_image != null) ? true : false,
            'text': entryText
          }
        })
        .then((value) => {
              if (_image != null)
                {
                  _storage
                      .ref("${_user.uid}/${widget.documentId}")
                      .putFile(_image)
                      .then((value) => print("Photo Uploaded Successfully"))
                      .catchError(
                          (error) => print("Failed to upload photo: $error"))
                }
            })
        .catchError((error) => print("Failed to add entry: $error"));
  }

  /// Get from gallery
  _getFromGallery() async {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      List<double> _coordinates = await getExifFromFile(File(pickedFile.path));
      String location;
      if (_coordinates.toString() != '[]') {
        final HttpsCallable httpsCallable =
            _functions.httpsCallable("getLocation");
        final results = await httpsCallable.call({
          "lat": _coordinates[0].toString(),
          "lon": _coordinates[1].toString()
        });
        location = results.data;
      }

      // Map<String, double> labelMap = await readLabel(File(pickedFile.path));
      // print(labelMap.toString());
      setState(() {
        _image = File(pickedFile.path);
        if (location != null) {
          entryText = "I went to $location ... \n";
        } else {
          entryText = "";
        }
        _textEditingController = TextEditingController(text: entryText);
      });
    }
  }

  /// Get from Camera
  _getFromCamera() async {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // background color
          ),
          child: ListView(
            children: <Widget>[
              _isEditingText == true
                  ? Container(
                      color: Colors.blueGrey,
                      height: 300,
                      child: _image == null
                          ? Container(
                              // alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  RaisedButton(
                                    color: Colors.greenAccent,
                                    onPressed: () {
                                      _getFromGallery();
                                    },
                                    child: Text("PICK FROM GALLERY"),
                                  ),
                                  Container(
                                    height: 40.0,
                                  ),
                                  RaisedButton(
                                    color: Colors.lightGreenAccent,
                                    onPressed: () {
                                      _getFromCamera();
                                    },
                                    child: Text("PICK FROM CAMERA"),
                                  )
                                ],
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              child: Image.file(
                                _image,
                                fit: BoxFit.cover,
                              )),
                    )
                  : Container(
                      color: Colors.blueGrey,
                      height: 300,
                      width: double.infinity,
                      child: _image == null
                          ? Container(
                              alignment: Alignment.center,
                              child: FadeInImage(
                                  image: NetworkImage(_bucketUrl),
                                  placeholder:
                                      AssetImage("assets/placeholder.png"),
                                  fit: BoxFit.cover),
                            )
                          : Container(
                              alignment: Alignment.center,
                              child: //_image != null ?
                                  Image.file(
                                _image,
                                fit: BoxFit.cover,
                              )
                              // : Image.memory(_downloadImage),
                              ),
                    ),
              Align(
                alignment: FractionalOffset.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 25.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: _entryText(),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 40.0,
              ),
              Align(
                  alignment: FractionalOffset.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      if (_isEditingText) {
                        if (_image == null &&
                            titleText == "" &&
                            entryText == "") {
                        } else if (widget.documentId == "") {
                          _addNewEntry();
                        } else {
                          _overwriteEntry();
                        }
                        // toggle view mode
                        setState(() {
                          buttonText = "Edit";
                          _isEditingText = false;
                        });
                      } else {
                        // toggle edit mode
                        setState(() {
                          buttonText = "Save";
                          _isEditingText = true;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        height: 50.0,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color:
                                Colors.transparent, // background button color
                            border: Border.all(
                                color: Color(0xFFFB8986)) // all border colors
                            ),
                        child: Center(
                            child: Text(
                          buttonText,
                          style: TextStyle(
                              color: Color(0xFFFB8986),
                              fontSize: 17.0,
                              fontWeight: FontWeight.w400,
                              fontFamily: "Poppins",
                              letterSpacing: 1.5),
                        )),
                      ),
                    ),
                  )),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      launch(_emailLaunchUri.toString());
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                          height: 50.0,
                          width: 130.0,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color:
                                  Colors.transparent, // background button color
                              border: Border.all(
                                  color: Colors.grey) // all border colors
                              ),
                          child: Row(children: <Widget>[
                            Text(
                              "Report",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "Poppins",
                                  letterSpacing: 1.5),
                            ),
                            Icon(
                              Icons.mail,
                              color: Colors.grey,
                              size: 30.0,
                            ),
                          ], mainAxisAlignment: MainAxisAlignment.center)),
                    ),
                  ))
            ],
          ),
        ),
      ),
      floatingActionButton: _getFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
