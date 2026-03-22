import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarNovaSenhaController = TextEditingController();
  final _senhaExclusaoController = TextEditingController();

  String nomeUsuario = "Usuário";
  bool carregandoSenha = false;
  bool carregandoExclusao = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarNovaSenhaController.dispose();
    _senhaExclusaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeUsuario = prefs.getString('usuario_nome') ?? "Usuário";
    });
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _alterarSenha() async {
    final senhaAtual = _senhaAtualController.text.trim();
    final novaSenha = _novaSenhaController.text.trim();
    final confirmarNovaSenha = _confirmarNovaSenhaController.text.trim();

    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmarNovaSenha.isEmpty) {
      _mostrarSnackBar("Preencha todos os campos.", Colors.orange);
      return;
    }

    if (novaSenha != confirmarNovaSenha) {
      _mostrarSnackBar("A nova senha e a confirmação não conferem.", Colors.orange);
      return;
    }

    setState(() => carregandoSenha = true);

    final result = await ApiService.alterarSenha(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
      confirmarNovaSenha: confirmarNovaSenha,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarNovaSenhaController.clear();
      _mostrarSnackBar(
        result['message'] ?? "Senha alterada com sucesso.",
        Colors.green,
      );
    } else {
      _mostrarSnackBar(
        result['error'] ?? "Não foi possível alterar a senha.",
        Colors.red,
      );
    }

    setState(() => carregandoSenha = false);
  }

  Future<void> _excluirConta() async {
    final senhaAtual = _senhaExclusaoController.text.trim();

    if (senhaAtual.isEmpty) {
      _mostrarSnackBar("Digite sua senha atual para confirmar.", Colors.orange);
      return;
    }

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: const Text("Excluir conta?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Esta ação é irreversível. Todos os seus dados vinculados à conta serão removidos.",
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaExclusaoController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha atual",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() => carregandoExclusao = true);

    final result = await ApiService.excluirConta(
      senhaAtual: senhaAtual,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await ApiService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _mostrarSnackBar(
        result['message'] ?? "Conta excluída com sucesso.",
        Colors.green,
      );

      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      _mostrarSnackBar(
        result['error'] ?? "Não foi possível excluir a conta.",
        Colors.red,
      );
    }

    setState(() => carregandoExclusao = false);
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFF1A1B4B), const Color(0xFF3730A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Configurações",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF6366F1),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        nomeUsuario,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text("Conta do usuário"),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "ALTERAR SENHA",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPasswordField(
                            controller: _senhaAtualController,
                            label: "Senha atual",
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            controller: _novaSenhaController,
                            label: "Nova senha",
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            controller: _confirmarNovaSenhaController,
                            label: "Confirmar nova senha",
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: carregandoSenha ? null : _alterarSenha,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: carregandoSenha
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "ATUALIZAR SENHA",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    "ZONA CRÍTICA",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Excluir minha conta",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Digite sua senha atual e confirme a exclusão definitiva da conta.",
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _senhaExclusaoController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Senha atual",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: carregandoExclusao ? null : _excluirConta,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: carregandoExclusao
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.delete_forever),
                              label: Text(
                                carregandoExclusao ? "EXCLUINDO..." : "EXCLUIR CONTA",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}