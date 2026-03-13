import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: _CircleBackButton(),
            actions: [
              _CircleIconButton(icon: LucideIcons.share2, onTap: () {}),
              const SizedBox(width: 8),
              _CircleIconButton(icon: LucideIcons.moreVertical, onTap: () => _showOptionsSheet(context)),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: project['image_url'] != null
                  ? CachedNetworkImage(imageUrl: project['image_url'], fit: BoxFit.cover, width: double.infinity)
                  : Container(color: AppColors.surfaceVariant, child: const Center(child: Icon(LucideIcons.image, size: 48, color: AppColors.textTertiary))),
            ),
          ),
        ],
        body: Column(
          children: [
            // Proje bilgileri ve Karşılaştırma Butonu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.surface,
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
                  // ---------------------------------------

                  Row(
                    children: [
                      _StatusBadge(status: status),
                      if (project['room_type'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                          child: Text(project['room_type'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(project['name'] ?? 'İsimsiz Proje', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  if (project['location'] != null)
                    _InfoRow(icon: LucideIcons.mapPin, text: project['location']),
                  if (project['client_name'] != null)
                    _InfoRow(icon: LucideIcons.user, text: project['client_name']),
                  if (project['budget'] != null)
                    _InfoRow(icon: LucideIcons.wallet, text: Helpers.formatCurrency(project['budget'].toDouble())),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
                tabs: const [Tab(text: 'Renk Paleti'), Tab(text: 'Ölçümler'), Tab(text: 'Notlar')],
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
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              _OptionItem(icon: LucideIcons.edit3, label: 'Projeyi Düzenle', onTap: () => Navigator.pop(ctx)),
              _OptionItem(icon: LucideIcons.archive, label: 'Arşivle', onTap: () => Navigator.pop(ctx)),
              _OptionItem(icon: LucideIcons.trash2, label: 'Sil', onTap: () => Navigator.pop(ctx), isDestructive: true),
            ],
          ),
        ),
      ),
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    final colors = paletteGenerator!.colors.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mekan Renk Paleti', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Fotoğraftan çıkarılan ${colors.length} ana renk', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          // Büyük palet
          Container(
            height: 120,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.radiusLG), boxShadow: AppColors.softShadow),
            child: Row(children: colors.map((c) => Expanded(child: Container(color: c))).toList()),
          ),
          const SizedBox(height: 24),
          // Renk kartları
          ...colors.map((color) {
            final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: hex));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$hex kopyalandı!')));
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5))),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(hex, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('R:${color.red} G:${color.green} B:${color.blue}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                      ]),
                      const Spacer(),
                      const Icon(LucideIcons.copy, size: 16, color: AppColors.textTertiary),
                    ],
                  ),
                ),
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
          Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)), child: const Icon(LucideIcons.maximize, size: 32, color: AppColors.primary)),
          const SizedBox(height: 16),
          Text('AR Ölçümler', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('AR aracı ile yaptığın ölçümler\nburada listelenecek.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.plus, size: 18), label: const Text('Ölçüm Ekle')),
        ],
      ),
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
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _OptionItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
    );
  }
}
