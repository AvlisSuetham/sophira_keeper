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

  // Função para abrir o Modal de Termos
  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1B4B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Termos e Condições',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "1. Aceitação dos Termos\nAo criar uma conta no Sophira Keeper, você concorda integralmente com estas regras...\n\n"
                  "2. Descrição do Serviço\nO Sophira Keeper permite o armazenamento criptografado de senhas...\n\n"
                  "3. O Modelo de Segurança e a 'Chave Mestra'\nArquitetura de Segurança: O usuário possui a chave de acesso principal. Em caso de perda, a recuperação é possível exclusivamente através do contato com a gerência mediante comprovação de identidade.\n\n"
                  "4. Privacidade e Dados Pessoais\nOperamos em conformidade com a LGPD.\n\n"
                  "5. Obrigações do Usuário\nUtilizar uma senha mestra forte e exclusiva.\n\n"
                  "6. Limitação de Responsabilidade\nNão nos responsabilizamos por negligência do usuário ou furto do dispositivo.",
                  style: TextStyle(
                    color: Colors.white70,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'ENTENDI',
                  style: TextStyle(
                    color: Colors.white,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos e atenda aos requisitos de senha.'),
        ),
      );
      return;
    }

    if (!_isEmailValido(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email inválido.')),
      );
      return;
    }

    if (cpfLimpo.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CPF inválido.')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Erro no cadastro')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão. Verifique sua internet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1B4B), Color(0xFF2196F3), Color(0xFFE91E63)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nova Conta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildField(
                    nomeController,
                    'Nome Completo',
                    Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    emailController,
                    'E-mail',
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    cpfController,
                    'CPF',
                    Icons.person_outline,
                    formatters: [maskCpf],
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    senhaController,
                    'Chave Mestra',
                    Icons.lock_outline,
                    obscure: obscureSenha,
                    suffix: IconButton(
                      icon: Icon(
                        obscureSenha ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => obscureSenha = !obscureSenha),
                    ),
                  ),

                  // --- INDICADORES VISUAIS DE SENHA (OTIMIZADO) ---
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _checkItem("8+ caracteres", temMinimo),
                        _checkItem("Maiúscula", temMaiuscula),
                        _checkItem("Minúscula", temMinuscula),
                        _checkItem("Número", temNumero),
                        _checkItem("Símbolo (!@#\$%)", temEspecial),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- BOTÃO DE CRIAR CONTA ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (loading || !_isSenhaForte()) ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
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
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'CRIAR MINHA CONTA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- TERMOS DE CONDIÇÕES ---
                  GestureDetector(
                    onTap: _showTermsModal,
                    child: const Text.rich(
                      TextSpan(
                        text: 'Ao cadastrar, você concorda com os ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
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

                  // --- ESQUEMA DE VOLTAR PARA O LOGIN ---
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

  // --- WIDGETS AUXILIARES ---

  Widget _checkItem(String texto, bool valid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.circle_outlined,
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

  Widget _buildField(
    TextEditingController c,
    String l,
    IconData i, {
    bool obscure = false,
    List<TextInputFormatter>? formatters,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      inputFormatters: formatters,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(i, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}