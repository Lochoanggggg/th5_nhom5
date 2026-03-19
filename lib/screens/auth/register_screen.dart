import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await FirebaseService.instance.registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = _toFriendlyAuthError(e);
      });
    } catch (e) {
      setState(() {
        _errorText = 'Dang ky that bai: $e';
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
        return 'Dang ky that bai: Firebase Auth chua duoc cau hinh. Vao Firebase Console > Authentication > Get started, bat Email/Password trong Sign-in method.';
      case 'operation-not-allowed':
        return 'Dang ky that bai: Email/Password chua duoc bat tren Firebase Console.';
      case 'email-already-in-use':
        return 'Dang ky that bai: Email nay da ton tai.';
      case 'invalid-email':
        return 'Dang ky that bai: Email khong hop le.';
      case 'weak-password':
        return 'Dang ky that bai: Mat khau qua yeu (toi thieu 6 ky tu).';
      default:
        return 'Dang ky that bai: [${e.code}] ${e.message ?? 'Khong xac dinh'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dang ky')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Ho ten'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) return 'Nhap ho ten';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
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
                      if (text.length < 6) {
                        return 'Mat khau toi thieu 6 ky tu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xac nhan mat khau',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim() != _passwordController.text) {
                        return 'Mat khau xac nhan khong khop';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorText != null)
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Tao tai khoan'),
                    ),
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
