import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // --- 1. CARREGAR DADOS DO USUÁRIO ---
  _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    String nome = prefs.getString('usuario_nome') ?? "Usuário";
    
    setState(() {
      nomeUsuario = nome;
      inicialNome = nome.isNotEmpty ? nome[0].toUpperCase() : "U";
      usuarioId = prefs.getInt('usuario_id') ?? 0;
    });

    if (usuarioId > 0) {
      _fetchCofres();
    }
  }

  // --- 2. BUSCAR DADOS (READ) ---
  Future<void> _fetchCofres() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiUrl?acao=listar&usuario_id=$usuarioId'));
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() => cofres = data['data']);
      }
    } catch (e) {
      debugPrint("Erro ao carregar cofres: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- 3. EXCLUIR DADOS (DELETE) ---
  Future<void> _excluirCofre(int id) async {
    // Confirmação antes de excluir
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
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        _fetchCofres();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registro excluído!"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Erro ao excluir: $e");
    }
  }

  // --- 4. MODAL DE FORMULÁRIO (CREATE / UPDATE) ---
  void _showFormDialog({Map<String, dynamic>? registro}) {
    final isEditing = registro != null;
    final nomeController = TextEditingController(text: isEditing ? registro['servico_nome'] : '');
    final userController = TextEditingController(text: isEditing ? registro['servico_usuario'] : '');
    final senhaController = TextEditingController(text: isEditing ? registro['servico_senha'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? "Editar Registro" : "Novo Registro"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: "Nome do Serviço (ex: Netflix)", prefixIcon: Icon(Icons.label)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: "Usuário/E-mail", prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: senhaController,
                decoration: const InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.lock)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), foregroundColor: Colors.white),
            onPressed: () async {
              if (nomeController.text.isEmpty || userController.text.isEmpty || senhaController.text.isEmpty) return;

              final payload = {
                'usuario_id': usuarioId,
                'servico_nome': nomeController.text,
                'servico_usuario': userController.text,
                'servico_senha': senhaController.text,
              };

              if (isEditing) payload['id'] = registro['id'];

              final acao = isEditing ? 'editar' : 'adicionar';

              try {
                final response = await http.post(
                  Uri.parse('$apiUrl?acao=$acao'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                );
                final data = jsonDecode(response.body);

                if (data['success'] == true) {
                  Navigator.pop(context);
                  _fetchCofres();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvo com sucesso!"), backgroundColor: Colors.green));
                  }
                }
              } catch (e) {
                debugPrint("Erro ao salvar: $e");
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  // --- GERA COR DINÂMICA BASEADA NO NOME ---
  Color _obterCor(String nome) {
    final cores = [Colors.red, Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.teal];
    int hash = nome.codeUnits.fold(0, (prev, curr) => prev + curr);
    return cores[hash % cores.length].shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header Gradiente Premium
          Container(
            padding: const EdgeInsets.only(top: 50, left: 25, right: 15, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1B4B), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(inicialNome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Row(
                      children: [
                        IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.white70)),
                        IconButton(onPressed: _logout, icon: const Icon(Icons.exit_to_app, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Text('Olá, $nomeUsuario', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const Text('Bem-vindo ao seu cofre seguro!', style: TextStyle(color: Colors.white70, fontSize: 15)),
              ],
            ),
          ),

          // Área de Conteúdo
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
                : cofres.isEmpty
                    ? const Center(child: Text("Seu cofre está vazio. Adicione um registro!"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        itemCount: cofres.length,
                        itemBuilder: (context, index) {
                          final item = cofres[index];
                          final cor = _obterCor(item['servico_nome']);

                          return _buildSenhaItem(item, cor);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(), // Abre modal vazio (NOVO)
        backgroundColor: const Color(0xFFE91E63),
        label: const Text("NOVO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSenhaItem(Map<String, dynamic> item, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.lock_outline, color: iconColor, size: 24),
        ),
        title: Text(item['servico_nome'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1B4B))),
        subtitle: Text(item['servico_usuario'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Lápis (Edição)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _showFormDialog(registro: item),
            ),
            // Botão Lixeira (Exclusão)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _excluirCofre(int.parse(item['id'].toString())),
            ),
          ],
        ),
      ),
    );
  }
}