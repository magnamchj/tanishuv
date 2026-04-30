import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting user data: $e');
    }
    return null;
  }

  // --- Email/Password Auth ---
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    }
  }

  Future<String?> createUserWithEmail({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required int age,
    required String gender,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _db.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'nickname': nickname,
        'photoUrl': '',
        'age': age,
        'gender': gender,
        'interests': [],
        'isAnonymous': false,
        'isPremium': false,
        'isVerified': false,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
      });
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    }
  }

  // --- Phone Auth ---
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerified,
    required Function(FirebaseAuthException) onError,
    required Function(String, int?) onCodeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerified,
      verificationFailed: onError,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<String?> signInWithOTP(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      // Create user doc if new
      final doc = await _db.collection('users').doc(result.user!.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(result.user!.uid).set({
          'name': 'User',
          'nickname': result.user!.phoneNumber ?? '',
          'photoUrl': '',
          'age': 18,
          'gender': 'Unknown',
          'interests': [],
          'isAnonymous': false,
          'isPremium': false,
          'isVerified': false,
          'isAdmin': false,
          'blockedUsers': [],
          'swipesToday': 0,
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    }
  }

  // --- Anonymous ---
  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'name': 'Anonymous User',
        'nickname': 'Anon',
        'photoUrl': '',
        'age': 18,
        'gender': 'Unknown',
        'interests': [],
        'isAnonymous': true,
        'isPremium': false,
        'isVerified': false,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
      });
      return userCredential;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
