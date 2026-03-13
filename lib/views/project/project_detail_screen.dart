import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../utils/helpers.dart';
// Yeni eklediğimiz sayfa importu
import 'before_after_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  PaletteGenerator? paletteGenerator;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generatePalette();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePalette() async {
    if (widget.project['image_url'] != null) {
      try {
        final generator = await PaletteGenerator.fromImageProvider(
          NetworkImage(widget.project['image_url']),
          maximumColorCount: 12,
        );
        if (mounted) setState(() => paletteGenerator = generator);
      } catch (e) {
        debugPrint('Palette error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final status = project['status'] ?? 'active';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: _CircleBackButton(),
            actions: [
              _CircleIconButton(icon: LucideIcons.share2, onTap: () {}),
              const SizedBox(width: 8),
              _CircleIconButton(icon: LucideIcons.moreVertical, onTap: () => _showOptionsSheet(context)),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fotoğraf veya gradient
                  project['image_url'] != null
                      ? CachedNetworkImage(
                          imageUrl: project['image_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.home, size: 56, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 8),
                                Text(
                                  project['room_type'] ?? '',
                                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                  // Alt gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Proje bilgileri ve Karşılaştırma Butonu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HAMLE 1: Dönüşümü Planla Butonu ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BeforeAfterScreen(
                              projectName: project['name'] ?? 'Proje',
                              existingImageUrl: project['image_url'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.gitCompare, size: 20, color: Colors.white),
                      label: const Text('DÖNÜŞÜMÜ PLANLA (ÖNCE / SONRA)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Badges
                  Row(
                    children: [
                      _StatusBadge(status: status),
                      if (project['room_type'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.home, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(project['room_type'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 14),
                  Text(
                    project['name'] ?? 'İsimsiz Proje',
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                  const SizedBox(height: 14),

                  // Info chips
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (project['location'] != null)
                        _InfoChip(icon: LucideIcons.mapPin, text: project['location'], color: AppColors.accent),
                      if (project['client_name'] != null)
                        _InfoChip(icon: LucideIcons.user, text: project['client_name'], color: AppColors.purple),
                      if (project['budget'] != null)
                        _InfoChip(icon: LucideIcons.wallet, text: Helpers.formatCurrency(project['budget'].toDouble()), color: AppColors.gold),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.accent,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
                tabs: const [
                  Tab(text: 'Renk Paleti'),
                  Tab(text: 'Ölçümler'),
                  Tab(text: 'Notlar'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ColorPaletteTab(paletteGenerator: paletteGenerator),
                  _MeasurementsTab(projectId: project['id']?.toString() ?? ''),
                  _NotesTab(project: project),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
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
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                _OptionItem(icon: LucideIcons.edit3, label: 'Projeyi Düzenle', color: AppColors.primary, onTap: () => Navigator.pop(ctx)),
                const SizedBox(height: 8),
                _OptionItem(icon: LucideIcons.archive, label: 'Arşivle', color: AppColors.gold, onTap: () => Navigator.pop(ctx)),
                const SizedBox(height: 8),
                _OptionItem(icon: LucideIcons.trash2, label: 'Sil', color: AppColors.error, onTap: () => Navigator.pop(ctx), isDestructive: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoChip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Renk Paleti Tab ───────────────────────────────────
class _ColorPaletteTab extends StatelessWidget {
  final PaletteGenerator? paletteGenerator;
  const _ColorPaletteTab({this.paletteGenerator});

  @override
  Widget build(BuildContext context) {
    if (paletteGenerator == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(LucideIcons.palette, size: 28, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text('Renk paleti oluşturuluyor...', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
          ],
        ),
      );
    }
    final colors = paletteGenerator!.colors.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.palette, size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mekan Renk Paleti', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('${colors.length} ana renk tespit edildi', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Büyük palet
          Container(
            height: 100,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(children: colors.map((c) => Expanded(child: Container(color: c))).toList()),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.05),
          const SizedBox(height: 24),

          // Renk kartları
          ...colors.asMap().entries.map((entry) {
            final i = entry.key;
            final color = entry.value;
            final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: hex));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Container(width: 20, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 10),
                          Text('$hex kopyalandı!'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hex, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('R:${color.red}  G:${color.green}  B:${color.blue}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.copy, size: 16, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(delay: Duration(milliseconds: 300 + i * 60), duration: 300.ms)
                  .slideX(begin: 0.02),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Ölçümler Tab ──────────────────────────────────────
class _MeasurementsTab extends StatelessWidget {
  final String projectId;
  const _MeasurementsTab({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.teal.withOpacity(0.15), AppColors.teal.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(LucideIcons.maximize, size: 36, color: AppColors.teal),
          ),
          const SizedBox(height: 20),
          Text('AR Ölçümler', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'AR aracı ile yaptığın ölçümler\nburada listelenecek.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.teal, AppColors.teal.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
              label: Text('Ölçüm Ekle', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

// ─── Notlar Tab ────────────────────────────────────────
// ─── Görsel Notlar Tab (Photo Markup) ────────────────────────────────────────
class _NotesTab extends StatefulWidget {
  final Map<String, dynamic> project;
  const _NotesTab({required this.project});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  // Pin'leri tutan liste (Şu anlık lokal, Supabase entegrasyonu sonra yapılacak)
  final List<Map<String, dynamic>> _pins = [];

  void _addPin(Offset localPosition, Size imageSize) {
    // Koordinatları resim boyutuna göre oranlıyoruz (0.0 - 1.0 arası)
    final double dx = localPosition.dx / imageSize.width;
    final double dy = localPosition.dy / imageSize.height;

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Bu Noktaya Not Ekle'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Örn: Kanepe buraya alınacak"),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _pins.add({
                      'x': dx,
                      'y': dy,
                      'note': controller.text,
                      'color': AppColors.accent,
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.project['image_url'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Görsel Planlama', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Fotoğrafın üzerine dokunarak değişim notlarını ekle.',
               style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // İnteraktif Fotoğraf Alanı
          if (imageUrl != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double height = width * 0.75; // 4:3 oranında gösterim

                return GestureDetector(
                  onTapUp: (details) => _addPin(details.localPosition, Size(width, height)),
                  child: Stack(
                    children: [
                      // Ana Fotoğraf
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Pin'ler
                      ..._pins.map((pin) {
                        return Positioned(
                          left: pin['x'] * width - 15,
                          top: pin['y'] * height - 15,
                          child: Tooltip(
                            message: pin['note'],
                            triggerMode: TooltipTriggerMode.tap,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: pin['color'].withOpacity(0.9),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                              ),
                              child: const Icon(LucideIcons.info, size: 16, color: Colors.white),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            )
          else
            const Text("Fotoğraf bulunamadı."),

          const SizedBox(height: 32),
          Text('Not Listesi', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Eklenen Notların Listesi
          if (_pins.isEmpty)
            Text('Henüz bir planlama notu eklenmemiş.', style: TextStyle(color: AppColors.textTertiary))
          else
            ..._pins.map((pin) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 16, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(child: Text(pin['note'], style: const TextStyle(fontSize: 14))),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.grey),
                    onPressed: () => setState(() => _pins.remove(pin)),
                  )
                ],
              ),
            )),
        ],
      ),
    );
  }
}
// ─── Yardımcı Widget'lar ───────────────────────────────
class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 18)),
      onTap: onTap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status == 'completed' ? 'Tamamlandı' : status == 'paused' ? 'Beklemede' : 'Aktif';
    final color = status == 'completed' ? AppColors.statusCompleted : status == 'paused' ? AppColors.statusPaused : AppColors.statusActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;
  const _OptionItem({required this.icon, required this.label, required this.color, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: color)),
            const Spacer(),
            Icon(LucideIcons.chevronRight, size: 18, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
