import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/register.dart';

void main() {
  runApp(const SophiraKeeper());
}

class SophiraKeeper extends StatelessWidget {
  const SophiraKeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sophira Keeper',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
