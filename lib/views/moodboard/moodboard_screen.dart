import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

class MoodboardScreen extends StatefulWidget {
  final String projectName;
  const MoodboardScreen({super.key, this.projectName = 'Moodboard'});

  @override
  State<MoodboardScreen> createState() => _MoodboardScreenState();
}

class _MoodboardScreenState extends State<MoodboardScreen> {
  final List<_MoodboardItem> _items = [];
  final List<Color> _selectedColors = [];

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80);

    for (final file in files) {
      final bytes = await file.readAsBytes();
      setState(() {
        _items.add(_MoodboardItem(imageBytes: bytes));
      });
    }
  }

  void _addColor() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Renk Ekle', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _presetColorTile(ctx, const Color(0xFFE8D5C4), 'Warm Beige'),
                  _presetColorTile(ctx, const Color(0xFF2C3E50), 'Navy'),
                  _presetColorTile(ctx, const Color(0xFF8B9467), 'Sage'),
                  _presetColorTile(ctx, const Color(0xFFD4A574), 'Terracotta'),
                  _presetColorTile(ctx, const Color(0xFF6C5B7B), 'Mauve'),
                  _presetColorTile(ctx, const Color(0xFF355C7D), 'Steel Blue'),
                  _presetColorTile(ctx, const Color(0xFFC06C84), 'Dusty Rose'),
                  _presetColorTile(ctx, const Color(0xFF2D2D2D), 'Charcoal'),
                  _presetColorTile(ctx, const Color(0xFFF8F3E6), 'Cream'),
                  _presetColorTile(ctx, const Color(0xFF4A7C59), 'Forest'),
                  _presetColorTile(ctx, const Color(0xFFB8860B), 'Gold'),
                  _presetColorTile(ctx, const Color(0xFF708090), 'Slate'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetColorTile(BuildContext ctx, Color color, String name) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedColors.add(color));
        Navigator.pop(ctx);
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  void _addNote() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Not Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Tasarım notun...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _items.add(_MoodboardItem(note: controller.text));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Moodboard', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proje adı + açıklama
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              widget.projectName,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),

          // Seçili renkler
          if (_selectedColors.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('Renk Paleti', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _selectedColors.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onLongPress: () => setState(() => _selectedColors.removeAt(i)),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedColors[i],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Grid
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(LucideIcons.layoutGrid, size: 32, color: AppColors.accent),
                        ),
                        const SizedBox(height: 16),
                        Text('Moodboard Boş', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'İlham fotoğrafları, renkler ve notlar\nekleyerek vizyonunu oluştur.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (_, index) {
                      final item = _items[index];
                      return GestureDetector(
                        onLongPress: () {
                          setState(() => _items.removeAt(index));
                        },
                        child: item.imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                child: Image.memory(item.imageBytes!, fit: BoxFit.cover),
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                  border: Border.all(color: AppColors.border, width: 0.5),
                                ),
                                child: Center(
                                  child: Text(
                                    item.note ?? '',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Alt butonlar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _AddButton(icon: LucideIcons.image, label: 'Fotoğraf', onTap: _addImage),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AddButton(icon: LucideIcons.palette, label: 'Renk', onTap: _addColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AddButton(icon: LucideIcons.stickyNote, label: 'Not', onTap: _addNote),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MoodboardItem {
  final Uint8List? imageBytes;
  final String? note;

  _MoodboardItem({this.imageBytes, this.note});
}
