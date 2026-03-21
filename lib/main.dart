import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para controlar a Status Bar
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
  // Garante a inicialização dos bindings antes de qualquer await
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Configuração global da Status Bar para ser transparente desde o início
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Padrão claro, o Flutter alterna depois
  ));

  final prefs = await SharedPreferences.getInstance();
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
      
      themeMode: ThemeMode.system, 

      // --- TEMA CLARO ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1B4B),
          primary: const Color(0xFF1A1B4B), 
          secondary: const Color(0xFFE91E63), 
          surface: const Color(0xFFF8FAFC),
        ),
        // Garante que o Scaffold do Light Mode seja branco puro para bater com o XML
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark, // Ícones escuros na barra
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),

      // --- TEMA ESCURO ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFEC4899),
          surface: const Color(0xFF0F172A), 
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),

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