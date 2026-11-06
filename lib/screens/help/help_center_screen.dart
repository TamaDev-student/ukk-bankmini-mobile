import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'help_content.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HelpGuide> get _filteredGuides {
    final query = _searchController.text.trim().toLowerCase();
    return helpGuides.where((guide) {
      final matchesCategory =
          _selectedCategory == 'Semua' || guide.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty || guide.searchableText.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<HelpFaq> get _filteredFaqs {
    final query = _searchController.text.trim().toLowerCase();
    return helpFaqs.where((faq) {
      final matchesCategory =
          _selectedCategory == 'Semua' || faq.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty || faq.searchableText.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Akun & Login':
        return Icons.login_rounded;
      case 'PIN & Keamanan':
        return Icons.lock_outline_rounded;
      case 'Saldo & Rekening':
        return Icons.account_balance_wallet_outlined;
      case 'Transaksi & Mutasi':
        return Icons.receipt_long_outlined;
      default:
        return Icons.support_agent_rounded;
    }
  }

  void _openGuide(HelpGuide guide) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HelpGuideDetailScreen(guide: guide),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guides = _filteredGuides;
    final faqs = _filteredFaqs;
    final hasResults = guides.isNotEmpty || faqs.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const Text(
            'Panduan penggunaan aplikasi dan jawaban atas pertanyaan umum.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari panduan atau pertanyaan...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in helpCategories)
                ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: AppTheme.primary.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: _selectedCategory == category
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontWeight: _selectedCategory == category
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: _selectedCategory == category
                        ? AppTheme.primary.withValues(alpha: 0.35)
                        : const Color(0xFFE4E7EC),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (!hasResults)
            _NoHelpResults(
              onClear: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = 'Semua';
                });
              },
            )
          else ...[
            if (guides.isNotEmpty) ...[
              const _HelpSectionTitle(
                title: 'Panduan Penggunaan',
                icon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 10),
              for (final guide in guides) ...[
                _GuideCard(
                  guide: guide,
                  icon: _categoryIcon(guide.category),
                  onTap: () => _openGuide(guide),
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (faqs.isNotEmpty) ...[
              const SizedBox(height: 14),
              const _HelpSectionTitle(
                title: 'Pertanyaan Umum',
                icon: Icons.quiz_outlined,
              ),
              const SizedBox(height: 10),
              for (final category in helpCategories.skip(1))
                if (faqs.any((faq) => faq.category == category)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final faq in faqs.where(
                    (faq) => faq.category == category,
                  ))
                    _FaqTile(faq: faq),
                ],
            ],
          ],
        ],
      ),
    );
  }
}

class HelpGuideDetailScreen extends StatelessWidget {
  const HelpGuideDetailScreen({required this.guide, super.key});

  final HelpGuide guide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Panduan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            guide.category,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guide.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            guide.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const _HelpSectionTitle(
            title: 'Langkah-langkah',
            icon: Icons.format_list_numbered_rounded,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < guide.steps.length; index++)
            _GuideStep(number: index + 1, text: guide.steps[index]),
          if (guide.note case final note?) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB45309),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: Color(0xFF78350F),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Jika kendala belum terselesaikan, sampaikan pesan yang muncul kepada petugas Bank Mini sekolah.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSectionTitle extends StatelessWidget {
  const _HelpSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.guide,
    required this.icon,
    required this.onTap,
  });

  final HelpGuide guide;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEAECF0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEEF3FF),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          guide.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            guide.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final HelpFaq faq;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFEAECF0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          faq.question,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.textSecondary,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              faq.answer,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFEEF3FF),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHelpResults extends StatelessWidget {
  const _NoHelpResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppTheme.textSecondary,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Panduan tidak ditemukan',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba kata kunci lain atau tampilkan semua kategori.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onClear, child: const Text('Hapus pencarian')),
        ],
      ),
    );
  }
}
