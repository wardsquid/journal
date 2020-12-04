import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'LoginPage.dart';
import '../managers/SignIn.dart';
import '../managers/Firebase.dart';
import '../managers/LocalNotificationManager.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkable/linkable.dart';

class UserProfile extends StatefulWidget {
  final User currentUser = checkUserLoginStatus();
  @override
  _UserProfile createState() => new _UserProfile(currentUser);
}

class _UserProfile extends State<UserProfile> {
  User currentUser;
  _UserProfile(this.currentUser);
  TimeOfDay reminderTime;
  bool isTimeSet = false;
  final _formKey = GlobalKey<FormState>();
  var _emailController = TextEditingController();
  var _nameController = TextEditingController();
  final CollectionReference users = getFireStoreUsersDB();
  final User _user = checkUserLoginStatus();
  String _email = "";
  String _name = "";
  List<dynamic> friends = [];

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
                print("reminder time set to  " + reminderTime.toString());
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
    print("friends exist = $yourVariableName");
    if (yourVariableName) {
      return users.doc(_user.uid).update({
        'friends': FieldValue.arrayUnion([friend])
      }).then((value) => {
            _getNewFriends(),
            showDialog<void>(
              context: context,
              barrierDismissible: false, // user must tap button!
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Successfully Added!'),
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
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('The Email address does not exist.'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Please input correctly.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
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
              CircleAvatar(
                backgroundImage: NetworkImage(
                  currentUser.photoURL,
                ),
                radius: 60,
                backgroundColor: Colors.transparent,
              ),
              SizedBox(height: 40),
              Text(
                'NAME',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
              Text(
                currentUser.displayName,
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'EMAIL',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
              Text(
                currentUser.email, //email,
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              RaisedButton(
                onPressed: () async {
                  _openReminderPopup(context);
                },
                color: Colors.deepPurple,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Set Reminder',
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
              ),
              SizedBox(height: 40),
              RaisedButton(
                onPressed: () {
                  signOutGoogle();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) {
                    return LoginPage();
                  }), ModalRoute.withName('/'));
                },
                color: Colors.deepPurple,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
              ),
              SizedBox(height: 40),
              RaisedButton(
                color: Colors.deepPurple,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Friends',
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                ),
                elevation: 5,
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
              SizedBox(height: 80),
              Linkable(
                linkColor: Colors.white,
                textColor: Colors.deepPurple,
                text:
                    "Privacy Policy: \nhttps://sites.google.com/view/inkling-policy",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      title: Text("Your Friends:"),
      content: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 350,
                width: 300,
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (BuildContext buildContext, int index) =>
                      ListTile(
                    title: Text(
                        "${friends[index]["name"]} \n ${friends[index]["email"]}"),
                  ),
                  shrinkWrap: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(
                  child: Text("Add"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return _buildAddFriendForm();
                      },
                      barrierDismissible: false,
                    );
                  },
                ),
              ),
            ],
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
            Navigator.of(context).pop();
          },
        )
      ],
    );
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
                    controller: _emailController,
                    onSaved: (String value) {
                      setState(() {
                        _name = value;
                      });
                      _emailController.clear();
                    },
                    decoration: InputDecoration(
                      hintText: "Name",
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
                  padding: EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _nameController,
                    onChanged: (text) {},
                    onSaved: (String value) {
                      setState(() {
                        _email = value;
                      });
                      _addFriend();
                      _nameController.clear();
                    },
                    decoration: InputDecoration(
                      hintText: "Email Address",
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
            Navigator.of(context).pop();
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
