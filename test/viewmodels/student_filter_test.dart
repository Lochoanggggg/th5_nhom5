import 'package:flutter_test/flutter_test.dart';
import 'package:th5_nhom5/models/student_model.dart';
import 'package:th5_nhom5/viewmodels/student_filter.dart';

void main() {
  final students = <StudentModel>[
    StudentModel(
      id: '1',
      studentId: 'SV001',
      fullName: 'Nguyen Van A',
      className: 'D21CQCN01',
      department: 'CNTT',
      gpa: 3.5,
      email: 'a@school.edu',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    StudentModel(
      id: '2',
      studentId: 'SV002',
      fullName: 'Tran Thi B',
      className: 'D21CQCN02',
      department: 'KT',
      gpa: 2.8,
      email: 'b@school.edu',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  group('applyStudentFilter', () {
    test('filters by search term', () {
      final result = applyStudentFilter(
        students,
        const StudentFilter(searchTerm: 'sv001'),
      );

      expect(result.length, 1);
      expect(result.first.studentId, 'SV001');
    });

    test('filters by class, department, and gpa range', () {
      final result = applyStudentFilter(
        students,
        const StudentFilter(
          className: 'D21CQCN01',
          department: 'CNTT',
          minGpa: 3.0,
          maxGpa: 4.0,
        ),
      );

      expect(result.length, 1);
      expect(result.first.fullName, 'Nguyen Van A');
    });

    test('returns empty when no student matches', () {
      final result = applyStudentFilter(
        students,
        const StudentFilter(department: 'Y duoc'),
      );

      expect(result, isEmpty);
    });
  });

  group('filter options', () {
    test('buildClassOptions returns sorted distinct class names', () {
      final options = buildClassOptions(students);
      expect(options, ['D21CQCN01', 'D21CQCN02']);
    });

    test('buildDepartmentOptions returns sorted distinct departments', () {
      final options = buildDepartmentOptions(students);
      expect(options, ['CNTT', 'KT']);
    });
  });
}
