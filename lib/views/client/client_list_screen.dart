import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  void _showAddClientSheet() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
            Text('Yeni Müşteri', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(LucideIcons.user, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta (opsiyonel)',
                prefixIcon: Icon(LucideIcons.mail, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon (opsiyonel)',
                prefixIcon: Icon(LucideIcons.phone, size: 20),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty) {
                    final service = ref.read(supabaseServiceProvider);
                    await service.createClient({
                      'name': _nameController.text.trim(),
                      'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
                      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      setState(() {});
                    }
                  }
                },
                child: const Text('Müşteri Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Müşteriler', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder(
        future: service.getClients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final clients = snapshot.data ?? [];

          if (clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(LucideIcons.users, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('Henüz müşteri yok', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('İlk müşterini ekleyerek başla.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: clients.length,
            itemBuilder: (_, i) {
              final client = clients[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                          if (client.email != null)
                            Text(client.email!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                          if (client.phone != null)
                            Text(client.phone!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textTertiary),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.userPlus, color: Colors.white),
      ),
    );
  }
}
