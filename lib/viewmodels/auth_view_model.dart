import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user_model.dart';
import '../services/firebase_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({FirebaseService? service})
      : _service = service ?? FirebaseService.instance {
    _authSubscription = _service.authStateChanges().listen(_handleAuthChanged);
  }

  final FirebaseService _service;
  StreamSubscription<User?>? _authSubscription;

  User? _firebaseUser;
  AppUserModel? _appUser;
  bool _isAuthStateLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  AppUserModel? get appUser => _appUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAdmin => _appUser?.isAdmin ?? false;
  bool get isAuthStateLoading => _isAuthStateLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _handleAuthChanged(User? user) async {
    _firebaseUser = user;
    _appUser = null;
    _errorMessage = null;

    if (user == null) {
      _isAuthStateLoading = false;
      notifyListeners();
      return;
    }

    _isAuthStateLoading = true;
    notifyListeners();

    try {
      _appUser = await _service.getCurrentUserProfile();
    } catch (e) {
      _errorMessage = 'Không thể tải thông tin người dùng: $e';
    } finally {
      _isAuthStateLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _runAction(() async {
      await _service.loginWithEmailPassword(email: email, password: password);
    });
  }

  Future<bool> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _runAction(() async {
      await _service.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    });
  }

  Future<bool> signInWithGoogle() async {
    return _runAction(() async {
      await _service.signInWithGoogle();
    });
  }

  Future<bool> logout() async {
    return _runAction(() async {
      await _service.logout();
    });
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại.';
      case 'wrong-password':
        return 'Sai mật khẩu.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'sign_in_canceled':
        return 'Bạn đã hủy đăng nhập Google.';
      case 'permission-denied':
        return 'Bạn không có quyền thực hiện thao tác này.';
      default:
        return e.message ?? 'Xác thực thất bại.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
