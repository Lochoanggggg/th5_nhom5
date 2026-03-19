import 'package:flutter/material.dart';

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

  String _searchTerm = '';
  bool _checkingRole = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          title: const Text('Xac nhan xoa'),
          content: Text('Ban co chac muon xoa ${student.fullName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xoa'),
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
      ).showSnackBar(SnackBar(content: Text('Xoa that bai: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sach sinh vien'),
        actions: [
          IconButton(
            tooltip: 'Dang xuat',
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
              label: const Text('Them SV'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tim theo ten hoac ma SV',
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
          ),
          Expanded(
            child: _checkingRole
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<StudentModel>>(
                    stream: _service.watchStudentsFiltered(
                      searchTerm: _searchTerm,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Loi tai du lieu: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final students = snapshot.data!;
                      if (students.isEmpty) {
                        return const Center(
                          child: Text('Chua co sinh vien nao.'),
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
                              'MSV: ${student.studentId} | Lop: ${student.className} | GPA: ${student.gpa.toStringAsFixed(2)}',
                            ),
                            trailing: _isAdmin
                                ? Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        tooltip: 'Sua',
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
                                        tooltip: 'Xoa',
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
