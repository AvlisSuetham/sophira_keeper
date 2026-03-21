// lib/screens/tokens.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  final Color _deepBlue = const Color(0xFF1A1B4B);
  final Color _neonPink = const Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  int _agoraEmMillis() => DateTime.now().millisecondsSinceEpoch;

  int _calcularTempoRestante() {
    final segundosUnix = _agoraEmMillis() ~/ 1000;
    final restante = 30 - (segundosUnix % 30);
    return restante == 0 ? 30 : restante;
  }

  void _iniciarTimer() {
    _atualizarTempo();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _atualizarTempo();
    });
  }

  void _atualizarTempo() {
    if (!mounted) return;
    setState(() {
      _tempoRestante = _calcularTempoRestante();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _hexToColor(String? hexCode) {
    if (hexCode == null || hexCode.isEmpty) return const Color(0xFF6366F1);
    try {
      final cleaned = hexCode.replaceFirst('#', '');
      final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
      return Color(int.parse('0x$value'));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  String _gerarCodigo(String? secret) {
    if (secret == null || secret.isEmpty) return "000000";
    try {
      final nowMillis = _agoraEmMillis();
      final code = OTP.generateTOTPCodeString(
        secret,
        nowMillis,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      return code.padLeft(6, '0');
    } catch (_) {
      return "000000";
    }
  }

  void _copiarParaAreaTransferencia(BuildContext context, String texto, bool isDark) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Código 2FA copiado!", style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF334155) : _deepBlue,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                      color: isDark ? Colors.white.withOpacity(0.05) : _deepBlue.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      size: 80,
                      color: isDark ? Colors.white38 : _deepBlue.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Nenhum token 2FA cadastrado",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Toque no botão flutuante para escanear um QR Code",
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final agora = _agoraEmMillis();
    _tempoRestante = _calcularTempoRestante();

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

          final String codigoAtual =
              _gerarCodigo(token['servico_otp_secret']?.toString());

          final String codigoFormatado = codigoAtual.length == 6
              ? "${codigoAtual.substring(0, 3)} ${codigoAtual.substring(3)}"
              : codigoAtual;

          final bool estaExpirando = _tempoRestante <= 5;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : _deepBlue.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _copiarParaAreaTransferencia(context, codigoAtual, isDark),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.shield_rounded,
                              color: color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  token['servico_nome']?.toString() ?? 'Serviço',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  codigoFormatado,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    fontFamily: 'monospace',
                                    color: estaExpirando
                                        ? _neonPink
                                        : (isDark ? Colors.white : _deepBlue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            color: isDark ? const Color(0xFF334155) : Colors.white,
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: isDark ? Colors.white54 : Colors.grey[400],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) async {
                              if (value == 'excluir') {
                                final id = _parseId(token['id']);
                                if (id > 0) {
                                  await widget.onDelete(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("ID inválido para exclusão"),
                                    ),
                                  );
                                }
                              } else if (value == 'copiar') {
                                _copiarParaAreaTransferencia(
                                    context, codigoAtual, isDark);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'copiar',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 20,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Copiar', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Excluir',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 6,
                          child: LinearProgressIndicator(
                            value: _tempoRestante / 30,
                            backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              estaExpirando
                                  ? _neonPink
                                  : color.withOpacity(0.8),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escanear QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF1A1B4B),
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
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE91E63),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}