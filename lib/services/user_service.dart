import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

// Lab Activity 5: Firebase Authentication is the identity of the account.
// Lab Activity 6: the profile lives in the Firestore `Users` collection and
// its document id is the Firebase Authentication UID.
class HusseinAdvmobprogUserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('Users');

  // Sign in with an email address or a username
  Future<HusseinAdvmobprogUser> signIn(
    String usernameOrEmail,
    String password,
  ) async {
    final input = usernameOrEmail.trim();

    if (input.isEmpty || password.isEmpty) {
      throw Exception('Username/email and password are required.');
    }

    try {
      final email =
          input.contains('@') ? input : await _emailFromUsername(input);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user!;
      final existing = await _readProfile(firebaseUser);

      // Refresh the same profile document instead of creating a duplicate
      await _writeProfile(existing);
      return existing;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  // Keep login as another option for the same sign-in function
  Future<HusseinAdvmobprogUser> login(String username, String password) {
    return signIn(username, password);
  }

  // Create a new Firebase account and its Firestore profile
  Future<HusseinAdvmobprogUser> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String emailAddress,
    required String password,
    String loginType = 'User',
  }) async {
    final cleanUsername = username.trim();
    final cleanEmail = emailAddress.trim();

    if (cleanUsername.isEmpty || cleanEmail.isEmpty || password.isEmpty) {
      throw Exception('Username, email, and password are required.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(cleanUsername);

      final user = HusseinAdvmobprogUser(
        id: 0,
        uid: firebaseUser.uid,
        username: cleanUsername,
        email: cleanEmail,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        gender: '',
        image: '',
        age: age,
        contactNo: contactNo.trim(),
        loginType: loginType,
      );

      await _writeProfile(user);

      // Sign-up ends on the sign-in screen, so the new session is closed
      await _auth.signOut();
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  // Get the currently logged-in user (fresh from Firestore)
  Future<HusseinAdvmobprogUser?> getUserData() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _readProfile(firebaseUser);
  }

  // Same as getUserData, kept for the existing screens
  Future<HusseinAdvmobprogUser?> getSavedUser() => getUserData();

  // Firebase handles tokens itself, so this only reloads the account
  Future<HusseinAdvmobprogUser> refreshToken() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No active user session.');
    }
    await firebaseUser.reload();
    return _readProfile(_auth.currentUser!);
  }

  // Change the username
  Future<HusseinAdvmobprogUser> updateUsername(
    String newUsername, {
    String? currentPassword,
  }) async {
    final firebaseUser = _requireUser();
    final cleanUsername = newUsername.trim();

    if (cleanUsername.isEmpty) {
      throw Exception('Username cannot be empty.');
    }

    if (currentPassword != null && currentPassword.isNotEmpty) {
      await _reauthenticate(currentPassword);
    }

    final user = await _readProfile(firebaseUser);
    final updated = user.copyWith(username: cleanUsername);

    await firebaseUser.updateDisplayName(cleanUsername);
    await _writeProfile(updated);
    return updated;
  }

  // Change the current password
  Future<HusseinAdvmobprogUser> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _requireUser();

    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters.');
    }

    await _reauthenticate(currentPassword);

    try {
      await firebaseUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }

    return _readProfile(firebaseUser);
  }

  // Delete the Firebase account and its Users document
  Future<void> deleteAccount({String? currentPassword}) async {
    final firebaseUser = _requireUser();

    if (currentPassword != null && currentPassword.isNotEmpty) {
      await _reauthenticate(currentPassword);
    }

    final uid = firebaseUser.uid;

    try {
      await firebaseUser.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }

    await _users.doc(uid).delete();
  }

  // Log the user out
  Future<void> signOut() => logout();

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  User _requireUser() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No active user session.');
    }
    return firebaseUser;
  }

  // Look up the email that belongs to a username
  Future<String> _emailFromUsername(String username) async {
    final query =
        await _users.where('username', isEqualTo: username).limit(1).get();

    if (query.docs.isEmpty) {
      throw Exception('No account found for that username.');
    }

    final email = query.docs.first.data()['email']?.toString() ?? '';
    if (email.isEmpty) {
      throw Exception('No account found for that username.');
    }
    return email;
  }

  Future<void> _reauthenticate(String currentPassword) async {
    final firebaseUser = _requireUser();

    if (currentPassword.isEmpty) {
      throw Exception('Current password is required.');
    }

    try {
      await firebaseUser.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: firebaseUser.email ?? '',
          password: currentPassword,
        ),
      );
    } on FirebaseAuthException {
      throw Exception('Current password is incorrect.');
    }
  }

  // Read Users/{uid}; fall back to the Firebase account data
  Future<HusseinAdvmobprogUser> _readProfile(User firebaseUser) async {
    final doc = await _users.doc(firebaseUser.uid).get();
    final data = doc.data();

    if (data == null) {
      return HusseinAdvmobprogUser(
        id: 0,
        uid: firebaseUser.uid,
        username: firebaseUser.displayName ??
            (firebaseUser.email ?? '').split('@').first,
        email: firebaseUser.email ?? '',
        firstName: '',
        lastName: '',
        gender: '',
        image: firebaseUser.photoURL ?? '',
      );
    }

    return HusseinAdvmobprogUser.fromJson({
      ...data,
      'uid': firebaseUser.uid,
      'email': data['email'] ?? firebaseUser.email ?? '',
    });
  }

  // Write Users/{uid} with merge so the same document is refreshed
  Future<void> _writeProfile(HusseinAdvmobprogUser user) async {
    await _users.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'username': user.username,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'image': user.image,
      'age': user.age,
      'contactNo': user.contactNo,
      'loginType': user.loginType,
    }, SetOptions(merge: true));
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect username/email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again and retry.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
