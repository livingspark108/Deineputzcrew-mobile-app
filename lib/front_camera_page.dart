import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// A full-screen camera page locked to the front-facing camera.
/// Returns the image file path (String) via Navigator.pop, or null if cancelled.
class FrontCameraPage extends StatefulWidget {
  const FrontCameraPage({super.key});

  @override
  State<FrontCameraPage> createState() => _FrontCameraPageState();
}

// Cached once per app session to avoid slow re-enumeration on iOS
List<CameraDescription>? _cachedCameras;

class _FrontCameraPageState extends State<FrontCameraPage> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isCapturing = false;
  String? _errorMessage;
  bool _isPermissionError = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cachedCameras ??= await availableCameras();
      final cameras = _cachedCameras!;
      if (cameras.isEmpty) {
        if (mounted) setState(() => _errorMessage = 'No cameras found on this device.');
        return;
      }

      CameraDescription? frontCamera;
      for (final cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          frontCamera = cam;
          break;
        }
      }

      if (frontCamera == null) {
        if (mounted) setState(() => _errorMessage = 'No front camera found on this device.');
        return;
      }

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isReady = true);
    } on CameraException catch (e) {
      if (mounted) {
        final isPermission = e.code == 'CameraAccessDenied' ||
            e.code == 'CameraAccessDeniedWithoutPrompt' ||
            e.code == 'CameraAccessRestricted' ||
            e.code == 'permissionDenied';
        setState(() {
          _isPermissionError = isPermission;
          _errorMessage = isPermission
              ? 'Camera access is denied.\nPlease enable it in your device Settings.'
              : 'Camera error: ${e.description}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to open camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final file = await _controller!.takePicture();
      if (mounted) Navigator.of(context).pop(file.path);
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white54, size: 64),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (_isPermissionError)
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop(null);
                      await openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Go Back', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isReady
          ? Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ),
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isCapturing ? null : _capture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? Colors.grey : Colors.white,
                          border: Border.all(color: Colors.grey.shade400, width: 4),
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(strokeWidth: 3),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
