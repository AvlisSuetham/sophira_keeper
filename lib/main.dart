import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool logado = prefs.containsKey('usuario_id');

  runApp(SophiraKeeper(inicialLogado: logado));
}

class SophiraKeeper extends StatelessWidget {
  final bool inicialLogado;
  const SophiraKeeper({super.key, required this.inicialLogado});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sophira Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1B4B),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFFE91E63),
        ),
      ),
      initialRoute: inicialLogado ? '/home' : '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}