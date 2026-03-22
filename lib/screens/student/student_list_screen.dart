import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/student_model.dart';
import '../../services/firebase_service.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/student_view_model.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchController = TextEditingController();
  final _minGpaController = TextEditingController();
  final _maxGpaController = TextEditingController();

  String? _gpaInputError;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = context.read<StudentViewModel>();
      _searchController.text = viewModel.searchTerm;
      _syncGpaInputsFromRange(viewModel.gpaRange);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minGpaController.dispose();
    _maxGpaController.dispose();
    super.dispose();
  }

  void _syncGpaInputsFromRange(RangeValues range) {
    _minGpaController.text = range.start.toStringAsFixed(1);
    _maxGpaController.text = range.end.toStringAsFixed(1);
  }

  void _updateGpaRange(StudentViewModel viewModel, RangeValues values) {
    viewModel.setGpaRange(values);
    _gpaInputError = null;
    _syncGpaInputsFromRange(values);
  }

  void _applyGpaInputs(StudentViewModel viewModel) {
    final minText = _minGpaController.text.trim();
    final maxText = _maxGpaController.text.trim();

    final minValue = double.tryParse(minText);
    final maxValue = double.tryParse(maxText);

    if (minValue == null || maxValue == null) {
      setState(() {
        _gpaInputError = 'Vui lòng nhập GPA hợp lệ (ví dụ: 2.5).';
      });
      return;
    }

    if (minValue < 0 ||
        minValue > FirebaseService.maxGpa ||
        maxValue < 0 ||
        maxValue > FirebaseService.maxGpa) {
      setState(() {
        _gpaInputError =
            'GPA phải nằm trong khoảng 0.0 đến ${FirebaseService.maxGpa.toStringAsFixed(1)}.';
      });
      return;
    }

    final start = minValue <= maxValue ? minValue : maxValue;
    final end = minValue <= maxValue ? maxValue : minValue;

    setState(() {
      _updateGpaRange(viewModel, RangeValues(start, end));
    });
  }

  Future<void> _deleteStudent(StudentViewModel viewModel, StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc muốn xóa ${student.fullName} không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final isSuccess = await viewModel.deleteStudent(student);
    if (!mounted) return;
    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa sinh viên thành công')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Xóa thất bại')),
      );
    }
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    StudentModel student,
    bool isAdmin,
    StudentViewModel studentViewModel,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  child: Text(
                    _initials(student.fullName),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã SV: ${student.studentId}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'GPA ${student.gpa.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('Khoa: ${student.department}'),
                  avatar: const Icon(Icons.account_balance_outlined, size: 16),
                ),
                Chip(
                  label: Text('Lớp: ${student.className}'),
                  avatar: const Icon(Icons.class_outlined, size: 16),
                ),
                Chip(
                  label: Text(student.email),
                  avatar: const Icon(Icons.email_outlined, size: 16),
                ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EditStudentScreen(student: student),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa'),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.tonalIcon(
                    onPressed: () => _deleteStudent(studentViewModel, student),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final studentViewModel = context.watch<StudentViewModel>();
    final theme = Theme.of(context);
    final students = studentViewModel.students;
    final totalStudents = students.length;
    final totalClasses = studentViewModel.classOptions.length;
    final totalDepartments = studentViewModel.departmentOptions.length;
    final roleText = authViewModel.isAdmin ? 'Admin' : 'User';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sinh viên'),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleText,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              final auth = context.read<AuthViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              final isSuccess = await auth.logout();
              if (!mounted) return;
              if (!isSuccess) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      auth.errorMessage ?? 'Đăng xuất thất bại',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: authViewModel.isAdmin
          ? FloatingActionButton.extended(
              elevation: 0,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddStudentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm sinh viên'),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách sinh viên',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Theo dõi thông tin học tập và quản lý dữ liệu theo thời gian thực.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc mã sinh viên',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: studentViewModel.searchTerm.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                context.read<StudentViewModel>().setSearchTerm('');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor:
                          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      context.read<StudentViewModel>().setSearchTerm(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.groups_rounded,
                          label: 'Tổng sinh viên',
                          value: '$totalStudents',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.class_outlined,
                          label: 'Số lớp',
                          value: '$totalClasses',
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.apartment_outlined,
                          label: 'Số khoa',
                          value: '$totalDepartments',
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildStatCard(
                      icon: Icons.groups_rounded,
                      label: 'Tổng sinh viên',
                      value: '$totalStudents',
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildStatCard(
                      icon: Icons.class_outlined,
                      label: 'Số lớp',
                      value: '$totalClasses',
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 8),
                    _buildStatCard(
                      icon: Icons.apartment_outlined,
                      label: 'Số khoa',
                      value: '$totalDepartments',
                      color: theme.colorScheme.tertiary,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bộ lọc nâng cao',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (studentViewModel.hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              context.read<StudentViewModel>().clearFilters();
                              _searchController.clear();
                              _syncGpaInputsFromRange(
                                context.read<StudentViewModel>().gpaRange,
                              );
                              setState(() {
                                _gpaInputError = null;
                              });
                            },
                            child: const Text('Xóa'),
                          ),
                        IconButton(
                          tooltip: _showFilters ? 'Thu gọn' : 'Mở rộng',
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                          icon: Icon(
                            _showFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'class-${studentViewModel.selectedClassName ?? 'all'}',
                            ),
                            initialValue: studentViewModel.selectedClassName,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Lọc theo lớp',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Tất cả lớp'),
                              ),
                              ...studentViewModel.classOptions.map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              context.read<StudentViewModel>().setClassName(value);
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'department-${studentViewModel.selectedDepartment ?? 'all'}',
                            ),
                            initialValue: studentViewModel.selectedDepartment,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Lọc theo khoa',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Tất cả khoa'),
                              ),
                              ...studentViewModel.departmentOptions.map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              context.read<StudentViewModel>().setDepartment(value);
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Khoảng GPA: ${studentViewModel.gpaRange.start.toStringAsFixed(1)} - ${studentViewModel.gpaRange.end.toStringAsFixed(1)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _minGpaController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}$'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'GPA tối thiểu',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _applyGpaInputs(studentViewModel),
                                  onEditingComplete: () => _applyGpaInputs(studentViewModel),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _maxGpaController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}$'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'GPA tối đa',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _applyGpaInputs(studentViewModel),
                                  onEditingComplete: () => _applyGpaInputs(studentViewModel),
                                ),
                              ),
                            ],
                          ),
                          if (_gpaInputError != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _gpaInputError!,
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                          RangeSlider(
                            values: studentViewModel.gpaRange,
                            min: 0,
                            max: FirebaseService.maxGpa,
                            divisions: (FirebaseService.maxGpa * 10).toInt(),
                            labels: RangeLabels(
                              studentViewModel.gpaRange.start.toStringAsFixed(1),
                              studentViewModel.gpaRange.end.toStringAsFixed(1),
                            ),
                            onChanged: (values) {
                              setState(() {
                                _updateGpaRange(studentViewModel, values);
                              });
                            },
                          ),
                        ],
                      ),
                      crossFadeState: _showFilters
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 220),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (studentViewModel.isLoading && students.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (studentViewModel.errorMessage != null && students.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(studentViewModel.errorMessage!),
                    ),
                  ],
                ),
              )
            else if (students.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 54,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Chưa có sinh viên nào',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Thêm sinh viên mới để bắt đầu quản lý danh sách.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: students
                    .map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildStudentCard(
                          context,
                          student,
                          authViewModel.isAdmin,
                          studentViewModel,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
