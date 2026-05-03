import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserModel?> get currentUserModelStream {
    return _auth.authStateChanges().asyncExpand((User? user) {
      if (user == null) return Stream.value(null);
      return _db.collection('users').doc(user.uid).snapshots().map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      });
    });
  }

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
    String? invitedByCode,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newReferralCode = const Uuid().v4().substring(0, 8).toUpperCase();
      await _db.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'nickname': nickname,
        'photoUrl': '',
        'age': age,
        'gender': gender,
        'interests': [],
        'isAnonymous': false,
        
        'isVerified': false,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'referralCode': newReferralCode,
      }, SetOptions(merge: true));
      // NOTE: Referral processing is handled centrally in root_screen.dart
      // after auth completes, reading from SharedPreferences 'pending_referral'
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
          
          'isVerified': false,
          'isAdmin': false,
          'blockedUsers': [],
          'swipesToday': 0,
          'referralCode': const Uuid().v4().substring(0, 8).toUpperCase(),
        }, SetOptions(merge: true));
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    }
  }

  Future<UserCredential?> signInWithGoogle(String? invitedByCode) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _handleSocialCredential(credential);
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithApple(String? invitedByCode) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      return await _handleSocialCredential(oauthCredential);
    } catch (e) {
      print('Apple sign in error: $e');
      return null;
    }
  }

  Future<UserCredential> _handleSocialCredential(AuthCredential credential) async {
    final result = await _auth.signInWithCredential(credential);
    final doc = await _db.collection('users').doc(result.user!.uid).get();
    if (!doc.exists) {
      final newReferralCode = const Uuid().v4().substring(0, 8).toUpperCase();
      await _db.collection('users').doc(result.user!.uid).set({
        'name': result.user!.displayName ?? 'User',
        'nickname': '',
        'photoUrl': result.user!.photoURL ?? '',
        'age': 18,
        'gender': 'Unknown',
        'interests': [],
        'isAnonymous': false,
        
        'isVerified': false,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'referralCode': newReferralCode,
      }, SetOptions(merge: true));
      // NOTE: Referral processing is handled centrally in root_screen.dart
    }
    return result;
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
        
        'isVerified': false,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'referralCode': const Uuid().v4().substring(0, 8).toUpperCase(),
      }, SetOptions(merge: true));
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
