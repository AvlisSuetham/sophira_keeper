import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://cyan-grouse-960236.hostingersite.com/api";
  static const String _usuario = "$baseUrl/usuario.php";

  // Método de Cadastro sincronizado com o seu PHP antigo
  static Future<Map<String, dynamic>> cadastro(String nome, String cpf, String senha) async {
    final response = await http.post(
      Uri.parse('$_usuario?acao=cadastro'), // Ajustado de 'cadastrar' para 'cadastro'
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
}