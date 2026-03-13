import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import '../../providers/project_provider.dart';
import '../../utils/helpers.dart';

class AddProjectScreen extends ConsumerStatefulWidget {
  const AddProjectScreen({super.key});

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _clientController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _clientController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.path.split('.').last;
      ref.read(addProjectProvider.notifier).setImage(bytes, ext);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 24),
                Text('Fotoğraf Ekle', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Proje için kapak fotoğrafı seçin', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ImageSourceCard(
                        icon: LucideIcons.camera,
                        label: 'Kamera',
                        sublabel: 'Fotoğraf çek',
                        color: AppColors.teal,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImageSourceCard(
                        icon: LucideIcons.image,
                        label: 'Galeri',
                        sublabel: 'Fotoğraf seç',
                        color: AppColors.purple,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      Helpers.showSnackBar(context, 'Proje adı gerekli', isError: true);
      return;
    }
    ref.read(addProjectProvider.notifier).saveProject(
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      clientName: _clientController.text.trim().isNotEmpty ? _clientController.text.trim() : null,
      budget: _budgetController.text.isNotEmpty ? double.tryParse(_budgetController.text) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProjectProvider);

    ref.listen(addProjectProvider, (prev, next) {
      if (next.errorMessage != null) {
        Helpers.showSnackBar(context, next.errorMessage!, isError: true);
      }
      if (next.isSuccess) {
        Helpers.showSnackBar(context, AppStrings.projectSaved);
        ref.read(addProjectProvider.notifier).reset();
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text('Proje kaydediliyor...', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // ─── Üst bar ──────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      child: Column(
                        children: [
                          // Navigasyon
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                                onPressed: () {
                                  ref.read(addProjectProvider.notifier).reset();
                                  Navigator.pop(context);
                                },
                              ),
                              const Spacer(),
                              Text(
                                'Yeni Proje',
                                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const Spacer(),
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Fotoğraf alanı
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              height: 180,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: state.imageBytes != null ? Colors.transparent : Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: state.imageBytes == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: const Icon(LucideIcons.camera, size: 26, color: Colors.white),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Kapak Fotoğrafı Ekle',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kamera veya galeriden seçin',
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                                        ),
                                      ],
                                    )
                                  : Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.memory(state.imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                        ),
                                        Positioned(
                                          bottom: 12,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: _showImageSourceDialog,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(LucideIcons.refreshCw, size: 14, color: Colors.white),
                                                  const SizedBox(width: 6),
                                                  Text('Değiştir', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // ─── Form ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Oda Tipi
                        _SectionTitle(title: 'Oda Tipi', icon: LucideIcons.home),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppStrings.roomTypes.map((type) {
                            final isSelected = state.selectedRoomType == type;
                            return GestureDetector(
                              onTap: () => ref.read(addProjectProvider.notifier).setRoomType(type),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 1.5 : 0.5,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
                                  ] : null,
                                ),
                                child: Text(
                                  type,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 28),

                        // Proje Bilgileri
                        _SectionTitle(title: 'Proje Bilgileri', icon: LucideIcons.fileText),
                        const SizedBox(height: 16),

                        _StyledTextField(
                          controller: _nameController,
                          label: AppStrings.projectName,
                          icon: LucideIcons.layout,
                          hint: 'ör. Modern Salon Tasarımı',
                        ),
                        const SizedBox(height: 14),
                        _StyledTextField(
                          controller: _locationController,
                          label: AppStrings.projectLocation,
                          icon: LucideIcons.mapPin,
                          hint: 'ör. İstanbul, Kadıköy',
                        ),
                        const SizedBox(height: 14),
                        _StyledTextField(
                          controller: _clientController,
                          label: 'Müşteri Adı',
                          icon: LucideIcons.user,
                          hint: 'Opsiyonel',
                        ),
                        const SizedBox(height: 14),
                        _StyledTextField(
                          controller: _budgetController,
                          label: 'Tahmini Bütçe (₺)',
                          icon: LucideIcons.wallet,
                          hint: 'ör. 150000',
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 36),

                        // Kaydet butonu
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: AppColors.buttonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.check, size: 20, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Projeyi Kaydet',
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                        const SizedBox(height: 40),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.02),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Section Title ────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

// ─── Styled Text Field ────────────────────────────────
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, size: 20, color: AppColors.textTertiary),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─── Image Source Card ────────────────────────────────
class _ImageSourceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ImageSourceCard({required this.icon, required this.label, required this.sublabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(sublabel, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
