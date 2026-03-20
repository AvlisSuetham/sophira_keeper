import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  final maskCpf = MaskTextInputFormatter(
    mask: "###.###.###-##",
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool loading = false;
  bool obscureSenha = true;

  Future<void> login() async {
    final cpfLimpo = maskCpf.getUnmaskedText();
    final senha = senhaController.text;

    if (cpfLimpo.length != 11 || senha.isEmpty) {
      _showMsg('CPF ou Chave Mestra inválidos', Colors.orange);
      return;
    }

    setState(() => loading = true);

    try {
      final data = await ApiService.login(cpfLimpo, senha);

      if (!mounted) return;
      setState(() => loading = false);

      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('usuario_id', data['user']['id']);
        await prefs.setString('usuario_nome', data['user']['nome']);
        await prefs.setString('usuario_email', data['user']['email']);

        _showMsg('Bem-vindo, ${data['user']['nome']}', Colors.green);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMsg(data['error'] ?? 'Erro ao acessar conta', Colors.redAccent);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showMsg('Erro de conexão com o servidor', Colors.red);
    }
  }

  void _showMsg(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Cores escuras para o modo dark e cyberpunk para o light
            colors: isDark
                ? [const Color(0xFF020617), const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFF1A1B4B), const Color(0xFF2196F3), const Color(0xFFE91E63)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ÍCONE ORIGINAL RESTAURADO
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.shield_rounded, size: 80, color: Colors.white24);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sophira Keeper',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'Seu cofre digital seguro',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),

                _buildField(
                  controller: cpfController,
                  label: 'CPF',
                  icon: Icons.person_outline,
                  formatters: [maskCpf],
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _buildField(
                  controller: senhaController,
                  label: 'Chave Mestra',
                  icon: Icons.lock_outline,
                  obscure: obscureSenha,
                  suffix: IconButton(
                    icon: Icon(
                      obscureSenha ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() => obscureSenha = !obscureSenha),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgotten'),
                    child: const Text(
                      'Esqueci minha senha',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF6366F1) : const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      disabledBackgroundColor: Colors.white10,
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Text(
                            'ACESSAR CONTA',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    'Ainda não tem acesso? Cadastre-se',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    List<TextInputFormatter>? formatters,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      inputFormatters: formatters,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}