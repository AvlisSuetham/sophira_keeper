import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 1. MUDANÇA PARA HTTPS
  static const String baseUrl = "https://keeper.sophira.com.br/api";

  /* ================= HEADERS ================= */
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // User-Agent ajuda a evitar bloqueios de Firewalls de servidores (como ModSecurity)
      'User-Agent': 'SophiraKeeper/1.0', 
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /* ================= TRATAMENTO DE ERRO GENÉRICO ================= */
  // Função auxiliar para logar erros reais no console durante o debug
  static Map<String, dynamic> _handleError(dynamic e, String mensagemPadrao) {
    print("Erro detalhado na API: $e");
    return {'success': false, 'error': '$mensagemPadrao: ${e.toString()}'};
  }

  /* ================= AUTENTICAÇÃO (USER) ================= */

  static Future<Map<String, dynamic>> cadastro(
      String nome, String email, String cpf, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cadastro'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': nome,
          'email': email,
          'cpf': cpf,
          'password': senha,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Falha de conexão ao cadastrar');
    }
  }

  static Future<Map<String, dynamic>> login(String cpf, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: await _getHeaders(),
        body: jsonEncode({'cpf': cpf, 'password': senha}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
      }
      return data;
    } catch (e) {
      return _handleError(e, 'Erro ao tentar autenticar');
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
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao buscar registros do cofre');
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
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Falha de conexão ao salvar');
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
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Falha de conexão ao editar');
    }
  }

  static Future<Map<String, dynamic>> excluirCofre(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cofre/$id'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao processar exclusão');
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
      return _handleError(e, 'Falha na importação');
    }
  }

  /* ================= MÓDULO: TOKENS 2FA ================= */

  static Future<Map<String, dynamic>> listarTokens() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tokens'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao listar tokens');
    }
  }

  static Future<Map<String, dynamic>> adicionarToken(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tokens'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao salvar token');
    }
  }

  static Future<Map<String, dynamic>> excluirToken(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tokens/$id'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao remover token');
    }
  }
}