import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../services/firebase_service.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key, this.existingStudent});

  final StudentModel? existingStudent;

  bool get isEditMode => existingStudent != null;

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentIdController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _classNameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _gpaController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final student = widget.existingStudent;
    _studentIdController = TextEditingController(
      text: student?.studentId ?? '',
    );
    _fullNameController = TextEditingController(text: student?.fullName ?? '');
    _classNameController = TextEditingController(
      text: student?.className ?? '',
    );
    _departmentController = TextEditingController(
      text: student?.department ?? '',
    );
    _gpaController = TextEditingController(
      text: student == null ? '' : student.gpa.toStringAsFixed(2),
    );
    _emailController = TextEditingController(text: student?.email ?? '');
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _fullNameController.dispose();
    _classNameController.dispose();
    _departmentController.dispose();
    _gpaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final gpa = double.parse(_gpaController.text.trim());
    final now = DateTime.now();
    final current = widget.existingStudent;
    final student = StudentModel(
      id: current?.id ?? '',
      studentId: _studentIdController.text.trim(),
      fullName: _fullNameController.text.trim(),
      className: _classNameController.text.trim(),
      department: _departmentController.text.trim(),
      gpa: gpa,
      email: _emailController.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (widget.isEditMode) {
        await FirebaseService.instance.updateStudent(student);
      } else {
        await FirebaseService.instance.addStudent(student);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorText = 'Luu du lieu that bai: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Sua sinh vien' : 'Them sinh vien'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Ma sinh vien',
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Nhap ma sinh vien';
                      }
                      if (!RegExp(r'^[A-Za-z0-9_-]{3,20}$').hasMatch(text)) {
                        return 'Ma SV gom chu, so, -, _ (3-20 ky tu)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Ho va ten'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Nhap ho va ten';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _classNameController,
                    decoration: const InputDecoration(labelText: 'Lop'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) return 'Nhap lop';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(labelText: 'Khoa'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Nhap khoa';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gpaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'GPA (0-4)'),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return 'Nhap GPA';
                      final gpa = double.tryParse(text);
                      if (gpa == null || gpa < 0 || gpa > 4) {
                        return 'GPA phai trong khoang 0 den 4';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return 'Nhap email';
                      if (!text.contains('@')) return 'Email khong hop le';
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
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isEditMode ? 'Cap nhat' : 'Them moi'),
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
