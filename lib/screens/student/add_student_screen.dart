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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(widget.isEditMode
              ? 'Cập nhật thành công'
              : 'Thêm sinh viên thành công'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorText = 'Lưu dữ liệu thất bại: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('Lỗi khi lưu dữ liệu: $e'),
          ),
        );
      }
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Sửa sinh viên' : 'Thêm sinh viên'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin cơ bản',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _studentIdController,
                          decoration: InputDecoration(
                            labelText: 'Mã sinh viên',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) return 'Vui lòng nhập mã sinh viên';
                            if (!RegExp(r'^[A-Za-z0-9_-]{3,20}$').hasMatch(text)) {
                              return 'Mã SV gồm chữ, số, -, _ (3-20 ký tự)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập họ và tên';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Thông tin học tập',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _classNameController,
                                decoration: InputDecoration(
                                  labelText: 'Lớp',
                                  prefixIcon: const Icon(Icons.class_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) return 'Nhập lớp';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _gpaController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'GPA',
                                  prefixIcon: const Icon(Icons.grade_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                ),
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return 'Nhập GPA';
                                  final gpa = double.tryParse(text);
                                  if (gpa == null || gpa < 0 || gpa > FirebaseService.maxGpa) {
                                    return '0 - ${FirebaseService.maxGpa.toStringAsFixed(0)}';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _departmentController,
                          decoration: InputDecoration(
                            labelText: 'Khoa',
                            prefixIcon: const Icon(Icons.account_balance_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập khoa';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) return 'Vui lòng nhập email';
                            if (!text.contains('@')) return 'Email không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        if (_errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _errorText!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(widget.isEditMode ? Icons.edit : Icons.add),
                            label: Text(
                              widget.isEditMode ? 'CẬP NHẬT' : 'THÊM MỚI',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
