import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'DiaryEntryView.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../managers/Firebase.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Diary extends StatefulWidget {
  DateTime activeDate;
  Diary({this.activeDate});
  @override
  _Diary createState() => new _Diary(activeDate: activeDate);
}

class _Diary extends State<Diary> {
  DateTime activeDate;
  _Diary({this.activeDate});
  User currentUser = checkUserLoginStatus();
  FirebaseStorage _cloudStorage = getStorage();
  CollectionReference _entries = getFireStore();
  bool _isEditingText = false;
  TextEditingController _textEditingController;
  TextEditingController _titleEditingController;
  String entryText = "";
  String titleText = "";
  String buttonText = "Edit";
  File _image;

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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Background Color
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue[100], Colors.blue[400]],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    color: Colors.black,
                    image: DecorationImage(
                      image: ExactAssetImage('assets/onBoarding1.jpeg'),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: Colors.black,
                    ),
                    borderRadius: BorderRadius.circular(12)),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 3,
                  width: MediaQuery.of(context).size.width - 20,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 20),
              Text(
                'Date',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
              Text(
                DateDisplay(activeDate),
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 30),
              Text(
                'Text',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
              _entryText(),
              SizedBox(height: 40),
              FlatButton(
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
                color: Colors.deepPurple,
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////
