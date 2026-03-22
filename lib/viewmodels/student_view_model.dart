import 'dart:async';

import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../services/firebase_service.dart';
import 'auth_view_model.dart';
import 'student_filter.dart';

class StudentViewModel extends ChangeNotifier {
  StudentViewModel({FirebaseService? service})
      : _service = service ?? FirebaseService.instance;

  final FirebaseService _service;
  StreamSubscription<List<StudentModel>>? _studentsSubscription;

  AuthViewModel? _authViewModel;
  List<StudentModel> _allStudents = const [];
  List<StudentModel> _filteredStudents = const [];

  String _searchTerm = '';
  String? _selectedClassName;
  String? _selectedDepartment;
  RangeValues _gpaRange = const RangeValues(0, FirebaseService.maxGpa);

  bool _isLoading = false;
  String? _errorMessage;

  List<StudentModel> get students => _filteredStudents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchTerm => _searchTerm;
  String? get selectedClassName => _selectedClassName;
  String? get selectedDepartment => _selectedDepartment;
  RangeValues get gpaRange => _gpaRange;

  List<String> get classOptions => buildClassOptions(_allStudents);
  List<String> get departmentOptions => buildDepartmentOptions(_allStudents);

  bool get hasActiveFilters {
    final filter = StudentFilter(
      searchTerm: _searchTerm,
      className: _selectedClassName,
      department: _selectedDepartment,
      minGpa: minGpaFilter,
      maxGpa: maxGpaFilter,
    );
    return filter.hasActiveFilters;
  }

  double? get minGpaFilter => _gpaRange.start <= 0 ? null : _gpaRange.start;
  double? get maxGpaFilter =>
      _gpaRange.end >= FirebaseService.maxGpa ? null : _gpaRange.end;

  void bindAuth(AuthViewModel authViewModel) {
    if (identical(_authViewModel, authViewModel)) return;
    _authViewModel = authViewModel;

    if (!authViewModel.isAuthenticated) {
      _stopWatchingStudents();
      _allStudents = const [];
      _filteredStudents = const [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _watchStudents();
  }

  void setSearchTerm(String value) {
    _searchTerm = value;
    _applyFilters();
  }

  void setClassName(String? value) {
    _selectedClassName = value;
    _applyFilters();
  }

  void setDepartment(String? value) {
    _selectedDepartment = value;
    _applyFilters();
  }

  void setGpaRange(RangeValues value) {
    _gpaRange = value;
    _applyFilters();
  }

  void clearFilters() {
    _searchTerm = '';
    _selectedClassName = null;
    _selectedDepartment = null;
    _gpaRange = const RangeValues(0, FirebaseService.maxGpa);
    _applyFilters();
  }

  Future<bool> deleteStudent(StudentModel student) async {
    try {
      _errorMessage = null;
      notifyListeners();
      await _service.deleteStudent(student.id);
      return true;
    } catch (e) {
      _errorMessage = 'Xóa thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveStudent(StudentModel student, {required bool isEditMode}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditMode) {
        await _service.updateStudent(student);
      } else {
        await _service.addStudent(student);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Lưu dữ liệu thất bại: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _watchStudents() {
    _studentsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _studentsSubscription = _service.watchStudents().listen(
      (students) {
        _allStudents = students;
        _isLoading = false;
        _errorMessage = null;
        _applyFilters(notify: false);
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Lỗi tải dữ liệu: $error';
        notifyListeners();
      },
    );
  }

  void _stopWatchingStudents() {
    _studentsSubscription?.cancel();
    _studentsSubscription = null;
  }

  void _applyFilters({bool notify = true}) {
    final filter = StudentFilter(
      searchTerm: _searchTerm,
      className: _selectedClassName,
      department: _selectedDepartment,
      minGpa: minGpaFilter,
      maxGpa: maxGpaFilter,
    );

    _filteredStudents = applyStudentFilter(_allStudents, filter);
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopWatchingStudents();
    super.dispose();
  }
}
