import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VaultWidget extends StatelessWidget {
  final List<dynamic> cofres;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function({Map<String, dynamic>? registro}) onEdit;
  final void Function(int id) onDelete;

  const VaultWidget({
    super.key,
    required this.cofres,
    required this.isLoading,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  Color _hexToColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  Widget _buildAvatarIcon(String texto, Color cor, {double tamanho = 25}) {
    return CircleAvatar(
      radius: tamanho,
      backgroundColor: cor.withOpacity(0.15),
      child: Text(
        texto.isNotEmpty ? texto[0].toUpperCase() : "?",
        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: tamanho * 0.8),
      ),
    );
  }

  void _showDetailsModal(BuildContext context, Map<String, dynamic> item) {
    final Color corFundo = _hexToColor(item['color'] ?? '#2196F3');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            _buildAvatarIcon(item['servico_nome'], corFundo, tamanho: 40),
            const SizedBox(height: 15),
            Text(item['servico_nome'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 40),
            _buildDetailRow(context, "Usuário", item['servico_usuario'], Icons.person_outline),
            const SizedBox(height: 20),
            _buildDetailRow(context, "Senha", item['servico_senha'], Icons.lock_outline),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String valor, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.blueGrey),
              const SizedBox(width: 12),
              Expanded(child: Text(valor, style: const TextStyle(fontSize: 16, letterSpacing: 0.5))),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.blue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: valor));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label copiado!"), behavior: SnackBarBehavior.floating));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isLoading && cofres.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cofres.isEmpty
              ? ListView(children: const [SizedBox(height: 100), Center(child: Text("Nenhum registro encontrado."))])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: cofres.length,
                  itemBuilder: (context, index) {
                    final item = cofres[index];
                    final Color cor = _hexToColor(item['color'] ?? '#2196F3');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        onTap: () => _showDetailsModal(context, item),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: _buildAvatarIcon(item['servico_nome'], cor),
                        title: Text(item['servico_nome'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1B4B))),
                        subtitle: Text(item['servico_usuario']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () => onEdit(registro: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => onDelete(int.parse(item['id'].toString())),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}