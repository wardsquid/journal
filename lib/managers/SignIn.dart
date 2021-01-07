import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../managers/Firebase.dart';
import './userInfo.dart' as inkling;

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<User> signInWithGoogle() async {
  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final UserCredential authResult =
      await _auth.signInWithCredential(credential);
  final User user = authResult.user;

  if (user != null) {
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);
    assert(user.email != null);
    assert(user.displayName != null);
    assert(user.photoURL != null);

    final User currentUser = _auth.currentUser;
    assert(user.uid == currentUser.uid);

    // Check if user already exists in FireStore
    // bool userExists = await checkUserExists();
    // if (!userExists) {
    await addUser();
    // await inkling.initializeUserCaching();
    // }

    return currentUser;
  }

  return null;
}

Future<void> signOutGoogle() async {
  await googleSignIn.signOut();
}
