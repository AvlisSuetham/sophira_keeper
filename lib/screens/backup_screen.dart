import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool isProcessing = false;
  final String apiUrl = "https://cyan-grouse-960236.hostingersite.com/api/vault.php";

  void _showMsg(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m), 
        backgroundColor: c, 
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      )
    );
  }

  Future<void> _exportarBackup() async {
    setState(() => isProcessing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int usuarioId = prefs.getInt('usuario_id') ?? 0;

      final response = await http.get(Uri.parse('$apiUrl?acao=listar&usuario_id=$usuarioId'));
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        List registros = data['data'];
        
        var backupData = registros.map((e) => {
          'servico_nome': e['servico_nome'],
          'servico_usuario': e['servico_usuario'],
          'servico_senha': e['servico_senha'],
          'color': e['color'],
        }).toList();

        String jsonString = jsonEncode(backupData);
        String fileName = 'backup_sophira_${DateTime.now().millisecondsSinceEpoch}.sph';

        if (!kIsWeb && Platform.isLinux) {
          String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Selecione onde salvar seu backup',
            fileName: fileName,
            allowedExtensions: ['sph'],
            type: FileType.custom,
          );

          if (outputFile != null) {
            final file = File(outputFile);
            await file.writeAsString(jsonString);
            _showMsg("Backup salvo com sucesso!", Colors.green);
          }
        } else if (kIsWeb) {
          _showMsg("Exportação via Web não implementada nesta view.", Colors.orange);
        } else {
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(jsonString);

          await Share.shareXFiles(
            [XFile(file.path)], 
            text: 'Meu Backup Sophira Keeper',
            subject: 'Backup de Senhas'
          );
        }
      } else {
        _showMsg("Erro ao obter dados: ${data['error']}", Colors.red);
      }
    } catch (e) {
      _showMsg("Erro ao exportar: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _importarBackup() async {
    try {
      // Alterado para FileType.any para permitir qualquer arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        setState(() => isProcessing = true);
        
        String content;
        
        // Suporte para leitura em múltiplas plataformas (Bytes para Web, Path para Mobile/Desktop)
        if (kIsWeb) {
          content = utf8.decode(result.files.single.bytes!);
        } else {
          final file = File(result.files.single.path!);
          content = await file.readAsString();
        }

        final List registros = jsonDecode(content);

        final prefs = await SharedPreferences.getInstance();
        final int usuarioId = prefs.getInt('usuario_id') ?? 0;

        final response = await http.post(
          Uri.parse('$apiUrl?acao=importar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'usuario_id': usuarioId,
            'registros': registros
          }),
        );

        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          _showMsg("${resData['importados']} registros importados com sucesso!", Colors.green);
        } else {
          _showMsg("Erro na importação: ${resData['error']}", Colors.red);
        }
      }
    } catch (e) {
      debugPrint("Erro na importação: $e");
      _showMsg("Erro: Arquivo inválido ou corrompido.", Colors.red);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Backup e Restauração"), 
        backgroundColor: const Color(0xFF1A1B4B), 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isProcessing 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Processando dados...", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildOptionCard(
                  "Exportar Dados", 
                  "Gera um arquivo com suas senhas atuais para segurança ou migração.", 
                  Icons.cloud_upload_outlined, 
                  Colors.blue, 
                  _exportarBackup
                ),
                const SizedBox(height: 20),
                _buildOptionCard(
                  "Importar Dados", 
                  "Selecione qualquer arquivo de backup para restaurar seus registros.", 
                  Icons.file_download_outlined, 
                  Colors.green, 
                  _importarBackup
                ),
                const SizedBox(height: 40),
                _buildWarningBox(),
              ],
            ),
          ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3))
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "Atenção: Arquivos de backup contêm suas senhas. Mantenha-os em local seguro e evite compartilhá-los com terceiros.",
              style: TextStyle(color: Colors.black87, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOptionCard(String title, String desc, IconData icon, Color color, VoidCallback action) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.2))
      ),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.1), 
                child: Icon(icon, color: color, size: 28)
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}