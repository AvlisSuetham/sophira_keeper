import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_service.dart';
import 'backup_screen.dart'; // Certifique-se que o caminho está correto

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
      _mostrarSnackBar(result['message'] ?? "Senha alterada com sucesso.", Colors.green);
    } else {
      _mostrarSnackBar(result['error'] ?? "Não foi possível alterar a senha.", Colors.red);
    }

    setState(() => carregandoSenha = false);
  }

  Future<void> _confirmarExclusaoConta() async {
    _senhaExclusaoController.clear();
    
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: const Text("Confirmar Exclusão"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Esta ação é irreversível. Para continuar, digite sua senha atual:",
                style: TextStyle(fontSize: 14),
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
              child: const Text("Excluir Definitivamente"),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      _processarExclusao();
    }
  }

  Future<void> _processarExclusao() async {
    final senha = _senhaExclusaoController.text.trim();
    if (senha.isEmpty) {
      _mostrarSnackBar("A senha é obrigatória para excluir a conta.", Colors.orange);
      return;
    }

    setState(() => carregandoExclusao = true);

    final result = await ApiService.excluirConta(senhaAtual: senha);

    if (!mounted) return;

    if (result['success'] == true) {
      await ApiService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _mostrarSnackBar("Conta excluída com sucesso.", Colors.green);
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      _mostrarSnackBar(result['error'] ?? "Senha incorreta ou erro no servidor.", Colors.red);
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
            // Header
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
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
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Card Usuário
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF6366F1),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(nomeUsuario, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Conta do usuário"),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SEÇÃO: DADOS
                  _buildSectionTitle("DADOS E BACKUP", isDark, Colors.blueGrey),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      leading: const Icon(Icons.storage_rounded, color: Color(0xFF6366F1)),
                      title: const Text("Importar e Exportar Dados"),
                      subtitle: const Text("Gerenciar backup e restauração"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BackupScreen()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SEÇÃO: ALTERAR SENHA
                  _buildSectionTitle("SEGURANÇA", isDark, Colors.blueGrey),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPasswordField(controller: _senhaAtualController, label: "Senha atual", isDark: isDark),
                          const SizedBox(height: 12),
                          _buildPasswordField(controller: _novaSenhaController, label: "Nova senha", isDark: isDark),
                          const SizedBox(height: 12),
                          _buildPasswordField(controller: _confirmarNovaSenhaController, label: "Confirmar nova senha", isDark: isDark),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: carregandoSenha ? null : _alterarSenha,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: carregandoSenha
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text("ATUALIZAR SENHA", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // SEÇÃO: ZONA CRÍTICA
                  _buildSectionTitle("ZONA CRÍTICA", isDark, Colors.red[400]!),
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
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ao excluir sua conta, todos os seus dados serão removidos permanentemente.",
                            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: carregandoExclusao ? null : _confirmarExclusaoConta,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: carregandoExclusao
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.delete_forever),
                              label: Text(
                                carregandoExclusao ? "EXCLUINDO..." : "SOLICITAR EXCLUSÃO",
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

  Widget _buildSectionTitle(String title, bool isDark, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : color,
        ),
      ),
    );
  }
}