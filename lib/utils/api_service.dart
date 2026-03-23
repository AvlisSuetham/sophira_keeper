import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://keeper.sophira.com.br/api";

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'SophiraKeeper/1.0',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Tratamento Unificado de Erros para suportar Modo Offline
  static Map<String, dynamic> _handleError(dynamic e, String mensagemPadrao) {
    if (e is SocketException || e is TimeoutException) {
      return {
        'success': false,
        'error': 'Sem conexão com o servidor. Operando em modo offline.',
        'is_offline': true,
      };
    }
    return {
      'success': false,
      'error': '$mensagemPadrao: ${e.toString()}',
      'is_offline': false,
    };
  }

  /* ================= AUTENTICAÇÃO ================= */

  static Future<Map<String, dynamic>> cadastro(
    String nome,
    String email,
    String cpf,
    String senha,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/cadastro'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'name': nome,
              'email': email,
              'cpf': cpf,
              'password': senha,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Falha de conexão ao cadastrar');
    }
  }

  static Future<Map<String, dynamic>> login(String cpf, String senha) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'cpf': cpf,
              'password': senha,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        if (data['user'] != null && data['user'] is Map<String, dynamic>) {
          final user = data['user'] as Map<String, dynamic>;
          await prefs.setInt('usuario_id', user['id'] ?? 0);
          await prefs.setString('usuario_nome', user['nome'] ?? '');
          await prefs.setString('usuario_email', user['email'] ?? '');
        }
      }

      return data;
    } catch (e) {
      return _handleError(e, 'Erro ao tentar autenticar');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_nome');
    await prefs.remove('usuario_email');
  }

  /* ================= PERFIL ================= */

  static Future<Map<String, dynamic>> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/alterar-senha'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'current_password': senhaAtual,
              'new_password': novaSenha,
              'new_password_confirmation': confirmarNovaSenha,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Falha de conexão ao alterar a senha');
    }
  }

  static Future<Map<String, dynamic>> excluirConta({
    required String senhaAtual,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/excluir-conta'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'current_password': senhaAtual,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Falha de conexão ao excluir a conta');
    }
  }

  /* ================= MÓDULO: COFRE ================= */

  static Future<Map<String, dynamic>> listarCofres() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/cofre'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 8)); // Timeout menor para detecção rápida offline

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
      final response = await http
          .post(
            Uri.parse('$baseUrl/cofre'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'servico_nome': nome,
              'servico_email': email,
              'servico_usuario': usuario,
              'servico_senha': senha,
              'color': color,
            }),
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await http
          .put(
            Uri.parse('$baseUrl/cofre/$id'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'servico_nome': nome,
              'servico_email': email,
              'servico_usuario': usuario,
              'servico_senha': senha,
              'color': color,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Falha de conexão ao editar');
    }
  }

  static Future<Map<String, dynamic>> excluirCofre(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/cofre/$id'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao processar exclusão');
    }
  }

  static Future<Map<String, dynamic>> importarCofres(List<dynamic> registros) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/cofre/importar'),
            headers: await _getHeaders(),
            body: jsonEncode({'registros': registros}),
          )
          .timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Falha na importação');
    }
  }

  /* ================= MÓDULO: TOKENS 2FA ================= */

  static Future<Map<String, dynamic>> listarTokens() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/tokens'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao listar tokens');
    }
  }

  static Future<Map<String, dynamic>> adicionarToken(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/tokens'),
            headers: await _getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao salvar token');
    }
  }

  static Future<Map<String, dynamic>> excluirToken(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/tokens/$id'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e, 'Erro ao remover token');
    }
  }
}