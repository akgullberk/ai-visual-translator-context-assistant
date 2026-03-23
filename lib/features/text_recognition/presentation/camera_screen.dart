import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:bitirme_projesi/core/configs/theme/app_colors.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_cubit.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_state.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_bottom_bar.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_top_bar.dart';
import 'package:bitirme_projesi/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitirme_projesi/features/translation/domain/usecases/translate_text_usecase.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/usecases/get_cultural_context_usecase.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late final TextRecognitionCubit _textRecognitionCubit;
  late final TranslateTextUseCase _translateTextUseCase;
  late final GetCulturalContextUseCase _getCulturalContextUseCase;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _error;
  bool _isFlashOn = false;
  String _sourceLanguage = 'Otomatik';
  String _targetLanguage = 'Türkçe';

  @override
  void initState() {
    super.initState();
    _textRecognitionCubit = sl<TextRecognitionCubit>();
    _translateTextUseCase = sl<TranslateTextUseCase>();
    _getCulturalContextUseCase = sl<GetCulturalContextUseCase>();
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

  String _getDeepLTargetLangCode() {
    switch (_targetLanguage) {
      case 'Türkçe':
        return 'TR';
      case 'English':
        return 'EN';
      default:
        return 'TR';
    }
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

        if (state.status == TextRecognitionStatus.success &&
            state.recognizedText.trim().isNotEmpty) {
          final recognizedText = state.recognizedText.trim();

          unawaited(_processText(recognizedText));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Future<void> _processText(String recognizedText) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
    final translationResult = await _translateTextUseCase(
      text: recognizedText,
      targetLang: _getDeepLTargetLangCode(),
    );

    if (translationResult.isSuccess && translationResult.data != null) {
      debugPrint('TRANSLATION RESULT: ${translationResult.data!.value}');
    } else {
      debugPrint('TRANSLATION ERROR: '
          '${translationResult.failure?.message ?? 'Bilinmeyen hata'}');
    }

    final culturalResult = await _getCulturalContextUseCase(
      text: recognizedText,
    );

    if (culturalResult.isSuccess && culturalResult.data != null) {
      debugPrint('CULTURAL_CONTEXT RESULT: ${culturalResult.data!.value}');
    } else {
      debugPrint('CULTURAL_CONTEXT ERROR: '
          '${culturalResult.failure?.message ?? 'Bilinmeyen hata'}');
    }
    } finally {
      _isProcessing = false;
    }
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
