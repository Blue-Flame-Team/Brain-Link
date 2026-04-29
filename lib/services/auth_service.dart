import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential?> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user!.updateDisplayName(name);

      try {
        await _db
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'fullName': name,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint("Firestore Error (Ignoring to proceed): $e");
      }

      return userCredential;
    } catch (e) {
      debugPrint("Auth Error: $e");
      rethrow;
    }
  }
}
