import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  const StudentModel({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.className,
    required this.department,
    required this.gpa,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String fullName;
  final String className;
  final String department;
  final double gpa;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentModel copyWith({
    String? id,
    String? studentId,
    String? fullName,
    String? className,
    String? department,
    double? gpa,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      className: className ?? this.className,
      department: department ?? this.department,
      gpa: gpa ?? this.gpa,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StudentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return StudentModel(
      id: doc.id,
      studentId: (data['studentId'] ?? '') as String,
      fullName: (data['fullName'] ?? '') as String,
      className: (data['className'] ?? '') as String,
      department: (data['department'] ?? '') as String,
      gpa: ((data['gpa'] ?? 0) as num).toDouble(),
      email: (data['email'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'className': className,
      'department': department,
      'gpa': gpa,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
