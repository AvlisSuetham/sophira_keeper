import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importações das telas
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/home.dart';
import 'screens/forgotten.dart';
import 'screens/password_generator_screen.dart'; 
import 'screens/settings_screen.dart';
import 'screens/backup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  // Verifica se o ID do usuário existe e é válido (> 0)
  final int usuarioId = prefs.getInt('usuario_id') ?? 0;
  final bool logado = usuarioId > 0;

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
          primary: const Color(0xFF1A1B4B), 
          secondary: const Color(0xFFE91E63), 
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      // Se estiver logado, vai direto para a Home, senão, tela de Login
      initialRoute: inicialLogado ? '/home' : '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/forgotten': (context) => const ForgottenScreen(),
        '/generator': (context) => const PasswordGeneratorScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/backup': (context) => const BackupScreen(),
      },
    );
  }
}