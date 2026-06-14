import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bitirme_projesi/core/configs/theme/app_colors.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/entities/recognized_text.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_cubit.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_state.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_bottom_bar.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/widgets/camera_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitirme_projesi/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitirme_projesi/features/translation/domain/usecases/translate_text_usecase.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/usecases/get_cultural_context_usecase.dart';
import 'package:bitirme_projesi/features/history/domain/usecases/save_history_entry_usecase.dart';
import 'package:bitirme_projesi/features/text_recognition/data/mappers/camera_image_mapper.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/usecases/recognize_live_frame_usecase.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/utils/jpeg_orientation_reader.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/utils/ocr_viewport_mapper.dart';
import 'dart:convert';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.initialImagePath});

  /// Ana sayfadan galeri ile gelindiyse, açılışta bu görüntü işlenir.
  final String? initialImagePath;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late final TextRecognitionCubit _textRecognitionCubit;
  late final TranslateTextUseCase _translateTextUseCase;
  late final GetCulturalContextUseCase _getCulturalContextUseCase;
  late final SaveHistoryEntryUseCase _saveHistoryEntryUseCase;
  late final RecognizeLiveFrameUseCase _recognizeLiveFrameUseCase;
  bool _isProcessing = false;
  final bool _isLiveMode = true;
  bool _isLiveProcessing = false;
  DateTime? _lastLiveProcessAt;
  Size? _liveOcrImageSize;
  bool _mirrorLiveOverlay = false;
  bool _isInitialized = false;
  String? _error;
  bool _isFlashOn = false;
  String _sourceLanguage = 'Otomatik';
  String _targetLanguage = 'Türkçe';
  bool _showTranslatedText = true;
  /// Canlı modda aynı cümleyi tekrar çevirmemek için: `hedefDil:orijinalMetin` → çeviri.
  final Map<String, String> _liveTranslationCache = {};
  List<_OverlayTextItem> _overlayItems = const [];
  String? _capturedImagePath;
  Size? _capturedImageSize;
  int? _selectedIndex;

  /// `false`: tam panel görünür, `true`: sadece mini handle.
  bool _isResultPanelCollapsed = false;

  /// Üst drag handle: jest boyunca aşağı kaydırma toplamı (px, pozitif = aşağı).
  double _resultPanelHandleDragDy = 0;

  /// Mini handle: jest boyunca yukarı kaydırma toplamı (negatif dy birikir).
  double _miniHandleDragDy = 0;

  static const double _collapseAfterDownDy = 28;
  static const double _expandAfterUpDy = 24;
  static const double _collapseFlickVelocity = 600;
  static const double _expandFlickVelocity = -500;

  bool _isCulturalContextLoading = false;
  String? _culturalContextValue;
  String? _culturalContextError;
  String? _culturalContextForText;
  int _culturalContextRequestId = 0;

  String _displayCulturalContext(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Bağlam bulunamadı.';

    final unfenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      multiLine: true,
    ).firstMatch(value)?.group(1)?.trim();
    final candidate = (unfenced ?? value).trim();

    final jsonCandidate =
        RegExp(r'\{[\s\S]*\}').firstMatch(candidate)?.group(0)?.trim() ??
            candidate;

    try {
      final decoded = jsonDecode(jsonCandidate);
      if (decoded is Map<String, dynamic>) {
        final v = decoded['cultural_context'];
        if (v is String && v.trim().isNotEmpty) {
          return v.trim();
        }
      }
    } catch (_) {}

    return candidate;
  }

  @override
  void initState() {
    super.initState();
    _textRecognitionCubit = sl<TextRecognitionCubit>();
    _translateTextUseCase = sl<TranslateTextUseCase>();
    _getCulturalContextUseCase = sl<GetCulturalContextUseCase>();
    _saveHistoryEntryUseCase = sl<SaveHistoryEntryUseCase>();
    _recognizeLiveFrameUseCase = sl<RecognizeLiveFrameUseCase>();
    _initCamera();

    final initialPath = widget.initialImagePath?.trim();
    if (initialPath != null && initialPath.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_beginRecognitionForImage(initialPath));
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Kamera bulunamadı');
        return;
      }

      final camera = cameras.first;
      _mirrorLiveOverlay =
          camera.lensDirection == CameraLensDirection.front;

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      if (widget.initialImagePath == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_startLiveStream());
        });
      }
    } on CameraException catch (e) {
      setState(() => _error = 'Kamera başlatılamadı: ${e.description}');
    }
  }

  @override
  void dispose() {
    unawaited(_stopLiveStream());
    _textRecognitionCubit.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startLiveStream() async {
    if (!_isLiveMode || _capturedImagePath != null) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    _liveTranslationCache.clear();

    try {
      await controller.startImageStream(_onCameraImage);
    } on CameraException catch (e) {
      debugPrint('Canlı kamera akışı başlatılamadı: ${e.description}');
    }
  }

  DeviceOrientation _readDeviceOrientation() {
    final mq = MediaQuery.maybeOrientationOf(context);
    if (mq == Orientation.landscape) {
      return DeviceOrientation.landscapeLeft;
    }
    return DeviceOrientation.portraitUp;
  }

  Size? _liveOverlayImageSize() => _liveOcrImageSize;

  Future<void> _stopLiveStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isStreamingImages) return;
    try {
      await controller.stopImageStream();
    } on CameraException catch (_) {}
  }

  void _onCameraImage(CameraImage image) {
    if (!_isLiveMode || _capturedImagePath != null || _isLiveProcessing) {
      return;
    }

    final now = DateTime.now();
    if (_lastLiveProcessAt != null &&
        now.difference(_lastLiveProcessAt!) <
            const Duration(milliseconds: 1500)) {
      return;
    }
    _lastLiveProcessAt = now;
    unawaited(_processLiveCameraImage(image));
  }

  Future<void> _processLiveCameraImage(CameraImage image) async {
    final controller = _controller;
    if (controller == null || _capturedImagePath != null) return;

    final frame = CameraImageMapper.toLiveFrame(
      image,
      controller.description,
      deviceOrientation: _readDeviceOrientation(),
    );
    if (frame == null) {
      debugPrint(
        'Canlı kare dönüştürülemedi (format: ${image.format.raw}, '
        'planes: ${image.planes.length})',
      );
      return;
    }

    _isLiveProcessing = true;
    try {
      final ocrResult = await _recognizeLiveFrameUseCase(frame);
      if (!mounted || _capturedImagePath != null) return;
      if (!ocrResult.isSuccess || ocrResult.data == null) {
        debugPrint(
          'Canlı OCR hatası: ${ocrResult.failure?.message ?? 'bilinmeyen'}',
        );
        return;
      }

      final items = ocrResult.data!.items;
      if (items.isEmpty) return;

      final limited = items.length > 8 ? items.sublist(0, 8) : items;
      final targetLang = _getDeepLTargetLangCode();
      final translated = await _translateRecognizedItems(
        recognizedItems: limited,
        targetLang: targetLang,
        liveTranslationCache: _liveTranslationCache,
      );

      if (!mounted || _capturedImagePath != null) return;

      setState(() {
        _liveOcrImageSize = OcrViewportMapper.coordinateImageSize(
          bufferWidth: frame.width,
          bufferHeight: frame.height,
          rotationDegrees: frame.rotationDegrees,
        );
        _overlayItems = translated;
      });
    } catch (e, stack) {
      debugPrint('Canlı işleme hatası: $e\n$stack');
    } finally {
      _isLiveProcessing = false;
    }
  }

  void _setResultPanelCollapsed(bool collapsed) {
    if (_isResultPanelCollapsed == collapsed) return;
    setState(() {
      _isResultPanelCollapsed = collapsed;
      _resultPanelHandleDragDy = 0;
      _miniHandleDragDy = 0;
    });
  }

  void _resetResultPanelHandleDrag() => _resultPanelHandleDragDy = 0;
  void _resetMiniHandleDrag() => _miniHandleDragDy = 0;

  bool get _hasSentenceSelection {
    final index = _selectedIndex;
    return index != null && index >= 0 && index < _overlayItems.length;
  }

  void _selectSentence(int index) {
    if (index < 0 || index >= _overlayItems.length) return;
    final item = _overlayItems[index];
    setState(() {
      _selectedIndex = index;
      _isResultPanelCollapsed = false;
    });
    if (_capturedImagePath == null) {
      unawaited(_stopLiveStream());
    }
    unawaited(
      _loadCulturalContext(
        originalText: item.originalText,
        translatedText: item.translatedText,
      ),
    );
  }

  Future<void> _persistHistoryEntry({
    required String originalText,
    required String translatedText,
    String? culturalContext,
  }) async {
    final normalizedContext = culturalContext == null
        ? null
        : _displayCulturalContext(culturalContext);
    final contextToSave = (normalizedContext == null ||
            normalizedContext == 'Bağlam bulunamadı.')
        ? null
        : normalizedContext;

    await _saveHistoryEntryUseCase(
      originalText: originalText,
      translatedText: translatedText,
      culturalContext: contextToSave,
    );
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

  Future<void> _beginRecognitionForImage(
    String imagePath, {
    bool fromCameraCapture = false,
  }) async {
    await _stopLiveStream();
    final bytes = await File(imagePath).readAsBytes();
    final rawSize = await _decodeImageSize(bytes);
    final imageSize = _resolveCapturedImageSize(
      rawSize: rawSize,
      bytes: bytes,
      fromCameraCapture: fromCameraCapture,
    );
    if (!mounted) return;

    setState(() {
      _capturedImagePath = imagePath;
      _capturedImageSize = imageSize;
      _overlayItems = const [];
      _selectedIndex = null;
      _showTranslatedText = true;
      _isCulturalContextLoading = false;
      _culturalContextValue = null;
      _culturalContextError = null;
      _culturalContextForText = null;
      _isResultPanelCollapsed = false;
      _resultPanelHandleDragDy = 0;
      _miniHandleDragDy = 0;
    });

    await _textRecognitionCubit.recognizeTextFromImage(imagePath);
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (_textRecognitionCubit.state.isRecognizing) {
      return;
    }

    try {
      await _stopLiveStream();
      final image = await _controller!.takePicture();
      await _beginRecognitionForImage(
        image.path,
        fromCameraCapture: true,
      );
    } on CameraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görüntü alınamadı: ${e.description}')),
      );
    }
  }

  Future<void> _pickFromGalleryAndRecognize() async {
    if (_textRecognitionCubit.state.isRecognizing) {
      return;
    }

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null) return;

      await _beginRecognitionForImage(picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeriden görüntü seçilemedi: $e')),
      );
    }
  }

  Future<Size> _decodeImageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
  }

  Size _resolveCapturedImageSize({
    required Size rawSize,
    required Uint8List bytes,
    required bool fromCameraCapture,
  }) {
    final exifOrientation = JpegOrientationReader.readOrientation(bytes);
    if (exifOrientation != null) {
      return JpegOrientationReader.orientedSize(rawSize, exifOrientation);
    }

    if (fromCameraCapture && _controller != null) {
      final rotation = CameraImageMapper.rotationDegreesForCamera(
        _controller!.description,
        _readDeviceOrientation(),
      );
      return OcrViewportMapper.coordinateImageSize(
        bufferWidth: rawSize.width.toInt(),
        bufferHeight: rawSize.height.toInt(),
        rotationDegrees: rotation,
      );
    }

    return rawSize;
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
        final correctedSize = _capturedImageSize == null
            ? null
            : OcrViewportMapper.fitImageSizeToOcrItems(
                candidate: _capturedImageSize!,
                rightEdges: recognizedItems.map((item) => item.right),
                bottomEdges: recognizedItems.map((item) => item.bottom),
              );
        setState(() {
          if (correctedSize != null) {
            _capturedImageSize = correctedSize;
          }
          _overlayItems = translatedItems;
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _loadCulturalContext({
    required String originalText,
    required String translatedText,
  }) async {
    final query = originalText.trim();
    final translation = translatedText.trim();
    if (query.isEmpty) return;

    final requestId = ++_culturalContextRequestId;

    if (mounted) {
      setState(() {
        _isCulturalContextLoading = true;
        _culturalContextValue = null;
        _culturalContextError = null;
        _culturalContextForText = query;
      });
    }

    final culturalResult = await _getCulturalContextUseCase(text: query);
    if (!mounted) return;
    if (requestId != _culturalContextRequestId) return;

    if (culturalResult.isSuccess && culturalResult.data != null) {
      final contextValue = culturalResult.data!.value;
      setState(() {
        _isCulturalContextLoading = false;
        _culturalContextValue = contextValue;
        _culturalContextError = null;
      });
      await _persistHistoryEntry(
        originalText: query,
        translatedText: translation.isEmpty ? query : translation,
        culturalContext: contextValue,
      );
      return;
    }

    setState(() {
      _isCulturalContextLoading = false;
      _culturalContextValue = null;
      _culturalContextError =
          culturalResult.failure?.message ?? 'Bilinmeyen hata';
    });

    await _persistHistoryEntry(
      originalText: query,
      translatedText: translation.isEmpty ? query : translation,
    );
  }

  void _showCulturalContextSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          decoration: const BoxDecoration(
            color: Color(0xFF111318),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Kültürel Bağlam',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isCulturalContextLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Bağlam hazırlanıyor…',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                else if (_culturalContextError != null)
                  Text(
                    _culturalContextError!,
                    style: const TextStyle(color: Colors.redAccent),
                  )
                else
                  SelectableText(
                    _displayCulturalContext(_culturalContextValue),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<_OverlayTextItem>> _translateRecognizedItems({
    required List<RecognizedTextItemEntity> recognizedItems,
    required String targetLang,
    Map<String, String>? liveTranslationCache,
  }) async {
    if (recognizedItems.isEmpty) {
      return const [];
    }

    final translatedItems = await Future.wait(
      recognizedItems.map((item) async {
        final original = item.value.trim();
        final cacheKey = '$targetLang:$original';

        if (liveTranslationCache != null) {
          final cached = liveTranslationCache[cacheKey];
          if (cached != null) {
            return _OverlayTextItem(
              originalText: original,
              translatedText: cached,
              left: item.left,
              top: item.top,
              right: item.right,
              bottom: item.bottom,
            );
          }
        }

        final result = await _translateTextUseCase(
          text: original,
          targetLang: targetLang,
        );
        final translatedValue = (result.isSuccess && result.data != null)
            ? result.data!.value
            : original;

        liveTranslationCache?[cacheKey] = translatedValue;

        return _OverlayTextItem(
          originalText: original,
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
          _buildLiveCameraPreview(),
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
                    _liveTranslationCache.clear();
                  });
                },
                onSourceLanguageTap: () {},
                onTargetLanguageTap: () {},
                isPostCapture: _capturedImagePath != null || _hasSentenceSelection,
                overlayShowsTranslation: _showTranslatedText,
                onTapOverlayOriginal: () {
                  setState(() => _showTranslatedText = false);
                },
                onTapOverlayTranslation: () {
                  setState(() => _showTranslatedText = true);
                },
              ),
              const Spacer(),
              if (_capturedImagePath == null && !_hasSentenceSelection) ...[
                if (_isLiveMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentBlue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLiveProcessing)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentBlue,
                              ),
                            )
                          else
                            Icon(
                              Icons.sensors,
                              size: 14,
                              color: AppColors.accentBlue.withValues(alpha: 0.9),
                            ),
                          const SizedBox(width: 8),
                          const Text(
                            'Canlı çeviri aktif',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                CameraBottomBar(
                  onGalleryTap: _pickFromGalleryAndRecognize,
                  onCapture: _captureAndRecognize,
                ),
              ],
              if (_hasSentenceSelection &&
                  !_isResultPanelCollapsed)
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
        if (_hasSentenceSelection &&
            _isResultPanelCollapsed)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _resetMiniHandleDrag();
                  _setResultPanelCollapsed(false);
                },
                onVerticalDragStart: (_) => _resetMiniHandleDrag(),
                onVerticalDragUpdate: (details) {
                  _miniHandleDragDy += details.delta.dy;
                  if (_miniHandleDragDy <= -_expandAfterUpDy) {
                    _resetMiniHandleDrag();
                    _setResultPanelCollapsed(false);
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dy <
                      _expandFlickVelocity) {
                    _setResultPanelCollapsed(false);
                  }
                  _resetMiniHandleDrag();
                },
                onVerticalDragCancel: _resetMiniHandleDrag,
                child: Container(
                  width: 92,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final imageSize = _liveOverlayImageSize();

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller!),
            if (imageSize != null && _overlayItems.isNotEmpty)
              ..._buildOverlayWordWidgets(
                displayRect: OcrViewportMapper.coverRect(
                  imageSize: imageSize,
                  viewportSize: viewportSize,
                ),
                imageSize: imageSize,
                mirrorHorizontal: _mirrorLiveOverlay,
              ),
          ],
        );
      },
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

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: viewportSize.width,
              maxHeight: viewportSize.height,
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: imageSize.width,
                height: imageSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.fill,
                        alignment: Alignment.center,
                      ),
                    ),
                    ..._buildPixelSpaceOverlayWidgets(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPixelSpaceOverlayWidgets() {
    if (_overlayItems.isEmpty) {
      return const [];
    }

    return _overlayItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final width = math.max(1.0, item.right - item.left);
      final height = math.max(1.0, item.bottom - item.top);

      return Positioned(
        left: item.left,
        top: item.top,
        width: width,
        height: height,
        child: _buildOverlayTapTarget(index: index, item: item, width: width, height: height),
      );
    }).toList();
  }

  List<Widget> _buildOverlayWordWidgets({
    required Rect displayRect,
    required Size imageSize,
    bool mirrorHorizontal = false,
  }) {
    if (_overlayItems.isEmpty) {
      return const [];
    }

    return _overlayItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final mapped = OcrViewportMapper.mapBoundingBox(
        left: item.left,
        top: item.top,
        right: item.right,
        bottom: item.bottom,
        imageSize: imageSize,
        displayRect: displayRect,
        mirrorHorizontal: mirrorHorizontal,
      );
      final width = mapped.width < 1 ? 1.0 : mapped.width;
      final height = mapped.height < 1 ? 1.0 : mapped.height;

      return Positioned(
        left: mapped.left,
        top: mapped.top,
        width: width,
        height: height,
        child: _buildOverlayTapTarget(
          index: index,
          item: item,
          width: width,
          height: height,
        ),
      );
    }).toList();
  }

  Widget _buildOverlayTapTarget({
    required int index,
    required _OverlayTextItem item,
    required double width,
    required double height,
  }) {
      final isSelected = _selectedIndex == index;
      final isOriginalMode = !_showTranslatedText;
      final displayText = _showTranslatedText
          ? item.translatedText
          : item.originalText;
      final fittedFontSize = _calculateFittedFontSize(
        text: displayText,
        maxWidth: width,
        maxHeight: height,
      );

      return GestureDetector(
        onTap: () => _selectSentence(index),
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
          child: displayText.trim().isEmpty
              ? const SizedBox.shrink()
              : Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: isOriginalMode ? Colors.white : Colors.black87,
                    fontSize: fittedFontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    shadows: isOriginalMode
                        ? const [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black54,
                            ),
                          ]
                        : null,
                  ),
                ),
        ),
      );
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
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _resetResultPanelHandleDrag(),
              onVerticalDragUpdate: (details) {
                _resultPanelHandleDragDy += details.delta.dy;
                if (_resultPanelHandleDragDy >= _collapseAfterDownDy) {
                  _resetResultPanelHandleDrag();
                  _setResultPanelCollapsed(true);
                }
              },
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy >
                    _collapseFlickVelocity) {
                  _setResultPanelCollapsed(true);
                }
                _resetResultPanelHandleDrag();
              },
              onVerticalDragCancel: _resetResultPanelHandleDrag,
              child: SizedBox(
                width: 120,
                height: 36,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kültürel Bağlam',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isCulturalContextLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: _showCulturalContextSheet,
                  child: const Text('Görüntüle'),
                ),
            ],
          ),
          if (_culturalContextForText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Seçim: ${_culturalContextForText!}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),
          if (_culturalContextError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _culturalContextError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            )
          else if (_culturalContextValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _displayCulturalContext(_culturalContextValue),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            )
          else if (_isCulturalContextLoading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Bağlam hazırlanıyor…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _capturedImagePath = null;
                  _capturedImageSize = null;
                  _overlayItems = const [];
                  _liveOcrImageSize = null;
                  _selectedIndex = null;
                  _isResultPanelCollapsed = false;
                  _isCulturalContextLoading = false;
                  _culturalContextValue = null;
                  _culturalContextError = null;
                  _culturalContextForText = null;
                  _resultPanelHandleDragDy = 0;
                  _miniHandleDragDy = 0;
                  _lastLiveProcessAt = null;
                });
                unawaited(_startLiveStream());
              },
              child: Text(_capturedImagePath != null ? 'Tekrar Çek' : 'Devam Et'),
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
