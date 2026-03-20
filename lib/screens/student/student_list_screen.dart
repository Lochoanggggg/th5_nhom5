import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/student_model.dart';
import '../../services/firebase_service.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _service = FirebaseService.instance;
  final _searchController = TextEditingController();
  final _minGpaController = TextEditingController();
  final _maxGpaController = TextEditingController();

  String _searchTerm = '';
  String? _selectedClassName;
  String? _selectedDepartment;
  RangeValues _gpaRange = const RangeValues(0, 4);
  String? _gpaInputError;
  bool _showFilters = false;
  bool _checkingRole = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _syncGpaInputsFromRange();
    _loadRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minGpaController.dispose();
    _maxGpaController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedClassName = null;
      _selectedDepartment = null;
      _gpaRange = const RangeValues(0, 4);
      _gpaInputError = null;
      _syncGpaInputsFromRange();
    });
  }

  void _syncGpaInputsFromRange() {
    _minGpaController.text = _gpaRange.start.toStringAsFixed(1);
    _maxGpaController.text = _gpaRange.end.toStringAsFixed(1);
  }

  void _updateGpaRange(RangeValues values) {
    _gpaRange = values;
    _gpaInputError = null;
    _syncGpaInputsFromRange();
  }

  void _applyGpaInputs() {
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

    if (minValue < 0 || minValue > 4 || maxValue < 0 || maxValue > 4) {
      setState(() {
        _gpaInputError = 'GPA phải nằm trong khoảng 0.0 đến 4.0.';
      });
      return;
    }

    final start = minValue <= maxValue ? minValue : maxValue;
    final end = minValue <= maxValue ? maxValue : minValue;

    setState(() {
      _updateGpaRange(RangeValues(start, end));
    });
  }

  List<String> _buildClassOptions(List<StudentModel> students) {
    final options = students
        .map((student) => student.className)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return options;
  }

  List<String> _buildDepartmentOptions(List<StudentModel> students) {
    final options = students
        .map((student) => student.department)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return options;
  }

  bool get _hasActiveFilters {
    return (_selectedClassName != null && _selectedClassName!.isNotEmpty) ||
        (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) ||
        _gpaRange.start > 0 ||
        _gpaRange.end < 4;
  }

  double? get _minGpaFilter => _gpaRange.start <= 0 ? null : _gpaRange.start;
  double? get _maxGpaFilter => _gpaRange.end >= 4 ? null : _gpaRange.end;

  Future<void> _loadRole() async {
    final isAdmin = await _service.isCurrentUserAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _checkingRole = false;
    });
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc muốn xóa ${student.fullName}?'),
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

    try {
      await _service.deleteStudent(student.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sinh viên'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await _service.logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddStudentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm SV'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc mã SV',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchTerm.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchTerm = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<StudentModel>>(
                  stream: _service.watchStudents(),
                  builder: (context, snapshot) {
                    final allStudents = snapshot.data ?? const <StudentModel>[];
                    final classOptions = _buildClassOptions(allStudents);
                    final departmentOptions = _buildDepartmentOptions(
                      allStudents,
                    );

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.filter_alt_outlined),
                                const SizedBox(width: 8),
                                const Expanded(child: Text('Bộ lọc')),
                                if (_hasActiveFilters)
                                  TextButton(
                                    onPressed: _clearFilters,
                                    child: const Text('Xóa bộ lọc'),
                                  ),
                                IconButton(
                                  tooltip: _showFilters
                                      ? 'Thu gọn bộ lọc'
                                      : 'Mở bộ lọc',
                                  onPressed: () {
                                    setState(() {
                                      _showFilters = !_showFilters;
                                    });
                                  },
                                  icon: Icon(
                                    _showFilters
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                ),
                              ],
                            ),
                            if (_showFilters) ...[
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                key: ValueKey<String>(
                                  'class-${_selectedClassName ?? 'all'}',
                                ),
                                initialValue: _selectedClassName,
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
                                  ...classOptions.map(
                                    (value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedClassName = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                key: ValueKey<String>(
                                  'department-${_selectedDepartment ?? 'all'}',
                                ),
                                initialValue: _selectedDepartment,
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
                                  ...departmentOptions.map(
                                    (value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartment = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Lọc theo GPA: ${_gpaRange.start.toStringAsFixed(1)} - ${_gpaRange.end.toStringAsFixed(1)}',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _minGpaController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}$'),
                                        ),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'GPA min',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _applyGpaInputs(),
                                      onEditingComplete: _applyGpaInputs,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _maxGpaController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}$'),
                                        ),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'GPA max',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _applyGpaInputs(),
                                      onEditingComplete: _applyGpaInputs,
                                    ),
                                  ),
                                ],
                              ),
                              if (_gpaInputError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _gpaInputError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                              RangeSlider(
                                values: _gpaRange,
                                min: 0,
                                max: 4,
                                divisions: 40,
                                labels: RangeLabels(
                                  _gpaRange.start.toStringAsFixed(1),
                                  _gpaRange.end.toStringAsFixed(1),
                                ),
                                onChanged: (values) {
                                  setState(() {
                                    _updateGpaRange(values);
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _checkingRole
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<StudentModel>>(
                    stream: _service.watchStudentsFiltered(
                      searchTerm: _searchTerm,
                      className: _selectedClassName,
                      department: _selectedDepartment,
                      minGpa: _minGpaFilter,
                      maxGpa: _maxGpaFilter,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final students = snapshot.data!;
                      if (students.isEmpty) {
                        return const Center(
                          child: Text('Chưa có sinh viên nào.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: students.length,
                        separatorBuilder: (_, index) =>
                            const Divider(height: 1, thickness: 1),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return ListTile(
                            title: Text(student.fullName),
                            subtitle: Text(
                              'MSV: ${student.studentId} | Khoa: ${student.department} | Lớp: ${student.className} | GPA: ${student.gpa.toStringAsFixed(2)}',
                            ),
                            trailing: _isAdmin
                                ? Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        tooltip: 'Sửa',
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => EditStudentScreen(
                                                student: student,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit),
                                      ),
                                      IconButton(
                                        tooltip: 'Xóa',
                                        onPressed: () =>
                                            _deleteStudent(student),
                                        icon: const Icon(Icons.delete),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
