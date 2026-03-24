import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:bitirme_projesi/core/configs/theme/app_colors.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/recognized_text.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_cubit.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_state.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_bottom_bar.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_top_bar.dart';
import 'package:flutter/material.dart';
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
  bool _showTranslatedText = true;
  List<_OverlayTextItem> _overlayItems = const [];
  String? _capturedImagePath;
  Size? _capturedImageSize;
  int? _selectedIndex;

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
      final imageSize = await _readImageSize(image.path);
      if (mounted) {
        setState(() {
          _capturedImagePath = image.path;
          _capturedImageSize = imageSize;
          _overlayItems = const [];
          _selectedIndex = null;
          _showTranslatedText = true;
        });
      }
      await _textRecognitionCubit.recognizeTextFromImage(image.path);
    } on CameraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goruntu alinamadi: ${e.description}')),
      );
    }
  }

  Future<Size> _readImageSize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
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
          unawaited(
            _processText(
              recognizedText: state.recognizedText.trim(),
              recognizedItems: state.recognizedItems,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Future<void> _processText({
    required String recognizedText,
    required List<RecognizedTextItemEntity> recognizedItems,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final targetLang = _getDeepLTargetLangCode();
      final translatedItems = await _translateRecognizedItems(
        recognizedItems: recognizedItems,
        targetLang: targetLang,
      );

      if (mounted) {
        setState(() {
          _overlayItems = translatedItems;
        });
      }

      final translationResult = await _translateTextUseCase(
        text: recognizedText,
        targetLang: targetLang,
      );

      if (translationResult.isSuccess && translationResult.data != null) {
        debugPrint('TRANSLATION RESULT: ${translationResult.data!.value}');
      } else {
        debugPrint(
          'TRANSLATION ERROR: '
          '${translationResult.failure?.message ?? 'Bilinmeyen hata'}',
        );
      }

      final culturalResult = await _getCulturalContextUseCase(
        text: recognizedText,
      );

      if (culturalResult.isSuccess && culturalResult.data != null) {
        debugPrint('CULTURAL_CONTEXT RESULT: ${culturalResult.data!.value}');
      } else {
        debugPrint(
          'CULTURAL_CONTEXT ERROR: '
          '${culturalResult.failure?.message ?? 'Bilinmeyen hata'}',
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<_OverlayTextItem>> _translateRecognizedItems({
    required List<RecognizedTextItemEntity> recognizedItems,
    required String targetLang,
  }) async {
    if (recognizedItems.isEmpty) {
      return const [];
    }

    final translatedItems = await Future.wait(
      recognizedItems.map((item) async {
        final result = await _translateTextUseCase(
          text: item.value,
          targetLang: targetLang,
        );
        final translatedValue = (result.isSuccess && result.data != null)
            ? result.data!.value
            : item.value;
        return _OverlayTextItem(
          originalText: item.value,
          translatedText: translatedValue,
          left: item.left,
          top: item.top,
          right: item.right,
          bottom: item.bottom,
        );
      }),
    );

    return translatedItems;
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
        if (_capturedImagePath != null && _capturedImageSize != null)
          _buildCapturedImageOverlay()
        else
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
              if (_capturedImagePath == null)
                CameraBottomBar(
                  onGalleryTap: () {},
                  onCapture: _captureAndRecognize,
                ),
              if (_capturedImagePath != null && _overlayItems.isNotEmpty)
                _buildResultPanel(),
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

  Widget _buildCapturedImageOverlay() {
    final imagePath = _capturedImagePath;
    final imageSize = _capturedImageSize;
    if (imagePath == null || imageSize == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final fittedRect = _calculateFittedRect(
          imageSize: imageSize,
          viewportSize: viewportSize,
        );

        return Stack(
          children: [
            Center(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                width: viewportSize.width,
                height: viewportSize.height,
              ),
            ),
            ..._buildOverlayWordWidgets(
              fittedRect: fittedRect,
              imageSize: imageSize,
            ),
          ],
        );
      },
    );
  }

  Rect _calculateFittedRect({
    required Size imageSize,
    required Size viewportSize,
  }) {
    final scale = (viewportSize.width / imageSize.width)
        .clamp(0.0, double.infinity);
    final heightScale = (viewportSize.height / imageSize.height)
        .clamp(0.0, double.infinity);
    final appliedScale = scale < heightScale ? scale : heightScale;

    final renderedWidth = imageSize.width * appliedScale;
    final renderedHeight = imageSize.height * appliedScale;
    final left = (viewportSize.width - renderedWidth) / 2;
    final top = (viewportSize.height - renderedHeight) / 2;
    return Rect.fromLTWH(left, top, renderedWidth, renderedHeight);
  }

  List<Widget> _buildOverlayWordWidgets({
    required Rect fittedRect,
    required Size imageSize,
  }) {
    if (_overlayItems.isEmpty) {
      return const [];
    }

    return _overlayItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final left = fittedRect.left + (item.left / imageSize.width) * fittedRect.width;
      final top = fittedRect.top + (item.top / imageSize.height) * fittedRect.height;
      final rawWidth = ((item.right - item.left) / imageSize.width) * fittedRect.width;
      final rawHeight = ((item.bottom - item.top) / imageSize.height) * fittedRect.height;
      final width = rawWidth < 1 ? 1.0 : rawWidth;
      final height = rawHeight < 1 ? 1.0 : rawHeight;
      final isSelected = _selectedIndex == index;
      final hasDifferentTranslation =
          item.translatedText.trim().toLowerCase() !=
          item.originalText.trim().toLowerCase();
      final isOriginalMode = !_showTranslatedText;
      final displayText = _showTranslatedText
          ? (hasDifferentTranslation ? item.translatedText : '')
          : '';
      final fittedFontSize = _calculateFittedFontSize(
        text: displayText,
        maxWidth: width,
        maxHeight: height,
      );

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: isOriginalMode
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? AppColors.accentBlue.withValues(alpha: 0.9)
                    : (isOriginalMode
                          ? Colors.white.withValues(alpha: 0.22)
                          : Colors.transparent),
                width: 1.2,
              ),
            ),
            child: displayText.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: fittedFontSize,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
          ),
        ),
      );
    }).toList();
  }

  double _calculateFittedFontSize({
    required String text,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (text.trim().isEmpty) {
      return 12;
    }

    final usableWidth = math.max(1.0, maxWidth - 2);
    final usableHeight = math.max(1.0, maxHeight - 2);

    var fontSize = (usableHeight * 0.72).clamp(8.0, 42.0);
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    while (fontSize > 8) {
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1.0,
        ),
      );
      painter.layout(maxWidth: usableWidth);
      if (painter.width <= usableWidth && painter.height <= usableHeight) {
        break;
      }
      fontSize -= 0.5;
    }

    return fontSize;
  }

  Widget _buildResultPanel() {
    final title = _showTranslatedText ? 'Algılanan Çeviri' : 'Algılanan Orijinal';
    final selectedItem = (_selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < _overlayItems.length)
        ? _overlayItems[_selectedIndex!]
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SegmentedButton<bool>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Orijinal'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Çeviri'),
                  ),
                ],
                selected: {_showTranslatedText},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  setState(() {
                    _showTranslatedText = selection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (selectedItem != null) ...[
            Text(
              'Seçili Kelime',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Orijinal: ${selectedItem.originalText}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Çeviri: ${selectedItem.translatedText}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _capturedImagePath = null;
                  _capturedImageSize = null;
                  _overlayItems = const [];
                  _selectedIndex = null;
                });
              },
              child: const Text('Tekrar Çek'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayTextItem {
  const _OverlayTextItem({
    required this.originalText,
    required this.translatedText,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String originalText;
  final String translatedText;
  final double left;
  final double top;
  final double right;
  final double bottom;
}
