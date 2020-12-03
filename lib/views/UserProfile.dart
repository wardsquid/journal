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

  @override
  void initState() {
    super.initState();
    notificationPlugin.setOnNotificationClick(onNotificationClick);
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
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Positioned(
                                right: -40.0,
                                top: -40.0,
                                child: InkResponse(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: CircleAvatar(
                                    child: Icon(Icons.close),
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ),
                              Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'EMAIL ADDRESS:',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        onSaved: (String value) {
                                          print(value);
                                        },
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
                                        child: Text("Send"),
                                        onPressed: () {
                                          if (_formKey.currentState
                                              .validate()) {
                                            _formKey.currentState.save();
                                          }
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                },
                color: Colors.deepPurple,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Add Friend',
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
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
