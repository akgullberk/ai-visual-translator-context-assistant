import 'package:flutter/material.dart';
import 'package:bitirme_projesi/core/configs/theme/app_colors.dart';

class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.isFlashOn,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onBack,
    required this.onFlashToggle,
    required this.onSwapLanguages,
    required this.onSourceLanguageTap,
    required this.onTargetLanguageTap,
    this.isPostCapture = false,
    this.overlayShowsTranslation = true,
    this.onTapOverlayOriginal,
    this.onTapOverlayTranslation,
  });

  final bool isFlashOn;
  final String sourceLanguage;
  final String targetLanguage;
  final VoidCallback onBack;
  final VoidCallback onFlashToggle;
  final VoidCallback onSwapLanguages;
  final VoidCallback onSourceLanguageTap;
  final VoidCallback onTargetLanguageTap;

  /// Foto çekildikten sonra dil şeridinde Orijinal / Türkçe (çeviri) seçimi.
  final bool isPostCapture;
  final bool overlayShowsTranslation;
  final VoidCallback? onTapOverlayOriginal;
  final VoidCallback? onTapOverlayTranslation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
              const Spacer(),
              IconButton(
                onPressed: onFlashToggle,
                icon: Icon(
                  isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: isFlashOn ? Colors.amber : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _buildLanguageSelector(),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: isPostCapture ? _buildPostCaptureRow() : _buildPreCaptureRow(),
    );
  }

  Widget _buildPreCaptureRow() {
    return Row(
      children: [
        Expanded(
          child: _LanguageChip(
            label: sourceLanguage,
            onTap: onSourceLanguageTap,
          ),
        ),
        GestureDetector(
          onTap: onSwapLanguages,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentBlue.withValues(alpha: 0.8),
                  AppColors.accentPurple.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: const Icon(
              Icons.swap_horiz,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        Expanded(
          child: _LanguageChip(
            label: targetLanguage,
            onTap: onTargetLanguageTap,
          ),
        ),
      ],
    );
  }

  Widget _buildPostCaptureRow() {
    return Row(
      children: [
        Expanded(
          child: _OverlayModeChip(
            label: 'Orijinal',
            selected: !overlayShowsTranslation,
            onTap: onTapOverlayOriginal ?? () {},
          ),
        ),
        const SizedBox(width: 36, height: 36),
        Expanded(
          child: _OverlayModeChip(
            label: 'Türkçe',
            selected: overlayShowsTranslation,
            onTap: onTapOverlayTranslation ?? () {},
          ),
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OverlayModeChip extends StatelessWidget {
  const _OverlayModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentBlue.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.accentBlue.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
