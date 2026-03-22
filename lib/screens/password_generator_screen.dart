import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _senhaGerada = "";
  double _tamanhoSenha = 16;

  void _gerarSenha() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%&*()_+=';
    final random = Random();
    setState(() {
      _senhaGerada = List.generate(_tamanhoSenha.toInt(), 
        (index) => chars[random.nextInt(chars.length)]).join();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Cabeçalho seguindo o padrão da Home
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
                  : [const Color(0xFF1A1B4B), const Color(0xFF3730A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Gerador de Senhas",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Instruções",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : const Color(0xFF1A1B4B)
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Ajuste o comprimento desejado e clique no botão para gerar uma senha segura com caracteres especiais.",
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 14),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Slider de Tamanho
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Comprimento:", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      Text("${_tamanhoSenha.toInt()} caracteres", 
                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _tamanhoSenha,
                    min: 8,
                    max: 32,
                    activeColor: const Color(0xFF6366F1),
                    inactiveColor: isDark ? const Color(0xFF1E293B) : Colors.grey[300],
                    onChanged: (value) => setState(() => _tamanhoSenha = value),
                  ),

                  const SizedBox(height: 30),

                  // Resultado
                  Text("Senha Gerada:", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), 
                          blurRadius: 10
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _senhaGerada.isEmpty ? "---- ---- ---- ----" : _senhaGerada,
                            style: TextStyle(
                              fontSize: 18,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                              color: _senhaGerada.isEmpty 
                                  ? Colors.grey 
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        if (_senhaGerada.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy, color: Color(0xFF6366F1)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _senhaGerada));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Copiado!")),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),

                  // Botão Gerar
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _gerarSenha,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        "GERAR SENHA AGORA",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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