import 'package:flutter/material.dart';

/// Full-screen, non-dismissible loading overlay shown while a blocking async
/// action (checking location, opening camera, punch in/out, break in/out...)
/// is in progress, so the user can't tap anything else underneath it.
///
/// Usage:
/// ```dart
/// FullScreenLoader.show(context, 'Punching in...');
/// try {
///   await doSomething();
/// } finally {
///   FullScreenLoader.hide();
/// }
/// ```
/// Calling [show] again while already showing just updates the message in
/// place (no flicker), so a single overlay can be reused across the steps
/// of one flow (e.g. "Checking location..." -> "Opening camera...").
///
/// Implemented as an [OverlayEntry] inserted into the root [Overlay] rather
/// than a dialog route — that's what lets it stay on screen underneath a
/// screen pushed via [Navigator.push] (e.g. showing while a camera page
/// opens) without [hide] accidentally popping that pushed screen instead.
class FullScreenLoader {
  FullScreenLoader._();

  static OverlayEntry? _entry;
  static final ValueNotifier<String> _message = ValueNotifier<String>('');

  static bool get isShowing => _entry != null;

  static void show(BuildContext context, String message) {
    _message.value = message;
    if (_entry != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (_) => _FullScreenLoaderView(message: _message),
    );
    overlay.insert(_entry!);
  }

  /// Update the message of an already-visible loader without closing it.
  static void updateMessage(String message) {
    _message.value = message;
  }

  /// [context] is accepted (and ignored) for source-compatibility with call
  /// sites that still pass one — hiding no longer needs it.
  static void hide([BuildContext? context]) {
    _entry?.remove();
    _entry = null;
  }
}

class _FullScreenLoaderView extends StatefulWidget {
  final ValueNotifier<String> message;

  const _FullScreenLoaderView({required this.message});

  @override
  State<_FullScreenLoaderView> createState() => _FullScreenLoaderViewState();
}

class _FullScreenLoaderViewState extends State<_FullScreenLoaderView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Blocks taps/gestures from reaching whatever is underneath.
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.55),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 48),
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 68,
                      width: 68,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.18);
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: scale,
                                child: Container(
                                  height: 68,
                                  width: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green.withOpacity(
                                        0.15 * (1 - _pulseController.value * 0.6)),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 46,
                                width: 46,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.green),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    ValueListenableBuilder<String>(
                      valueListenable: widget.message,
                      builder: (context, value, _) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          value,
                          key: ValueKey(value),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please wait, don't close the app",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
