import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_list_screen.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/student_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const StudentManagerApp());
  } catch (e) {
    runApp(AppInitError(error: e.toString()));
  }
}

class StudentManagerApp extends StatelessWidget {
  const StudentManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, StudentViewModel>(
          create: (_) => StudentViewModel(),
          update: (_, auth, student) {
            final model = student ?? StudentViewModel();
            model.bindAuth(auth);
            return model;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Student Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        if (authViewModel.isAuthStateLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authViewModel.isAuthenticated) {
          return const StudentListScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class AppInitError extends StatelessWidget {
  const AppInitError({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase setup required')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Khoi tao Firebase that bai. Hay cau hinh Firebase cho project truoc khi chay app.\n\nChi tiet: $error',
          ),
        ),
      ),
    );
  }
}
