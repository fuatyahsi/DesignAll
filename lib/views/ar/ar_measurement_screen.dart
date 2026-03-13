import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';

/// Kamera tabanlı ölçüm aracı
/// Canlı kamera görüntüsü üzerinde iki nokta koyarak
/// referans uzunluk ile gerçek mesafe hesaplar
class ArMeasurementScreen extends StatefulWidget {
  const ArMeasurementScreen({super.key});

  @override
  State<ArMeasurementScreen> createState() => _ArMeasurementScreenState();
}

class _ArMeasurementScreenState extends State<ArMeasurementScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _cameraError = false;
  String _errorMsg = '';

  // Ölçüm modu
  _MeasureMode _mode = _MeasureMode.twoPoint;

  // Referans kalibrasyon — kullanıcı bilinen bir uzunluk girer
  double _referenceRealCm = 100; // varsayılan 1 metre
  double _referencePxLength = 0; // ekrandaki piksel uzunluğu
  bool _isCalibrated = false;

  // Noktalar
  final List<Offset> _points = [];
  final List<_MeasurementResult> _measurements = [];
  String _currentDistance = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = true;
          _errorMsg = 'Kamera bulunamadı';
        });
        return;
      }

      // Arka kamerayı tercih et
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _errorMsg = 'Kamera açılamadı: $e';
        });
      }
    }
  }

  void _onTapScreen(TapDownDetails details) {
    final point = details.localPosition;

    if (_mode == _MeasureMode.calibrate) {
      // Kalibrasyon modu — 2 nokta ile referans uzunluk belirle
      setState(() {
        _points.add(point);
        if (_points.length == 2) {
          _referencePxLength = _distanceBetween(_points[0], _points[1]);
          _isCalibrated = true;
          _mode = _MeasureMode.twoPoint;
          _points.clear();
          _showCalibrationSuccess();
        }
      });
    } else {
      // Normal ölçüm modu
      setState(() {
        _points.add(point);
        if (_points.length == 2) {
          final pxDist = _distanceBetween(_points[0], _points[1]);
          double realCm;

          if (_isCalibrated && _referencePxLength > 0) {
            // Kalibre edilmiş ölçüm
            realCm = (pxDist / _referencePxLength) * _referenceRealCm;
          } else {
            // Kalibre edilmemiş — ekran oranına göre yaklaşık
            final screenDiag = sqrt(
              MediaQuery.of(context).size.width * MediaQuery.of(context).size.width +
              MediaQuery.of(context).size.height * MediaQuery.of(context).size.height,
            );
            realCm = (pxDist / screenDiag) * 250; // yaklaşık
          }

          final label = 'Ölçüm ${_measurements.length + 1}';
          _measurements.add(_MeasurementResult(
            distanceCm: realCm,
            label: label,
            timestamp: DateTime.now(),
            p1: _points[0],
            p2: _points[1],
          ));

          if (realCm >= 100) {
            _currentDistance = '${(realCm / 100).toStringAsFixed(2)} m';
          } else {
            _currentDistance = '${realCm.toStringAsFixed(1)} cm';
          }

          _points.clear();
        }
      });
    }
  }

  double _distanceBetween(Offset a, Offset b) {
    return sqrt(pow(a.dx - b.dx, 2) + pow(a.dy - b.dy, 2));
  }

  void _showCalibrationSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Kalibrasyon tamamlandı! (${_referenceRealCm.toStringAsFixed(0)} cm referans)'),
          ],
        ),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startCalibration() {
    final controller = TextEditingController(text: '100');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(LucideIcons.ruler, size: 22, color: AppColors.teal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kalibrasyon', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('Doğru ölçüm için referans belirleyin', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Kamera görüntüsünde uzunluğunu bildiğiniz bir nesne seçin (kapı, kağıt, cetvel vb.). Gerçek uzunluğunu cm olarak girin, sonra o nesnenin iki ucuna dokunun.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Referans uzunluk (cm)',
                  prefixIcon: const Icon(LucideIcons.maximize, size: 20),
                  suffixText: 'cm',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Hızlı seçenekler
            Text('Hızlı Seçim:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickRef(label: 'A4 Uzun kenar', value: '29.7', onTap: (v) => controller.text = v),
                _QuickRef(label: 'A4 Kısa kenar', value: '21', onTap: (v) => controller.text = v),
                _QuickRef(label: 'Kapı genişliği', value: '80', onTap: (v) => controller.text = v),
                _QuickRef(label: 'Kapı yüksekliği', value: '200', onTap: (v) => controller.text = v),
                _QuickRef(label: '1 Metre', value: '100', onTap: (v) => controller.text = v),
                _QuickRef(label: 'Kredi kartı', value: '8.5', onTap: (v) => controller.text = v),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.teal, AppColors.teal.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val != null && val > 0) {
                      setState(() {
                        _referenceRealCm = val;
                        _mode = _MeasureMode.calibrate;
                        _points.clear();
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Referansı İşaretle', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _points.clear();
      _measurements.clear();
      _currentDistance = '';
    });
  }

  double get _totalCm => _measurements.fold(0.0, (s, m) => s + m.distanceCm);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ─── Kamera görünümü ────────────────────
          if (_isCameraReady && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else if (_cameraError)
            _buildErrorBackground()
          else
            _buildLoadingBackground(),

          // ─── Dokunma alanı ──────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _isCameraReady ? _onTapScreen : null,
              behavior: HitTestBehavior.translucent,
              child: CustomPaint(
                painter: _MeasurePainter(
                  points: _points,
                  measurements: _measurements,
                  isCalibrating: _mode == _MeasureMode.calibrate,
                ),
              ),
            ),
          ),

          // ─── Üst bar ───────────────────────────
          _buildTopBar(),

          // ─── Mesafe gösterge ────────────────────
          if (_currentDistance.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppColors.accentGlow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.ruler, size: 18, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(_currentDistance, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
            ),

          // ─── Sağ panel — son ölçümler ──────────
          if (_measurements.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              right: 16,
              child: Container(
                width: 150,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Ölçümler', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5))),
                        const Spacer(),
                        if (_isCalibrated)
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(_measurements.reversed.take(5).map((m) {
                      final formatted = m.distanceCm >= 100
                          ? '${(m.distanceCm / 100).toStringAsFixed(2)} m'
                          : '${m.distanceCm.toStringAsFixed(1)} cm';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(m.label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.6)), overflow: TextOverflow.ellipsis)),
                            Text(formatted, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      );
                    })),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1),
            ),

          // ─── Alt panel ─────────────────────────
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildLoadingBackground() {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 16),
            Text('Kamera açılıyor...', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
              child: const Icon(LucideIcons.cameraOff, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text('Kamera erişilemedi', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(_errorMsg, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.5))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _GlassBtn(icon: LucideIcons.arrowLeft, onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              // Durum
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _mode == _MeasureMode.calibrate
                            ? AppColors.warning
                            : (_isCalibrated ? AppColors.teal : AppColors.accent),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.5), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _mode == _MeasureMode.calibrate
                          ? 'Referansı işaretleyin'
                          : (_points.length == 1 ? '2. noktaya dokunun' : (_isCalibrated ? 'Kalibre • Ölçüme hazır' : 'Ölçüm Aracı')),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_measurements.isNotEmpty)
                _GlassBtn(icon: LucideIcons.rotateCcw, onTap: _clearAll),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
            child: Column(
              children: [
                // İstatistik
                if (_measurements.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniStat(label: 'Ölçüm', value: '${_measurements.length}', icon: LucideIcons.hash),
                        Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                        _MiniStat(label: 'Toplam', value: _totalCm >= 100 ? '${(_totalCm / 100).toStringAsFixed(1)} m' : '${_totalCm.toStringAsFixed(0)} cm', icon: LucideIcons.ruler),
                        Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                        _MiniStat(label: 'Son', value: _currentDistance.isNotEmpty ? _currentDistance : '-', icon: LucideIcons.target),
                      ],
                    ),
                  ),

                // Butonlar
                Row(
                  children: [
                    // Kalibrasyon butonu
                    GestureDetector(
                      onTap: _startCalibration,
                      child: Container(
                        width: 58, height: 58,
                        decoration: BoxDecoration(
                          color: _isCalibrated ? AppColors.teal.withOpacity(0.2) : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _isCalibrated ? AppColors.teal.withOpacity(0.4) : Colors.white.withOpacity(0.15)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.target, size: 20, color: _isCalibrated ? AppColors.teal : Colors.white),
                            const SizedBox(height: 2),
                            Text('Kalibre', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: _isCalibrated ? AppColors.teal : Colors.white.withOpacity(0.6))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ana buton
                    Expanded(
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: _mode == _MeasureMode.calibrate ? null : AppColors.accentGradient,
                          color: _mode == _MeasureMode.calibrate ? AppColors.warning : null,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _mode != _MeasureMode.calibrate ? AppColors.buttonShadow : null,
                        ),
                        child: Center(
                          child: Text(
                            _mode == _MeasureMode.calibrate
                                ? (_points.isEmpty ? 'Referansın 1. ucuna dokunun' : '2. ucuna dokunun')
                                : (_points.isEmpty ? 'İlk noktaya dokunun' : 'İkinci noktaya dokunun'),
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    if (_measurements.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showHistory(context),
                        child: Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.list, size: 18, color: Colors.white),
                              const SizedBox(height: 2),
                              Text('${_measurements.length}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  _isCalibrated ? 'Kalibre edildi — doğru ölçüm yapılabilir' : 'Daha doğru sonuç için kalibre edin',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.ruler, size: 20, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ölçüm Geçmişi', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                          '${_measurements.length} ölçüm  •  Toplam: ${_totalCm >= 100 ? '${(_totalCm / 100).toStringAsFixed(1)} m' : '${_totalCm.toStringAsFixed(0)} cm'}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _measurements.length,
                    itemBuilder: (ctx, i) {
                      final m = _measurements[i];
                      final formatted = m.distanceCm >= 100
                          ? '${(m.distanceCm / 100).toStringAsFixed(2)} m'
                          : '${m.distanceCm.toStringAsFixed(1)} cm';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text('${i + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.accent))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text('${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                child: Text(formatted, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Kamera Preview Widget ────────────────────────────
class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  const CameraPreviewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CameraPreview(controller);
  }
}

// ─── Custom Painter — çizgiler ve noktalar ────────────
class _MeasurePainter extends CustomPainter {
  final List<Offset> points;
  final List<_MeasurementResult> measurements;
  final bool isCalibrating;

  _MeasurePainter({required this.points, required this.measurements, required this.isCalibrating});

  @override
  void paint(Canvas canvas, Size size) {
    // Tamamlanmış ölçümlerin çizgileri
    for (final m in measurements) {
      _drawMeasureLine(canvas, m.p1, m.p2, AppColors.accent);
    }

    // Aktif noktalar
    final dotColor = isCalibrating ? AppColors.teal : AppColors.accent;
    for (final p in points) {
      // Dış halka
      canvas.drawCircle(p, 18, Paint()..color = dotColor.withOpacity(0.2)..style = PaintingStyle.fill);
      canvas.drawCircle(p, 18, Paint()..color = dotColor..style = PaintingStyle.stroke..strokeWidth = 2);
      // İç nokta
      canvas.drawCircle(p, 6, Paint()..color = dotColor);
      // Artı işareti
      final crossPaint = Paint()..color = dotColor.withOpacity(0.5)..strokeWidth = 1;
      canvas.drawLine(Offset(p.dx - 28, p.dy), Offset(p.dx - 20, p.dy), crossPaint);
      canvas.drawLine(Offset(p.dx + 20, p.dy), Offset(p.dx + 28, p.dy), crossPaint);
      canvas.drawLine(Offset(p.dx, p.dy - 28), Offset(p.dx, p.dy - 20), crossPaint);
      canvas.drawLine(Offset(p.dx, p.dy + 20), Offset(p.dx, p.dy + 28), crossPaint);
    }
  }

  void _drawMeasureLine(Canvas canvas, Offset p1, Offset p2, Color color) {
    // Çizgi
    canvas.drawLine(p1, p2, Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    // Uç noktalar
    canvas.drawCircle(p1, 5, Paint()..color = color);
    canvas.drawCircle(p2, 5, Paint()..color = color);
    // Dış halkalar
    canvas.drawCircle(p1, 10, Paint()..color = color.withOpacity(0.15));
    canvas.drawCircle(p2, 10, Paint()..color = color.withOpacity(0.15));
  }

  @override
  bool shouldRepaint(covariant _MeasurePainter old) => true;
}

// ─── Veri Modelleri ───────────────────────────────────
enum _MeasureMode { twoPoint, calibrate }

class _MeasurementResult {
  final double distanceCm;
  final String label;
  final DateTime timestamp;
  final Offset p1, p2;
  _MeasurementResult({required this.distanceCm, required this.label, required this.timestamp, required this.p1, required this.p2});
}

// ─── Yardımcı Widget'lar ──────────────────────────────
class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.4)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
      ],
    );
  }
}

class _QuickRef extends StatelessWidget {
  final String label, value;
  final Function(String) onTap;
  const _QuickRef({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Text('$label (${value}cm)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ),
    );
  }
}
