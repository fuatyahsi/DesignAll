import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

class BeforeAfterScreen extends StatefulWidget {
  final String projectName;
  final String? existingImageUrl;

  const BeforeAfterScreen({
    super.key,
    required this.projectName,
    this.existingImageUrl,
  });

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen> {
  Uint8List? _beforeImage;
  Uint8List? _afterImage;
  double _sliderValue = 0.5;
  bool _isCompareMode = false;

  Future<void> _pickImage(bool isBefore) async {
    final picker = ImagePicker();
    final source = await _showSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        if (isBefore) {
          _beforeImage = bytes;
        } else {
          _afterImage = bytes;
        }
        if (_beforeImage != null && _afterImage != null) {
          _isCompareMode = true;
        }
      });
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
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
        title: Text('Before / After', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCompareMode ? _buildCompareView() : _buildUploadView(),
    );
  }

  Widget _buildUploadView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            widget.projectName,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Öncesi ve sonrası fotoğraflarını ekleyerek dönüşümü görselleştir.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Before
          Expanded(
            child: _ImageUploadCard(
              label: 'ÖNCE',
              imageBytes: _beforeImage,
              icon: LucideIcons.imageMinus,
              color: AppColors.warning,
              onTap: () => _pickImage(true),
            ),
          ),
          const SizedBox(height: 16),
          // After
          Expanded(
            child: _ImageUploadCard(
              label: 'SONRA',
              imageBytes: _afterImage,
              icon: LucideIcons.imagePlus,
              color: AppColors.success,
              onTap: () => _pickImage(false),
            ),
          ),
          const SizedBox(height: 24),

          if (_beforeImage != null && _afterImage != null)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isCompareMode = true),
                icon: const Icon(LucideIcons.gitCompare, size: 20),
                label: const Text('Karşılaştır'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompareView() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // After (arka plan)
                  Positioned.fill(
                    child: Image.memory(_afterImage!, fit: BoxFit.cover),
                  ),
                  // Before (kırpılmış)
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _SliderClipper(_sliderValue),
                      child: Image.memory(_beforeImage!, fit: BoxFit.cover),
                    ),
                  ),
                  // Slider çizgisi
                  Positioned(
                    left: constraints.maxWidth * _sliderValue - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: Colors.white,
                    ),
                  ),
                  // Slider tutamaç
                  Positioned(
                    left: constraints.maxWidth * _sliderValue - 20,
                    top: constraints.maxHeight / 2 - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: const Icon(LucideIcons.moveHorizontal, size: 20, color: AppColors.primary),
                    ),
                  ),
                  // Etiketler
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _CompareLabel(text: 'ÖNCE', color: AppColors.warning),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _CompareLabel(text: 'SONRA', color: AppColors.success),
                  ),
                  // Gesture
                  Positioned.fill(
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _sliderValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // Alt kontroller
        Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _isCompareMode = false),
                icon: const Icon(LucideIcons.edit3, size: 18),
                label: const Text('Düzenle'),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _sliderValue = 0.5),
                icon: const Icon(LucideIcons.alignCenter, size: 18),
                label: const Text('Ortala'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageUploadCard extends StatelessWidget {
  final String label;
  final Uint8List? imageBytes;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ImageUploadCard({
    required this.label,
    this.imageBytes,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: imageBytes != null ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: imageBytes != null ? Colors.transparent : AppColors.border),
          image: imageBytes != null
              ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
              : null,
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(height: 12),
                  Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: color, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Fotoğraf ekle', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                ],
              )
            : Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _CompareLabel(text: label, color: color),
                ),
              ),
      ),
    );
  }
}

class _CompareLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _CompareLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double sliderValue;
  _SliderClipper(this.sliderValue);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * sliderValue, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) => sliderValue != oldClipper.sliderValue;
}
