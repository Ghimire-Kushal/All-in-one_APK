import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  static const _accent = Color(0xFF26A69A);

  String? _inputPath;
  String? _inputName;
  int? _inputSize;
  String? _outputPath;
  int? _outputSize;
  bool _isCompressing = false;
  _Quality _quality = _Quality.medium;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.path == null) return;
    setState(() {
      _inputPath = f.path;
      _inputName = f.name;
      _inputSize = File(f.path!).lengthSync();
      _outputPath = null;
      _outputSize = null;
    });
  }

  Future<void> _compress() async {
    if (_inputPath == null) return;
    setState(() => _isCompressing = true);
    try {
      final bytes = await File(_inputPath!).readAsBytes();
      final dpi = _quality.dpi;
      final doc = pw.Document();

      await for (final page in Printing.raster(bytes, dpi: dpi)) {
        final png = await page.toPng();
        final img = pw.MemoryImage(png);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (_) =>
                pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
          ),
        );
      }

      final dir = await getTemporaryDirectory();
      final out = File(
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await out.writeAsBytes(await doc.save());

      setState(() {
        _outputPath = out.path;
        _outputSize = out.lengthSync();
        _isCompressing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF compressed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCompressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _share() async {
    if (_outputPath == null) return;
    await Share.shareXFiles([XFile(_outputPath!)], text: 'Compressed PDF');
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
  }

  int get _savings {
    if (_inputSize == null || _outputSize == null || _inputSize! == 0) return 0;
    return ((_inputSize! - _outputSize!) / _inputSize! * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compress PDF',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_outputPath != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _share,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Pick file button
          GestureDetector(
            onTap: _pickPdf,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_rounded, color: _accent),
                  const SizedBox(width: 8),
                  Text(
                    _inputPath == null ? 'Pick a PDF' : 'Change PDF',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_inputPath != null) ...[
            const SizedBox(height: 16),
            _infoCard(
              isDark,
              icon: Icons.picture_as_pdf_rounded,
              label: _inputName ?? '',
              value: _formatSize(_inputSize!),
            ),
            const SizedBox(height: 20),

            // Quality selector
            Text(
              'Quality',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ...(_Quality.values.map((q) => _qualityTile(q, isDark))),

            const SizedBox(height: 24),
            FilledButton.icon(
              icon: _isCompressing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.compress_rounded),
              label: Text(_isCompressing ? 'Compressing…' : 'Compress PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
              onPressed: _isCompressing ? null : _compress,
            ),
          ],

          if (_outputPath != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _sizeColumn('Original', _formatSize(_inputSize!)),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.green,
                      ),
                      _sizeColumn('Compressed', _formatSize(_outputSize!)),
                    ],
                  ),
                  if (_savings > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      '$_savings% smaller',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share Compressed PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
              onPressed: _share,
            ),
          ],

          if (_inputPath == null) ...[
            const SizedBox(height: 60),
            Icon(Icons.compress_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Pick a PDF to compress',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(value, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _qualityTile(_Quality q, bool isDark) {
    final selected = _quality == q;
    return GestureDetector(
      onTap: () => setState(() {
        _quality = q;
        _outputPath = null;
        _outputSize = null;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1C1F2A) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _accent : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? _accent : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? _accent : null,
                    ),
                  ),
                  Text(
                    q.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ],
    );
  }
}

enum _Quality {
  high(dpi: 150, label: 'High', description: 'Best quality, larger file'),
  medium(dpi: 96, label: 'Medium', description: 'Balanced quality and size'),
  low(dpi: 72, label: 'Low', description: 'Smallest file, lower quality');

  final double dpi;
  final String label;
  final String description;
  const _Quality({
    required this.dpi,
    required this.label,
    required this.description,
  });
}
