import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Generator
  final _textCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _wifiPwCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  String _qrData = '';
  String _qrType = 'text';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _textCtrl.dispose();
    _ssidCtrl.dispose();
    _wifiPwCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    String data = '';
    switch (_qrType) {
      case 'text':
        data = _textCtrl.text.trim();
        break;
      case 'url':
        data = _urlCtrl.text.trim();
        break;
      case 'wifi':
        if (_ssidCtrl.text.isEmpty) return;
        data = 'WIFI:S:${_ssidCtrl.text};T:WPA;P:${_wifiPwCtrl.text};;';
        break;
    }
    if (data.isNotEmpty) setState(() => _qrData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Code',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Generator'),
            Tab(text: 'Scanner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildGenerator(context), const _QrScannerTab()],
      ),
    );
  }

  Widget _buildGenerator(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QR Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _typeChip('Text', 'text', Icons.text_fields_rounded),
              _typeChip('URL', 'url', Icons.link_rounded),
              _typeChip('WiFi', 'wifi', Icons.wifi_rounded),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputForType(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Generate QR'),
            ),
          ),
          if (_qrData.isNotEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 220,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _qrData));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy data'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputForType() {
    switch (_qrType) {
      case 'url':
        return TextField(
          controller: _urlCtrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Enter URL',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        );
      case 'wifi':
        return Column(
          children: [
            TextField(
              controller: _ssidCtrl,
              decoration: const InputDecoration(
                labelText: 'WiFi Name (SSID)',
                prefixIcon: Icon(Icons.wifi_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _wifiPwCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
          ],
        );
      default:
        return TextField(
          controller: _textCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Enter text',
            prefixIcon: Icon(Icons.text_fields_rounded),
            alignLabelWithHint: true,
          ),
        );
    }
  }

  Widget _typeChip(String label, String value, IconData icon) {
    final isSelected = _qrType == value;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() {
        _qrType = value;
        _qrData = '';
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? cs.primary : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? cs.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QR Scanner Tab ────────────────────────────────────────────────────────────

class _QrScannerTab extends StatefulWidget {
  const _QrScannerTab();

  @override
  State<_QrScannerTab> createState() => _QrScannerTabState();
}

class _QrScannerTabState extends State<_QrScannerTab>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  String? _scannedValue;
  bool _torchOn = false;
  bool _paused = false;
  File? _galleryImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _galleryImage = File(picked.path));
    final result = await _controller.analyzeImage(picked.path);
    if (!mounted) return;
    if (result != null && result.barcodes.isNotEmpty) {
      final value = result.barcodes.first.rawValue;
      if (value != null) {
        _showResultSheet(value);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code found in the image')),
      );
      setState(() => _galleryImage = null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed && !_paused) {
      _controller.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final value = barcode.rawValue!;
    if (value == _scannedValue) return;

    setState(() {
      _scannedValue = value;
      _paused = true;
    });
    _controller.stop();
    _showResultSheet(value);
  }

  void _showResultSheet(String value) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScanResultSheet(value: value),
    ).then((_) {
      setState(() {
        _scannedValue = null;
        _paused = false;
        _galleryImage = null;
      });
      _controller.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Camera view (always running in background)
        MobileScanner(controller: _controller, onDetect: _onDetect),

        // Gallery image preview overlay
        if (_galleryImage != null)
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _galleryImage!,
                    fit: BoxFit.contain,
                    width: 280,
                    height: 280,
                  ),
                ),
              ),
            ),
          ),

        // Overlay with scan frame (only when camera is active)
        if (_galleryImage == null)
          CustomPaint(
            painter: _ScanOverlayPainter(cs.primary),
            child: const SizedBox.expand(),
          ),

        // Top controls
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _OverlayButton(
                  icon: _torchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  onTap: () {
                    _controller.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  },
                ),
                const SizedBox(width: 8),
                _OverlayButton(
                  icon: Icons.photo_library_rounded,
                  onTap: _pickFromGallery,
                ),
              ],
            ),
          ),
        ),

        // Bottom hint
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _galleryImage != null
                    ? 'Scanning image…'
                    : 'Point camera at a QR code',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Color accentColor;
  _ScanOverlayPainter(this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black54;
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final cornerPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const boxSize = 240.0;
    const cornerLen = 24.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - boxSize / 2;
    final top = cy - boxSize / 2;
    final right = left + boxSize;
    final bottom = top + boxSize;
    const r = 12.0;

    // Dim overlay with a clear hole
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, dimPaint);
    canvas.drawRRect(
      RRect.fromLTRBR(left, top, right, bottom, const Radius.circular(r)),
      clearPaint,
    );
    canvas.restore();

    // Corner brackets
    final corners = [
      [Offset(left + r, top), Offset(left, top + r), cornerLen],
      [Offset(right - r, top), Offset(right, top + r), cornerLen],
      [Offset(left + r, bottom), Offset(left, bottom - r), cornerLen],
      [Offset(right - r, bottom), Offset(right, bottom - r), cornerLen],
    ];

    for (final c in corners) {
      final h = c[0] as Offset;
      final v = c[1] as Offset;
      final len = c[2] as double;
      final hDir = Offset((h.dx < cx ? 1 : -1) * len, 0);
      final vDir = Offset(0, (v.dy < cy ? 1 : -1) * len);
      canvas.drawLine(h, h + hDir, cornerPaint);
      canvas.drawLine(v, v + vDir, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ScanResultSheet extends StatelessWidget {
  final String value;
  const _ScanResultSheet({required this.value});

  bool get _isUrl =>
      value.startsWith('http://') || value.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.qr_code_rounded, color: cs.primary, size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            'QR Code Scanned',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ),
              if (_isUrl) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text('Open URL'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('URL: $value')));
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Scan Again'),
            ),
          ),
        ],
      ),
    );
  }
}
