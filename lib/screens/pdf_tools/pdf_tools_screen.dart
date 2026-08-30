import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'merge_pdf_screen.dart';
import 'compress_pdf_screen.dart';

class PdfToolsScreen extends StatelessWidget {
  const PdfToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool(
        'Image to PDF',
        'Convert photos to PDF document',
        Icons.image_rounded,
        const Color(0xFFF57C00),
        true,
      ),
      _Tool(
        'Scan Document',
        'Capture & convert to PDF',
        Icons.document_scanner_rounded,
        const Color(0xFFEC407A),
        true,
      ),
      _Tool(
        'Merge PDF',
        'Combine multiple PDFs into one',
        Icons.merge_type_rounded,
        const Color(0xFF5C6BC0),
        true,
      ),
      _Tool(
        'Compress PDF',
        'Reduce PDF file size',
        Icons.compress_rounded,
        const Color(0xFF26A69A),
        true,
      ),
      _Tool(
        'Share PDF',
        'Share PDF via any app',
        Icons.share_rounded,
        const Color(0xFF42A5F5),
        false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PDF Tools',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tools.length,
        itemBuilder: (_, i) => _ToolCard(tool: tools[i]),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _Tool tool;
  const _ToolCard({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tool.color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: tool.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(tool.icon, color: tool.color, size: 26),
        ),
        title: Row(
          children: [
            Text(
              tool.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            if (tool.ready) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Ready',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            tool.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 13,
          color: Colors.grey[400],
        ),
        onTap: () {
          if (tool.name == 'Image to PDF') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImageToPdfScreen()),
            );
          } else if (tool.name == 'Scan Document') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ImageToPdfScreen(
                  useCamera: true,
                  title: 'Scan Document',
                  accent: Color(0xFFEC407A),
                ),
              ),
            );
          } else if (tool.name == 'Merge PDF') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MergePdfScreen()),
            );
          } else if (tool.name == 'Compress PDF') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompressPdfScreen()),
            );
          } else {
            _showComingSoon(context, tool);
          }
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, _Tool t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: t.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(t.icon, color: t.color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              t.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tool {
  final String name, description;
  final IconData icon;
  final Color color;
  final bool ready;
  _Tool(this.name, this.description, this.icon, this.color, this.ready);
}

// ─── Image to PDF / Scan Document ─────────────────────────────────────────────

class ImageToPdfScreen extends StatefulWidget {
  final bool useCamera;
  final String title;
  final Color accent;

  const ImageToPdfScreen({
    super.key,
    this.useCamera = false,
    this.title = 'Image to PDF',
    this.accent = const Color(0xFFF57C00),
  });

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<File> _images = [];
  bool _isConverting = false;
  String? _pdfPath;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    if (widget.useCamera) {
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (picked != null) {
        setState(() {
          _images.add(File(picked.path));
          _pdfPath = null;
        });
      }
    } else {
      final picked = await picker.pickMultiImage(imageQuality: 90);
      if (picked.isNotEmpty) {
        setState(() {
          _images.addAll(picked.map((x) => File(x.path)));
          _pdfPath = null;
        });
      }
    }
  }

  void _removeImage(int index) => setState(() {
    _images.removeAt(index);
    _pdfPath = null;
  });

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final img = _images.removeAt(oldIndex);
      _images.insert(newIndex, img);
      _pdfPath = null;
    });
  }

  Future<void> _convert() async {
    if (_images.isEmpty) return;
    setState(() => _isConverting = true);
    try {
      final doc = pw.Document();
      for (final file in _images) {
        final image = pw.MemoryImage(await file.readAsBytes());
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (_) =>
                pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
          ),
        );
      }
      final dir = await getTemporaryDirectory();
      final out = File(
        '${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await out.writeAsBytes(await doc.save());
      setState(() {
        _pdfPath = out.path;
        _isConverting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isConverting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _share() async {
    if (_pdfPath == null) return;
    await Share.shareXFiles([XFile(_pdfPath!)], text: 'PDF created');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_pdfPath != null)
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
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: widget.useCamera
                        ? Icons.camera_alt_rounded
                        : Icons.photo_library_rounded,
                    label: widget.useCamera ? 'Camera' : 'Gallery',
                    color: widget.accent,
                    onTap: _pickImages,
                  ),
                ),
                if (!widget.useCamera) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: const Color(0xFF5C6BC0),
                      onTap: () async {
                        final p = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 90,
                        );
                        if (p != null) {
                          setState(() {
                            _images.add(File(p.path));
                            _pdfPath = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _images.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No images selected',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.useCamera
                              ? 'Tap Camera to scan a page'
                              : 'Tap Gallery or Camera to add images',
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
                    itemCount: _images.length,
                    itemBuilder: (_, i) => _ImageTile(
                      key: ValueKey(_images[i].path),
                      file: _images[i],
                      index: i,
                      onRemove: () => _removeImage(i),
                      isDark: isDark,
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_images.isNotEmpty)
                    Text(
                      '${_images.length} page${_images.length == 1 ? '' : 's'} · drag to reorder',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_pdfPath != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share PDF'),
                            onPressed: _share,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: FilledButton.icon(
                          icon: _isConverting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf_rounded),
                          label: Text(
                            _isConverting ? 'Converting…' : 'Convert to PDF',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: (_images.isEmpty || _isConverting)
                              ? null
                              : _convert,
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final File file;
  final int index;
  final VoidCallback onRemove;
  final bool isDark;
  const _ImageTile({
    super.key,
    required this.file,
    required this.index,
    required this.onRemove,
    required this.isDark,
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  file.path.split('/').last,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            onPressed: onRemove,
          ),
          const Icon(Icons.drag_handle_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
