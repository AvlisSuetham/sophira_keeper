import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://cyan-grouse-960236.hostingersite.com/api";
  static const String _usuario = "$baseUrl/usuario.php";
  static const String _vault = "$baseUrl/vault.php"; // Endpoint do cofre

  // --- MÉTODOS DE USUÁRIO ---
  
  static Future<Map<String, dynamic>> cadastro(String nome, String cpf, String senha) async {
    final response = await http.post(
      Uri.parse('$_usuario?acao=cadastro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'cpf': cpf,
        'senha': senha,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String cpf, String senha) async {
    final response = await http.post(
      Uri.parse('$_usuario?acao=login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cpf': cpf, 'senha': senha}),
    );
    return jsonDecode(response.body);
  }

  // --- MÉTODOS DO COFRE (VAULT) ---

  static Future<Map<String, dynamic>> listarCofres(int usuarioId) async {
    final response = await http.get(
      Uri.parse('$_vault?acao=listar&usuario_id=$usuarioId'),
    ).timeout(const Duration(seconds: 7));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> adicionarCofre(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$_vault?acao=adicionar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> editarCofre(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$_vault?acao=editar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> excluirCofre(int id, int usuarioId) async {
    final response = await http.get(
      Uri.parse('$_vault?acao=excluir&id=$id&usuario_id=$usuarioId'),
    );
    return jsonDecode(response.body);
  }
}