import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'core/widgets/session_timeout_wrapper.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        return SessionTimeoutWrapper(child: child!);
      },
      home: const LoginScreen(),
    );
  }
}
