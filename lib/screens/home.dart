import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nomeUsuario = "";
  String inicialNome = "";
  int usuarioId = 0;
  List<dynamic> cofres = [];
  bool isLoading = true;
  bool isOffline = false; // Indica se os dados atuais vieram do cache

  final String apiUrl = "https://cyan-grouse-960236.hostingersite.com/api/vault.php";

  final List<Color> listaCores = [
    Colors.blue, Colors.red, Colors.green, Colors.purple,
    Colors.orange, Colors.teal, Colors.pink, Colors.indigo,
    Colors.blueGrey, Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  // --- LÓGICA DE SINCRONIZAÇÃO E CACHE ---

  Future<void> _inicializarApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeUsuario = prefs.getString('usuario_nome') ?? "Usuário";
      inicialNome = nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : "U";
      usuarioId = prefs.getInt('usuario_id') ?? 0;
    });

    // 1. Carrega o que tiver no cache imediatamente para o usuário não ver tela vazia
    await _loadFromCache();
    
    // 2. Tenta buscar dados novos do servidor
    if (usuarioId > 0) {
      _fetchCofres();
    }
  }

  Future<void> _saveToCache(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_vault_$usuarioId', jsonEncode(data));
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cache_vault_$usuarioId');
    if (cachedData != null) {
      setState(() {
        cofres = jsonDecode(cachedData);
        // Não alteramos isLoading aqui para não interromper a tentativa de fetch
      });
    }
  }

  // --- API: LISTAR ---
  Future<void> _fetchCofres() async {
    try {
      // Timeout de 7 segundos para evitar espera infinita
      final response = await http.get(
        Uri.parse('$apiUrl?acao=listar&usuario_id=$usuarioId'),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            cofres = data['data'];
            isOffline = false;
            isLoading = false;
          });
          _saveToCache(data['data']); // Sincroniza o cache local
        }
      }
    } catch (e) {
      debugPrint("Erro de conexão, operando offline: $e");
      setState(() {
        isOffline = true;
        isLoading = false;
      });
      _loadFromCache(); // Garante que os dados locais estão na tela
    }
  }

  // --- API: EXCLUIR ---
  Future<void> _excluirCofre(int id) async {
    if (isOffline) {
      _showErrorSnackBar("Não é possível excluir enquanto estiver offline.");
      return;
    }

    bool confirmar = await showDialog(
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

    if (!confirmar) return;

    try {
      final response = await http.get(Uri.parse('$apiUrl?acao=excluir&id=$id&usuario_id=$usuarioId'));
      if (jsonDecode(response.body)['success'] == true) {
        _fetchCofres();
      }
    } catch (e) {
      _showErrorSnackBar("Erro ao excluir. Verifique sua conexão.");
    }
  }

  // --- UTILS ---
  void _showErrorSnackBar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  Color _hexToColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  // --- MODAIS (DETALHES E FORMULÁRIO) ---

  void _showDetailsModal(Map<String, dynamic> item) {
    final Color corFundo = _hexToColor(item['color'] ?? '#2196F3');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 30, backgroundColor: corFundo,
              child: Text(item['servico_nome'][0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Text(item['servico_nome'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _buildDetailRow("Usuário", item['servico_usuario'], Icons.person_outline),
            const SizedBox(height: 15),
            _buildDetailRow("Senha", item['servico_senha'], Icons.lock_outline),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String valor, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(child: Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            IconButton(
              icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: valor));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label copiado!")));
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showFormDialog({Map<String, dynamic>? registro}) {
    if (isOffline) {
      _showErrorSnackBar("Conecte-se à internet para salvar alterações.");
      return;
    }

    final isEditing = registro != null;
    final nomeController = TextEditingController(text: isEditing ? registro['servico_nome'] : '');
    final userController = TextEditingController(text: isEditing ? registro['servico_usuario'] : '');
    final senhaController = TextEditingController(text: isEditing ? registro['servico_senha'] : '');
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
                TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Serviço")),
                TextField(controller: userController, decoration: const InputDecoration(labelText: "Usuário")),
                TextField(controller: senhaController, decoration: const InputDecoration(labelText: "Senha")),
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
                if (isEditing) payload['id'] = registro['id'];
                
                final response = await http.post(
                  Uri.parse('$apiUrl?acao=${isEditing ? 'editar' : 'adicionar'}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload)
                );
                
                if (jsonDecode(response.body)['success']) {
                  Navigator.pop(context);
                  _fetchCofres();
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          // Alerta visual de modo offline
          if (isOffline)
            Container(
              width: double.infinity,
              color: Colors.amber[700],
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text("MODO OFFLINE - APENAS LEITURA", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCofres,
              child: isLoading && cofres.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cofres.length,
                    itemBuilder: (context, index) {
                      final item = cofres[index];
                      final Color cor = _hexToColor(item['color'] ?? '#2196F3');
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          onTap: () => _showDetailsModal(item),
                          leading: CircleAvatar(backgroundColor: cor, child: Text(item['servico_nome'][0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                          title: Text(item['servico_nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item['servico_usuario']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFormDialog(registro: item)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _excluirCofre(int.parse(item['id'].toString()))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFFE91E63),
        label: const Text("NOVO", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 25, right: 15, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A1B4B), Color(0xFF2196F3)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(backgroundColor: Colors.white24, child: Text(inicialNome, style: const TextStyle(color: Colors.white))),
              IconButton(onPressed: _logout, icon: const Icon(Icons.exit_to_app, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Olá, $nomeUsuario', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}