import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

//import 'Choose_Login.dart';

class DiaryEntryView extends StatefulWidget {
  DateTime activeDate;
  DiaryEntryView({this.activeDate});
  @override
  _DiaryEntryViewState createState() => _DiaryEntryViewState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  bool _isEditingText = false;
  TextEditingController _textEditingController;
  String entryText = "";
  String buttonText = "Edit";

  File _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: entryText);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Widget _entryText() {
    if (_isEditingText)
      return Center(
        child: TextField(
          decoration: InputDecoration(hintText: 'Dear diary...'),
          onChanged: (text) {
            entryText = text;
          },
          // onSubmitted: (newValue){
          //   setState(() {
          //     entryText = newValue;
          //     _isEditingText = false;
          //   });
          // },
          autofocus: true,
          controller: _textEditingController,
        ),
      );
    if (entryText == "")
      return Text(
        "Write an entry",
        style: TextStyle(
          color: Colors.black,
          fontSize: 18.0,
        ),
      );
    return Text(
      entryText,
      style: TextStyle(
        color: Colors.black,
        fontSize: 18.0,
      ),
    );
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      height: 5.0,
      width: isActive ? 24.0 : 16.0,
      decoration: BoxDecoration(
        color: /*isActive ? Color(0xFFFB8986) :*/ Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

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
            color: Colors.blueGrey, // background color
          ),
          child: Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: <Widget>[
                    Container(
                      child: _image == null
                          ? Container(
                              alignment: Alignment.center,
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
                            Text(
                              widget.activeDate.toString(),
                              style: _textH1,
                            ),
                            SizedBox(height: 25.0),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 15.0, right: 15.0),
                              child: _entryText(),
                              // TextField(
                              //   onChanged: (text) {
                              //     print("First text field: $text");
                              //     setState(() {
                              //       textContent = text;
                              //     });
                              //   },
                              //   // decoration: InputDecoration(
                              //   //   border: InputBorder.none,
                              //   //   hintText: 'Write your entry',
                              //   //   // 'Entry State will live here, make this editable',
                              //   //   // textAlign: TextAlign.center,
                              //   //   // style: _textH2,
                              //   // ),
                              // ),
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
                                  color: Colors
                                      .transparent, // background button color
                                  border: Border.all(
                                      color: Color(
                                          0xFFFB8986)) // all border colors
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
            ],
          ),
        ),
      ),
      //   floatingActionButton: FloatingActionButton(
      //   onPressed: getImage,
      //   tooltip: 'Pick Image',
      //   child: Icon(Icons.add_a_photo),
      // ),
    );
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
}