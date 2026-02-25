import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para o Clipboard
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

  final String apiUrl = "https://cyan-grouse-960236.hostingersite.com/api/vault.php";

  // Cores disponíveis para o usuário escolher
  final List<Color> listaCores = [
    Colors.blue, Colors.red, Colors.green, Colors.purple,
    Colors.orange, Colors.teal, Colors.pink, Colors.indigo,
    Colors.blueGrey, Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // --- UTILITÁRIOS DE COR ---
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

  // --- CARREGAR DADOS INICIAIS ---
  _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    String nome = prefs.getString('usuario_nome') ?? "Usuário";
    setState(() {
      nomeUsuario = nome;
      inicialNome = nome.isNotEmpty ? nome[0].toUpperCase() : "U";
      usuarioId = prefs.getInt('usuario_id') ?? 0;
    });
    if (usuarioId > 0) _fetchCofres();
  }

  // --- API: LISTAR ---
  Future<void> _fetchCofres() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiUrl?acao=listar&usuario_id=$usuarioId'));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => cofres = data['data']);
      }
    } catch (e) {
      debugPrint("Erro ao carregar: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- API: EXCLUIR ---
  Future<void> _excluirCofre(int id) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir registro?"),
        content: const Text("Esta ação não pode ser desfeita."),
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
      debugPrint("Erro ao excluir: $e");
    }
  }

  // --- MODAL: DETALHES (AO CLICAR NO CARD) ---
  void _showDetailsModal(Map<String, dynamic> item) {
    final Color corFundo = _hexToColor(item['color'] ?? '#2196F3');
    final String inicial = item['servico_nome'].toString().isNotEmpty ? item['servico_nome'][0].toUpperCase() : "?";

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
              radius: 30,
              backgroundColor: corFundo,
              child: Text(inicial, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Text(item['servico_nome'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _buildDetailRow("Usuário", item['servico_usuario'], Icons.person_outline),
            const SizedBox(height: 15),
            _buildDetailRow("Senha", item['servico_senha'], Icons.lock_outline),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1B4B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("FECHAR", style: TextStyle(color: Colors.white)),
              ),
            ),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label copiado!"), duration: const Duration(seconds: 1)));
              },
            ),
          ],
        ),
      ],
    );
  }

  // --- MODAL: FORMULÁRIO (ADD / EDIT) ---
  void _showFormDialog({Map<String, dynamic>? registro}) {
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
                TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Serviço", prefixIcon: Icon(Icons.label))),
                TextField(controller: userController, decoration: const InputDecoration(labelText: "Usuário", prefixIcon: Icon(Icons.person))),
                TextField(controller: senhaController, decoration: const InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.lock))),
                const SizedBox(height: 20),
                const Text("Cor do ícone:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: listaCores.map((cor) => GestureDetector(
                    onTap: () => setModalState(() => corSelecionada = cor),
                    child: CircleAvatar(
                      radius: 18, backgroundColor: cor,
                      child: corSelecionada == cor ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isEmpty) return;
                final payload = {
                  'usuario_id': usuarioId,
                  'servico_nome': nomeController.text,
                  'servico_usuario': userController.text,
                  'servico_senha': senhaController.text,
                  'color': _colorToHex(corSelecionada),
                };
                if (isEditing) payload['id'] = registro['id'];
                
                final acao = isEditing ? 'editar' : 'adicionar';
                final response = await http.post(Uri.parse('$apiUrl?acao=$acao'),
                    headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
                
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cofres.length,
                    itemBuilder: (context, index) {
                      final item = cofres[index];
                      final Color cor = _hexToColor(item['color'] ?? '#2196F3');
                      final String inicial = item['servico_nome'].toString().isNotEmpty ? item['servico_nome'][0].toUpperCase() : "?";
                      return _buildSenhaItem(item, cor, inicial);
                    },
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

  Widget _buildSenhaItem(Map<String, dynamic> item, Color cor, String inicial) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => _showDetailsModal(item),
        leading: CircleAvatar(backgroundColor: cor, child: Text(inicial, style: const TextStyle(color: Colors.white))),
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
  }
}