// lib/screens/home.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import '../utils/api_service.dart';
import 'password_generator_screen.dart';
import 'settings_screen.dart';
import 'vault.dart';
import 'tokens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  int _indiceAtual = 0;
  String nomeUsuario = "";
  String inicialNome = "";
  int usuarioId = 0;

  List<Map<String, dynamic>> tokens = [];
  List<dynamic> cofres = [];

  bool isLoading = true;
  bool isOffline = false;
  bool _estaAutenticado = false;

  final List<Color> listaCores = [
    const Color(0xFF3B82F6), const Color(0xFFEF4444), const Color(0xFF10B981), 
    const Color(0xFF8B5CF6), const Color(0xFFF59E0B), const Color(0xFF06B6D4), 
    const Color(0xFFEC4899), const Color(0xFF6366F1), const Color(0xFF64748B), 
    const Color(0xFFFBBF24),
  ];

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  // --- LÓGICA DE BIOMETRIA ---
  Future<void> _verificarBiometria() async {
    if (kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))) {
      setState(() => _estaAutenticado = true);
      _inicializarApp();
      return;
    }

    try {
      final bool podeVerificar = await auth.canCheckBiometrics;
      final bool suporteHardware = await auth.isDeviceSupported();

      if (podeVerificar || suporteHardware) {
        final bool autenticado = await auth.authenticate(
          localizedReason: 'Autentique-se para acessar seu cofre de senhas',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );

        if (autenticado) {
          setState(() => _estaAutenticado = true);
          _inicializarApp();
        } else {
          SystemNavigator.pop();
        }
      } else {
        setState(() => _estaAutenticado = true);
        _inicializarApp();
      }
    } on PlatformException catch (_) {
      setState(() => _estaAutenticado = true);
      _inicializarApp();
    }
  }

  // --- INICIALIZAÇÃO E CACHE ---
  Future<void> _inicializarApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeUsuario = prefs.getString('usuario_nome') ?? "Usuário";
      inicialNome = nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : "U";
      usuarioId = prefs.getInt('usuario_id') ?? 0;
    });

    await _loadFromCache();
    _fetchCofres();
    _fetchTokens();
  }

  Future<void> _saveToCache(String key, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${key}_$usuarioId', jsonEncode(data));
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedCofre = prefs.getString('cache_vault_$usuarioId');
    String? cachedTokens = prefs.getString('cache_tokens_$usuarioId');

    setState(() {
      if (cachedCofre != null) cofres = jsonDecode(cachedCofre);
      if (cachedTokens != null) {
        try {
          final parsed = jsonDecode(cachedTokens);
          if (parsed is List) {
            tokens = parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        } catch (_) { tokens = []; }
      }
      isLoading = false;
    });
  }

  // --- BUSCA DE DADOS ---
  Future<void> _fetchCofres() async {
    try {
      final data = await ApiService.listarCofres();
      if (data['success'] == true) {
        setState(() {
          cofres = data['data'];
          isOffline = false;
          isLoading = false;
        });
        _saveToCache('cache_vault', data['data'] as List<dynamic>);
      }
    } catch (e) {
      setState(() { isOffline = true; isLoading = false; });
      _loadFromCache();
    }
  }

  Future<void> _fetchTokens() async {
    try {
      final data = await ApiService.listarTokens();
      if (data['success'] == true) {
        final raw = data['data'];
        if (raw is List) {
          setState(() {
            tokens = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            isOffline = false;
          });
          _saveToCache('cache_tokens', tokens);
        }
      }
    } catch (e) {
      setState(() { isOffline = true; });
    }
  }

  // --- EXCLUSÃO ---
  Future<void> _excluirCofre(int id) async {
    if (isOffline) { _showErrorSnackBar("Offline: Ação bloqueada."); return; }
    bool confirmar = await _mostrarConfirmacaoExclusao();
    if (!confirmar) return;
    try {
      final data = await ApiService.excluirCofre(id);
      if (data['success'] == true) _fetchCofres();
    } catch (e) { _showErrorSnackBar("Erro ao excluir."); }
  }

  Future<void> _excluirToken(int id) async {
    if (isOffline) { _showErrorSnackBar("Offline: Ação bloqueada."); return; }
    bool confirmar = await _mostrarConfirmacaoExclusao();
    if (!confirmar) return;
    try {
      final data = await ApiService.excluirToken(id);
      if (data['success'] == true) _fetchTokens();
    } catch (e) { _showErrorSnackBar("Erro ao excluir."); }
  }

  Future<bool> _mostrarConfirmacaoExclusao() async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text("Excluir?", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text("Esta ação é permanente no servidor.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Manter")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  // --- SCANNER QR CODE ---
  Future<void> _escanearESalvarToken() async {
    if (isOffline) { _showErrorSnackBar("Conecte-se para salvar tokens."); return; }

    final code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (code == null || (code is String && code.isEmpty)) return;

    try {
      final uri = Uri.parse(code as String);
      if (uri.scheme == 'otpauth') {
        final secret = uri.queryParameters['secret'];
        if (secret == null) return;

        String servicoNome = uri.queryParameters['issuer'] ?? uri.pathSegments.last;
        final randomColorHex = '#${listaCores[tokens.length % listaCores.length].value.toRadixString(16).substring(2)}';

        final payload = {
          'servico_nome': Uri.decodeComponent(servicoNome),
          'servico_otp_secret': secret.toUpperCase(),
          'color': randomColorHex,
        };

        final response = await ApiService.adicionarToken(payload);
        if (response['success'] == true) {
          setState(() => _indiceAtual = 1);
          _fetchTokens();
        }
      }
    } catch (e) { _showErrorSnackBar("Erro ao processar QR Code."); }
  }

  // --- INTERFACE PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_estaAutenticado) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator())
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _indiceAtual == 0
                      ? VaultWidget(
                          cofres: cofres,
                          isLoading: isLoading,
                          onRefresh: _fetchCofres,
                          onEdit: _showFormDialog,
                          onDelete: _excluirCofre,
                        )
                      : TokensWidget(
                          tokens: tokens,
                          isLoading: isLoading,
                          onRefresh: _fetchTokens,
                          onDelete: _excluirToken,
                        ),
                ),
              ),
            ],
          ),
          if (isOffline) _buildOfflineBanner(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1), 
              blurRadius: 10
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceAtual,
          onTap: (index) => setState(() => _indiceAtual = index),
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.lock_outline_rounded), activeIcon: Icon(Icons.lock_rounded), label: 'Senhas'),
            BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield_rounded), label: '2FA'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _indiceAtual == 0 ? _showFormDialog() : _escanearESalvarToken(),
        backgroundColor: _indiceAtual == 0 ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
        elevation: 4,
        label: Text(_indiceAtual == 0 ? "NOVA SENHA" : "ESCANEAR", style: const TextStyle(color: Colors.white)),
        icon: Icon(_indiceAtual == 0 ? Icons.add_rounded : Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 60, 15, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
            : [const Color(0xFF1A1B4B), const Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(inicialNome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              _headerIcon(Icons.password_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordGeneratorScreen()))),
              _headerIcon(Icons.settings_outlined, () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                _fetchCofres(); _fetchTokens();
              }),
              _headerIcon(Icons.logout_rounded, _logout, color: Colors.redAccent.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 25),
          Text('Olá,', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
          Text(nomeUsuario, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap, {Color color = Colors.white70}) {
    return IconButton(icon: Icon(icon, color: color, size: 22), onPressed: onTap);
  }

  Widget _buildOfflineBanner() {
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text("Modo Offline Ativo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- NOVO DIALOGO DE FORMULÁRIO (ESTÉTICA ARRUMADA) ---
  void _showFormDialog({Map<String, dynamic>? registro}) {
    if (isOffline) { _showErrorSnackBar("Conecte-se para salvar."); return; }

    final isEditing = registro != null;
    final nomeController = TextEditingController(text: isEditing ? registro['servico_nome'] : '');
    final emailController = TextEditingController(text: isEditing ? registro['servico_email'] : '');
    final userController = TextEditingController(text: isEditing ? registro['servico_usuario'] : '');
    final senhaController = TextEditingController(text: isEditing ? registro['servico_senha'] : '');

    Color hexToColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));
    String colorToHex(Color c) => '#${c.value.toRadixString(16).substring(2)}';
    
    Color corSelecionada = isEditing && registro['color'] != null 
        ? hexToColor(registro['color']) : listaCores[0];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(isEditing ? "Editar Acesso" : "Novo Acesso", 
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInput(nomeController, "Serviço", Icons.apps_rounded, isDark),
                  _buildInput(emailController, "E-mail", Icons.alternate_email_rounded, isDark),
                  _buildInput(userController, "Usuário", Icons.person_outline_rounded, isDark),
                  _buildInput(senhaController, "Senha", Icons.lock_outline_rounded, isDark, obscure: true),
                  const SizedBox(height: 15),
                  const Align(alignment: Alignment.centerLeft, child: Text("Cor de identificação", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: listaCores.map((cor) => GestureDetector(
                      onTap: () => setModalState(() => corSelecionada = cor),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: corSelecionada == cor ? cor : Colors.transparent, width: 2),
                        ),
                        child: CircleAvatar(radius: 12, backgroundColor: cor, child: corSelecionada == cor ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text("Cancelar", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nomeController.text.isEmpty) return;
                  try {
                    final colorHex = colorToHex(corSelecionada);
                    Map<String, dynamic> resp;
                    if (isEditing) {
                      resp = await ApiService.editarCofre(
                        id: int.parse(registro['id'].toString()),
                        nome: nomeController.text, email: emailController.text,
                        usuario: userController.text, senha: senhaController.text, color: colorHex,
                      );
                    } else {
                      resp = await ApiService.adicionarCofre(
                        nome: nomeController.text, email: emailController.text,
                        usuario: userController.text, senha: senhaController.text, color: colorHex,
                      );
                    }
                    if (resp['success'] == true) {
                      Navigator.pop(context);
                      _fetchCofres();
                    }
                  } catch (e) { _showErrorSnackBar("Erro ao salvar."); }
                },
                child: const Text("Confirmar"),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, bool isDark, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
          prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          filled: true,
          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent));

  _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}