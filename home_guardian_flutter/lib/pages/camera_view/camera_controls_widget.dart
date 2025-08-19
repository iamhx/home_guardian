import 'package:flutter/material.dart';
import 'package:home_guardian/providers/camera_view_provider.dart';
import 'package:provider/provider.dart';
import 'manual_control_sheet.dart';

class CameraControlsWidget extends StatefulWidget {
  const CameraControlsWidget({super.key});

  @override
  State<CameraControlsWidget> createState() => _CameraControlsWidgetState();
}

class _CameraControlsWidgetState extends State<CameraControlsWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CameraViewProvider>(
      builder: (context, provider, child) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Power Control - Full Width
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: provider.isPowerLoading ? null : provider.togglePower,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: provider.isPowerLoading
                            ? [Colors.grey[700]!, Colors.grey[600]!]
                            : provider.cameraStatus!.active
                            ? [Colors.red[600]!, Colors.red[700]!]
                            : [Colors.green[600]!, Colors.green[700]!],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        provider.isPowerLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                provider.cameraStatus!.active
                                    ? Icons.power_off_outlined
                                    : Icons.power_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                        const SizedBox(width: 12),
                        Text(
                          provider.isPowerLoading
                              ? 'Loading...'
                              : provider.cameraStatus!.active
                              ? 'Power Off'
                              : 'Power On',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Control Grid - 2x2
            Row(
              children: [
                // Patrol Control
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap:
                            (provider.isPatrolLoading ||
                                !provider.cameraStatus!.active ||
                                provider.isPowerLoading ||
                                provider.mode == 'smart' ||
                                provider.mode == 'manual')
                            ? null
                            : provider.togglePatrol,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color:
                                (provider.isPatrolLoading ||
                                    !provider.cameraStatus!.active ||
                                    provider.isPowerLoading ||
                                    provider.mode == 'smart')
                                ? Colors.grey[100]
                                : Colors.deepPurple[50],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              provider.isPatrolLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      provider.mode == 'patrol'
                                          ? Icons.stop
                                          : Icons.autorenew,
                                      size: 32,
                                      color:
                                          (provider.isPatrolLoading ||
                                              !provider.cameraStatus!.active ||
                                              provider.isPowerLoading ||
                                              provider.mode == 'smart')
                                          ? Colors.grey[400]
                                          : Colors.deepPurple,
                                    ),
                              const SizedBox(height: 8),
                              Text(
                                provider.isPatrolLoading
                                    ? 'Loading...'
                                    : provider.mode == 'patrol'
                                    ? 'Stop Patrol'
                                    : 'Patrol',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (provider.isPatrolLoading ||
                                          !provider.cameraStatus!.active ||
                                          provider.isPowerLoading ||
                                          provider.mode == 'smart')
                                      ? Colors.grey[600]
                                      : Colors.deepPurple[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Smart Patrol Control
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap:
                            (provider.isSmartPatrolLoading ||
                                !provider.cameraStatus!.active ||
                                provider.isPowerLoading ||
                                provider.mode == 'patrol' ||
                                provider.mode == 'manual')
                            ? null
                            : provider.toggleSmartPatrol,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color:
                                (provider.isSmartPatrolLoading ||
                                    !provider.cameraStatus!.active ||
                                    provider.isPowerLoading ||
                                    provider.mode == 'patrol')
                                ? Colors.grey[100]
                                : Colors.indigo[50],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              provider.isSmartPatrolLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      provider.mode == 'smart'
                                          ? Icons.stop
                                          : Icons.smart_toy_outlined,
                                      size: 32,
                                      color:
                                          (provider.isSmartPatrolLoading ||
                                              !provider.cameraStatus!.active ||
                                              provider.isPowerLoading ||
                                              provider.mode == 'patrol')
                                          ? Colors.grey[400]
                                          : Colors.indigo,
                                    ),
                              const SizedBox(height: 8),
                              Text(
                                provider.isSmartPatrolLoading
                                    ? 'Loading...'
                                    : provider.mode == 'smart'
                                    ? 'Stop Smart'
                                    : 'Smart Patrol',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (provider.isSmartPatrolLoading ||
                                          !provider.cameraStatus!.active ||
                                          provider.isPowerLoading ||
                                          provider.mode == 'patrol')
                                      ? Colors.grey[600]
                                      : Colors.indigo[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Manual Control - Full Width
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap:
                      (provider.cameraStatus!.active &&
                          !provider.isPowerLoading &&
                          provider.mode != 'patrol' &&
                          provider.mode != 'smart')
                      ? () {
                          showModalBottomSheet(
                            isDismissible: false,
                            enableDrag: false,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.95,
                            ),
                            barrierColor: Colors.transparent,
                            context: context,
                            builder: (context) => ListenableProvider.value(
                              value: provider,
                              child: const ManualControlSheet(),
                            ),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors:
                            (provider.cameraStatus!.active &&
                                !provider.isPowerLoading &&
                                provider.mode != 'patrol' &&
                                provider.mode != 'smart')
                            ? [Colors.blueGrey[600]!, Colors.blueGrey[700]!]
                            : [Colors.grey[300]!, Colors.grey[400]!],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.drive_eta_outlined,
                          color:
                              (provider.cameraStatus!.active &&
                                  !provider.isPowerLoading &&
                                  provider.mode != 'patrol' &&
                                  provider.mode != 'smart')
                              ? Colors.white
                              : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Manual Control',
                          style: TextStyle(
                            color:
                                (provider.cameraStatus!.active &&
                                    !provider.isPowerLoading &&
                                    provider.mode != 'patrol' &&
                                    provider.mode != 'smart')
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
