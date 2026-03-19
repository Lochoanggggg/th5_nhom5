import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firebase_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await FirebaseService.instance.loginWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = _toFriendlyAuthError(e);
      });
    } catch (e) {
      setState(() {
        _errorText = 'Dang nhap that bai: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await FirebaseService.instance.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = _toFriendlyAuthError(e);
      });
    } catch (e) {
      setState(() {
        _errorText = 'Dang nhap Google that bai: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _toFriendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'configuration-not-found':
        return 'Dang nhap that bai: Firebase Auth chua duoc cau hinh tren project.';
      case 'operation-not-allowed':
        return 'Dang nhap that bai: Phuong thuc dang nhap nay chua duoc bat.';
      case 'user-not-found':
        return 'Dang nhap that bai: Khong tim thay tai khoan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Dang nhap that bai: Sai email hoac mat khau.';
      case 'invalid-email':
        return 'Dang nhap that bai: Email khong hop le.';
      default:
        return 'Dang nhap that bai: [${e.code}] ${e.message ?? 'Khong xac dinh'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dang nhap')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Nhap email';
                      if (!text.contains('@')) return 'Email khong hop le';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mat khau'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Nhap mat khau';
                      if (text.length < 6) return 'Mat khau toi thieu 6 ky tu';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorText != null)
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Dang nhap'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Dang nhap voi Google'),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text('Chua co tai khoan? Dang ky'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
