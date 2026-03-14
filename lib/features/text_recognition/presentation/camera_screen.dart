import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:bitirme_projesi/core/configs/theme/app_colors.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_top_bar.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_bottom_bar.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _error;
  bool _isFlashOn = false;
  String _sourceLanguage = 'Otomatik';
  String _targetLanguage = 'Türkçe';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Kamera bulunamadı');
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } on CameraException catch (e) {
      setState(() => _error = 'Kamera başlatılamadı: ${e.description}');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentBlue),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        SafeArea(
          child: Column(
            children: [
              CameraTopBar(
                isFlashOn: _isFlashOn,
                sourceLanguage: _sourceLanguage,
                targetLanguage: _targetLanguage,
                onBack: () => Navigator.pop(context),
                onFlashToggle: () {
                  setState(() => _isFlashOn = !_isFlashOn);
                },
                onSwapLanguages: () {
                  setState(() {
                    final temp = _sourceLanguage;
                    _sourceLanguage = _targetLanguage;
                    _targetLanguage = temp;
                  });
                },
                onSourceLanguageTap: () {},
                onTargetLanguageTap: () {},
              ),
              const Spacer(),
              CameraBottomBar(
                onGalleryTap: () {},
                onCapture: () {},
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
