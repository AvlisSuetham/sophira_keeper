// lib/screens/tokens.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Componente de tokens 2FA + scanner QR
/// Tokens: List<Map<String, dynamic>>
class TokensWidget extends StatefulWidget {
  final List<Map<String, dynamic>> tokens;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int) onDelete;

  const TokensWidget({
    super.key,
    required this.tokens,
    required this.isLoading,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  State<TokensWidget> createState() => _TokensWidgetState();
}

class _TokensWidgetState extends State<TokensWidget> {
  Timer? _timer;
  int _tempoRestante = 30;

  // Cores base para a UI
  final Color _deepBlue = const Color(0xFF1A1B4B);
  final Color _neonPink = const Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _atualizarTempo();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _atualizarTempo();
    });
  }

  void _atualizarTempo() {
    setState(() {
      _tempoRestante = 30 - (DateTime.now().second % 30);
      if (_tempoRestante == 0) _tempoRestante = 30;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _hexToColor(String? hexCode) {
    if (hexCode == null || hexCode.isEmpty) return _deepBlue;
    try {
      final cleaned = hexCode.replaceFirst('#', '');
      final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
      return Color(int.parse('0x$value'));
    } catch (_) {
      return _deepBlue;
    }
  }

  String _gerarCodigo(String? secret) {
    if (secret == null || secret.isEmpty) return "000000";
    try {
      final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final code = OTP.generateTOTPCodeString(
        secret,
        seconds,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      return code.padLeft(6, '0');
    } catch (_) {
      return "000000";
    }
  }

  void _copiarParaAreaTransferencia(BuildContext context, String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Código 2FA copiado!"),
          ],
        ),
        backgroundColor: _deepBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int _parseId(dynamic idField) {
    if (idField is int) return idField;
    if (idField is String) return int.tryParse(idField) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _neonPink),
      );
    }

    if (widget.tokens.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: _neonPink,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _deepBlue.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.security_rounded, size: 80, color: _deepBlue.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Nenhum token 2FA cadastrado",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Toque no botão flutuante para escanear um QR Code",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: _neonPink,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.tokens.length,
        itemBuilder: (context, index) {
          final token = widget.tokens[index];
          final color = _hexToColor(token['color']?.toString());
          final String codigoAtual = _gerarCodigo(token['servico_otp_secret']?.toString());

          final String codigoFormatado = codigoAtual.length == 6
              ? "${codigoAtual.substring(0, 3)} ${codigoAtual.substring(3)}"
              : codigoAtual;

          final bool estaExpirando = _tempoRestante <= 5;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _deepBlue.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _copiarParaAreaTransferencia(context, codigoAtual),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Ícone do Serviço
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.shield_rounded, color: color, size: 28),
                          ),
                          const SizedBox(width: 16),
                          
                          // Nome do Serviço e Código
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  token['servico_nome']?.toString() ?? 'Serviço',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  codigoFormatado,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    fontFamily: 'monospace', // Dá um ar tech/cyberpunk
                                    color: estaExpirando ? _neonPink : _deepBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Menu de Opções
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) async {
                              if (value == 'excluir') {
                                final id = _parseId(token['id']);
                                if (id > 0) {
                                  await widget.onDelete(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("ID inválido para exclusão")),
                                  );
                                }
                              } else if (value == 'copiar') {
                                _copiarParaAreaTransferencia(context, codigoAtual);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'copiar',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded, size: 20, color: Colors.black54),
                                    SizedBox(width: 12),
                                    Text('Copiar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Excluir', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Barra de Progresso Animada
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 6,
                          child: LinearProgressIndicator(
                            value: _tempoRestante / 30,
                            backgroundColor: Colors.grey[100],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              estaExpirando ? _neonPink : color.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tela simples de scanner QR integrada
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _foiDetectado = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // Substituídos os ValueListenableBuilders por chamadas diretas (compatível com v7.2.0)
  Widget _buildTorchButton() {
    return IconButton(
      onPressed: () => cameraController.toggleTorch(),
      icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
      tooltip: 'Alternar Flash',
    );
  }

  Widget _buildCameraButton() {
    return IconButton(
      onPressed: () => cameraController.switchCamera(),
      icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
      tooltip: 'Alternar Câmera',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1B4B), // Combinando com o tema escuro/azul
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildTorchButton(),
          _buildCameraButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_foiDetectado) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  setState(() => _foiDetectado = true);
                  Navigator.pop(context, raw);
                  break;
                }
              }
            },
          ),
          // Overlay para simular a área de leitura
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE91E63), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}