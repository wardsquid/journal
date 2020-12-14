import 'package:inkling/managers/DateToHuman.dart';
import 'package:share/share.dart';
import '../managers/userInfo.dart' as inkling;
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'timeline/TimeLineView.dart';
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
// import views
import './alerts/DiaryEntryAlerts.dart';
//import liquid controller
import 'package:liquid_swipe/liquid_swipe.dart';

class DiaryEntryView extends StatefulWidget {
  DateTime activeDate;
  String documentId = "";
  LiquidController liquidController;
  bool editController;
  DiaryEntryView(
      {this.documentId,
      this.activeDate,
      this.liquidController,
      this.editController});
  @override
  _DiaryEntryViewState createState() => _DiaryEntryViewState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<AutoCompleteTextFieldState> _autoCompleteKey =
      new GlobalKey<AutoCompleteTextFieldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool toogleML = true;
  bool _isEditingText = false;
  String buttonText = "Create a new entry";
  List<double> _coordinates;

  // Spotify
  var _spotifyToken;
  var _currentTrack;
  var _storedTrack;
  bool _trackReady = false;
  String _spotifyUrl; // = "";
  List<dynamic> _todaysTracks;
  var _chosenTrack;
  var _suggestionTextFieldController = new TextEditingController();

  // Controllers
  TextEditingController _entryEditingController;
  TextEditingController _titleEditingController;
  // FocusNode FocusNode;

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
    // print(inkling.localDocumentStorage.length);
    // print(inkling.localDocumentStorage);
    // print(inkling.userProfile.toString());
    // print(_isEditingText.toString());
    super.initState();
    _entryEditingController = TextEditingController(text: entryText);
    _titleEditingController = TextEditingController(text: titleText);
    if (widget.documentId != "" && mounted) {
      readEntry(widget.documentId); //as DocumentSnapshot;
    } else {
      // _isEditingText = true;
    }
    if (widget.editController) {
      _isEditingText = true;
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

//////////////////////////////////////////////////////////////////////////////////
  /// STATE MANAGEMENT CALLBACKS
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
  /// CHANGES ACTIVE JOURNAL (TAP ON DRAWER ENTRY)
/////////////////////////////////////////////////////////////////////////////////////
  void changeActiveJournal(String text) {
    setState(() {
      inkling.currentJournal = text;
    });
  }

////////////////////////////////////////////////////////////////////////////////////////
  /// DELETE JOURNAL AND RELATED ENTRY / PICTURE
/////////////////////////////////////////////////////////////////////////////////////
  void deleteJournal(String journalName) async {
    // in progress snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Deleting...'),
        duration: const Duration(seconds: 2),
      ),
    );
    // creates a copy of the list
    List<dynamic> newList = [...inkling.userProfile['journals_list']];
    // remove the journal
    newList.remove(journalName);
    bool writeResult = await deleteJournalEntriesCascade(journalName);
    await addJournalToDB(newList);

    // result snackbar
    if (writeResult) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Journal deleted.'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        print(inkling.userProfile['journals_list']);
        inkling.userProfile['journals_list'] = newList;
        print(inkling.userProfile['journals_list']);
        changeActiveJournal('Personal');
        MainView.of(context).documentId = '';
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

/////////////////////////////////////////////////////////////////////////////////////
  /// UPDATE JOURNALS NAME LIST
/////////////////////////////////////////////////////////////////////////////////////
  void updateJournalsListName(
      List<dynamic> journalsList, String oldTitle, String newTitle) async {
    bool updateJournalList = await addJournalToDB(journalsList);
    bool updatePreviousEntries =
        await updateJournalNameCascade(oldTitle, newTitle);
    bool writeResult = updateJournalList && updatePreviousEntries;

    if (writeResult) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Journals list updated successfully.'),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        inkling.userProfile['journals_list'] = journalsList;
        // addJournalToDB(inkling.userProfile['journal_list']);
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
  /// CREATES A NEW JOURNAL AND SETS IT AS ACTIVE
/////////////////////////////////////////////////////////////////////////////////////
  void updateJournal(text) async {
    // inkling.userProfile['journals_list'].add(text);
    List<dynamic> journalList = inkling.userProfile['journals_list'];
    journalList.add(text);

    bool writeResult = await addJournalToDB(journalList);

    if (writeResult) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Journal created successfully.'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        inkling.userProfile['journals_list'] = journalList;
        inkling.currentJournal = text;
        // addJournalToDB(inkling.userProfile['journal_list']);
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
  /// CREATES A NEW JOURNAL AND SETS IT AS ACTIVE
/////////////////////////////////////////////////////////////////////////////////////
  void updateSharingList(String title, List<dynamic> sharingWith) {
    // print(title);
    // print(sharingWith);
    setState(() {
      inkling.currentlySharingWith[title] = sharingWith;
    });
  }

  //////////////////////////////////////////////////////////////////////////////////
  /// POSTS THE UPDATED SHARING SETTINGS TO THE DB
/////////////////////////////////////////////////////////////////////////////////////
  void updateJournalSharingInDB(String journalName) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('updating $journalName settings...'),
        duration: const Duration(seconds: 2),
      ),
    );
    bool updateUserSettings =
        await updateJournalSharing(inkling.currentlySharingWith);
    bool updateOlderEntries = await updateJournalSharingCascade(
        journalName, inkling.currentlySharingWith[journalName]);
    bool writeResult = updateUserSettings && updateOlderEntries;
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
  ///
/////////////////////////////////////////////////////////////////////////////////////
  /// SPEECH RECOGNITION
/////////////////////////////////////////////////////////////////////////////////////

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
    // print(selectedVal);
  }

///////////////////////////////////////////////////////////////////////
  /// GET IMAGE URL
///////////////////////////////////////////////////////////////////////
  Future<void> downloadURLImage(String creatorID) async {
    String setUrl =
        await _storage.ref("$creatorID/${widget.documentId}").getDownloadURL();
    if (mounted)
      setState(() {
        _bucketUrl = setUrl;
      });
    // print(_bucketUrl);
  }

///////////////////////////////////////////////////////////////////////
  /// RETRIEVE ENTRY FROM DB
///////////////////////////////////////////////////////////////////////
  Future<void> readEntry(String documentId) async {
    inkling.orderedListIDMap
        .forEach((key, value) => print('index $value, docid $key'));
    if (inkling.orderedListIDMap.containsKey(documentId)) {
      print('inkling.orderedListIDMap.containsKey(documentId)');
      readEntryFromLocalStorage((inkling.orderedListIDMap[documentId]));
      print('called from localList');
      return;
    }

    print('fetching from DB');
    entries.doc(documentId).get().then((DocumentSnapshot documentSnapshot) {
      if (!documentSnapshot.exists)
        print('Document does not exist on the database');
      if (documentSnapshot.data() != null) {
        if (documentSnapshot.data()["content"]["image"] == true && mounted) {
          downloadURLImage(documentSnapshot.data()["user_id"]);
        } else {
          _bucketUrl = '';
        }
        if (mounted)
          setState(() {
            inkling.activeEntry = documentSnapshot.data();
            titleText = inkling.activeEntry["title"];
            entryText = inkling.activeEntry["content"]["text"];
            ownerId = inkling.activeEntry['user_id'];
            if (inkling.activeEntry["content"].containsKey("spotify")) {
              _spotifyUrl = inkling.activeEntry["content"]["spotify"];
            } else {
              _spotifyUrl = null;
            }
            _isEditingText = false;
            _entryEditingController = TextEditingController(text: entryText);
            _titleEditingController = TextEditingController(text: titleText);
          });
      }
      if (_spotifyUrl != null && mounted) {
        _getTrackByUrl();
      }
    });
  }

  ///////////////////////////////////////////////////////////////////////
  /// RETRIEVE ENTRY FROM LOCAL STORAGE
///////////////////////////////////////////////////////////////////////
  Future<void> readEntryFromLocalStorage(int index) async {
    print('fetching from Local Storage');

    Map<String, dynamic> document = inkling.orderedList[index];
    print(document.toString());
    // if (!mounted) return;
    if (document["content"]["image"] == true &&
        document["imageUrl"].length > 0 &&
        mounted) {
      _bucketUrl = document["imageUrl"];
    } else {
      _bucketUrl = '';
    }
    if (mounted)
      setState(() {
        inkling.activeEntry = document;
        titleText = inkling.activeEntry["title"];
        entryText = inkling.activeEntry["content"]["text"];
        ownerId = inkling.activeEntry['user_id'];
        if (inkling.activeEntry["content"].containsKey("spotify")) {
          _spotifyUrl = inkling.activeEntry["content"]["spotify"];
        } else {
          _spotifyUrl = null;
        }
        _isEditingText = false;
        _entryEditingController = TextEditingController(text: entryText);
        _titleEditingController = TextEditingController(text: titleText);
      });
    if (_spotifyUrl != null && mounted) {
      _getTrackByUrl();
    }
  }

///////////////////////////////////////////////////////////////////////
  /// ENTRY TEXT FIELDS
///////////////////////////////////////////////////////////////////////
  Widget _entryText() {
    if (_isEditingText) {
      return Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
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
            TextFormField(
              maxLines: null,
              controller: _titleEditingController,
              decoration: InputDecoration(hintText: 'Title is...'),
              onChanged: (text) {
                titleText = text;
              },
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter a title';
                } else if (value.trim() == "") {
                  return 'Please enter a non-empty title';
                }
                return null;
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
        ),
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
  /// SAVE BUTTOON
///////////////////////////////////////////////////////////////////////
  Widget _saveButton() {
    return IconButton(
      onPressed: () => {
        if (_formKey.currentState.validate())
          {
            if (titleText != "" && widget.documentId == "")
              {
                _addNewEntry(),
                setState(() {
                  _isEditingText = false;
                }),
              }
            else if (titleText != "" && widget.documentId != "")
              {
                _overwriteEntry(),
                setState(() {
                  _isEditingText = false;
                }),
              },
          }
      },
      icon: Icon(Icons.save),
    );
  }

  ///////////////////////////////////////////////////////////////////////
  /// CANCEL FLOATING BUTTON
///////////////////////////////////////////////////////////////////////
  Widget _cancelFloatingButton() {
    return IconButton(
      icon: Icon(Icons.cancel),
      onPressed: () => {
        if (widget.documentId == "")
          {
            setState(() {
              titleText = '';
              entryText = '';
              _entryEditingController = TextEditingController(text: entryText);
              _titleEditingController = TextEditingController(text: titleText);
              _image = null;
              _chosenTrack = null;
              _currentTrack = null;
              _storedTrack = null;
              _trackReady = false;
              _spotifyUrl = null;
              _isEditingText = false;
            })
          }
        else
          {
            setState(() {
              _image = null;

              readEntry(widget.documentId);
              _isEditingText = false;
            })
          }
      },
    );
  }

  ///////////////////////////////////////////////////////////////////////
  /// EDITMODE BUTTON
///////////////////////////////////////////////////////////////////////
  Widget _editButton() {
    return IconButton(
      onPressed: () => {
        tempTitleText = titleText,
        tempEntryText = entryText,
        initSpeechState(),
        if (ownerId == _user.uid || ownerId == "")
          {
            setState(() {
              _isEditingText = true;
            })
          }
      },
      icon: Icon(Icons.edit),
    );
  }

///////////////////////////////////////////////////////////////////////
  /// NEW ENTRY BUTTON
///////////////////////////////////////////////////////////////////////
  Widget _newEntryButton() {
    return IconButton(
      onPressed: () {
        initSpeechState();
        setState(() {
          _isEditingText = true;
          inkling.activeEntry = {
            "title": "### Load More ###",
            "timestamp":
                Timestamp.fromDate(DateTime.parse("1900-01-01 13:27:00")),
            "content": {
              "image": false,
              'text': "filler",
              "spotify": null,
              "artist": null,
              "track": null,
              "albumImage": null,
              "url": null, // to open in spotify
            },
            "shared_with": [],
            "user_name": "",
          };
          if (ownerId != "") {
            MainView.of(context).date = DateTime.now();
          }
          ownerId = "";
          entryText = "";
          titleText = "";
          tempTitleText = "";
          tempEntryText = "";
          _image = null;
          _bucketUrl = '';
          lastWords = "";
          lastError = "";
          lastStatus = "";
          _currentTrack = null;
          _storedTrack = null;
          _trackReady = false;
          _spotifyUrl = null;
          _entryEditingController = TextEditingController(text: entryText);
          _titleEditingController =
              TextEditingController(text: titleText); // = "";
          MainView.of(context).documentIdReference = '';
        });
      },
      icon: Icon(Icons.fiber_new),
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
      },
      onClose: () => print('DIAL CLOSED'),
      tooltip: 'Speed Dial',
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: Colors.pink,
      foregroundColor: Colors.white,
      elevation: 8.0,
      shape: CircleBorder(),
      children: (_isEditingText == true)
          ? ([
              SpeedDialChild(
                child: Icon(Icons.menu_book),
                backgroundColor: Colors.brown,
                label: 'Current Journal: ${inkling.currentJournal}',
                // labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => {
                  // print(inkling.userProfile.keys.toString()),
                  // print(_user.email),
                  _scaffoldKey.currentState.openDrawer(),
                },
              ),
              if (_isEditingText == true) _spotifySpeedDial(),
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
            ])
          : ///////////////////////////////////////////////////////
          /// IF IN VIEW MODE
          ///////////////////////////////////////////////////////
          // ):
          ([
                SpeedDialChild(
                  child: Icon(Icons.menu_book),
                  backgroundColor: Colors.brown,
                  label: 'Current Journal: ${inkling.currentJournal}',
                  // labelStyle: TextStyle(fontSize: 18.0),
                  onTap: () => {
                    // print(inkling.userProfile.keys.toString()),
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
                            print('THIRD CHILD')
                          },
                        )
                      ] +
                      [
                        SpeedDialChild(
                          child: Icon(Icons.restore_from_trash_outlined),
                          backgroundColor: Colors.red,
                          label: 'Delete entry',
                          // labelStyle: TextStyle(fontSize: 18.0),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return _buildDeleteEntryForm();
                              },
                              barrierDismissible: false,
                            );
                          },
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
  Future<void> _addNewEntry() async {
    print(widget.activeDate);
    if (_spotifyUrl != null) {
      print('storedTrack');
      print(_storedTrack);
      print(_storedTrack.artist);
      print(_storedTrack.track);
      print(_storedTrack.imageUrl);
      print(_storedTrack.url);
    }

    Map<String, dynamic> createdEntry = {
      'user_id': _user.uid,
      'user_name': _user.displayName,
      'title': titleText,
      'timestamp': DateTime(widget.activeDate.year, widget.activeDate.month,
                  widget.activeDate.day) !=
              DateTime(
                  DateTime.now().year, DateTime.now().month, DateTime.now().day)
          ? widget.activeDate
          : DateTime.now(),
      'content': {
        'image': (_image != null) ? true : false,
        'text': entryText,
        'spotify': (_spotifyUrl != null) ? _spotifyUrl : null,
      },
      'journal': inkling.currentJournal,
      'shared_with':
          inkling.currentlySharingWith.containsKey(inkling.currentJournal)
              ? inkling.currentlySharingWith[inkling.currentJournal]
              : [],
    };
    dynamic newEntry = await entries
        .add(createdEntry)
        .then((value) => {
              if (_spotifyUrl != null)
                {
                  createdEntry["content"]["track"] = _storedTrack.track,
                  createdEntry["content"]["artist"] = _storedTrack.artist,
                  createdEntry["content"]["albumImage"] = _storedTrack.imageUrl,
                  createdEntry["content"]["url"] = _storedTrack.url,
                },
              setState(() {
                // inkling.lastTimelineFetch = inkling
                // inkling.localDocumentStorage[value.id] = createdEntry;
                // print(inkling.localDocumentStorage[value.id]);
                MainView.of(context).documentIdReference = value.id.toString();
                ownerId = _user.uid;
                inkling.activeEntry = createdEntry;
                // print(inkling.activeEntry.toString());
                // print(ownerId);
                // print(widget.documentId);
                // print(ownerId);
                // print(widget.documentId);
              }),
              if (_image != null)
                {
                  ////
                  // inkling.lastTimelineFetch = null,
                  _storage
                      .ref("${_user.uid}/${value.id}")
                      .putFile(_image)
                      .then((uploadReturn) {
                    _storage
                        .ref(uploadReturn.ref.fullPath)
                        .getDownloadURL()
                        .then((url) {
                      createdEntry["imageUrl"] = url;
                      // setState(() {
                      inkling.orderedListIDMap
                          .forEach((key, value) => value = value + 1);
                      inkling.orderedListIDMap[value.id.toString()] = 0;
                      inkling.orderedList.insert(0, createdEntry);
                    });
                  }).catchError(
                          (error) => print("Failed to upload photo: $error"))
                }
              else
                {
                  setState(() {
                    inkling.orderedListIDMap
                        .forEach((key, value) => value = value + 1);
                    inkling.orderedListIDMap[value.id.toString()] = 0;
                    inkling.orderedList.insert(0, createdEntry);
                  })
                }
            })
        .catchError((error) => print("Failed to add entry: $error"));
  }

///////////////////////////////////////////////////////////////////////
  /// UPDATE DIARY ENTRY
///////////////////////////////////////////////////////////////////////
  Future<void> _overwriteEntry() {
    bool checkPictureUpdate = false;
    if (_image != null) checkPictureUpdate = true;
    if (inkling.activeEntry['content']['image'] == true)
      checkPictureUpdate = true;
    Map<String, dynamic> updatedEntry = {
      'title': titleText,
      'content': {
        'text': entryText,
        'image': checkPictureUpdate,
        'spotify': (_spotifyUrl != null) ? _spotifyUrl : null,
      },
    };
    final int index = inkling.orderedListIDMap[widget.documentId];
    inkling.orderedList[index]['title'] = titleText;
    inkling.orderedList[index]['content'] = {
      'text': entryText,
      'image': checkPictureUpdate,
      'spotify': (_spotifyUrl != null) ? _spotifyUrl : null,
    };

    return entries
        .doc(widget.documentId)
        .update(updatedEntry)
        .then((value) => {
              if (_storedTrack != null)
                {
                  inkling.orderedList[index]["content"]["track"] =
                      _storedTrack.track,
                  inkling.orderedList[index]["content"]["artist"] =
                      _storedTrack.artist,
                  inkling.orderedList[index]["content"]["albumImage"] =
                      _storedTrack.imageUrl,
                  inkling.orderedList[index]["content"]["url"] =
                      _storedTrack.url,
                },
              if (_image != null)
                {
                  // inkling.lastTimelineFetch = null,
                  // inkling.orderedList[index]["imageUrl"] = '',
                  // inkling.orderedList[index]["doc_id"] = widget.documentId,
                  _storage
                      .ref(
                          "${inkling.activeEntry['user_id']}/${widget.documentId}")
                      .putFile(_image)
                      .then((uploadReturn) {
                    _storage
                        .ref(uploadReturn.ref.fullPath)
                        .getDownloadURL()
                        .then((url) {
                      inkling.orderedList[index]["imageUrl"] = url;
                    });
                  }).catchError(
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
      String currentText = _entryEditingController.text;
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
        // print(location);
      }

      //pulls labels from image
      Map<String, double> labelMap = await readLabel(File(pickedFile.path));
      //using the labels pulled, creates a list of related prompt strings
      List<String> generatedText = generateText(labelMap);
      //converts the array of related prompt strings into the prompt tags to be displayed in the alert box
      List tags = mlTagConverter(generatedText);
      print("TAGS: $tags");
      //renders an alertDialog populated with the prompt strings and allows the user to choose prompts. returns
      String selectedTagsString = await createTagAlert(context, tags);
      if (mounted)
        setState(() {
          _image = File(pickedFile.path);
          if (currentText != null || currentText.trim() != '') {
            if (location != null) {
              entryText = currentText +
                  '\n' +
                  selectedTagsString +
                  '\n' +
                  "I went to $location ...  \n";
            } else {
              entryText = currentText + '\n' + selectedTagsString;
            }
          } else if (currentText == null || currentText.trim() == '') {
            if (location != null) {
              entryText =
                  selectedTagsString + "\n" + "I went to $location ...  \n";
            } else {
              entryText = selectedTagsString;
            }
          }

          _entryEditingController = TextEditingController(text: entryText);
        });
    }
  }

///////////////////////////////////////////////////////////////////////
  /// When an Image is selected from Camera
///////////////////////////////////////////////////////////////////////
  _getFromCamera() async {
    String currentText = _entryEditingController.text;
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
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
        if (currentText != null || currentText.trim() != '') {
          if (location != null) {
            entryText = currentText +
                '\n' +
                '\n' +
                selectedTagsString +
                '\n' +
                '\n' +
                "I went to $location ...  \n";
          } else {
            entryText = currentText + '\n' + selectedTagsString;
          }
        } else if (currentText == null || currentText.trim() == '') {
          if (location != null) {
            entryText =
                selectedTagsString + "\n" + "I went to $location ...  \n";
          } else {
            entryText = selectedTagsString;
          }
        }
        _entryEditingController = TextEditingController(text: entryText);
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
          //   print("updating for token $_spotifyToken");
          //   setState(() {
          //     _todaysTracks = [];
          //   });
          //   await _updateLatestSpotifyTrack();
          _selectTrackPopup(context);
        } else {
          _linkSpotifyPopup(context);
        }
      },
    );
  }

  Future<void> _initializeSpotify() async {
    var token = fetchSpotifyToken();
    if (mounted)
      setState(() {
        _spotifyToken = token;
      });

    if (_spotifyToken != null) {
      print("updating for token $_spotifyToken");
      if (mounted)
        setState(() {
          _todaysTracks = [];
        });
    }
    await _updateLatestSpotifyTrack();
  }

  _updateLatestSpotifyTrack() async {
    await loadSpotifyTrack();
    await loadTodaysTracks();
    if (mounted)
      setState(() {
        _todaysTracks = fetchTodaysTracks();
      });
  }

  _selectTrackPopup(context) {
    if (_todaysTracks != null) {
      return Alert(
          context: context,
          title: "Type a song you listened to today:",
          //_todaysTracks[0].track,
          content: //_currentSpotifyTrack(),
              AutoCompleteTextField(
            key: _autoCompleteKey,
            controller: _suggestionTextFieldController,
            clearOnSubmit: false,
            suggestions: _todaysTracks,
            suggestionsAmount: 5,
            decoration: InputDecoration(hintText: _todaysTracks[0].track),
            itemFilter: (item, query) {
              return item.track.toLowerCase().startsWith(query.toLowerCase());
            },
            itemSorter: (a, b) {
              return a.track.compareTo(b.track);
            },
            itemSubmitted: (item) {
              _suggestionTextFieldController.text = item.track;
              setState(() {
                _chosenTrack = item;
              });
              print("chosen track: ${item.track}");
            },
            itemBuilder: (context, item) {
              return new ListTile(
                title: new Text("${item.track}"),
                subtitle: new Text("${item.artist}"),
                leading: Image.network(item.imageUrl, width: 20, height: 20),
              );
            },
          ),
          buttons: [
            DialogButton(
                child: Text("Pick for me"),
                color: Colors.pinkAccent,
                onPressed: () {
                  Random random = new Random();
                  int _randomIndex = random.nextInt(_todaysTracks.length - 1);
                  print("random index: $_randomIndex");
                  setState(() {
                    _spotifyUrl = _todaysTracks[_randomIndex].href;
                  });
                  _getTrackByUrl();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Song added below.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }),
            DialogButton(
                child: Text("Add song"),
                color: Colors.greenAccent,
                onPressed: () {
                  setState(() {
                    _spotifyUrl = _chosenTrack.href;
                  });
                  _getTrackByUrl();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Song added below.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }),
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
                if (mounted)
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
    return _isEditingText
        ? ListTile(
            contentPadding: EdgeInsets.only(right: 80),
            leading:
                Image.network(_storedTrack.imageUrl, width: 70, height: 70),
            title: Text('${_storedTrack.track}'),
            subtitle: Text('${_storedTrack.artist}'),
            isThreeLine: true,
            trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 30.0),
                onPressed: () {
                  // remove widget
                  setState(() {
                    _trackReady = false;
                  });
                }))
        : Padding(
            padding: EdgeInsets.only(bottom: 50),
            child: ListTile(
              leading:
                  Image.network(_storedTrack.imageUrl, width: 70, height: 70),
              title: Text('${_storedTrack.track}'),
              subtitle: Text('${_storedTrack.artist}'),
              isThreeLine: true,
              trailing: IconButton(
                  icon: Icon(Icons.play_circle_fill,
                      color: Colors.green, size: 50.0),
                  onPressed: () {
                    // play in spotify
                    _playSpotifyTrack();
                  }),
            ),
          );
  }

  _getTrackByUrl() async {
    if (_spotifyUrl != null) {
      await getTrackByUrl(_spotifyUrl);
      if (mounted)
        setState(() {
          _storedTrack = fetchStoredTrack();
          _trackReady = true;
        });
    }
  }

  _playSpotifyTrack() async {
    if (_storedTrack.uri != null) {
      await playSpotifyTrack(_storedTrack.uri, _storedTrack.url);
    }
  }

  ///////////////////////////////////////////////////////////////////////
  /// SPOTIFY
///////////////////////////////////////////////////////////////////////

  Widget callAction() {
    if (_isEditingText == true) return _saveButton();
    if (_isEditingText == false && ownerId != _user.uid)
      return _newEntryButton();
    else
      return _editButton();
  }

///////////////////////////////////////////////////////////////////////
  /// DELETE ENTRY
///////////////////////////////////////////////////////////////////////
  Widget _buildDeleteEntryForm() {
    return AlertDialog(
      title: Text("Are you sure to delete $titleText ?"),
      contentPadding: EdgeInsets.all(0.0),
      actions: <Widget>[
        FlatButton(
          child: Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            _deleteEntry();
          },
        ),
        FlatButton(
          child: Text(
            'Cancel',
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  Future<void> _deleteEntry() {
    // deletes from local storage
    final int deleteIndex = inkling.orderedListIDMap[widget.documentId];
    inkling.orderedList.removeAt(deleteIndex);
    // deletes picture from cloud storage
    if (inkling.activeEntry['content']['image']) {
      deletePhoto(widget.documentId);
    }
    // delete entry from firestore and sets the state
    return entries.doc(widget.documentId).delete().then((value) {
      setState(() {
        inkling.activeEntry = {
          "title": "### Load More ###",
          "timestamp":
              Timestamp.fromDate(DateTime.parse("1900-01-01 13:27:00")),
          "content": {
            "image": false,
            'text': "filler",
            "spotify": null,
            "artist": null,
            "track": null,
            "albumImage": null,
            "url": null, // to open in spotify
          },
          "shared_with": [],
          "user_name": "",
        };
        ownerId = "";
        entryText = "";
        titleText = "";
        tempTitleText = "";
        tempEntryText = "";
        _image = null;
        _bucketUrl = '';
        lastWords = "";
        lastError = "";
        lastStatus = "";
        _chosenTrack = null;
        _currentTrack = null;
        _storedTrack = null;
        _trackReady = false;
        _spotifyUrl = null;
        // = "";
        // inkling.localDocumentStorage.remove(widget.documentId);
        MainView.of(context).documentIdReference = '';
      });
      Navigator.of(context).pop();
    });
  }

///////////////////////////////////////////////////////////////////////
  /// MAIN VIEW
///////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    // print(_isEditingText);
    return Scaffold(
      appBar: AppBar(
        //home  edit
        leading: (() {
          if (_isEditingText == true) {
            return _cancelFloatingButton();
          } else {
            return IconButton(
                icon: Icon(Icons.home),
                onPressed: () {
                  widget.liquidController.animateToPage(page: 2, duration: 750);
                });
          }
        })(),
        title: ownerId != _user.uid &&
                inkling.activeEntry['shared_with'].length > 0
            ?
            // Text("Shared Journal")
            (inkling.activeEntry['user_name'] == null)
                ? Text("Shared Journal")
                : Text(
                    "Shared by ${inkling.activeEntry['user_name'].split(" ")[0]}")
            : Text(inkling.currentJournal),
        centerTitle: true,
        actions: [
          callAction(),
        ],
      ),
      // floatingActionButton: Row(children: [
      //   SizedBox(
      //     width: 30,
      //   ),
      //   if (_isEditingText == true) _cancelFloatingButton(),
      //   Spacer(
      //     flex: 1,
      //   ),
      //   if (_isEditingText == false &&
      //       widget.documentId != "" &&
      //       ownerId == _user.uid)
      //     _editFloatingButton(),
      //   if (_isEditingText == true) _saveFloatingButton()
      // ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Scaffold(
        backgroundColor: Colors.orange[200], // background color
        key: _scaffoldKey,
        // resizeToAvoidBottomInset: false,
        drawerEnableOpenDragGesture: false,
        drawer: Scaffold(
            backgroundColor: Colors.transparent,
            body: journalDrawer(
                context,
                inkling.userProfile,
                updateJournal,
                changeActiveJournal,
                updateSharingList,
                updateJournalSharingInDB,
                updateJournalsListName,
                deleteJournal)),
        // body: AnnotatedRegion<SystemUiOverlayStyle>(
        // value: SystemUiOverlayStyle.light,
        body: widget.documentId == "" && _isEditingText == false
            ? Center(
                child: Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          image: DecorationImage(
                            image: AssetImage('assets/place.jpg'),
                            // width: double.infinity,
                            fit: BoxFit.cover,
                          )), // color: Colors.redAccent,
                      // ),
                      alignment: Alignment.center,
                      // child: Image(
                      //   image: AssetImage('assets/place.jpg'),
                      //   // height: 250,
                      //   width: double.infinity,
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                    Container(
                        alignment: Alignment.center,
                        child: FlatButton(
                          onPressed: () {
                            initSpeechState();
                            setState(() {
                              _isEditingText = true;
                              inkling.activeEntry = {
                                "title": "### Load More ###",
                                "timestamp": Timestamp.fromDate(
                                    DateTime.parse("1900-01-01 13:27:00")),
                                "content": {
                                  "image": false,
                                  'text': "filler",
                                  "spotify": null,
                                  "artist": null,
                                  "track": null,
                                  "albumImage": null,
                                  "url": null, // to open in spotify
                                },
                                "shared_with": [],
                                "user_name": "",
                              };
                              if (ownerId != "") {
                                MainView.of(context).date = DateTime.now();
                              }
                              ownerId = "";
                              entryText = "";
                              titleText = "";
                              tempTitleText = "";
                              tempEntryText = "";
                              _image = null;
                              _bucketUrl = '';
                              lastWords = "";
                              lastError = "";
                              lastStatus = "";
                              _currentTrack = null;
                              _storedTrack = null;
                              _trackReady = false;
                              _spotifyUrl = null;
                              _entryEditingController =
                                  TextEditingController(text: entryText);
                              _titleEditingController = TextEditingController(
                                  text: titleText); // = "";
                              MainView.of(context).documentIdReference = '';
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ), //side: BorderSide(color: Colors.white, width: 4)),
                          // shape: StadiumBorder(),//Border.all(width: 5.0, color: Colors.white),
                          color: Colors.orange[300],
                          child: Text(
                            'Tap new,\n and create a new entry\n\n${dateToHumanReadable(widget.activeDate).substring(0, dateToHumanReadable(widget.activeDate).indexOf(' at'))}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 30.0,
                              shadows: [
                                Shadow(
                                    // bottomLeft
                                    offset: Offset(-1.5, -1.5),
                                    color: Colors.black),
                                Shadow(
                                    // bottomRight
                                    offset: Offset(1.5, -1.5),
                                    color: Colors.black),
                                Shadow(
                                    // topRight
                                    offset: Offset(1.5, 1.5),
                                    color: Colors.black),
                                Shadow(
                                    // topLeft
                                    offset: Offset(-1.5, 1.5),
                                    color: Colors.black),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              )
            : Container(
                margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                decoration: BoxDecoration(
                    // color: Colors.white, // background color
                    ),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0)),
                  child: ListView(
                    children: <Widget>[
                      // if image is null
                      _image == null
                          ? (_bucketUrl == ''
                              // if no image is being loaded from the DB
                              ? Stack(
                                  children: <Widget>[
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              3,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8.0)),
                                          image: DecorationImage(
                                            image: AssetImage(
                                                'assets/addphoto.jpg'),
                                            fit: BoxFit.cover,
                                          )),
                                      alignment: Alignment.center,
                                    ),
                                    Container(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                3,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Tell more of your journey\nwith a photo.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28.0,
                                            shadows: [
                                              Shadow(
                                                  // bottomLeft
                                                  offset: Offset(-1.5, -1.5),
                                                  color: Colors.black),
                                              Shadow(
                                                  // bottomRight
                                                  offset: Offset(1.5, -1.5),
                                                  color: Colors.black),
                                              Shadow(
                                                  // topRight
                                                  offset: Offset(1.5, 1.5),
                                                  color: Colors.black),
                                              Shadow(
                                                  // topLeft
                                                  offset: Offset(-1.5, 1.5),
                                                  color: Colors.black),
                                            ],
                                          ),
                                        )),
                                  ],
                                )

                              // Image.asset(
                              //     'assets/Inkling_Login.png',
                              //     width: MediaQuery.of(context).size.width - 20,
                              //     semanticLabel: "Inkling Logo",
                              //   )
                              // if an image is being loaded from the DB
                              : FadeInImage(
                                  image: NetworkImage(_bucketUrl),
                                  placeholder: AssetImage(
                                      "assets/placeholder_transparent.gif"),
                                  fit: BoxFit.cover))
                          // if image is has been selected
                          : Image.file(
                              _image,
                              fit: BoxFit.cover,
                            ),
                      SizedBox(height: MediaQuery.of(context).size.height / 30),
                      Center(
                        child: Text(
                          dateToHumanReadable(widget.activeDate) +
                              (inkling.activeEntry['user_id'] != _user.uid &&
                                      inkling.activeEntry['shared_with']
                                              .length >
                                          0
                                  ? (inkling.activeEntry['user_name'] == null)
                                      ? " - shared entry"
                                      : " - shared by ${inkling.activeEntry['user_name'].split(" ")[0]}"
                                  : ''),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 30),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                        child: Center(
                          child: _entryText(),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 50),
                      if (_trackReady) _storedSpotifyTrack(),
                      SizedBox(height: MediaQuery.of(context).size.height / 50),

                      // if (_isEditingText == false && ownerId != _user.uid)
                      //   Center(
                      //     // alignment: FractionalOffset.bottomRight,
                      //     child: FlatButton(
                      //       color: Colors.purpleAccent,
                      //       child: Padding(
                      //         padding: const EdgeInsets.all(8.0),
                      //         child: Text(
                      //           buttonText,
                      //           style: TextStyle(fontSize: 25, color: Colors.white),
                      //         ),
                      //       ),
                      //       // elevation: 5,
                      //       shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(40)),
                      //       onPressed: () {
                      //         initSpeechState();
                      //         setState(() {
                      //           // tempTitleText = titleText;
                      //           // tempEntryText = entryText;
                      //           _isEditingText = true;

                      //           inkling.activeEntry = null;
                      //           if (ownerId != "") {
                      //             MainView.of(context).date = DateTime.now();
                      //           }
                      //           ownerId = "";
                      //           entryText = "";
                      //           titleText = "";
                      //           tempTitleText = "";
                      //           tempEntryText = "";
                      //           _image = null;
                      //           _bucketUrl = '';
                      //           lastWords = "";
                      //           lastError = "";
                      //           lastStatus = "";
                      //           _currentTrack = null;
                      //           _storedTrack = null;
                      //           _trackReady = false;
                      //           _spotifyUrl = null;
                      //           _entryEditingController =
                      //               TextEditingController(text: entryText);
                      //           _titleEditingController =
                      //               TextEditingController(text: titleText); // = "";
                      //           MainView.of(context).documentIdReference = '';
                      //         });
                      //       },
                      //     ),
                      //   ),
                      // SizedBox(height: MediaQuery.of(context).size.height / 20),
                    ],
                  ),
                ),
              ),
        floatingActionButton: speedDial(),
      ), // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
    // );
  }
}
// setState(() {
//   _isEditingText = true;
//   buttonText = "Save";
//   _entryEditingController =
//       TextEditingController(text: entryText);
//   _titleEditingController =
//       TextEditingController(text: titleText);
//   inkling.activeEntry = null;
//   ownerId = "";
//   entryText = "";
//   titleText = "";
//   tempTitleText = "";
//   tempEntryText = "";
//   _image = null;
//   _bucketUrl = '';
//   lastWords = "";
//   lastError = "";
//   lastStatus = "";
//   _currentTrack = null;
//   _storedTrack = null;
//   _trackReady = false;
//   _spotifyUrl = null; // = "";
//   MainView.of(context).documentIdReference = '';
// });
