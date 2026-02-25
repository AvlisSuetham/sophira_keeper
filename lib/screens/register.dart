import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  final maskCpf = MaskTextInputFormatter(
    mask: "###.###.###-##",
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool loading = false;

  // Função para abrir o Modal de Termos
  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1B4B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Termos e Condições',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
                child: SingleChildScrollView(
                child: const Text(
                  "1. Aceitação dos Termos\nAo criar uma conta no Sophira Keeper, você concorda integralmente com estas regras. Este é um contrato vinculativo entre você e a Sophira Keeper para garantir a segurança das suas credenciais.\n\n"
                  "2. Descrição do Serviço\nO Sophira Keeper é um gerenciador de senhas projetado para segurança e organização pessoal. O serviço permite o armazenamento criptografado de senhas, sincronização entre múltiplos dispositivos e acesso offline.\n\n"
                  "3. O Modelo de Segurança e a 'Chave Mestra'\n"
                  "Arquitetura de Segurança: O Sophira Keeper utiliza criptografia onde o usuário possui a chave de acesso principal (Senha Mestra). Nós não temos acesso direto à sua Senha Mestra. "
                  "Em caso de perda, a recuperação dos dados é possível exclusivamente através do contato com a sua gerência de contas. "
                  "Neste processo, mediante a comprovação inequívoca de identidade do portador, os dados serão recuperados e a conta atual será excluída para garantir a integridade do sistema.\n\n" // Linha 3 modificada conforme solicitado
                  "4. Privacidade e Dados Pessoais\nCriptografia de Ponta: Suas senhas são criptografadas antes de saírem do seu dispositivo. Operamos em conformidade com a LGPD.\n\n"
                  "5. Obrigações do Usuário\nO usuário concorda em manter o sistema operacional atualizado, utilizar uma senha mestra forte e exclusiva, e não utilizar o serviço para atividades ilegais.\n\n"
                  "6. Limitação de Responsabilidade\nO Sophira Keeper não se responsabiliza por acesso indevido resultante de negligência do usuário, furto do dispositivo ou falhas de hardware que corrompam o banco de dados local.",
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
                child: const Text('ENTENDI', style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> register() async {
    final cpfLimpo = maskCpf.getUnmaskedText();

    if (nomeController.text.isEmpty || cpfLimpo.isEmpty || senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('https://cyan-grouse-960236.hostingersite.com/api/usuario.php?acao=cadastro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nomeController.text,
          'cpf': cpfLimpo,
          'senha': senhaController.text,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() => loading = false);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso! Faça login.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Erro no cadastro')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1B4B), Color(0xFF2196F3), Color(0xFFE91E63)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person_add_outlined, size: 80, color: Colors.white24);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nova Conta',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(controller: nomeController, label: 'Nome Completo', icon: Icons.badge_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: cpfController,
                      label: 'CPF',
                      icon: Icons.person_outline,
                      formatters: [maskCpf],
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(controller: senhaController, label: 'Senha', icon: Icons.lock_outline, obscure: true),
                    const SizedBox(height: 32),
                    
                    // Botão de Registro
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: loading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('CRIAR MINHA CONTA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // --- AVISO DE TERMOS ADICIONADO AQUI ---
                    GestureDetector(
                      onTap: _showTermsModal,
                      child: const Text.rich(
                        TextSpan(
                          text: 'Ao efetuar seu cadastro, você concorda com os ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'termos e condições de uso da aplicação',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    List<TextInputFormatter>? formatters,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}