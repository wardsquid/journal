import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'LocalNotificationManager.dart';
import 'userInfo.dart' as inkling;

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseMessaging _messaging = FirebaseMessaging.instance;

Future<String> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    getReminder();
    return 'done';
  } catch (error) {
    return error;
  }
}

Future<void> getReminder() async {
  CollectionReference users = getFireStoreUsersDB();
  User currentUser = checkUserLoginStatus();
  var reminderTime;

  users
      .doc(currentUser.uid)
      .snapshots()
      .listen((DocumentSnapshot documentSnapshot) {
    Timestamp data = documentSnapshot.data()["reminder"];
    if (data != null) {
      reminderTime = DateTime.parse(data.toDate().toString());
      print("data from snapshot: $reminderTime");
      notificationPlugin.showDailyAtTime(reminderTime);
    }
  }).onError((error) => {print("Error getting reminder: $error")});
}

User checkUserLoginStatus() {
  if (_auth.currentUser != null) {
    return _auth.currentUser;
  } else {
    return null;
  }
}

Future<FirebaseMessaging> setUpNotifications() async {
  NotificationSettings settings = await _messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
  return _messaging;
}

FirebaseFunctions getFunction() {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  return _functions;
}

FirebaseStorage getStorage() {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  return _storage;
}

CollectionReference getFireStoreEntriesDB() {
  CollectionReference entries =
      FirebaseFirestore.instance.collection('entries');
  return entries;
}

CollectionReference getFireStoreUsersDB() {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  return users;
}

Future<void> addUser() async {
  CollectionReference users = getFireStoreUsersDB();
  User currentUser = checkUserLoginStatus();
  final bool doesUserExist = await checkUserExists();
  if (doesUserExist == false) {
    users.doc(currentUser.uid).set({
      'journals_list': ["Personal"],
      'reminder': null,
      'sharing_info': {},
      'friends': [],
    }).then((value) async {
      await inkling.initializeUserCaching();
      print("Successfully added user $currentUser");
    }).catchError((error) => {print("Failed to add user: $error")});
  } else {
    if (inkling.userProfile == null) await inkling.initializeUserCaching();
  }
}

Future<bool> checkUserExists() async {
  bool exists = false;
  CollectionReference users = getFireStoreUsersDB();
  User currentUser = checkUserLoginStatus();
  users.doc(currentUser.uid).get().then((DocumentSnapshot documentSnapshot) {
    if (documentSnapshot.exists) {
      print('User exists');
      exists = true;
    } else {
      print('User does not exist on the database');
      exists = false;
    }
  }).catchError(
      (error) => {print('Error occured while checking for user $currentUser')});

  return (exists);
}

dynamic checkFriendEmail(String email) async {
  final HttpsCallable httpsCallable =
      FirebaseFunctions.instance.httpsCallable("checkFriendEmail");
  final results = await httpsCallable.call({"email": email});
  return results.data;
}

getUserProfile() async {
  User currentUser = checkUserLoginStatus();
  CollectionReference users = getFireStoreUsersDB();
  DocumentSnapshot userProfile = await users.doc(currentUser.uid).get();
  return userProfile;
}
/*
  How to use checkFriendEmail
  bool your_variable_name = await checkFriendEmail("insert email string here");
  print("friends exist = ${your_variable_name}");
*/

/////////////////////////////////////////////
/// ADD NEW JOURNAL
/////////////////////////////////////////////
// Future<bool> addNewJournal(String title) async {
//   CollectionReference users = getFireStoreUsersDB();
//   User currentUser = checkUserLoginStatus();
//   try {
//     users.doc(currentUser.uid).update({
//       'journals_list': FieldValue.arrayUnion([title])
//     });
//     return true;
//   } catch (error) {
//     return false;
//   }
// }

/////////////////////////////////////////////
/// ADD NEW JOURNAL
/////////////////////////////////////////////
Future<bool> addJournalToDB(List<dynamic> journalList) async {
  CollectionReference users = getFireStoreUsersDB();
  User currentUser = checkUserLoginStatus();
  try {
    users.doc(currentUser.uid).update({'journals_list': journalList});
    return true;
  } catch (error) {
    return false;
  }
}

/////////////////////////////////////////////
/// UPDATE JOURNAL SHARING
/////////////////////////////////////////////
Future<bool> updateJournalSharing(
    Map<String, dynamic> updatedSharingInfo) async {
  CollectionReference users = getFireStoreUsersDB();
  User currentUser = checkUserLoginStatus();
  try {
    users.doc(currentUser.uid).update({'sharing_info': updatedSharingInfo});
    return true;
  } catch (error) {
    return false;
  }
}

Future<bool> updateJournalSharingCascade() {}
Future<bool> deleteJournalEntriesCascade() {}
Future<bool> deleteJournalUser() {}

Future<bool> deletePhoto(String documentId) async {
  final FirebaseStorage _storage = getStorage();
  try {
    _storage.ref("${_auth.currentUser.uid}/$documentId").delete();
    return true;
  } catch (error) {
    return false;
  }
}
