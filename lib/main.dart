import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/home.dart';

void main() async {
  // Necessário para inicializar plugins antes do runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Verifica se existe usuário logado no cache
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
      // Se estiver logado, a rota inicial é /home, senão é /
      initialRoute: inicialLogado ? '/home' : '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}