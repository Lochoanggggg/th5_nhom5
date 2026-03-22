import '../models/student_model.dart';

class StudentFilter {
  const StudentFilter({
    this.searchTerm = '',
    this.className,
    this.department,
    this.minGpa,
    this.maxGpa,
  });

  final String searchTerm;
  final String? className;
  final String? department;
  final double? minGpa;
  final double? maxGpa;

  bool get hasActiveFilters {
    return searchTerm.trim().isNotEmpty ||
        (className?.isNotEmpty ?? false) ||
        (department?.isNotEmpty ?? false) ||
        minGpa != null ||
        maxGpa != null;
  }
}

List<StudentModel> applyStudentFilter(
  List<StudentModel> students,
  StudentFilter filter,
) {
  final normalizedSearch = filter.searchTerm.trim().toLowerCase();

  return students.where((student) {
    final matchesSearch =
        normalizedSearch.isEmpty ||
        student.fullName.toLowerCase().contains(normalizedSearch) ||
        student.studentId.toLowerCase().contains(normalizedSearch);

    final matchesClass =
        filter.className == null ||
        filter.className!.isEmpty ||
        student.className == filter.className;

    final matchesDepartment =
        filter.department == null ||
        filter.department!.isEmpty ||
        student.department == filter.department;

    final matchesMinGpa = filter.minGpa == null || student.gpa >= filter.minGpa!;
    final matchesMaxGpa = filter.maxGpa == null || student.gpa <= filter.maxGpa!;

    return matchesSearch &&
        matchesClass &&
        matchesDepartment &&
        matchesMinGpa &&
        matchesMaxGpa;
  }).toList();
}

List<String> buildClassOptions(List<StudentModel> students) {
  final options = students
      .map((student) => student.className)
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return options;
}

List<String> buildDepartmentOptions(List<StudentModel> students) {
  final options = students
      .map((student) => student.department)
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return options;
}
