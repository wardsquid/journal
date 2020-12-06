import 'package:inkling/managers/DateToHuman.dart';
import 'package:share/share.dart';
import '../managers/userInfo.dart' as inkling;

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
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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
// import views
import './alerts/DiaryEntryAlerts.dart';

class DiaryEntryView extends StatefulWidget {
  DateTime activeDate;
  String documentId = "";
  DiaryEntryView({this.documentId, this.activeDate});
  @override
  _DiaryEntryViewState createState() => _DiaryEntryViewState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool toogleML = true;
  bool _isEditingText = false;
  String buttonText = "Create a new entry";
  List<double> _coordinates;
  // Controllers
  TextEditingController _textEditingController;
  TextEditingController _titleEditingController;

  // Entry related variables
  String ownerId = "";
  String entryText = "";
  String titleText = "";
  String tempTitleText = "";
  String tempEntryText = "";
  File _image;
  String _bucketUrl = '';
  // Firebase Related initializations (via managers/Firebase.dart)
  final User _user = checkUserLoginStatus();
  final CollectionReference entries = getFireStoreEntriesDB();
  final FirebaseStorage _storage = getStorage();
  final FirebaseFunctions _functions = getFunction();
  // Future<DocumentSnapshot> _currentDoc;

  final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'teamwardsquid@gmail.com',
      queryParameters: {'subject': 'Report:'});

  @override
  void initState() {
    // print('init diaryview');
    // print(inkling.userProfile.toString());

    super.initState();
    _textEditingController = TextEditingController(text: entryText);
    _titleEditingController = TextEditingController(text: titleText);
    if (widget.documentId != "") {
      // _currentDoc =
      readEntry(widget.documentId); //as DocumentSnapshot;
    } else {
      // _isEditingText = true;
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

//////////////////////////////////////////////////////////////////////////////////
  /// STATE MANAGEMENT CALLBACKS
/////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
  /// CREATES A NEW JOURNAL AND SETS IT AS ACTIVE
/////////////////////////////////////////////////////////////////////////////////////
  void updateJournal(text) async {
    bool writeResult = await addNewJournal(text);
    if (writeResult) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Journal created successfully.'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        inkling.userProfile['journals_list'].add(text);
        inkling.currentJournal = text;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong, please try again.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

//////////////////////////////////////////////////////////////////////////////////
  /// CHANGES ACTIVE JOURNAL (TAP ON DRAWER ENTRY)
/////////////////////////////////////////////////////////////////////////////////////
  void changeActiveJournal(String text) {
    setState(() {
      inkling.currentJournal = text;
    });
  }

//////////////////////////////////////////////////////////////////////////////////
  /// CREATES A NEW JOURNAL AND SETS IT AS ACTIVE
/////////////////////////////////////////////////////////////////////////////////////
  void updateSharingList(String title, List<String> sharingWith) {
    // print(title);
    print(sharingWith);
    setState(() {
      inkling.currentlySharingWith[title] = sharingWith;
    });
  }

  //////////////////////////////////////////////////////////////////////////////////
  /// POSTS THE UPDATED SHARING SETTINGS TO THE DB
/////////////////////////////////////////////////////////////////////////////////////
  void updateJournalSharingInDB(String journalName) async {
    bool writeResult = await updateJournalSharing(inkling.currentlySharingWith);
    if (writeResult) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$journalName sharing setting updated.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong, please try again.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// STATE MANAGEMENT CALLBACKS END
/////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
  /// GET IMAGE URL
///////////////////////////////////////////////////////////////////////
  Future<void> downloadURLImage() async {
    String setUrl = await _storage
        .ref("${_user.uid}/${widget.documentId}")
        .getDownloadURL();
    setState(() {
      _bucketUrl = setUrl;
    });
    print(_bucketUrl);
  }

///////////////////////////////////////////////////////////////////////
  /// RETRIEVE ENTRY FROM DB
///////////////////////////////////////////////////////////////////////
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
        inkling.activeEntry = documentSnapshot.data();
        titleText = inkling.activeEntry["title"];
        entryText = inkling.activeEntry["content"]["text"];
        ownerId = inkling.activeEntry['user_id'];
        _isEditingText = false;
        _textEditingController = TextEditingController(text: entryText);
        _titleEditingController = TextEditingController(text: titleText);
      });
    });
  }

///////////////////////////////////////////////////////////////////////
  /// ENTRY TEXT FIELDS
///////////////////////////////////////////////////////////////////////
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
            maxLines: null,
            decoration: InputDecoration(hintText: 'Dear diary...'),
            onChanged: (text) {
              entryText = text;
            },
            autofocus: false,
            controller: _textEditingController,
          ),
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

///////////////////////////////////////////////////////////////////////
  /// FLOATING BUTTON BEHAVIOUR
///////////////////////////////////////////////////////////////////////
  Widget _getFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: () => {
        if (_isEditingText && widget.documentId != "")
          {
            setState(() {
              _isEditingText = false;
              buttonText = "Edit";
              titleText = tempTitleText;
              entryText = tempEntryText;
              _textEditingController = TextEditingController(text: entryText);
              _titleEditingController = TextEditingController(text: titleText);
            })
          }
        else if (_isEditingText && widget.documentId == "")
          {
            setState(() {
              titleText = '';
              entryText = '';
              _textEditingController = TextEditingController(text: entryText);
              _titleEditingController = TextEditingController(text: titleText);
              _image = null;
              _bucketUrl = "";
              buttonText = "Edit";
              _isEditingText = false;
            })
          }
        else
          {
            MainView.of(context).documentIdReference = "",
            widget.documentId = "",
            setState(() {
              titleText = '';
              entryText = '';
              _textEditingController = TextEditingController(text: entryText);
              _titleEditingController = TextEditingController(text: titleText);
              _image = null;
              buttonText = "Save";
              _isEditingText = true;
            })
          },
      },
      label: _isEditingText ? Text("Cancel") : Text("New"),
      backgroundColor: Colors.pink,
      icon: _isEditingText ? Icon(Icons.cancel) : Icon(Icons.add),
    );
  }

////////////////////////////////////////////////////////////////
  /// SPEED DIAL
////////////////////////////////////////////////////////////////
  Widget speedDial() {
    // print('speedDial');
    // print(inkling.userProfile.toString());
    return SpeedDial(
      // both default to 16

      // marginRight: 18,
      // marginBottom: 20,
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      // this is ignored if animatedIcon is non null
      // child: Icon(Icons.add),
      visible: true, //_dialVisible,
      // If true user is forced to close dial manually
      // by tapping main button and overlay is not rendered.
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      onOpen: () => {
        print('OPENING DIAL'),
        // setState(() => {
        //       inkling.updateJournal(),
        //     })
      },
      onClose: () => print('DIAL CLOSED'),
      tooltip: 'Speed Dial',
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: Colors.purpleAccent,
      foregroundColor: Colors.white,
      elevation: 8.0,
      shape: CircleBorder(),
      children: (_isEditingText == true
          ? [
              SpeedDialChild(
                child: Icon(Icons.menu_book),
                backgroundColor: Colors.brown,
                label: 'Current Journal: ${inkling.currentJournal}',
                // labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => {
                  print("called"),
                  print(inkling.userProfile.keys.toString()),
                  // print(_user.email),
                  _scaffoldKey.currentState.openDrawer(),
                },
              ),
              SpeedDialChild(
                child: Icon(Icons.add_photo_alternate),
                backgroundColor: Colors.red,
                label: 'Add a photo from your Gallery',
                // labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => _getFromGallery(),
              ),
              SpeedDialChild(
                child: Icon(Icons.add_a_photo),
                backgroundColor: Colors.blue,
                label: 'Add from Camera',
                // labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => _getFromCamera(),
              ),
              SpeedDialChild(
                child: Icon(Icons.keyboard_voice),
                backgroundColor: Colors.green,
                label: 'Record a voice entry',
                // labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => print('THIRD CHILD'),
              ),
              SpeedDialChild(
                child: Icon(Icons.plumbing),
                backgroundColor: toogleML ? Colors.cyan : Colors.grey,
                label: 'Toogle ML: current ${(toogleML ? "ON" : "OFF")}',
                onTap: () => {setState(() => toogleML = !toogleML)},
              ), //:
            ]
          : ///////////////////////////////////////////////////////
          /// IF IN VIEW MODE
          ///////////////////////////////////////////////////////
          // ):
          [
                SpeedDialChild(
                  child: Icon(Icons.menu_book),
                  backgroundColor: Colors.brown,
                  label: 'Current Journal: ${inkling.currentJournal}',
                  // labelStyle: TextStyle(fontSize: 18.0),
                  onTap: () => {
                    print("called"),
                    print(inkling.userProfile.keys.toString()),
                    // print(_user.email),
                    _scaffoldKey.currentState.openDrawer(),
                  },
                ),

                // if
              ] +
              (widget.documentId != '' && ownerId == _user.uid
                  ? [
                      SpeedDialChild(
                        child: Icon(Icons.share),
                        backgroundColor: Colors.orange,
                        label: 'Share with a friend',
                        // labelStyle: TextStyle(fontSize: 18.0),
                        onTap: () => {
                          Share.share(entryText, subject: titleText),
                          print('THIRD CHILD')},
                      )
                    ]
                  : []) +
              // Renders the report button only if it is not a blank document
              // and the owner id is not the user
              (widget.documentId != '' && ownerId != _user.uid
                  ? [
                      SpeedDialChild(
                          child: Icon(Icons.mail),
                          backgroundColor: Colors.black,
                          label: 'Report Entry',
                          // labelStyle: TextStyle(fontSize: 18.0),
                          onTap: () => {
                                launch(_emailLaunchUri.toString()),
                                print('Report Functionality'),
                              })
                    ]
                  : [])),
    );
  }

///////////////////////////////////////////////////////////////////////
  /// ADDS A NEW ENTRY
///////////////////////////////////////////////////////////////////////
  Future<void> _addNewEntry() {
    return entries
        .add({
          'user_id': _user.uid,
          'title': titleText,
          'timestamp': DateTime.now(),
          'content': {
            'image': (_image != null) ? true : false,
            'text': entryText
          },
          'journal': inkling.currentJournal,
          'shared_with':
              inkling.currentlySharingWith.containsKey(inkling.currentJournal)
                  ? inkling.currentlySharingWith[inkling.currentJournal]
                  : [],
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

///////////////////////////////////////////////////////////////////////
  /// UPDATE DIARY ENTRY
///////////////////////////////////////////////////////////////////////
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

  ///////////////////////////////////////////////////////////////////////
  /// When an image is selected from the Gallery
  ///////////////////////////////////////////////////////////////////////
  _getFromGallery() async {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      List<double> _coordinates = await getExifFromFile(File(pickedFile.path));
      String location;
      if (_coordinates.length == 2) {
        final HttpsCallable httpsCallable =
            _functions.httpsCallable("getLocation");
        final results = await httpsCallable.call({
          "lat": _coordinates[0].toString(),
          "lon": _coordinates[1].toString()
        });
        location = results.data;
        print(location);
      }
      Map<String, double> labelMap = await readLabel(File(pickedFile.path));
      String generatedText = generateText(labelMap);

      // print(generatedText);

      setState(() {
        _image = File(pickedFile.path);
        if (location != null) {
          entryText = "I went to $location ... \n" + generatedText;
        } else {
          entryText = generatedText;
        }
        _textEditingController = TextEditingController(text: entryText);
      });
    }
  }

///////////////////////////////////////////////////////////////////////
  /// When an Image is selected from Camera
///////////////////////////////////////////////////////////////////////
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

///////////////////////////////////////////////////////////////////////
  /// MAIN VIEW
///////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // resizeToAvoidBottomInset: false,
      drawer: Scaffold(
          backgroundColor: Colors.transparent,
          body: journalDrawer(
              context,
              inkling.userProfile,
              updateJournal,
              changeActiveJournal,
              updateSharingList,
              updateJournalSharingInDB)),
      // body: AnnotatedRegion<SystemUiOverlayStyle>(
      // value: SystemUiOverlayStyle.light,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white, // background color
        ),
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          child: ListView(
            children: <Widget>[
              // if image is null
              _image == null
                  ? (_bucketUrl == ''
                      // if no image is being loaded from the DB
                      ? Image.asset(
                          'assets/Inkling_Login.png',
                          width: MediaQuery.of(context).size.width - 20,
                          semanticLabel: "Inkling Logo",
                        )
                      // if an image is being loaded from the DB
                      : FadeInImage(
                          image: NetworkImage(_bucketUrl),
                          placeholder: AssetImage("assets/placeholder.png"),
                          fit: BoxFit.cover))
                  // if image is has been selected
                  : Image.file(
                      _image,
                      fit: BoxFit.cover,
                    ),
              SizedBox(height: MediaQuery.of(context).size.height / 20),
              Center(
                child: Text(dateToHumanReadable(DateTime.now())),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 20),
              Center(
                child: _entryText(),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 20),

              // Container(
              //   decoration: BoxDecoration(
              //     image: DecorationImage(
              //       image: AssetImage('assets/Inkling_Login.png'),
              //     ),
              //   ),
              // )
              // _isEditingText == true
              //     ? Container(
              //         color: Colors.blueGrey,
              //         height: 300,
              //         child: _image == null
              //             ? Container(
              //                 // alignment: Alignment.center,
              //                 // child: Column(
              //                 //   mainAxisAlignment: MainAxisAlignment.center,
              //                 //   children: <Widget>[
              //                 //     // RaisedButton(
              //                 //     //   color: Colors.greenAccent,
              //                 //     //   onPressed: () {
              //                 //     //     _getFromGallery();
              //                 //     //   },
              //                 //     //   child: Text("PICK FROM GALLERY"),
              //                 //     // ),
              //                 //     // Container(
              //                 //     //   height: 40.0,
              //                 //     // ),
              //                 //     // RaisedButton(
              //                 //     //   color: Colors.lightGreenAccent,
              //                 //     //   onPressed: () {
              //                 //     //     _getFromCamera();
              //                 //     //   },
              //                 //     //   child: Text("PICK FROM CAMERA"),
              //                 //     // )
              //                 //   ],
              //                 // ),
              //               )
              //             : Container(
              //                 alignment: Alignment.center,
              //                 child: Image.file(
              //                   _image,
              //                   fit: BoxFit.cover,
              //                 )),
              //       )
              //     : Container(
              //         color: Colors.blueGrey,
              //         height: 300,
              //         width: double.infinity,
              //         child: _image == null
              //             ? Container(
              //                 alignment: Alignment.center,
              //                 child: FadeInImage(
              //                     image: NetworkImage(_bucketUrl),
              //                     placeholder:
              //                         AssetImage("assets/placeholder.png"),
              //                     fit: BoxFit.cover),
              //               )
              //             : Container(
              //                 alignment: Alignment.center,
              //                 child: //_image != null ?
              //                     Image.file(
              //                   _image,
              //                   fit: BoxFit.cover,
              //                 )
              //                 // : Image.memory(_downloadImage),
              //                 ),
              //       ),
              // Align(
              //   alignment: FractionalOffset.center,
              //   child: Padding(
              //     padding: const EdgeInsets.only(top: 25.0),
              //     child: Column(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       crossAxisAlignment: CrossAxisAlignment.center,
              //       children: <Widget>[
              //         SizedBox(height: 25.0),
              //         Padding(
              //           padding:
              //               const EdgeInsets.only(left: 15.0, right: 15.0),
              //           child: _entryText(),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // Container(
              //   height: 40.0,
              // ),
              Center(
                // alignment: FractionalOffset.bottomRight,
                child: RaisedButton(
                  color: Colors.purpleAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      buttonText,
                      style: TextStyle(fontSize: 25, color: Colors.white),
                    ),
                  ),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)),
                  onPressed: () {
                    setState(() {
                      tempTitleText = titleText;
                      tempEntryText = entryText;
                    });
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
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 20),

              //       child: Padding(
              //         padding: const EdgeInsets.only(bottom: 20.0),
              //         child: Container(
              //           height: 50.0,
              //           decoration: BoxDecoration(
              //               borderRadius: BorderRadius.circular(30.0),
              //               color:
              //                   Colors.transparent, // background button color
              //               border: Border.all(
              //                   color: Color(0xFFFB8986)) // all border colors
              //               ),
              //           child: Center(
              //               child: Text(
              //             buttonText,
              //             style: TextStyle(
              //                 color: Color(0xFFFB8986),
              //                 fontSize: 17.0,
              //                 fontWeight: FontWeight.w400,
              //                 fontFamily: "Poppins",
              //                 letterSpacing: 1.5),
              //           )),
              //         ),
              //       ),
              //     )),

              ///////////////////////////////////////////////////////////////////////
              // Align(
              //     alignment: Alignment.centerRight,
              //     child: TextButton(
              //       onPressed: () {
              //         launch(_emailLaunchUri.toString());
              //       },
              //       child: Padding(
              //         padding: const EdgeInsets.only(bottom: 20.0),
              //         child: Container(
              //             height: 50.0,
              //             width: 130.0,
              //             decoration: BoxDecoration(
              //                 borderRadius: BorderRadius.circular(10.0),
              //                 color: Colors
              //                     .transparent, // background button color
              //                 border: Border.all(
              //                     color: Colors.grey) // all border colors
              //                 ),
              //             // child: Row(children: <Widget>[
              //             //   Text(
              //             //     "Report",
              //             //     style: TextStyle(
              //             //         color: Colors.grey,
              //             //         fontSize: 17.0,
              //             //         fontWeight: FontWeight.w400,
              //             //         fontFamily: "Poppins",
              //             //         letterSpacing: 1.5),
              //             //   ),
              //             //   Icon(
              //             //     Icons.mail,
              //             //     color: Colors.grey,
              //             //     size: 30.0,
              //             //   ),
              //             // ], mainAxisAlignment: MainAxisAlignment.center)),
              //       ),
              //     ),
              //     ),
              // Transform.translate(
              //     offset: Offset(
              //         0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
              //     child: bottomNavBar(context)),
              // bottomNavBar(context),
            ],
          ),
        ),
      ),
      // ),
      floatingActionButton: speedDial(),
    ); //_getFloatingButton(),
    // floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    // );
  }
}
