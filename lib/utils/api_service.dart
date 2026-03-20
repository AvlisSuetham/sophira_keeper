import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ DICA: Se usar emulador Android, troque 'localhost' por '10.0.2.2'
  static const String baseUrl = "http://localhost:8000/api";

  /* ================= HEADERS ================= */
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /* ================= AUTENTICAÇÃO (USER) ================= */

  static Future<Map<String, dynamic>> cadastro(
      String nome, String email, String cpf, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cadastro'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': nome,
          'email': email,
          'cpf': cpf,
          'password': senha,
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Falha de conexão com o servidor'};
    }
  }

  static Future<Map<String, dynamic>> login(String cpf, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'cpf': cpf, 'password': senha}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'error': 'Erro ao tentar autenticar'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  /* ================= MÓDULO: COFRE (SOPHIRA KEEPER) ================= */

  static Future<Map<String, dynamic>> listarCofres() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cofre'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Erro ao buscar registros do cofre'};
    }
  }

  static Future<Map<String, dynamic>> adicionarCofre({
    required String nome,
    required String senha,
    String? email,
    String? usuario,
    String color = '#2196F3',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cofre'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'servico_nome': nome,
          'servico_email': email,
          'servico_usuario': usuario,
          'servico_senha': senha,
          'color': color,
        }),
      ).timeout(const Duration(seconds: 10));

      // Laravel retorna 201 Created para novos registros
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      
      final erroBody = jsonDecode(response.body);
      return {'success': false, 'error': erroBody['error'] ?? 'Erro ao salvar'};
    } catch (e) {
      return {'success': false, 'error': 'Falha de conexão'};
    }
  }

  static Future<Map<String, dynamic>> editarCofre({
    required int id,
    required String nome,
    required String senha,
    String? email,
    String? usuario,
    String? color,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cofre/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'servico_nome': nome,
          'servico_email': email,
          'servico_usuario': usuario,
          'servico_senha': senha,
          'color': color,
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Falha de conexão'};
    }
  }

  static Future<Map<String, dynamic>> excluirCofre(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cofre/$id'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Erro ao processar exclusão'};
    }
  }

  static Future<Map<String, dynamic>> importarCofres(List<dynamic> registros) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cofre/importar'),
        headers: await _getHeaders(),
        body: jsonEncode({'registros': registros}),
      ).timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Falha na importação de lote'};
    }
  }

  /* ================= MÓDULO: TOKENS 2FA ================= */

  static Future<Map<String, dynamic>> listarTokens() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tokens'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Erro ao listar tokens'};
    }
  }

  static Future<Map<String, dynamic>> adicionarToken(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tokens'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Erro ao salvar token'};
    }
  }

  static Future<Map<String, dynamic>> excluirToken(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tokens/$id'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Erro ao remover token'};
    }
  }
}