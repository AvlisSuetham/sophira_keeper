import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TokensWidget extends StatefulWidget {
  final List<dynamic> tokens;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Function(dynamic) onDelete;

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

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _atualizarTempo();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _atualizarTempo();
      }
    });
  }

  void _atualizarTempo() {
    setState(() {
      _tempoRestante = 30 - (DateTime.now().second % 30);
      if (_tempoRestante == 0) {
        _tempoRestante = 30;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _hexToColor(String? hexCode) {
    if (hexCode == null || hexCode.isEmpty) return Colors.blue;

    try {
      final cleaned = hexCode.replaceFirst('#', '');
      final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
      return Color(int.parse('0x$value'));
    } catch (_) {
      return Colors.blue;
    }
  }

  String _gerarCodigo(String? secret) {
    if (secret == null || secret.isEmpty) return "000000";

    try {
      final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return OTP.generateTOTPCodeString(
        secret,
        seconds,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (_) {
      return "000000";
    }
  }

  void _copiar(BuildContext context, String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Código copiado"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.tokens.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.security, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Nenhum token cadastrado",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.tokens.length,
        itemBuilder: (context, index) {
          final token = widget.tokens[index];

          final color = _hexToColor(token['color']);
          final codigo = _gerarCodigo(token['servico_otp_secret']);

          final codigoFormatado =
              "${codigo.substring(0, 3)} ${codigo.substring(3)}";

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => _copiar(context, codigo),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(Icons.shield, color: color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            token['servico_nome'] ?? "Serviço",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            codigoFormatado,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _tempoRestante / 30,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _tempoRestante < 6 ? Colors.red : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'copiar') {
                          _copiar(context, codigo);
                        }

                        if (value == 'excluir') {
                          widget.onDelete(token['id']);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "copiar",
                          child: Text("Copiar"),
                        ),
                        PopupMenuItem(
                          value: "excluir",
                          child: Text(
                            "Excluir",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  ],
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

  bool _detectado = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Widget _buildTorchButton() {
    return ValueListenableBuilder(
      valueListenable: cameraController,
      builder: (context, value, child) {
        final torchState = (value as dynamic).torchState;

        final ligado = torchState == TorchState.on;

        return IconButton(
          onPressed: () => cameraController.toggleTorch(),
          icon: Icon(
            ligado ? Icons.flash_on : Icons.flash_off,
            color: ligado ? Colors.yellow : Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildCameraButton() {
    return ValueListenableBuilder(
      valueListenable: cameraController,
      builder: (context, value, child) {
        final facing = (value as dynamic).cameraFacing;

        final traseira = facing == CameraFacing.back;

        return IconButton(
          onPressed: () => cameraController.switchCamera(),
          icon: Icon(
            traseira ? Icons.camera_rear : Icons.camera_front,
            color: Colors.white,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear QR Code"),
        actions: [
          _buildTorchButton(),
          _buildCameraButton(),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (_detectado) return;

          for (final barcode in capture.barcodes) {
            final raw = barcode.rawValue;

            if (raw != null && raw.isNotEmpty) {
              _detectado = true;

              Navigator.pop(context, raw);
              break;
            }
          }
        },
      ),
    );
  }
}