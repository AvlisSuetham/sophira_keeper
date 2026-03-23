import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'register.dart';
import 'login.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _localPassController = TextEditingController();
  final TextEditingController _localUserController = TextEditingController();
  int _paginaAtual = 0;
  bool _obscureSenha = true;

  // Estados de validação da Chave Mestra
  bool temMinimo = false;
  bool temMaiuscula = false;
  bool temMinuscula = false;
  bool temNumero = false;
  bool temEspecial = false;

  final List<Map<String, dynamic>> _slides = [
    {
      "titulo": "Bem-vindo ao Sophira",
      "descricao": "Sua nova central de segurança digital com criptografia de ponta e arquitetura Zero Knowledge.",
      "icone": Icons.security_rounded,
    },
    {
      "titulo": "Tudo em um só lugar",
      "descricao": "Gerencie senhas complexas e tokens 2FA (TOTP) em uma interface cyberpunk minimalista.",
      "icone": Icons.vibration_rounded,
    },
    {
      "titulo": "Sincronização Inquebrável",
      "descricao": "Proteção total contra perda de dados. Com a Nuvem Sophira, seu cofre é criptografado localmente e sincronizado.",
      "tipo": "auth",
      "icone": Icons.cloud_sync_rounded,
    },
    {
      "titulo": "Cofre Local",
      "descricao": "Prefere não usar a nuvem? Defina um usuário e uma Chave Mestra para este dispositivo.",
      "tipo": "local_auth",
      "icone": Icons.lock_person_rounded,
    },
    {
      "titulo": "Tudo Pronto!",
      "descricao": "Agora você está no controle. Vamos proteger sua identidade digital.",
      "icone": Icons.rocket_launch_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _localPassController.addListener(_validarSenha);
  }

  void _validarSenha() {
    final s = _localPassController.text;
    setState(() {
      temMinimo = s.length >= 8;
      temMaiuscula = s.contains(RegExp(r'[A-Z]'));
      temMinuscula = s.contains(RegExp(r'[a-z]'));
      temNumero = s.contains(RegExp(r'[0-9]'));
      temEspecial = s.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  bool _isSenhaForte() => temMinimo && temMaiuscula && temMinuscula && temNumero && temEspecial;

  void _confirmarOffline() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Modo Offline", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "No modo offline, seus dados ficam apenas neste aparelho. Se você desinstalar o app ou perder o celular, não poderá recuperar os dados.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("VOLTAR")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text("ENTENDI", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finalizarSetup() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Marca o setup como concluído para nunca mais voltar aqui
    await prefs.setBool('setup_concluido', true);
    
    // Se preencheu dados locais, salva as configs de modo offline
    if (_localPassController.text.isNotEmpty && _localUserController.text.isNotEmpty) {
      await prefs.setString('local_master_key', _localPassController.text);
      await prefs.setString('local_username', _localUserController.text);
      await prefs.setBool('is_offline_mode', true);
      // Simula um ID para entrar direto na Home
      await prefs.setInt('usuario_id', 999); 
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isAuthSlide = _slides[_paginaAtual]['tipo'] == 'auth';
    bool isLocalAuthSlide = _slides[_paginaAtual]['tipo'] == 'local_auth';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildHeaderGradient(isDark),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: isLocalAuthSlide ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _paginaAtual = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) => _buildSlide(_slides[index], isDark),
                ),
              ),
              _buildBottomNavigation(isDark, isAuthSlide, isLocalAuthSlide),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGradient(bool isDark) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
            : [const Color(0xFF6366F1), const Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(60)),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark, bool isAuthSlide, bool isLocalAuthSlide) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _paginaAtual > 0 
            ? TextButton(
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                child: Text("VOLTAR", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
              )
            : const SizedBox(width: 80),

          Row(children: List.generate(_slides.length, (index) => _buildDot(index, isDark))),
          
          ElevatedButton(
            onPressed: (isLocalAuthSlide && (_localUserController.text.isEmpty || !_isSenhaForte())) 
              ? null 
              : () {
                  if (_paginaAtual == _slides.length - 1) {
                    _finalizarSetup();
                  } else if (isAuthSlide) {
                    _confirmarOffline();
                  } else {
                    _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                  }
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: _paginaAtual == _slides.length - 1 ? const Color(0xFFEC4899) : const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              disabledBackgroundColor: Colors.grey.withOpacity(0.1),
            ),
            child: Text(
              _paginaAtual == _slides.length - 1 ? "COMEÇAR" : (isAuthSlide ? "OFFLINE" : "PRÓXIMO"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide, bool isDark) {
    bool isAuthSlide = slide['tipo'] == 'auth';
    bool isLocalAuthSlide = slide['tipo'] == 'local_auth';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(slide['icone'], size: 100, color: Colors.white),
          const SizedBox(height: 50),
          Text(
            slide['titulo']!, 
            textAlign: TextAlign.center, 
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 26, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 15),
          Text(
            slide['descricao']!, 
            textAlign: TextAlign.center, 
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16, height: 1.5)
          ),
          
          if (isAuthSlide) ...[
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("CRIAR CONTA CLOUD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
              child: const Text("JÁ TENHO UMA CONTA", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
          ],

          if (isLocalAuthSlide) ...[
            const SizedBox(height: 30),
            _buildField(controller: _localUserController, label: "Seu Nome/Apelido", icon: Icons.person_outline, isDark: isDark),
            const SizedBox(height: 16),
            _buildField(controller: _localPassController, label: "Chave Mestra Local", icon: Icons.vpn_key_outlined, isDark: isDark, isPassword: true),
            const SizedBox(height: 20),
            _buildValidationWrap(),
          ]
        ],
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, required bool isDark, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureSenha : false,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        suffixIcon: isPassword ? IconButton(icon: Icon(_obscureSenha ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureSenha = !_obscureSenha)) : null,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildValidationWrap() {
    return Wrap(
      spacing: 12, runSpacing: 8,
      children: [
        _checkItem("8+ chars", temMinimo),
        _checkItem("Maiúsc.", temMaiuscula),
        _checkItem("minúsc.", temMinuscula),
        _checkItem("123", temNumero),
        _checkItem("!@#", temEspecial),
      ],
    );
  }

  Widget _checkItem(String texto, bool valid) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(valid ? Icons.check_circle_rounded : Icons.circle_outlined, color: valid ? Colors.greenAccent : Colors.grey, size: 14),
      const SizedBox(width: 4),
      Text(texto, style: TextStyle(fontSize: 11, color: valid ? Colors.greenAccent : Colors.grey)),
    ]);
  }

  Widget _buildDot(int index, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8, width: _paginaAtual == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _paginaAtual == index ? const Color(0xFF6366F1) : (isDark ? Colors.white24 : Colors.grey[300]), 
        borderRadius: BorderRadius.circular(4)
      ),
    );
  }
}