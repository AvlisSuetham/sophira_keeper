import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// IMPORTANTE: Adicione o import da sua nova tela
import 'backup_screen.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String nomeUsuario = "";
  int usuarioId = 0;
  bool isLoading = false;

  final TextEditingController _senhaAtualController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();

  final String apiUrl = "https://cyan-grouse-960236.hostingersite.com/api/usuario.php";

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeUsuario = prefs.getString('usuario_nome') ?? "Usuário";
      usuarioId = prefs.getInt('usuario_id') ?? 0;
    });
  }

  Future<void> _alterarSenha() async {
    if (_senhaAtualController.text.isEmpty || _novaSenhaController.text.isEmpty) {
      _showSnackBar("Preencha todos os campos", Colors.orange);
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiUrl?acao=alterar_senha'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': usuarioId,
          'senha_atual': _senhaAtualController.text,
          'nova_senha': _novaSenhaController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        _showSnackBar("Senha alterada!", Colors.green);
        _senhaAtualController.clear();
        _novaSenhaController.clear();
      } else {
        _showSnackBar(data['error'] ?? "Erro ao alterar", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Erro de conexão", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _excluirConta() async {
    final TextEditingController confirmacaoController = TextEditingController();

    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir conta definitivamente?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Esta ação apagará seu perfil e todos os seus registros salvos."),
            const SizedBox(height: 15),
            TextField(
              controller: confirmacaoController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Sua senha atual", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('$apiUrl?acao=excluir_conta'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': usuarioId,
            'senha': confirmacaoController.text
          }),
        ).timeout(const Duration(seconds: 15));

        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else {
          _showSnackBar(data['error'] ?? "Senha incorreta", Colors.red);
        }
      } catch (e) {
        _showSnackBar("Servidor offline ou erro de conexão", Colors.red);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: cor, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, left: 10, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A1B4B), Color(0xFF2D32A4)]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                const Text("Configurações", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFF2D32A4), child: Icon(Icons.person, color: Colors.white)),
                      title: Text(nomeUsuario, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // SEÇÃO SEGURANÇA
                  const Text("SEGURANÇA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(controller: _senhaAtualController, obscureText: true, decoration: const InputDecoration(labelText: "Chave Atual")),
                          const SizedBox(height: 15),
                          TextField(controller: _novaSenhaController, obscureText: true, decoration: const InputDecoration(labelText: "Nova Chave Mestra")),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D32A4)),
                              onPressed: isLoading ? null : _alterarSenha,
                              child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ATUALIZAR SENHA", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // SEÇÃO GERENCIAR DADOS (NOVO)
                  const Text("DADOS E BACKUP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen())),
                      leading: const Icon(Icons.storage_rounded, color: Colors.blue),
                      title: const Text("Gerenciar dados", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Exportar ou importar registros."),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  // ZONA CRÍTICA
                  const Text("ZONA CRÍTICA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.red[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.red)),
                    child: ListTile(
                      onTap: isLoading ? null : _excluirConta,
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text("Excluir minha conta", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}