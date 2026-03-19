import '../../models/student_model.dart';
import 'add_student_screen.dart';

class EditStudentScreen extends AddStudentScreen {
  const EditStudentScreen({super.key, required StudentModel student})
    : super(existingStudent: student);
}
