import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para copiar para a área de transferência

class ForgottenScreen extends StatelessWidget {
  const ForgottenScreen({super.key});

  // Função para copiar texto e mostrar aviso
  void _copiarParaAreaDeTransferencia(BuildContext context, String texto, String tipo) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$tipo copiado para a área de transferência!'),
        backgroundColor: const Color(0xFF2196F3),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1B4B),
              Color(0xFF2196F3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone de Segurança
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 70,
                  color: Color(0xFFE91E63),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Chave Mestra',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Card de Informação
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Para sua segurança, a recuperação da chave mestra deverá ser solicitada diretamente com sua gerência de conta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1B4B),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    
                    // E-mail
                    _buildContactTile(
                      context,
                      icon: Icons.email_outlined,
                      title: 'suporte@sophira.com.br',
                      subtitle: 'Toque para copiar e-mail',
                      onTap: () => _copiarParaAreaDeTransferencia(context, 'suporte@sophira.com.br', 'E-mail'),
                    ),

                    // Telefone (Mensagem Somente)
                    _buildContactTile(
                      context,
                      icon: Icons.message_outlined,
                      title: '(11) 99602-3625',
                      subtitle: 'Somente via mensagem (WhatsApp)',
                      onTap: () => _copiarParaAreaDeTransferencia(context, '11996023625', 'Número'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Demais instruções serão fornecidas no contato.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 40),

              // Botão Voltar
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'VOLTAR AO LOGIN',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para os itens de contato
  Widget _buildContactTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2196F3)),
      ),
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1B4B))
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.copy_all_outlined, size: 18, color: Colors.grey),
    );
  }
}