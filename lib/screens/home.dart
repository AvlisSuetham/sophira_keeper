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
  final TextEditingController _unlockController = TextEditingController();
  
  int _indiceAtual = 0;
  String nomeUsuario = "";
  String inicialNome = "";
  int usuarioId = 0;

  List<Map<String, dynamic>> tokens = [];
  List<dynamic> cofres = [];

  bool _isLoadingApp = true; // Controla o carregamento inicial
  bool _isLocked = true;     // Controla o bloqueio da tela
  bool _isOfflineMode = false; // Se o usuário escolheu "Apenas Offline"
  bool isOffline = false;      // Se a rede caiu (Dinâmico)
  String _localMasterKey = "";

  final List<Color> listaCores = [
    const Color(0xFF3B82F6), const Color(0xFFEF4444), const Color(0xFF10B981), 
    const Color(0xFF8B5CF6), const Color(0xFFF59E0B), const Color(0xFF06B6D4), 
    const Color(0xFFEC4899), const Color(0xFF6366F1), const Color(0xFF64748B), 
    const Color(0xFFFBBF24),
  ];

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  // --- INICIALIZAÇÃO E VERIFICAÇÃO DE MODO ---
  Future<void> _inicializarApp() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool('is_offline_mode') ?? false;

    if (_isOfflineMode) {
      // Configuração para Modo Estritamente Offline
      nomeUsuario = prefs.getString('local_username') ?? "Usuário Local";
      _localMasterKey = prefs.getString('local_master_key') ?? "";
      inicialNome = nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : "U";
      usuarioId = 0;
      isOffline = true;
      
      await _loadFromCache();
      setState(() { _isLoadingApp = false; }); // Mostra o Lock Screen Local
    } else {
      // Configuração para Modo Online (Nuvem)
      nomeUsuario = prefs.getString('usuario_nome') ?? "Usuário";
      inicialNome = nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : "U";
      usuarioId = prefs.getInt('usuario_id') ?? 0;
      
      await _loadFromCache();
      await _verificarBiometria(); // Biometria desbloqueia a conta online
    }
  }

  Future<void> _verificarBiometria() async {
    if (kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))) {
      setState(() { _isLocked = false; _isLoadingApp = false; });
      _fetchCofres(); _fetchTokens();
      return;
    }

    try {
      final bool podeVerificar = await auth.canCheckBiometrics;
      final bool suporteHardware = await auth.isDeviceSupported();

      if (podeVerificar || suporteHardware) {
        final bool autenticado = await auth.authenticate(
          localizedReason: 'Autentique-se para acessar sua Nuvem Sophira',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );

        if (autenticado) {
          setState(() { _isLocked = false; _isLoadingApp = false; });
          _fetchCofres(); _fetchTokens();
        } else {
          SystemNavigator.pop();
        }
      } else {
        setState(() { _isLocked = false; _isLoadingApp = false; });
        _fetchCofres(); _fetchTokens();
      }
    } on PlatformException catch (_) {
      setState(() { _isLocked = false; _isLoadingApp = false; });
      _fetchCofres(); _fetchTokens();
    }
  }

  // --- CACHE OFFLINE (FONTE DE VERDADE) ---
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
    });
  }

  // --- BUSCA DE DADOS (COM FALLBACK OFFLINE) ---
  Future<void> _fetchCofres() async {
    if (_isOfflineMode) return; // Se for puramente offline, ignora API
    try {
      final data = await ApiService.listarCofres();
      if (data['success'] == true) {
        setState(() { cofres = data['data']; isOffline = false; });
        _saveToCache('cache_vault', cofres);
      } else {
        setState(() => isOffline = true);
      }
    } catch (e) {
      setState(() => isOffline = true);
    }
  }

  Future<void> _fetchTokens() async {
    if (_isOfflineMode) return;
    try {
      final data = await ApiService.listarTokens();
      if (data['success'] == true) {
        setState(() {
          tokens = (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          isOffline = false;
        });
        _saveToCache('cache_tokens', tokens);
      }
    } catch (e) {
      setState(() => isOffline = true);
    }
  }

  // --- EXCLUSÃO COM SUPORTE OFFLINE ---
  Future<void> _excluirCofre(int id) async {
    bool confirmar = await _mostrarConfirmacaoExclusao();
    if (!confirmar) return;

    if (_isOfflineMode || isOffline) {
      setState(() => cofres.removeWhere((c) => c['id'].toString() == id.toString()));
      await _saveToCache('cache_vault', cofres);
      _showSnackBar("Excluído offline com sucesso.", Colors.orange);
      return;
    }

    try {
      final data = await ApiService.excluirCofre(id);
      if (data['success'] == true) _fetchCofres();
    } catch (e) { _showSnackBar("Erro ao excluir no servidor.", Colors.red); }
  }

  Future<void> _excluirToken(int id) async {
    bool confirmar = await _mostrarConfirmacaoExclusao();
    if (!confirmar) return;

    if (_isOfflineMode || isOffline) {
      setState(() => tokens.removeWhere((t) => t['id'].toString() == id.toString()));
      await _saveToCache('cache_tokens', tokens);
      _showSnackBar("Token excluído offline.", Colors.orange);
      return;
    }

    try {
      final data = await ApiService.excluirToken(id);
      if (data['success'] == true) _fetchTokens();
    } catch (e) { _showSnackBar("Erro ao excluir no servidor.", Colors.red); }
  }

  Future<bool> _mostrarConfirmacaoExclusao() async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text("Excluir?", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text("Tem certeza que deseja apagar este item do seu cofre?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  // --- DIALOGO DE FORMULÁRIO (SALVA OFFLINE SE NECESSÁRIO) ---
  void _showFormDialog({Map<String, dynamic>? registro}) {
    final isEditing = registro != null;
    final nomeController = TextEditingController(text: isEditing ? registro['servico_nome'] : '');
    final emailController = TextEditingController(text: isEditing ? registro['servico_email'] : '');
    final userController = TextEditingController(text: isEditing ? registro['servico_usuario'] : '');
    final senhaController = TextEditingController(text: isEditing ? registro['servico_senha'] : '');

    Color hexToColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));
    String colorToHex(Color c) => '#${c.value.toRadixString(16).substring(2)}';
    Color corSelecionada = isEditing && registro['color'] != null ? hexToColor(registro['color']) : listaCores[0];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(isEditing ? "Editar Acesso" : "Novo Acesso", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInput(nomeController, "Serviço", Icons.apps_rounded, isDark),
                  _buildInput(emailController, "E-mail", Icons.alternate_email_rounded, isDark),
                  _buildInput(userController, "Usuário", Icons.person_outline_rounded, isDark),
                  _buildInput(senhaController, "Senha", Icons.lock_outline_rounded, isDark, obscure: true),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: listaCores.map((cor) => GestureDetector(
                      onTap: () => setModalState(() => corSelecionada = cor),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: corSelecionada == cor ? cor : Colors.transparent, width: 2)),
                        child: CircleAvatar(radius: 12, backgroundColor: cor, child: corSelecionada == cor ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  if (nomeController.text.isEmpty) return;
                  final colorHex = colorToHex(corSelecionada);

                  // LOGICA OFFLINE
                  if (_isOfflineMode || isOffline) {
                    final payload = {
                      'id': isEditing ? registro['id'] : DateTime.now().millisecondsSinceEpoch,
                      'servico_nome': nomeController.text, 'servico_email': emailController.text,
                      'servico_usuario': userController.text, 'servico_senha': senhaController.text, 'color': colorHex,
                    };
                    setState(() {
                      if (isEditing) {
                        final idx = cofres.indexWhere((c) => c['id'].toString() == registro['id'].toString());
                        if (idx != -1) cofres[idx] = payload;
                      } else { cofres.add(payload); }
                    });
                    await _saveToCache('cache_vault', cofres);
                    Navigator.pop(context);
                    _showSnackBar("Salvo localmente no modo offline.", Colors.orange);
                    return;
                  }

                  // LOGICA ONLINE
                  try {
                    Map<String, dynamic> resp;
                    if (isEditing) {
                      resp = await ApiService.editarCofre(id: int.parse(registro['id'].toString()), nome: nomeController.text, email: emailController.text, usuario: userController.text, senha: senhaController.text, color: colorHex);
                    } else {
                      resp = await ApiService.adicionarCofre(nome: nomeController.text, email: emailController.text, usuario: userController.text, senha: senhaController.text, color: colorHex);
                    }
                    if (resp['success'] == true) { Navigator.pop(context); _fetchCofres(); }
                  } catch (e) { _showSnackBar("Erro de conexão.", Colors.red); }
                },
                child: const Text("Salvar"),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- INTERFACE PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingApp) return Scaffold(backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), body: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))));
    
    // TELA DE DESBLOQUEIO OFFLINE
    if (_isLocked && _isOfflineMode) return _buildLockScreen(isDark);

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
                      ? VaultWidget(cofres: cofres, isLoading: false, onRefresh: () async { await _loadFromCache(); _fetchCofres(); }, onEdit: _showFormDialog, onDelete: _excluirCofre)
                      : TokensWidget(tokens: tokens, isLoading: false, onRefresh: () async { await _loadFromCache(); _fetchTokens(); }, onDelete: _excluirToken),
                ),
              ),
            ],
          ),

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.lock_outline_rounded), activeIcon: Icon(Icons.lock_rounded), label: 'Senhas'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield_rounded), label: '2FA'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _indiceAtual == 0 ? _showFormDialog() : _showSnackBar("Leitor 2FA não disponível", Colors.grey), // Substitua pela lógica do QR Scanner
        backgroundColor: _indiceAtual == 0 ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
        label: Text(_indiceAtual == 0 ? "NOVA SENHA" : "ESCANEAR", style: const TextStyle(color: Colors.white)),
        icon: Icon(_indiceAtual == 0 ? Icons.add_rounded : Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }

  // --- TELA DE BLOQUEIO LOCAL ---
  Widget _buildLockScreen(bool isDark) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFF1A1B4B), const Color(0xFF3730A3)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text("Olá, $nomeUsuario", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Digite sua Chave Mestra.", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _unlockController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, letterSpacing: 2),
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white10,
                  hintText: "Sua Chave Mestra", hintStyle: const TextStyle(color: Colors.white54, letterSpacing: 0),
                  prefixIcon: const Icon(Icons.password_rounded, color: Colors.white70),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_unlockController.text == _localMasterKey) {
                  setState(() { _isLocked = false; _unlockController.clear(); });
                } else { _showSnackBar("Chave Incorreta!", Colors.redAccent); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text("DESBLOQUEAR COFRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 60, 15, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFF1A1B4B), const Color(0xFF3730A3)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
              _headerIcon(Icons.password_rounded, () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PasswordGeneratorScreen()),
                  )),
              _headerIcon(Icons.settings_outlined, () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
                _fetchCofres();
                _fetchTokens();
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

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, bool isDark, {bool obscure = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: ctrl, obscureText: obscure, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]), prefixIcon: Icon(icon, size: 20), filled: true, fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))));
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}