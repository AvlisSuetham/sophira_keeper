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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Cabeçalho seguindo o padrão da Home
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1B4B), Color(0xFF2D32A4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
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
                  const Text(
                    "Instruções",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1B4B)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Ajuste o comprimento desejado e clique no botão para gerar uma senha segura com caracteres especiais.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Slider de Tamanho
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Comprimento:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("${_tamanhoSenha.toInt()} caracteres", 
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _tamanhoSenha,
                    min: 8,
                    max: 32,
                    activeColor: const Color(0xFF2D32A4),
                    onChanged: (value) => setState(() => _tamanhoSenha = value),
                  ),

                  const SizedBox(height: 30),

                  // Resultado
                  const Text("Senha Gerada:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
                              color: _senhaGerada.isEmpty ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                        if (_senhaGerada.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy, color: Color(0xFF2D32A4)),
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
                        backgroundColor: const Color(0xFF2D32A4),
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