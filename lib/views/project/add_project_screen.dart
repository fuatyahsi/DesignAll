import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.path.split('.').last;
      ref.read(addProjectProvider.notifier).setImage(bytes, ext);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Fotoğraf Ekle', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              _ImageSourceOption(
                icon: LucideIcons.camera,
                label: 'Kamera ile Çek',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _ImageSourceOption(
                icon: LucideIcons.image,
                label: 'Galeriden Seç',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
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
      appBar: AppBar(
        title: Text('Yeni Proje', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            ref.read(addProjectProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Fotoğraf Alanı ──────────────────
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        border: Border.all(
                          color: state.imageBytes != null ? Colors.transparent : AppColors.border,
                          width: state.imageBytes != null ? 0 : 1.5,
                        ),
                      ),
                      child: state.imageBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(LucideIcons.camera, size: 28, color: AppColors.primary),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppStrings.takePhoto,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'veya galeriden seç',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                                  child: Image.memory(state.imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: _showImageSourceDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── Oda Tipi ────────────────────────
                  Text('Oda Tipi', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            type,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ─── Form Alanları ───────────────────
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.projectName,
                      prefixIcon: const Icon(LucideIcons.layout, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: AppStrings.projectLocation,
                      prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _clientController,
                    decoration: const InputDecoration(
                      labelText: 'Müşteri Adı (opsiyonel)',
                      prefixIcon: Icon(LucideIcons.user, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tahmini Bütçe (₺)',
                      prefixIcon: Icon(LucideIcons.wallet, size: 20),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── Kaydet Butonu ───────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(AppStrings.saveProject),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
