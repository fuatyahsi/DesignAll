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
  String distanceResult = 'Ölçüm için iki noktaya dokunun';
  bool isReady = false;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR View
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // Üst bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _ArButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'AR Ölçü Aracı',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    _ArButton(
                      icon: LucideIcons.rotateCcw,
                      onTap: _clearPoints,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Alt panel — ölçüm sonucu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Ölçüm sonucu
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.ruler,
                          size: 20,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            distanceResult,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (measurements.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showMeasurementHistory(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${measurements.length}',
                                style: GoogleFonts.inter(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
    this.arObjectManager!.onInitialize();
    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;

    setState(() => isReady = true);
  }

  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isNotEmpty) {
      var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      );

      var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

      if (didAddAnchor!) {
        anchors.add(newAnchor);
        var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: 'assets/models/dot.gltf',
          scale: vector.Vector3(0.05, 0.05, 0.05),
          position: vector.Vector3(0, 0, 0),
          rotation: vector.Vector4(1, 0, 0, 0),
        );
        bool? didAddNode = await arObjectManager!.addNode(newNode, anchor: newAnchor);
        if (didAddNode!) {
          nodes.add(newNode);
        }
      }

      if (nodes.length >= 2) {
        final position1 = nodes[nodes.length - 2].position;
        final position2 = nodes[nodes.length - 1].position;
        final distance = _calculateDistance(position1, position2);

        final entry = _MeasurementEntry(
          distance: distance,
          timestamp: DateTime.now(),
        );

        setState(() {
          measurements.add(entry);
          if (distance >= 1) {
            distanceResult = '${distance.toStringAsFixed(2)} metre';
          } else {
            distanceResult = '${(distance * 100).toStringAsFixed(1)} cm';
          }
        });
      }
    }
  }

  double _calculateDistance(vector.Vector3 start, vector.Vector3 end) {
    return start.distanceTo(end);
  }

  void _showMeasurementHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Ölçüm Geçmişi', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ...measurements.asMap().entries.map((entry) {
                final m = entry.value;
                final i = entry.key + 1;
                final formatted = m.distance >= 1
                    ? '${m.distance.toStringAsFixed(2)} m'
                    : '${(m.distance * 100).toStringAsFixed(1)} cm';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('$i', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(formatted, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                        const Spacer(),
                        Text(
                          '${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
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
