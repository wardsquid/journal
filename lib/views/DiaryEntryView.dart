// dart imports
import 'dart:io';
import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'dart:math';
// import dependencies
import 'package:async/async.dart';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

// import managers
import '../managers/Firebase.dart';
import '../managers/pageView.dart';
import '../managers/LocationInfo.dart';
import '../managers/GoogleMLKit.dart';
import '../managers/Spotify.dart';
import '../managers/PromptTags.dart';
// import Firebase for Class definitions
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DiaryEntryView extends StatefulWidget {
  DateTime activeDate;
  String documentId = "";
  DiaryEntryView({this.documentId, this.activeDate});
  @override
  _DiaryEntryViewState createState() => _DiaryEntryViewState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  bool toogleML = true;
  bool _isEditingText = false;
  String buttonText = "Edit";
  List<double> _coordinates;

  // Spotify
  var _spotifyToken;
  var _currentTrack;
  var _storedTrack;
  bool _trackReady = false;
  String _spotifyUrl = "";

  // Controllers
  TextEditingController _entryEditingController;
  TextEditingController _titleEditingController;

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

  //speach_to_text Related initializations
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = "";
  String lastError = "";
  String lastStatus = "";
  String _currentLocaleId = "";
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();
  FocusNode entryFocusNode;
  FocusNode titleFocusNode;
  final bool finalResult = true;

  final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'teamwardsquid@gmail.com',
      queryParameters: {'subject': 'Report:'});

  @override
  void initState() {
    super.initState();
    _entryEditingController = TextEditingController(text: entryText);
    _titleEditingController = TextEditingController(text: titleText);
    if (widget.documentId != "") {
      readEntry(widget.documentId); //as DocumentSnapshot;
    } else {
      // _isEditingText = true;
    }
    entryFocusNode = FocusNode();
    titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _entryEditingController.dispose();
    _titleEditingController.dispose();
    entryFocusNode.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale.localeId;
    }

    if (!mounted) return;

    setState(() {
      _hasSpeech = hasSpeech;
    });
  }

  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: 60),
      localeId: _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
      if (result.finalResult) {
        if (entryFocusNode.hasFocus) {
          entryText += " " + lastWords;
          _entryEditingController = TextEditingController(text: entryText);
          lastWords = "";
        }
        if (titleFocusNode.hasFocus) {
          titleText += " " + lastWords;
          _titleEditingController = TextEditingController(text: titleText);
          lastWords = "";
        }
      }
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = "$status";
    });
  }

  _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }

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
        titleText = documentSnapshot.data()["title"];
        entryText = documentSnapshot.data()["content"]["text"];
        _spotifyUrl = documentSnapshot.data()["content"]["spotify"];
        _isEditingText = false;
        _entryEditingController = TextEditingController(text: entryText);
        _titleEditingController = TextEditingController(text: titleText);
      });
    });
    _getTrackByUrl();
  }

///////////////////////////////////////////////////////////////////////
  /// ENTRY TEXT FIELDS
///////////////////////////////////////////////////////////////////////
  Widget _entryText() {
    if (_isEditingText) {
      return Column(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      blurRadius: .26,
                      spreadRadius: level * 1.5,
                      color: Colors.blue.withOpacity(.3))
                ],
                color: !_hasSpeech || speech.isListening
                    ? Colors.blue
                    : Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.mic,
                  color: Colors.white,
                ),
                onPressed: !_hasSpeech || speech.isListening
                    ? stopListening
                    : startListening,
              ),
            ),
          ),
          Text(lastWords),
          TextField(
            maxLines: null,
            controller: _titleEditingController,
            decoration: InputDecoration(hintText: 'Title is...'),
            onChanged: (text) {
              titleText = text;
            },
            autofocus: true,
            focusNode: titleFocusNode,
          ),
          TextField(
            maxLines: null,
            controller: _entryEditingController,
            decoration: InputDecoration(hintText: 'Dear diary...'),
            onChanged: (text) {
              entryText = text;
            },
            autofocus: false,
            focusNode: entryFocusNode,
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
              _entryEditingController = TextEditingController(text: entryText);
              _titleEditingController = TextEditingController(text: titleText);
              lastWords = "";
            })
          }
        else if (_isEditingText && widget.documentId == "")
          {
            setState(() {
              titleText = '';
              entryText = '';
              _entryEditingController = TextEditingController(text: entryText);
              _titleEditingController = TextEditingController(text: titleText);
              _image = null;
              _bucketUrl = "";
              buttonText = "Edit";
              _isEditingText = false;
              lastWords = "";
            })
          }
        else
          {
            MainView.of(context).documentIdReference = "",
            widget.documentId = "",
            setState(() {
              titleText = '';
              entryText = '';
              _entryEditingController = TextEditingController(text: entryText);
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
    return SpeedDial(
      // both default to 16
      marginRight: 18,
      marginBottom: 20,
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
      onOpen: () => print('OPENING DIAL'),
      onClose: () => print('DIAL CLOSED'),
      tooltip: 'Speed Dial',
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: Colors.pink,
      foregroundColor: Colors.white,
      elevation: 8.0,
      shape: CircleBorder(),
      children: [
        if (_isEditingText == true)
          SpeedDialChild(
              child: Icon(Icons.add_photo_alternate),
              backgroundColor: Colors.red,
              label: 'Add a photo from your Gallery',
              // labelStyle: TextStyle(fontSize: 18.0),
              onTap: () => print('FIRST CHILD')),
        if (_isEditingText == true)
          SpeedDialChild(
            child: Icon(Icons.add_a_photo),
            backgroundColor: Colors.blue,
            label: 'Add from Camera',
            // labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => print('SECOND CHILD'),
          ),
        if (_isEditingText == true)
          SpeedDialChild(
            child: Icon(Icons.keyboard_voice),
            backgroundColor: Colors.purple,
            label: 'Record a voice entry',
            // labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => print('THIRD CHILD'),
          ),
        if (_isEditingText == false)
          SpeedDialChild(
            child: Icon(Icons.share),
            backgroundColor: Colors.orange,
            label: 'Share with a friend',
            // labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => print('THIRD CHILD'),
          ),
        if (_isEditingText == false)
          SpeedDialChild(
            child: Icon(Icons.menu_book),
            backgroundColor: Colors.brown,
            label: 'Current Journal: Personal',
            // labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => {
              getUserProfile()
                  .then((profile) => print(profile.data().toString())),
            },
          ),
        // Commenting this out because buttons don't all fit anymore
        // SpeedDialChild(
        //   child: Icon(Icons.plumbing),
        //   backgroundColor: toogleML ? Colors.cyan : Colors.grey,
        //   label: 'Toogle ML: current ${(toogleML ? "ON" : "OFF")}',
        //   onTap: () => {setState(() => toogleML = !toogleML)},
        // ),
        if (_isEditingText == true) _spotifySpeedDial()
      ],
    );
  }

///////////////////////////////////////////////////////////////////////
  /// ADDS A NEW ENTRY
///////////////////////////////////////////////////////////////////////
  Future<void> _addNewEntry() {
    print("Adding track: ${_storedTrack.track}");
    return entries
        .add({
          'user_id': _user.uid,
          'title': titleText,
          'timestamp': DateTime.now(),
          'content': {
            'image': (_image != null) ? true : false,
            'text': entryText,
            'spotify': (_spotifyUrl != null) ? _spotifyUrl : ""
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
            'text': entryText,
            'spotify': (_spotifyUrl != null) ? _spotifyUrl : ""
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
      }

      //pulls labels from image
      Map<String, double> labelMap = await readLabel(File(pickedFile.path));
      //using the labels pulled, creates a list of related prompt strings
      List<String> generatedText = generateText(labelMap);
      //converts the array of related prompt strings into the prompt tags to be displayed in the alert box
      List tags = mlTagConverter(generatedText);
      //renders an alertDialog populated with the prompt strings and allows the user to choose prompts. returns
      String selectedTagsString = await createTagAlert(context, tags);
      setState(() {
        _image = File(pickedFile.path);
        if (location != null) {
          entryText = "I went to $location ...  \n" + selectedTagsString;
        } else {
          entryText = selectedTagsString;
        }
        _entryEditingController = TextEditingController(text: entryText);
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
  /// SPOTIFY
///////////////////////////////////////////////////////////////////////

  SpeedDialChild _spotifySpeedDial() {
    return SpeedDialChild(
      child: Icon(Icons.music_note),
      backgroundColor: Colors.green,
      label: 'Add Spotify track',
      onTap: () async {
        await _initializeSpotify();
        if (_spotifyToken != null) {
          print("updating for token $_spotifyToken");
          await _updateLatestSpotifyTrack();
          _selectTrackPopup(context);
        } else {
          _linkSpotifyPopup(context);
        }
      },
    );
  }

  Future<void> _initializeSpotify() async {
    // Use below code if we want to authenticate from this button, and not on app start
    // if (_spotifyToken == null) {
    //   print("no token found");
    //   await getSpotifyAuth();
    var token = fetchSpotifyToken();
    setState(() {
      _spotifyToken = token;
    });
    //}
  }

  _updateLatestSpotifyTrack() async {
    await loadSpotifyTrack();
    setState(() {
      _currentTrack = fetchSpotifyTrack();
    });
  }

  _selectTrackPopup(context) {
    if (_currentTrack != null) {
      return Alert(
          context: context,
          title: "Recently played:",
          content: _currentSpotifyTrack(),
          buttons: [
            DialogButton(
                child: Text("Add song"),
                onPressed: () {
                  setState(() {
                    _spotifyUrl = _currentTrack.href;
                  });
                  _getTrackByUrl();
                  Navigator.pop(context);
                })
          ]).show();
    }
  }

  _linkSpotifyPopup(context) {
    return Alert(
        context: context,
        title: "Oops!",
        content: Text(
            "This feature requires Spotify access. Would you like to link your Spotify now?"),
        buttons: [
          DialogButton(
              child: Text("Yes"),
              onPressed: () async {
                await getSpotifyAuth();
                var token = fetchSpotifyToken();
                setState(() {
                  _spotifyToken = token;
                });
                Navigator.pop(context);
              }),
          DialogButton(
              child: Text("No"),
              onPressed: () async {
                Navigator.pop(context);
              })
        ]).show();
  }

  Widget _currentSpotifyTrack() {
    return ListTile(
      leading: Image.network(_currentTrack.imageUrl, width: 70, height: 70),
      title: Text('${_currentTrack.track}'),
      subtitle: Text('${_currentTrack.artist}'),
      isThreeLine: true,
    );
  }

  Widget _storedSpotifyTrack() {
    return ListTile(
        leading: Image.network(_storedTrack.imageUrl, width: 70, height: 70),
        title: Text('${_storedTrack.track}'),
        subtitle: Text('${_storedTrack.artist}'),
        isThreeLine: true,
        trailing: _isEditingText
            ? IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red, size: 50.0),
                onPressed: () {
                  // remove widget
                  _trackReady = false;
                })
            : IconButton(
                icon: Icon(Icons.play_circle_fill,
                    color: Colors.green, size: 50.0),
                onPressed: () {
                  // open in spotify
                  return launch(_storedTrack.url);
                }));
  }

  _getTrackByUrl() async {
    await getTrackByUrl(_spotifyUrl);
    setState(() {
      _storedTrack = fetchStoredTrack();
      _trackReady = true;
    });
  }

///////////////////////////////////////////////////////////////////////
  /// SPOTIFY
///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
  /// MAIN VIEW
///////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // background color
          ),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0)),
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
                          padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                          child: _entryText(),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 40.0,
                ),
                // Spotify
                if (_trackReady) _storedSpotifyTrack(),
                Align(
                    alignment: FractionalOffset.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        initSpeechState();
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
      ),
      floatingActionButton: speedDial(), //_getFloatingButton(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
