import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import '../../models/budget_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final double? totalBudget;

  const BudgetScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.totalBudget,
  });

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  List<BudgetItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final service = ref.read(supabaseServiceProvider);
    final items = await service.getBudgetItems(widget.projectId);
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  double get _totalSpent => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get _remainingBudget => (widget.totalBudget ?? 0) - _totalSpent;

  void _showAddItemSheet() {
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String selectedCategory = AppStrings.budgetCategories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Kalem Ekle', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),

              // Kategori
              Text('Kategori', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppStrings.budgetCategories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 0.5),
                      ),
                      child: Text(cat, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Açıklama', prefixIcon: Icon(LucideIcons.fileText, size: 20))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Birim Fiyat (₺)', prefixIcon: Icon(LucideIcons.banknote, size: 20)))),
                  const SizedBox(width: 12),
                  SizedBox(width: 100, child: TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Adet'))),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (descController.text.isNotEmpty && priceController.text.isNotEmpty) {
                      final service = ref.read(supabaseServiceProvider);
                      await service.addBudgetItem({
                        'project_id': widget.projectId,
                        'category': selectedCategory,
                        'description': descController.text.trim(),
                        'unit_price': double.tryParse(priceController.text) ?? 0,
                        'quantity': int.tryParse(qtyController.text) ?? 1,
                        'is_purchased': false,
                      });
                      Navigator.pop(ctx);
                      _loadItems();
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bütçe', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // Özet kartları
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.projectName, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),

                        // Bütçe özeti
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _BudgetSummaryItem(label: 'Toplam Bütçe', value: Helpers.formatCurrency(widget.totalBudget ?? 0)),
                                  _BudgetSummaryItem(label: 'Harcanan', value: Helpers.formatCurrency(_totalSpent)),
                                  _BudgetSummaryItem(label: 'Kalan', value: Helpers.formatCurrency(_remainingBudget)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: widget.totalBudget != null && widget.totalBudget! > 0
                                      ? (_totalSpent / widget.totalBudget!).clamp(0.0, 1.0)
                                      : 0,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _remainingBudget >= 0 ? AppColors.success : AppColors.error,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Kalemler', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                // Bütçe kalemleri
                if (_items.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.receipt, size: 48, color: AppColors.border),
                          const SizedBox(height: 12),
                          Text('Henüz kalem eklenmemiş.', style: GoogleFonts.inter(color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final item = _items[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                // Kategori badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(item.category, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.description, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
                                      Text('${item.quantity} adet', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                                    ],
                                  ),
                                ),
                                Text(
                                  Helpers.formatCurrency(item.totalPrice),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _items.length,
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

class _BudgetSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _BudgetSummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.6))),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}
