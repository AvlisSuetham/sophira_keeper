import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../utils/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  final maskCpf = MaskTextInputFormatter(
    mask: "###.###.###-##",
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool loading = false;
  bool obscureSenha = true;

  // Estados de validação da senha
  bool temMinimo = false;
  bool temMaiuscula = false;
  bool temMinuscula = false;
  bool temNumero = false;
  bool temEspecial = false;

  @override
  void initState() {
    super.initState();
    // Ouve as mudanças na senha para validar em tempo real
    senhaController.addListener(_validarSenha);
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    cpfController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  void _validarSenha() {
    final s = senhaController.text;
    setState(() {
      temMinimo = s.length >= 8;
      temMaiuscula = s.contains(RegExp(r'[A-Z]'));
      temMinuscula = s.contains(RegExp(r'[a-z]'));
      temNumero = s.contains(RegExp(r'[0-9]'));
      temEspecial = s.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  bool _isSenhaForte() =>
      temMinimo && temMaiuscula && temMinuscula && temNumero && temEspecial;

  bool _isEmailValido(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  // Função para abrir o Modal de Termos adaptado para temas
  void _showTermsModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          // Fundo adaptativo para o modal
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Termos e Condições',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "1. Aceitação dos Termos\nAo criar uma conta no Sophira Keeper, você concorda integralmente com estas regras...\n\n"
                  "2. Descrição do Serviço\nO Sophira Keeper permite o armazenamento criptografado de senhas...\n\n"
                  "3. O Modelo de Segurança e a 'Chave Mestra'\nArquitetura de Segurança: O usuário possui a chave de acesso principal. Em caso de perda, a recuperação é possível exclusivamente através do contato com a gerência mediante comprovação de identidade.\n\n"
                  "4. Privacidade e Dados Pessoais\nOperamos em conformidade com a LGPD.\n\n"
                  "5. Obrigações do Usuário\nUtilizar uma senha mestra forte e exclusiva.\n\n"
                  "6. Limitação de Responsabilidade\nNão nos responsabilizamos por negligência do usuário ou furto do dispositivo.",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'ENTENDI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> register() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final cpfLimpo = maskCpf.getUnmaskedText();

    if (nome.isEmpty || email.isEmpty || cpfLimpo.isEmpty || !_isSenhaForte()) {
      _showSnackBar('Preencha todos os campos corretamente.', Colors.orange);
      return;
    }

    if (!_isEmailValido(email)) {
      _showSnackBar('Email inválido.', Colors.orange);
      return;
    }

    if (cpfLimpo.length != 11) {
      _showSnackBar('CPF inválido.', Colors.orange);
      return;
    }

    setState(() => loading = true);

    try {
      final response = await ApiService.cadastro(
        nome,
        email,
        cpfLimpo,
        senhaController.text,
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (response['success'] == true) {
        _showSnackBar('Conta criada com sucesso!', Colors.green);
        Navigator.pop(context);
      } else {
        _showSnackBar(response['error'] ?? 'Erro no cadastro', Colors.redAccent);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnackBar('Erro de conexão com o servidor', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detecta se o tema atual é escuro
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Gradiente adaptativo igual ao da login.dart
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF020617), const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFF1A1B4B), const Color(0xFF2196F3), const Color(0xFFE91E63)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone superior adaptado para o estilo da login
                  const Hero(
                    tag: 'register_icon',
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nova Conta',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    'Preencha os dados para se cadastrar',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 48),

                  _buildField(
                    controller: nomeController,
                    label: 'Nome Completo',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    controller: emailController,
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

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

                  // --- INDICADORES VISUAIS DE SENHA (ESTILO ADAPTADO) ---
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sua Chave Mestra deve conter:",
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _checkItem("8+ caracteres", temMinimo),
                            _checkItem("Maiúscula", temMaiuscula),
                            _checkItem("Minúscula", temMinuscula),
                            _checkItem("Número", temNumero),
                            _checkItem("Símbolo", temEspecial),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- BOTÃO DE CRIAR CONTA (ESTILO ADAPTADO) ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (loading || !_isSenhaForte()) ? null : register,
                      style: ElevatedButton.styleFrom(
                        // Cor adaptativa igual ao login
                        backgroundColor: isDark ? const Color(0xFF6366F1) : const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'CRIAR MINHA CONTA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- TERMOS DE CONDIÇÕES (ESTILO ADAPTADO) ---
                  GestureDetector(
                    onTap: () => _showTermsModal(isDark),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Ao cadastrar, você concorda com os ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'termos e condições',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- VOLTAR PARA O LOGIN (ESTILO ADAPTADO) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Já possui uma conta?',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Faça Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (IGUAIS À LOGIN.DART) ---

  Widget _checkItem(String texto, bool valid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          valid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: valid ? Colors.greenAccent : Colors.white24,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            color: valid ? Colors.greenAccent : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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