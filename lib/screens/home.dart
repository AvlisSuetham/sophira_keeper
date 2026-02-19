import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nomeUsuario = "";
  String inicialNome = "";

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    String nome = prefs.getString('usuario_nome') ?? "Usuário";
    setState(() {
      nomeUsuario = nome;
      // Pega a primeira letra do nome
      inicialNome = nome.isNotEmpty ? nome[0].toUpperCase() : "U";
    });
  }

  _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de Ações Superior
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        inicialNome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Botão de Configurações (Não funcional)
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                        ),
                        // Botão de Logout
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.exit_to_app, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Text(
                  'Olá, $nomeUsuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Text(
                  'Bem-vindo ao seu cofre seguro!',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 25),
                // Barra de Busca Decorativa (Não funcional)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.white60, size: 20),
                      SizedBox(width: 10),
                      Text("Buscar serviço...", style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Área de Conteúdo
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              children: [
                // Card de Segurança "Nível Banco"
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 0.8,
                            strokeWidth: 3,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                          ),
                          const Icon(Icons.shield_outlined, color: Color(0xFFE91E63), size: 20),
                        ],
                      ),
                      const SizedBox(width: 20),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Proteção Ativa",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            "Seu banco de dados está atualizado",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Meus Registros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1B4B))),
                    Text("Ver todos", style: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 15),

                _buildSenhaItem("Netflix", "Premium Family", Icons.play_circle_fill, Colors.red.shade400),
                _buildSenhaItem("Instagram", "Social Media", Icons.camera_rounded, Colors.purple.shade400),
                _buildSenhaItem("Cartão Nu", "Financeiro", Icons.credit_card_rounded, Colors.deepPurple.shade400),
                _buildSenhaItem("E-mail Google", "Trabalho", Icons.email_rounded, Colors.blue.shade400),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFE91E63),
        label: const Text("NOVO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSenhaItem(String titulo, String sub, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1B4B))),
        subtitle: Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}