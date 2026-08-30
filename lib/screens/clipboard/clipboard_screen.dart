import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/clipboard_provider.dart';
import '../../models/clipboard_item.dart';

class ClipboardScreen extends StatefulWidget {
  const ClipboardScreen({super.key});

  @override
  State<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends State<ClipboardScreen> {
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipboardProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clipboard History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (provider.unpinned.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, provider),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Paste or type text to save...',
                      prefixIcon: Icon(Icons.content_paste_rounded, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    provider.addItem(_addCtrl.text);
                    _addCtrl.clear();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.save_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () async {
              final data = await Clipboard.getData('text/plain');
              if (!mounted) return;
              if (data?.text != null) {
                provider.addItem(data!.text!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pasted from clipboard')),
                );
              }
            },
            icon: const Icon(Icons.content_paste_rounded, size: 16),
            label: const Text(
              'Paste from clipboard',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: provider.items.isEmpty
                ? _empty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      if (provider.pinned.isNotEmpty) ...[
                        _sectionLabel('📌 Pinned'),
                        ...provider.pinned.map(
                          (item) => _clipCard(context, item, provider),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (provider.unpinned.isNotEmpty) ...[
                        _sectionLabel('History'),
                        ...provider.unpinned.map(
                          (item) => _clipCard(context, item, provider),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  Widget _clipCard(
    BuildContext context,
    ClipboardItem item,
    ClipboardProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: item.isPinned
            ? Border.all(
                color: Colors.orange.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.text,
            style: const TextStyle(fontSize: 13, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _timeAgo(item.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const Spacer(),
              _iconBtn(
                item.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                item.isPinned ? Colors.orange : Colors.grey[400]!,
                () => provider.togglePin(item.id),
              ),
              const SizedBox(width: 4),
              _iconBtn(Icons.copy_rounded, Colors.blue, () {
                provider.copyToClipboard(item.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }),
              const SizedBox(width: 4),
              _iconBtn(
                Icons.delete_outline_rounded,
                Colors.red,
                () => provider.deleteItem(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      );

  Widget _empty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.content_paste_off_rounded,
          size: 60,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 12),
        Text('No saved clips', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 6),
        Text(
          'Paste text above or type to save',
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    ),
  );

  void _confirmClear(BuildContext context, ClipboardProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('Pinned items will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
