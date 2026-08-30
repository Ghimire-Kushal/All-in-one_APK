import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/dashboard_card.dart';
import '../notes/notes_screen.dart';
import '../todo/todo_screen.dart';
import '../expense/expense_screen.dart';
import '../utilities/utilities_hub_screen.dart';
import '../utilities/date_converter_screen.dart';
import '../utilities/stopwatch_screen.dart';
import '../utilities/timer_screen.dart';
import '../unit_converter/unit_converter_screen.dart';
import '../calculator/calculator_screen.dart';
import '../qr/qr_screen.dart';
import '../clipboard/clipboard_screen.dart';
import '../password_vault/vault_screen.dart';
import '../pdf_tools/pdf_tools_screen.dart';
import '../settings/settings_screen.dart';
import '../timetable/timetable_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isActive = true});

  /// Whether this tab is currently visible. The dashboard uses it to avoid
  /// refreshing the clock while the user is on another top-level tab.
  final bool isActive;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark, cs),
          if (_isSearching && _searchQuery.isNotEmpty)
            _buildSearchResults(context)
          else ...[
            SliverToBoxAdapter(
              child: DashboardCard(isActive: widget.isActive),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SectionHeader(
                  title: 'Productivity',
                  icon: Icons.checklist_rounded,
                  accentColor: AppColors.productivity,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildProductivityGrid(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SectionHeader(
                  title: 'Utilities',
                  icon: Icons.build_rounded,
                  accentColor: AppColors.utilities,
                  onSeeAll: () =>
                      _navigateTo(context, const UtilitiesHubScreen()),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildUtilitiesRow(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SectionHeader(
                  title: 'Documents',
                  icon: Icons.folder_rounded,
                  accentColor: AppColors.documents,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildDocumentsGrid(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SectionHeader(
                  title: 'Security',
                  icon: Icons.security_rounded,
                  accentColor: AppColors.security,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildSecurityCard(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark, ColorScheme cs) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search features...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1C1F2A) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : const Text(
              'All in One',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => setState(() => _isSearching = true),
          ),
        IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: cs.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: cs.onPrimaryContainer,
            ),
          ),
          onPressed: () => _navigateTo(context, const SettingsScreen()),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildProductivityGrid(BuildContext context) {
    final items = [
      _FeatureItem(
        'Notes',
        Icons.sticky_note_2_rounded,
        AppColors.notes,
        () => _navigateTo(context, const NotesScreen()),
      ),
      _FeatureItem(
        'To-Do',
        Icons.checklist_rounded,
        AppColors.todo,
        () => _navigateTo(context, const TodoScreen()),
      ),
      _FeatureItem(
        'Expenses',
        Icons.account_balance_wallet_rounded,
        AppColors.expense,
        () => _navigateTo(context, const ExpenseScreen()),
      ),
      _FeatureItem(
        'Timetable',
        Icons.calendar_view_week_rounded,
        AppColors.timetable,
        () => _navigateTo(context, const TimetableScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.0,
        children: items
            .map(
              (item) => FeatureCard(
                label: item.label,
                icon: item.icon,
                color: item.color,
                onTap: item.onTap,
                compact: true,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildUtilitiesRow(BuildContext context) {
    final items = [
      _FeatureItem(
        'Date\nConverter',
        Icons.calendar_month_rounded,
        AppColors.dateConverter,
        () => _navigateTo(context, const DateConverterScreen()),
      ),
      _FeatureItem(
        'Stopwatch',
        Icons.timer_rounded,
        AppColors.stopwatch,
        () => _navigateTo(context, const StopwatchScreen()),
      ),
      _FeatureItem(
        'Timer',
        Icons.hourglass_bottom_rounded,
        AppColors.timer,
        () => _navigateTo(context, const TimerScreen()),
      ),
      _FeatureItem(
        'Unit\nConverter',
        Icons.swap_horiz_rounded,
        AppColors.unitConverter,
        () => _navigateTo(context, const UnitConverterScreen()),
      ),
      _FeatureItem(
        'Calculator',
        Icons.calculate_rounded,
        AppColors.calculator,
        () => _navigateTo(context, const CalculatorScreen()),
      ),
    ];

    return SizedBox(
      height: 128,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        itemCount: items.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(right: i < items.length - 1 ? 10 : 0),
          child: SizedBox(
            width: 96,
            child: FeatureCard(
              label: items[i].label,
              icon: items[i].icon,
              color: items[i].color,
              onTap: items[i].onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsGrid(BuildContext context) {
    final items = [
      _FeatureItem(
        'QR Code',
        Icons.qr_code_2_rounded,
        AppColors.qr,
        () => _navigateTo(context, const QrScreen()),
      ),
      _FeatureItem(
        'PDF Tools',
        Icons.picture_as_pdf_rounded,
        AppColors.pdf,
        () => _navigateTo(context, const PdfToolsScreen()),
      ),
      _FeatureItem(
        'Clipboard',
        Icons.content_paste_rounded,
        AppColors.clipboard,
        () => _navigateTo(context, const ClipboardScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: items.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: entry.key < items.length - 1 ? 10 : 0,
              ),
              child: AspectRatio(
                aspectRatio: 0.95,
                child: FeatureCard(
                  label: entry.value.label,
                  icon: entry.value.icon,
                  color: entry.value.color,
                  onTap: entry.value.onTap,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: FeatureCard(
        label: 'Password Vault',
        icon: Icons.lock_rounded,
        color: AppColors.vault,
        subtitle: 'Store passwords securely with PIN',
        onTap: () => _navigateTo(context, const VaultScreen()),
        compact: true,
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final allItems = _allFeatures(context);
    final q = _searchQuery.toLowerCase();
    final filtered = allItems
        .where((item) => item.label.toLowerCase().contains(q))
        .toList();

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FeatureCard(
              label: filtered[i].label,
              icon: filtered[i].icon,
              color: filtered[i].color,
              onTap: filtered[i].onTap,
              compact: true,
            ),
          ),
          childCount: filtered.length,
        ),
      ),
    );
  }

  List<_FeatureItem> _allFeatures(BuildContext context) => [
    _FeatureItem(
      'Notes',
      Icons.sticky_note_2_rounded,
      AppColors.notes,
      () => _navigateTo(context, const NotesScreen()),
    ),
    _FeatureItem(
      'To-Do',
      Icons.checklist_rounded,
      AppColors.todo,
      () => _navigateTo(context, const TodoScreen()),
    ),
    _FeatureItem(
      'Expense Tracker',
      Icons.account_balance_wallet_rounded,
      AppColors.expense,
      () => _navigateTo(context, const ExpenseScreen()),
    ),
    _FeatureItem(
      'Timetable',
      Icons.calendar_view_week_rounded,
      AppColors.timetable,
      () => _navigateTo(context, const TimetableScreen()),
    ),
    _FeatureItem(
      'Date Converter',
      Icons.calendar_month_rounded,
      AppColors.dateConverter,
      () => _navigateTo(context, const DateConverterScreen()),
    ),
    _FeatureItem(
      'Stopwatch',
      Icons.timer_rounded,
      AppColors.stopwatch,
      () => _navigateTo(context, const StopwatchScreen()),
    ),
    _FeatureItem(
      'Timer',
      Icons.hourglass_bottom_rounded,
      AppColors.timer,
      () => _navigateTo(context, const TimerScreen()),
    ),
    _FeatureItem(
      'Unit Converter',
      Icons.swap_horiz_rounded,
      AppColors.unitConverter,
      () => _navigateTo(context, const UnitConverterScreen()),
    ),
    _FeatureItem(
      'Calculator',
      Icons.calculate_rounded,
      AppColors.calculator,
      () => _navigateTo(context, const CalculatorScreen()),
    ),
    _FeatureItem(
      'QR Scanner & Generator',
      Icons.qr_code_2_rounded,
      AppColors.qr,
      () => _navigateTo(context, const QrScreen()),
    ),
    _FeatureItem(
      'PDF Tools',
      Icons.picture_as_pdf_rounded,
      AppColors.pdf,
      () => _navigateTo(context, const PdfToolsScreen()),
    ),
    _FeatureItem(
      'Clipboard History',
      Icons.content_paste_rounded,
      AppColors.clipboard,
      () => _navigateTo(context, const ClipboardScreen()),
    ),
    _FeatureItem(
      'Password Vault',
      Icons.lock_rounded,
      AppColors.vault,
      () => _navigateTo(context, const VaultScreen()),
    ),
  ];

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _FeatureItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _FeatureItem(this.label, this.icon, this.color, this.onTap);
}
