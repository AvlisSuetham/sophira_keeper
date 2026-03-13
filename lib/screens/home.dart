import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

// Importações do projeto
import '../utils/api_service.dart';
import 'password_generator_screen.dart'; 
import 'settings_screen.dart'; 
import 'vault.dart';
import 'tokens.dart'; // NOVO: Componente e Scanner 2FA

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
  
  // Listas de dados
  List<dynamic> cofres = [];
  List<dynamic> tokens = [];
  
  bool isLoading = true;
  bool isOffline = false;
  bool _estaAutenticado = false;

  final List<Color> listaCores = [
    Colors.blue, Colors.red, Colors.green, Colors.purple,
    Colors.orange, Colors.teal, Colors.pink, Colors.indigo,
    Colors.blueGrey, Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _verificarBiometria(); 
  }

  // --- LÓGICA DE BIOMETRIA ADAPTATIVA ---

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

  // --- LÓGICA DE SINCRONIZAÇÃO E CACHE ---

  Future<void> _inicializarApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeUsuario = prefs.getString('usuario_nome') ?? "Usuário";
      inicialNome = nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : "U";
      usuarioId = prefs.getInt('usuario_id') ?? 0;
    });

    await _loadFromCache();
    if (usuarioId > 0) {
      _fetchCofres();
      _fetchTokens(); // Busca os tokens junto com o cofre
    }
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
      if (cachedTokens != null) tokens = jsonDecode(cachedTokens);
      isLoading = false;
    });
  }

  Future<void> _fetchCofres() async {
    if (usuarioId <= 0) return;
    try {
      final data = await ApiService.listarCofres(usuarioId);
      if (data['success'] == true) {
        setState(() {
          cofres = data['data'];
          isOffline = false;
          isLoading = false;
        });
        _saveToCache('cache_vault', data['data']);
      }
    } catch (e) {
      setState(() { isOffline = true; isLoading = false; });
      _loadFromCache();
    }
  }

  // NOVO: Método para buscar os Tokens
  Future<void> _fetchTokens() async {
    if (usuarioId <= 0) return;
    try {
      final data = await ApiService.listarTokens(usuarioId);
      if (data['success'] == true) {
        setState(() {
          tokens = data['data'];
          isOffline = false;
        });
        _saveToCache('cache_tokens', data['data']);
      }
    } catch (e) {
      setState(() { isOffline = true; });
    }
  }

  Future<void> _excluirCofre(int id) async {
    if (isOffline) {
      _showErrorSnackBar("Não é possível excluir enquanto estiver offline.");
      return;
    }
    bool confirmar = await _mostrarConfirmacaoExclusao();
    if (!confirmar) return;

    try {
      final data = await ApiService.excluirCofre(id, usuarioId);
      if (data['success'] == true) _fetchCofres();
    } catch (e) {
      _showErrorSnackBar("Erro ao excluir. Verifique sua conexão.");
    }
  }

  // NOVO: Método para excluir Token
  Future<void> _excluirToken(int id) async {
    if (isOffline) {
      _showErrorSnackBar("Não é possível excluir enquanto estiver offline.");
      return;
    }
    bool confirmar = await _mostrarConfirmacaoExclusao();
    if (!confirmar) return;

    try {
      final data = await ApiService.excluirToken(id, usuarioId);
      if (data['success'] == true) _fetchTokens();
    } catch (e) {
      _showErrorSnackBar("Erro ao excluir. Verifique sua conexão.");
    }
  }

  Future<bool> _mostrarConfirmacaoExclusao() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir registro?"),
        content: const Text("Esta ação removerá o dado do servidor."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  // NOVO: Lógica principal de processamento do QR Code
  Future<void> _escanearESalvarToken() async {
    if (isOffline) {
      _showErrorSnackBar("Conecte-se à internet para salvar um novo token.");
      return;
    }

    // Abre a tela de scanner
    final code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (code == null || code.isEmpty) return; // Usuário cancelou ou não leu nada

    // O formato padrão do Google Authenticator é:
    // otpauth://totp/Emissor:Conta?secret=CHAVE&issuer=Emissor
    try {
      final uri = Uri.parse(code as String);
      
      if (uri.scheme == 'otpauth' && uri.host == 'totp') {
        final secret = uri.queryParameters['secret'];
        if (secret == null) {
          _showErrorSnackBar("QR Code inválido: Chave secreta não encontrada.");
          return;
        }

        // Tenta pegar o nome do emissor (Issuer)
        String servicoNome = uri.queryParameters['issuer'] ?? 'Serviço Desconhecido';
        
        // Se o issuer não estiver nos parâmetros, tenta extrair do path
        if (servicoNome == 'Serviço Desconhecido' && uri.pathSegments.isNotEmpty) {
          servicoNome = Uri.decodeComponent(uri.pathSegments.last);
        }

        // Cor aleatória para o card
        final randomColorHex = '#${listaCores[tokens.length % listaCores.length].value.toRadixString(16).substring(2)}';

        final payload = {
          'usuario_id': usuarioId,
          'servico_nome': servicoNome,
          'servico_otp_secret': secret.toUpperCase(),
          'color': randomColorHex,
        };

        // Salva na API
        final response = await ApiService.adicionarToken(payload);
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Token adicionado com sucesso!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          // Vai para a aba de Tokens e atualiza a lista
          setState(() => _indiceAtual = 1);
          _fetchTokens();
        } else {
          _showErrorSnackBar("Falha ao salvar token no servidor.");
        }
      } else {
        _showErrorSnackBar("Formato de QR Code não suportado.");
      }
    } catch (e) {
      _showErrorSnackBar("Erro ao processar QR Code.");
    }
  }

  // --- INTERFACE ---

  @override
  Widget build(BuildContext context) {
    if (!_estaAutenticado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _indiceAtual == 0 
                  ? VaultWidget(
                      cofres: cofres,
                      isLoading: isLoading,
                      onRefresh: _fetchCofres,
                      onEdit: _showFormDialog,
                      onDelete: _excluirCofre,
                    )
                  : TokensWidget( // Componente NOVO implementado
                      tokens: tokens,
                      isLoading: isLoading,
                      onRefresh: _fetchTokens,
                      onDelete: _excluirToken,
                    ),
              ),
            ],
          ),
          
          if (isOffline)
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B4B).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 12),
                    Text("Modo Offline: Apenas leitura", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
        selectedItemColor: const Color(0xFF1A1B4B),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.lock_rounded), label: 'Senhas'),
          BottomNavigationBarItem(icon: Icon(Icons.security_rounded), label: 'Tokens 2FA'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _indiceAtual == 0 ? _showFormDialog() : _escanearESalvarToken(),
        backgroundColor: const Color(0xFFE91E63),
        elevation: 4,
        label: Text(_indiceAtual == 0 ? "NOVO ACESSO" : "LER QR CODE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: Icon(_indiceAtual == 0 ? Icons.add : Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 25, right: 10, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A1B4B), Color(0xFF2D32A4)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.white24, child: Text(inicialNome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const Spacer(),
              // Botão vinculado para o Scanner de QR Code
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white70), 
                onPressed: _escanearESalvarToken, 
                tooltip: "Escanear QR Code 2FA"
              ),
              IconButton(
                icon: const Icon(Icons.enhanced_encryption_rounded, color: Colors.white70),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordGeneratorScreen())),
                tooltip: "Gerador de Senhas",
              ),
              IconButton(
                icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white70),
                tooltip: "Configurações",
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  _fetchCofres();
                  _fetchTokens();
                },
              ),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout, tooltip: "Sair"),
            ],
          ),
          const SizedBox(height: 25),
          const Text('Bem-vindo ao seu cofre,', style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text(nomeUsuario, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- MODAIS E UTILITÁRIOS ---

  void _showFormDialog({Map<String, dynamic>? registro}) {
    if (isOffline) { _showErrorSnackBar("Conecte-se à internet para salvar."); return; }
    
    final isEditing = registro != null;
    final nomeController = TextEditingController(text: isEditing ? registro['servico_nome'] : '');
    final userController = TextEditingController(text: isEditing ? registro['servico_usuario'] : '');
    final senhaController = TextEditingController(text: isEditing ? registro['servico_senha'] : '');
    
    Color _hexToColor(String hexCode) {
      try { return Color(int.parse(hexCode.replaceFirst('#', '0xFF'))); } catch (e) { return Colors.blue; }
    }
    String _colorToHex(Color color) => '#${color.value.toRadixString(16).substring(2)}';
    
    Color corSelecionada = isEditing ? _hexToColor(registro['color']) : Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? "Editar Registro" : "Novo Registro"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Serviço", prefixIcon: Icon(Icons.apps))),
                TextField(controller: userController, decoration: const InputDecoration(labelText: "Usuário", prefixIcon: Icon(Icons.person))),
                TextField(controller: senhaController, decoration: const InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.vpn_key))),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: listaCores.map((cor) => GestureDetector(
                    onTap: () => setModalState(() => corSelecionada = cor),
                    child: CircleAvatar(radius: 15, backgroundColor: cor, child: corSelecionada == cor ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'usuario_id': usuarioId,
                  'servico_nome': nomeController.text,
                  'servico_usuario': userController.text,
                  'servico_senha': senhaController.text,
                  'color': _colorToHex(corSelecionada),
                };

                try {
                  Map<String, dynamic> responseData;
                  if (isEditing) {
                    payload['id'] = registro['id'];
                    responseData = await ApiService.editarCofre(payload);
                  } else {
                    responseData = await ApiService.adicionarCofre(payload);
                  }

                  if (responseData['success'] == true) {
                    if (context.mounted) Navigator.pop(context);
                    _fetchCofres();
                  } else {
                    _showErrorSnackBar("Falha ao salvar. Verifique os dados.");
                  }
                } catch (e) {
                   _showErrorSnackBar("Erro ao salvar. Verifique sua conexão.");
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String mensagem) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent));

  _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}