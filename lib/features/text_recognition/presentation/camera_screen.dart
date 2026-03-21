import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:bitirme_projesi/core/configs/theme/app_colors.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_cubit.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_state.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_top_bar.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_bottom_bar.dart';
import 'package:bitirme_projesi/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late final TextRecognitionCubit _textRecognitionCubit;
  bool _isInitialized = false;
  String? _error;
  bool _isFlashOn = false;
  String _sourceLanguage = 'Otomatik';
  String _targetLanguage = 'Türkçe';

  @override
  void initState() {
    super.initState();
    _textRecognitionCubit = sl<TextRecognitionCubit>();
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
    _textRecognitionCubit.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (_textRecognitionCubit.state.isRecognizing) {
      return;
    }

    try {
      final image = await _controller!.takePicture();
      await _textRecognitionCubit.recognizeTextFromImage(image.path);
    } on CameraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goruntu alinamadi: ${e.description}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TextRecognitionCubit, TextRecognitionState>(
      bloc: _textRecognitionCubit,
      listener: (context, state) {
        if (state.status == TextRecognitionStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
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
                onCapture: _captureAndRecognize,
              ),
              BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
                bloc: _textRecognitionCubit,
                builder: (context, state) {
                  if (!state.isRecognizing) {
                    return const SizedBox.shrink();
                  }
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: CircularProgressIndicator(
                      color: AppColors.accentBlue,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
