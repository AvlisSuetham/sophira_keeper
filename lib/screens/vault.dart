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

  // Converte Hex para Color com suporte a fallback
  Color _hexToColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  // Ícone de Avatar estilizado com gradiente
  Widget _buildAvatarIcon(String texto, Color cor, {double tamanho = 28}) {
    return Container(
      width: tamanho * 2,
      height: tamanho * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cor.withOpacity(0.7), cor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          texto.isNotEmpty ? texto[0].toUpperCase() : "?",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: tamanho * 0.9,
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label, bool isDark) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado!'),
        behavior: SnackBarBehavior.floating,
        width: 200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
      ),
    );
  }

  // MODAL DE DETALHES REESTILIZADO
  void _showDetailsModal(BuildContext context, Map<String, dynamic> item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color corTema = _hexToColor(item['color'] ?? '#6366F1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de arraste
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 30),
            _buildAvatarIcon(item['servico_nome'], corTema, tamanho: 35),
            const SizedBox(height: 16),
            Text(
              item['servico_nome'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 25),
            
            // Container de Informações (Card Interno)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (item['servico_usuario']?.toString().isNotEmpty ?? false)
                    _buildDetailItem(context, Icons.person_outline_rounded, "Usuário", item['servico_usuario'], isDark),
                  if (item['servico_email']?.toString().isNotEmpty ?? false) ...[
                    Divider(height: 30, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                    _buildDetailItem(context, Icons.alternate_email_rounded, "E-mail", item['servico_email'], isDark),
                  ],
                  Divider(height: 30, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  _buildDetailItem(context, Icons.lock_outline_rounded, "Senha", item['servico_senha'], isDark, isPassword: true),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete(int.parse(item['id'].toString()));
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    label: const Text("Excluir", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit(registro: item);
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 22),
                    label: const Text("Editar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value, bool isDark, {bool isPassword = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text(
                isPassword ? "••••••••••••" : value,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.w600, 
                  color: isDark ? Colors.white : const Color(0xFF1E293B)
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_all_rounded, size: 20, color: Color(0xFF6366F1)),
          onPressed: () => _copyToClipboard(context, value, label, isDark),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: onRefresh,
      child: isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : cofres.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // Padding extra no fundo para o FAB
                  itemCount: cofres.length,
                  itemBuilder: (context, index) {
                    final item = cofres[index];
                    final Color cor = _hexToColor(item['color'] ?? '#6366F1');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _showDetailsModal(context, item),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: _buildAvatarIcon(item['servico_nome'], cor, tamanho: 24),
                        title: Text(
                          item['servico_nome'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          (item['servico_email']?.toString().isNotEmpty ?? false)
                              ? item['servico_email']
                              : (item['servico_usuario'] ?? 'Sem usuário'),
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black12),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_moon_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 20),
          Text(
            "Seu cofre está vazio",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white38 : Colors.grey[600]
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Toque no botão + para começar",
            style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}