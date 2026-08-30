import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  static const _accent = Color(0xFF5C6BC0);
  final List<_PdfFile> _files = [];
  bool _isMerging = false;
  String? _outputPath;

  Future<void> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.path != null && !_files.any((e) => e.path == f.path)) {
          _files.add(_PdfFile(name: f.name, path: f.path!));
        }
      }
      _outputPath = null;
    });
  }

  void _remove(int index) => setState(() {
    _files.removeAt(index);
    _outputPath = null;
  });

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final f = _files.removeAt(oldIndex);
      _files.insert(newIndex, f);
      _outputPath = null;
    });
  }

  Future<void> _merge() async {
    if (_files.length < 2) return;
    setState(() => _isMerging = true);
    try {
      final doc = pw.Document();
      for (final pdfFile in _files) {
        final bytes = await File(pdfFile.path).readAsBytes();
        await for (final page in Printing.raster(bytes, dpi: 150)) {
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
      }
      final dir = await getTemporaryDirectory();
      final out = File(
        '${dir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await out.writeAsBytes(await doc.save());
      setState(() {
        _outputPath = out.path;
        _isMerging = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDFs merged!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isMerging = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _share() async {
    if (_outputPath == null) return;
    await Share.shareXFiles([XFile(_outputPath!)], text: 'Merged PDF');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Merge PDF',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: _pickPdfs,
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
                    Icon(Icons.add_rounded, color: _accent),
                    const SizedBox(width: 8),
                    Text(
                      'Pick PDFs',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.merge_type_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No PDFs selected',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick 2 or more PDFs to merge',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onReorder: _reorder,
                    itemCount: _files.length,
                    itemBuilder: (_, i) => _FileTile(
                      key: ValueKey(_files[i].path),
                      file: _files[i],
                      index: i,
                      isDark: isDark,
                      onRemove: () => _remove(i),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_files.isNotEmpty)
                    Text(
                      '${_files.length} PDF${_files.length == 1 ? '' : 's'} · drag to reorder',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_outputPath != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share'),
                            onPressed: _share,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: FilledButton.icon(
                          icon: _isMerging
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.merge_type_rounded),
                          label: Text(_isMerging ? 'Merging…' : 'Merge PDFs'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: (_files.length < 2 || _isMerging)
                              ? null
                              : _merge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfFile {
  final String name;
  final String path;
  _PdfFile({required this.name, required this.path});
}

class _FileTile extends StatelessWidget {
  final _PdfFile file;
  final int index;
  final bool isDark;
  final VoidCallback onRemove;

  const _FileTile({
    super.key,
    required this.file,
    required this.index,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF5C6BC0).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: Color(0xFF5C6BC0),
            size: 22,
          ),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'PDF ${index + 1}',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: onRemove,
            ),
            const Icon(Icons.drag_handle_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
