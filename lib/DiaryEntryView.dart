import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'manager/Firebase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//import 'Choose_Login.dart';

class DiaryEntryView extends StatefulWidget {
  @override
  _DiaryEntryViewState createState() => _DiaryEntryViewState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  bool _isEditingText = false;
  TextEditingController _textEditingController;
  TextEditingController _titleEditingController;
  String entryText = "";
  String titleText = "";
  String buttonText = "Edit";

  File _image;

  CollectionReference entries =
      FirebaseFirestore.instance.collection('entries');

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: entryText);
    _titleEditingController = TextEditingController(text: titleText);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Widget _entryText() {
    if (_isEditingText)
      return Column(
        children: <Widget>[
          TextField(
            decoration: InputDecoration(hintText: 'Title is...'),
            onChanged: (text) {
              titleText = text;
            },
            autofocus: true,
            controller: _titleEditingController,
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
    if (entryText == "" && titleText == "")
      return Text(
        "Write an entry",
        style: TextStyle(
          color: Colors.black,
          fontSize: 18.0,
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Title: $titleText",
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

  Widget _getFAB() {
    if (_isEditingText == true ||
        _image == null && titleText == "" && entryText == "") {
      return Container();
    } else {
      return FloatingActionButton(
        onPressed: _saveEntry,
        tooltip: 'Save Entry',
        backgroundColor: Colors.yellow[600],
        child: Icon(Icons.add),
      );
    }
  }

  _saveEntry() {
    final User _user = checkUserLoginStatus();
    String img64;
    if (_image != null) {
      final bytes = _image.readAsBytesSync();
      img64 = base64Encode(bytes);
    } else {
      img64 = "";
    }
    return entries
        .add({
          'user_id': _user.uid,
          'title': titleText,
          'timestamp': DateTime.now(),
          'content': {'image': img64, 'text': entryText}
        })
        .then((value) => setState(() {
              titleText = '';
              entryText = '';
              _image = null;
            }))
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
      setState(() {
        _image = File(pickedFile.path);
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

  // Widget _indicator(bool isActive) {
  //   return AnimatedContainer(
  //     duration: Duration(milliseconds: 150),
  //     margin: EdgeInsets.symmetric(horizontal: 8.0),
  //     height: 5.0,
  //     width: isActive ? 24.0 : 16.0,
  //     decoration: BoxDecoration(
  //       color: /*isActive ? Color(0xFFFB8986) :*/ Colors.white,
  //       borderRadius: BorderRadius.all(Radius.circular(12)),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;

    var _textH1 = TextStyle(
        fontFamily: "Sofia",
        fontWeight: FontWeight.w600,
        fontSize: 23.0,
        backgroundColor: Colors.blueGrey,
        color: Colors.white); // h1 text color

    var _textH2 = TextStyle(
        fontFamily: "Sofia",
        fontWeight: FontWeight.w200,
        fontSize: 16.0,
        color: Colors.white); // h2 text color

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // background color
          ),
          child: Column(
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
                              ),
                            ),
                    )
                  : Container(
                      color: Colors.blueGrey,
                      height: 300,
                      width: double.infinity,
                      child: _image == null
                          ? Center(
                              child: Text(
                                "NO IMAGE",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFFFB8986),
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "Poppins",
                                    letterSpacing: 1.5),
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              child: Image.file(
                                _image,
                                fit: BoxFit.cover,
                              ),
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
              Align(
                alignment: FractionalOffset.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 270.0),
                ),
              ),
              Align(
                  alignment: FractionalOffset.bottomRight,
                  child: FlatButton(
                    onPressed: () {
                      setState(() {
                        if (_isEditingText) {
                          // save updated text
                          setState(() {
                            entryText = _textEditingController.text;
                            _isEditingText = false;
                          });

                          // toggle view mode
                          buttonText = "Edit";
                          _isEditingText = false;
                          // print("saved text: " + _textEditingController.text);
                        } else {
                          // toggle edit mode
                          buttonText = "Save";
                          _isEditingText = true;
                        }
                      });
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
                  ))
            ],
          ),
        ),
      ),
      floatingActionButton: _getFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
