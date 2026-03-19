import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user_model.dart';
import '../models/student_model.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String usersCollection = 'users';
  static const String studentsCollection = 'students';

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AppUserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final snapshot = await _db.collection(usersCollection).doc(user.uid).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data() ?? <String, dynamic>{};
    return AppUserModel.fromMap(data);
  }

  Future<bool> isCurrentUserAdmin() async {
    final profile = await getCurrentUserProfile();
    return profile?.isAdmin ?? false;
  }

  Future<AppUserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String role = 'user',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'register-failed',
        message: 'Cannot create new user.',
      );
    }

    await user.updateDisplayName(displayName);

    final appUser = AppUserModel(
      uid: user.uid,
      email: email,
      displayName: displayName,
      role: role,
    );

    await _db.collection(usersCollection).doc(user.uid).set(appUser.toMap());
    return appUser;
  }

  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserProfile(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(provider);
      await _ensureUserProfile(credential.user);
      return credential;
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google sign-in canceled by user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final authCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final credential = await _auth.signInWithCredential(authCredential);
    await _ensureUserProfile(credential.user);
    return credential;
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // Ignore sign-out errors from Google provider and continue with Firebase sign-out.
      }
    }
    await _auth.signOut();
  }

  Future<void> setUserRole({required String uid, required String role}) async {
    await _requireAdmin();
    await _db.collection(usersCollection).doc(uid).set({
      'role': role,
    }, SetOptions(merge: true));
  }

  Stream<List<StudentModel>> watchStudents() {
    return _db
        .collection(studentsCollection)
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(StudentModel.fromFirestore).toList();
        });
  }

  Stream<List<StudentModel>> watchStudentsFiltered({
    String searchTerm = '',
    String? className,
    String? department,
    double? minGpa,
    double? maxGpa,
  }) {
    final normalizedSearch = searchTerm.trim().toLowerCase();
    return watchStudents().map((students) {
      return students.where((student) {
        final matchesSearch =
            normalizedSearch.isEmpty ||
            student.fullName.toLowerCase().contains(normalizedSearch) ||
            student.studentId.toLowerCase().contains(normalizedSearch);

        final matchesClass =
            className == null ||
            className.isEmpty ||
            student.className == className;

        final matchesDepartment =
            department == null ||
            department.isEmpty ||
            student.department == department;

        final matchesMinGpa = minGpa == null || student.gpa >= minGpa;
        final matchesMaxGpa = maxGpa == null || student.gpa <= maxGpa;

        return matchesSearch &&
            matchesClass &&
            matchesDepartment &&
            matchesMinGpa &&
            matchesMaxGpa;
      }).toList();
    });
  }

  Future<void> addStudent(StudentModel student) async {
    await _requireAdmin();

    final docRef = _db.collection(studentsCollection).doc();
    final now = DateTime.now();
    final newStudent = student.copyWith(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(newStudent.toMap());
  }

  Future<void> updateStudent(StudentModel student) async {
    await _requireAdmin();

    if (student.id.isEmpty) {
      throw ArgumentError('Student id is required for update.');
    }

    final updatedStudent = student.copyWith(updatedAt: DateTime.now());
    await _db
        .collection(studentsCollection)
        .doc(student.id)
        .update(updatedStudent.toMap());
  }

  Future<void> deleteStudent(String studentDocId) async {
    await _requireAdmin();

    await _db.collection(studentsCollection).doc(studentDocId).delete();
  }

  Future<void> _requireAdmin() async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      throw FirebaseAuthException(
        code: 'permission-denied',
        message: 'Only admin can perform this action.',
      );
    }
  }

  Future<void> _ensureUserProfile(User? user) async {
    if (user == null) return;

    final docRef = _db.collection(usersCollection).doc(user.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;

    final fallbackName = (user.email ?? 'user').split('@').first;
    final appUser = AppUserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? fallbackName,
      role: 'user',
    );

    await docRef.set(appUser.toMap());
  }
}
