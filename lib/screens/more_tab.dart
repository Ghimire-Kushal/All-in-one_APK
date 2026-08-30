import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'qr/qr_screen.dart';
import 'pdf_tools/pdf_tools_screen.dart';
import 'clipboard/clipboard_screen.dart';
import 'password_vault/vault_screen.dart';
import 'settings/settings_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionLabel('Documents'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            'QR Scanner & Generator',
            'Scan, generate, and save QR codes',
            Icons.qr_code_2_rounded,
            AppColors.qr,
            const QrScreen(),
          ),
          const SizedBox(height: 10),
          _buildCard(
            context,
            'PDF Tools',
            'Convert images to PDF and more',
            Icons.picture_as_pdf_rounded,
            AppColors.pdf,
            const PdfToolsScreen(),
          ),
          const SizedBox(height: 10),
          _buildCard(
            context,
            'Clipboard History',
            'Save and manage copied text',
            Icons.content_paste_rounded,
            AppColors.clipboard,
            const ClipboardScreen(),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Security'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            'Password Vault',
            'Store passwords with PIN protection',
            Icons.lock_rounded,
            AppColors.vault,
            const VaultScreen(),
          ),
          const SizedBox(height: 20),
          _sectionLabel('General'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            'Settings',
            'Theme, profile, and preferences',
            Icons.settings_rounded,
            Colors.grey,
            const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
  );

  Widget _buildCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
