import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

class ArMeasurementScreen extends StatefulWidget {
  const ArMeasurementScreen({super.key});

  @override
  State<ArMeasurementScreen> createState() => _ArMeasurementScreenState();
}

class _ArMeasurementScreenState extends State<ArMeasurementScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  List<_MeasurementEntry> measurements = [];
  final List<vector.Vector3> tappedPoints = [];
  String distanceResult = 'Ölçüm için iki noktaya dokunun';
  
  // UX ve Durum Takibi
  bool _planesDetected = false;
  int _pointCount = 0;
  bool _showInstructions = true;

  String get _instructionText {
    if (!_planesDetected) return 'Zemini taramak için telefonu yavaşça hareket ettirin';
    if (_pointCount == 0) return 'Ölçüme başlamak için bir noktaya dokunun';
    if (_pointCount == 1) return 'Mesafeyi görmek için ikinci noktaya dokunun';
    return 'Yeni bir nokta seçebilir veya sıfırlayabilirsiniz';
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  void _clearPoints() {
    setState(() {
      nodes.clear();
      anchors.clear();
      distanceResult = 'Ölçüm için iki noktaya dokunun';
      tappedPoints.clear();
      _pointCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            // Sadece Yatay (Zemin) algılama: Performansı artırır
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),

          // 1. REHBER KATMANI (Açılış Yardımı)
          if (_showInstructions)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.smartphone, size: 80, color: Colors.white),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'AR Ölçümü için telefonunuzu dairesel hareketlerle zemine doğru tutun.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      onPressed: () => setState(() => _showInstructions = false),
                      child: const Text('Anladım, Başlat'),
                    )
                  ],
                ),
              ),
            ),

          // Üst bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _ArIconButton(icon: LucideIcons.arrowLeft, onTap: () => Navigator.pop(context)),
                    const Spacer(),
                    Text('AR Ölçü Aracı', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    _ArIconButton(icon: LucideIcons.rotateCcw, onTap: _clearPoints),
                  ],
                ),
              ),
            ),
          ),

          // Dinamik Yönlendirme Mesajı
          Positioned(
            bottom: 110, left: 0, right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _showInstructions ? 0 : 1,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                  child: Text(_instructionText, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                ),
              ),
            ),
          ),

          // Alt Panel (Sonuçlar)
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.ruler, size: 20, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(distanceResult, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: true, // Noktaları göstererek kullanıcının zemini taradığını anlamasını sağlar
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
    this.arObjectManager!.onInitialize();
    this.arSessionManager!.onPlaneOrPointTap = (results) {
      if (!_planesDetected) setState(() => _planesDetected = true);
      onPlaneOrPointTap(results);
    };
  }

  Future<void> onPlaneOrPointTap(List<dynamic> hitTestResults) async {
    if (hitTestResults.isEmpty) return;

    final singleHitTestResult = hitTestResults.first;
    final worldTransform = singleHitTestResult.worldTransform;

    final newAnchor = ARPlaneAnchor(transformation: worldTransform);
    final bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      anchors.add(newAnchor);
      final newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: 'assets/models/dot.gltf',
        scale: vector.Vector3(0.05, 0.05, 0.05),
        position: vector.Vector3.zero(),
      );
      final bool? didAddNode = await arObjectManager?.addNode(newNode);
      if (didAddNode == true) nodes.add(newNode);
    }

    final hitPoint = _extractPositionFromTransform(worldTransform);
    tappedPoints.add(hitPoint);

    setState(() {
      _pointCount++;
      if (tappedPoints.length >= 2) {
        final distance = _calculateDistance(tappedPoints[tappedPoints.length - 2], tappedPoints[tappedPoints.length - 1]);
        distanceResult = distance >= 1 ? '${distance.toStringAsFixed(2)} m' : '${(distance * 100).toStringAsFixed(1)} cm';
      }
    });
  }

  vector.Vector3 _extractPositionFromTransform(dynamic worldTransform) {
    if (worldTransform is vector.Matrix4) return vector.Vector3(worldTransform.entry(0, 3), worldTransform.entry(1, 3), worldTransform.entry(2, 3));
    return vector.Vector3.zero();
  }

  double _calculateDistance(vector.Vector3 start, vector.Vector3 end) => start.distanceTo(end);
}

class _ArIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MeasurementEntry {
  final double distance;
  final DateTime timestamp;
  _MeasurementEntry({required this.distance, required this.timestamp});
}
