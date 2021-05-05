import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

String errorMsg = "";

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<String> signInWithGoogle() async {
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
    return '$user';
  }

  return null;
}

Future<String> emailLogin(_email, _password) async {
  String message;

  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _email, password: _password);
    final User user = userCredential.user;
    message = '$user';
  } on FirebaseAuthException catch (e) {
    errorMsg = "$e";
  } catch (e) {
    errorMsg = "$e";
  }
  return message;
}

Future<String> signUpWithEmailAndPassword(
    String _email, String _password) async {
  String message;
  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email, password: _password);
    final User user = userCredential.user;

    message = '$user';
  } on FirebaseAuthException catch (e) {
    errorMsg = '$e';
  } catch (e) {
    errorMsg = '$e';
  }
  return message;
}

Future<String> getCurrentUserUid() async {
  String uid;
  var user = _auth.currentUser;
  uid = user.uid;
  return uid;
}

String getCurrentUserEmail() {
  String email;
  var user = _auth.currentUser;
  email = user.email;
  return email;
}

Future<String> getCurrentUserName() async {
  String name;
  var user = _auth.currentUser;
  if (user.displayName != null) {
    name = user.displayName;
  } else {
    name = '';
  }
  return name;
}

String getCurrentUserImageUrl() {
  String imageUrl;
  var user = _auth.currentUser;
  if (user.photoURL != null) {
    imageUrl = user.photoURL;
  } else {
    imageUrl = 'https://picsum.photos/200';
  }

  return imageUrl;
}

Future<void> signOutGoogle() async {
  await FirebaseAuth.instance.signOut();
}
