import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_app/pages/admin_page.dart';
import 'state/auth_state.dart';
import 'pages/login_page.dart';
import 'pages/home/home_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AuthState(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rfid App',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/admin': (_) => const AdminPage(),
      },
    );
  }
}
