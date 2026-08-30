import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/password_vault_provider.dart';
import '../../models/password_entry.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PasswordVaultProvider>();

    if (!provider.hasPin) return _SetPinView(provider: provider);
    if (!provider.isUnlocked) return _UnlockView(provider: provider);
    return _VaultListView(provider: provider);
  }
}

// Set PIN screen
class _SetPinView extends StatefulWidget {
  final PasswordVaultProvider provider;
  const _SetPinView({required this.provider});

  @override
  State<_SetPinView> createState() => _SetPinViewState();
}

class _SetPinViewState extends State<_SetPinView> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Password Vault',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Set a PIN',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a PIN to protect your passwords',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter PIN (4-6 digits)',
                  prefixIcon: Icon(Icons.pin_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  prefixIcon: Icon(Icons.pin_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (_pinCtrl.text.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN must be at least 4 digits'),
                        ),
                      );
                      return;
                    }
                    if (_pinCtrl.text != _confirmCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PINs do not match')),
                      );
                      return;
                    }
                    await widget.provider.setPin(_pinCtrl.text);
                  },
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Set PIN & Open Vault'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: PIN is stored locally. This provides basic protection.',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Unlock screen
class _UnlockView extends StatefulWidget {
  final PasswordVaultProvider provider;
  const _UnlockView({required this.provider});

  @override
  State<_UnlockView> createState() => _UnlockViewState();
}

class _UnlockViewState extends State<_UnlockView> {
  final _pinCtrl = TextEditingController();
  bool _wrong = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Password Vault',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _wrong
                      ? Colors.red.withValues(alpha: 0.1)
                      : cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: _wrong ? Colors.red : cs.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter PIN',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              if (_wrong) ...[
                const SizedBox(height: 8),
                const Text(
                  'Incorrect PIN',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 32),
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  prefixIcon: const Icon(Icons.pin_rounded),
                  errorText: _wrong ? 'Wrong PIN' : null,
                ),
                onSubmitted: (_) => _unlock(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Unlock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    final ok = await widget.provider.unlock(_pinCtrl.text);
    if (!ok) setState(() => _wrong = true);
    _pinCtrl.clear();
  }
}

// Main vault list
class _VaultListView extends StatelessWidget {
  final PasswordVaultProvider provider;
  const _VaultListView({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Password Vault',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_rounded),
            onPressed: provider.lock,
            tooltip: 'Lock vault',
          ),
        ],
      ),
      body: provider.entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.password_rounded,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No passwords saved',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: provider.entries.length,
              itemBuilder: (context, i) =>
                  _entryCard(context, provider.entries[i], provider),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntry(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Password'),
      ),
    );
  }

  Widget _entryCard(
    BuildContext context,
    PasswordEntry entry,
    PasswordVaultProvider provider,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              entry.title.isNotEmpty ? entry.title[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.primary,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          entry.username,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () => provider.deleteEntry(entry.id),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _copyRow(context, 'Username', entry.username),
                const Divider(height: 16),
                _passwordRow(context, entry.password),
                if (entry.website.isNotEmpty) ...[
                  const Divider(height: 16),
                  _copyRow(context, 'Website', entry.website),
                ],
                if (entry.note.isNotEmpty) ...[
                  const Divider(height: 16),
                  Text(
                    'Note',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.note, style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(value, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _passwordRow(BuildContext context, String password) {
    return _PasswordRow(password: password);
  }

  void _addEntry(BuildContext context, PasswordVaultProvider provider) {
    final titleCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    final siteCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title / Service *',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username / Email *',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: siteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty ||
                        userCtrl.text.isEmpty ||
                        pwCtrl.text.isEmpty) {
                      return;
                    }
                    provider.addEntry(
                      titleCtrl.text.trim(),
                      userCtrl.text.trim(),
                      pwCtrl.text,
                      website: siteCtrl.text.trim(),
                      note: noteCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordRow extends StatefulWidget {
  final String password;
  const _PasswordRow({required this.password});

  @override
  State<_PasswordRow> createState() => _PasswordRowState();
}

class _PasswordRowState extends State<_PasswordRow> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                _visible ? widget.password : '•' * widget.password.length,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            _visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 16,
          ),
          onPressed: () => setState(() => _visible = !_visible),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.password));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password copied'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}
