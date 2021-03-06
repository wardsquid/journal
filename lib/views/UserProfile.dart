import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'LoginPage.dart';
import '../managers/SignIn.dart';
import '../managers/Firebase.dart';
import '../managers/LocalNotificationManager.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkable/linkable.dart';
import '../managers/userInfo.dart' as inkling;
import 'package:liquid_swipe/liquid_swipe.dart';

class UserProfile extends StatefulWidget {
  final User currentUser = checkUserLoginStatus();
  LiquidController liquidController;
  UserProfile({this.liquidController});
  @override
  _UserProfile createState() => new _UserProfile(currentUser);
}

class _UserProfile extends State<UserProfile> {
  User currentUser;
  LiquidController liquidController;

  _UserProfile(this.currentUser);
  TimeOfDay reminderTime;
  bool isTimeSet = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  final CollectionReference users = getFireStoreUsersDB();
  final User _user = checkUserLoginStatus();
  String _email = "";
  String _name = "";
  List<dynamic> friends = [];
  List<bool> _friendsChecked = [];
  int _selectedFriendIndex = 0;
  String _selectedFriendEmail = "";
  String _selectedFriendName = "";
  bool _isDeleteButtonDisabled = true;
  Map<String, dynamic> _sharingInfo;

  @override
  void initState() {
    super.initState();
    notificationPlugin.setOnNotificationClick(onNotificationClick);
    _getNewFriends();
  }

  Future<void> _getNewFriends() async {
    await users
        .doc(_user.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) => {
              setState(() {
                friends = documentSnapshot.data()["friends"];
                for (var i = 0; i < friends.length; i++) {
                  _friendsChecked.add(false);
                }
                inkling.userProfile["friends"] = friends;
              })
            });
  }

  _openReminderPopup(context) {
    final format = DateFormat("HH:mm");
    return Alert(
        context: context,
        title: "Set a daily reminder",
        content: Column(
          children: <Widget>[
            DateTimeField(
              format: format,
              onShowPicker: (context, currentValue) async {
                final time = await showTimePicker(
                  context: context,
                  initialTime:
                      TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
                );
                reminderTime = time;
                isTimeSet = true;
                // debug reminder
                // print("reminder time set to  " + reminderTime.toString());
                return DateTimeField.convert(time);
              },
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () {
              Navigator.pop(context);
              if (isTimeSet) {
                updateReminder(reminderTime);
                isTimeSet = false;
              }
            },
            child: Text(
              "Save",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }

  Future<void> _addFriend() async {
    Map<String, dynamic> friend = {'name': _name, 'email': _email};
    bool yourVariableName = await checkFriendEmail(_email);
    if (yourVariableName) {
      for (var element in friends) {
        if (element['email'] == _email)
          return showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('You are already friends with $_email.'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
      }
      return users.doc(_user.uid).update({
        'friends': FieldValue.arrayUnion([friend])
      }).then((value) => {
            // add user to local copy
            _getNewFriends(),
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Friend added!'),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            )
          });
    } else {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Email does not exist.'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Please enter a valid email.'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _deleteFriend() async {
    return users.doc(_user.uid).update({
      'friends': FieldValue.arrayRemove([
        {'email': _selectedFriendEmail, "name": _selectedFriendName}
      ])
    }).then((value) {
      _getNewFriends();
      _sharingInfo = inkling.userProfile["sharing_info"];
      for (String key in _sharingInfo.keys) {
        _sharingInfo[key] = _sharingInfo[key]
            .where((email) => email != _selectedFriendEmail)
            .toList();
      }
      return users
          .doc(_user.uid)
          .update({'sharing_info': _sharingInfo}).then((value) => {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false, // user must tap button!
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Successfully Deleted!'),
                      actions: <Widget>[
                        FlatButton(
                          child: Text('Close'),
                          onPressed: () {
                            _friendsChecked[_selectedFriendIndex] = false;
                            _selectedFriendName = "";
                            _selectedFriendEmail = "";
                            _isDeleteButtonDisabled = true;
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                )
              });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF2C4096),
        appBar: AppBar(
          backgroundColor: Color(0xFFf2296a),
          leading: IconButton(
            splashColor: Colors.orange[300],
            highlightColor: Colors.orange[300],
            hoverColor: Colors.orange[300],
            icon: Icon(Icons.home),
            onPressed: () {
              widget.liquidController.animateToPage(page: 2, duration: 750);
            },
          ),
          title: Text("User Profile"),
          centerTitle: true,
          actions: [
            IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  widget.liquidController.animateToPage(page: 3, duration: 750);
                }),
          ],
        ),
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(color: Color(0xFF2C4096)),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            currentUser.photoURL,
                          ),
                          radius: 60,
                          backgroundColor: Colors.transparent,
                        ),
                        SizedBox(height: 30),
                        Text(
                          'NAME',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54),
                        ),
                        Text(
                          currentUser.displayName,
                          style: TextStyle(
                              fontSize: 25,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'EMAIL',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54),
                        ),
                        Text(
                          currentUser.email, //email,
                          style: TextStyle(
                              fontSize: 25,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 30),
                        RaisedButton(
                          splashColor: Colors.orange[300],
                          highlightColor: Colors.orange[300],
                          hoverColor: Colors.orange[300],
                          onPressed: () async {
                            _openReminderPopup(context);
                          },
                          color: Color(0xFF13cf96),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Set Reminder',
                              style:
                                  TextStyle(fontSize: 25, color: Colors.white),
                            ),
                          ),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40)),
                        ),
                        SizedBox(height: 30),
                        RaisedButton(
                          color: Color(0xFF8BBFE3),
                          splashColor: Colors.orange[300],
                          highlightColor: Colors.orange[300],
                          hoverColor: Colors.orange[300],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Friends',
                              style:
                                  TextStyle(fontSize: 25, color: Colors.white),
                            ),
                          ),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40)),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return _buildFriendsList();
                                },
                                barrierDismissible: false);
                          },
                        ),
                        SizedBox(height: 30),
                        RaisedButton(
                          splashColor: Colors.orange[300],
                          highlightColor: Colors.orange[300],
                          hoverColor: Colors.orange[300],
                          onPressed: () {
                            inkling.orderedListIDMap = {};
                            inkling.orderedList = [];
                            inkling.lastTimelineFetch = null;
                            signOutGoogle();
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) {
                              return LoginPage();
                            }), ModalRoute.withName('/'));
                          },
                          color: Color(0xFFf2296a),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Sign Out',
                              style:
                                  TextStyle(fontSize: 25, color: Colors.white),
                            ),
                          ),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(bottom: 10, right: 10),
                child: InkWell(
                  child: Text("Privacy Policy",
                      style: TextStyle(fontSize: 15, color: Colors.white54)),
                  onTap: () =>
                      launch("https://sites.google.com/view/inkling-policy"),
                ),
              )
            ],
          ),
        ));
  }

  Widget _buildFriendsList() {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        title: Text("Your Friends:"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Divider(),
              Container(
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (BuildContext buildContext, int index) =>
                      CheckboxListTile(
                          title: Text("${friends[index]["name"]}"),
                          subtitle: Text("${friends[index]["email"]}"),
                          value: _friendsChecked[index],
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.red,
                          checkColor: Colors.white,
                          onChanged: (bool value) {
                            setState(() {
                              _friendsChecked[_selectedFriendIndex] = false;
                              _friendsChecked[index] = value;
                              _selectedFriendEmail = friends[index]["email"];
                              _selectedFriendName = friends[index]["name"];
                              _selectedFriendIndex = index;
                              if (_friendsChecked.contains(true)) {
                                _isDeleteButtonDisabled = false;
                              } else {
                                _isDeleteButtonDisabled = true;
                              }
                            });
                          }),
                  shrinkWrap: true,
                ),
              ),
              Divider(),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
              child: Text("Add"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildAddFriendForm();
                  },
                  barrierDismissible: false,
                );
              }),
          FlatButton(
              child: Text("Delete",
                  style: TextStyle(
                    color: _isDeleteButtonDisabled ? Colors.grey : Colors.red,
                  )),
              onPressed: _isDeleteButtonDisabled
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return _buildDeleteFriendForm();
                        },
                        barrierDismissible: false,
                      );
                    }),
          FlatButton(
            child: Text(
              'Close',
              style: TextStyle(fontSize: 15),
            ),
            onPressed: () {
              if (_friendsChecked.length > 0) {
                _friendsChecked[_selectedFriendIndex] = false;
              }
              _selectedFriendName = "";
              _selectedFriendEmail = "";
              _isDeleteButtonDisabled = true;
              Navigator.of(context).pop();
            },
          )
        ],
      );
    });
  }

  Widget _buildAddFriendForm() {
    return AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      content: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextFormField(
                    autofocus: true,
                    controller: _nameController,
                    onSaved: (String value) {
                      setState(() {
                        _name = value;
                      });
                      _nameController.clear();
                    },
                    decoration: InputDecoration(
                      hintText: "Name",
                      suffixIcon: IconButton(
                        onPressed: () => _nameController.clear(),
                        icon: Icon(Icons.clear),
                      ),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _emailController,
                    onChanged: (text) {},
                    onSaved: (String value) {
                      setState(() {
                        _email = value;
                      });
                      _addFriend();
                      _emailController.clear();
                    },
                    decoration: InputDecoration(
                      hintText: "Email Address",
                      suffixIcon: IconButton(
                        onPressed: () => _emailController.clear(),
                        icon: Icon(Icons.clear),
                      ),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    child: Text("Add"),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(
            'Close',
            style: TextStyle(fontSize: 15),
          ),
          onPressed: () {
            if (_friendsChecked.length > 0) {
              _friendsChecked[_selectedFriendIndex] = false;
            }
            _selectedFriendName = "";
            _selectedFriendEmail = "";
            _isDeleteButtonDisabled = true;
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  Widget _buildDeleteFriendForm() {
    return AlertDialog(
      title: Text("Are you sure you want to delete $_selectedFriendName?"),
      contentPadding: EdgeInsets.all(0.0),
      actions: <Widget>[
        FlatButton(
          child: Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            _deleteFriend();
          },
        ),
        FlatButton(
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: 15),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  setNotification(DateTime reminderTime) async {
    await notificationPlugin.showDailyAtTime(reminderTime);
  }

  onNotificationClick(String payload) {
    print('Payload: $payload');
  }

  updateReminder(TimeOfDay reminderTime) {
    final CollectionReference users = getFireStoreUsersDB();
    var now = DateTime.now();
    var dt = DateTime(
        7777, now.month, now.day, reminderTime.hour, reminderTime.minute);
    users
        .doc(currentUser.uid)
        .update({'reminder': dt})
        .then((value) =>
            print("Updated ${currentUser.displayName}'s reminder to $dt"))
        .catchError((error) => print("Failed to update reminder time: $error"));

    setNotification(dt);
  }
}
