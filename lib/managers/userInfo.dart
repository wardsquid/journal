library inkling.globals;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Firebase.dart';

// bool isLoggedIn = false;
Map<String, dynamic> userProfile;
Map<String, dynamic> activeEntry = {
  "title": "### Load More ###",
  "timestamp": Timestamp.fromDate(DateTime.parse("1900-01-01 13:27:00")),
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
String currentJournal;
Map<String, dynamic> currentlySharingWith;
// Map<String, dynamic> localDocumentStorage = {};
DateTime
    lastTimelineFetch; //= DateTime.now().subtract(new Duration(minutes: 5));
DateTime
    lastCalendarFetch; //= DateTime.now().subtract(new Duration(minutes: 5));
List<Map<String, dynamic>> orderedList = [];
Map<String, int> orderedListIDMap = {};

Future<void> initializeUserCaching() async {
  currentJournal = null;
  User current = checkUserLoginStatus();
  // print(current.toString());
  if (current == null)
    return null;
  else {
    CollectionReference userDB = getFireStoreUsersDB();
    DocumentSnapshot userInfo = await userDB.doc(current.uid).get();
    userProfile = userInfo.data();
    currentlySharingWith = userProfile['sharing_info'];
    updateJournal();
  }
}

void updateJournal() {
  currentJournal = userProfile['journals_list'][0].toString();
}

// void addToLocalStorage(String documentId, Map<String, dynamic> document) {
//   // print(documentId);
//   // print(document);
//   localDocumentStorage[documentId] = document;
// }
///////////////////////////////////////////////
/// import 'userInfo.dart' as inkling;
/// inkling.userProfile
///
