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
  });

  final bool isFlashOn;
  final String sourceLanguage;
  final String targetLanguage;
  final VoidCallback onBack;
  final VoidCallback onFlashToggle;
  final VoidCallback onSwapLanguages;
  final VoidCallback onSourceLanguageTap;
  final VoidCallback onTargetLanguageTap;

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
      child: Row(
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
      ),
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
