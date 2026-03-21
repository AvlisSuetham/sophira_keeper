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
      
      // --- CONFIGURAÇÃO DE TEMA ---
      
      // 1. Detecta automaticamente o tema do Windows, Linux ou Android
      themeMode: ThemeMode.system, 

      // 2. Tema Claro (Padrão)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1B4B),
          primary: const Color(0xFF1A1B4B), 
          secondary: const Color(0xFFE91E63), 
          surface: const Color(0xFFF8FAFC),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),

      // 3. Tema Escuro (Dark Mode)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Um azul mais vibrante para contraste no escuro
          brightness: Brightness.dark,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFEC4899),
          surface: const Color(0xFF0F172A), // Fundo azul marinho muito escuro
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFF1E293B), // Cor dos inputs no dark mode
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),

      // --- ROTAS ---
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