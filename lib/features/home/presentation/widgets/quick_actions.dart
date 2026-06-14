import 'package:flutter/material.dart';
import 'package:bitirme_projesi/common/helper/navigator/app_navigator.dart';
import 'package:bitirme_projesi/core/configs/theme/app_colors.dart';
import 'package:bitirme_projesi/features/history/presentation/history_page.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/camera_screen.dart';
import 'package:image_picker/image_picker.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static Future<void> _openGalleryAndRecognize(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (!context.mounted || picked == null) return;

      AppNavigator.push(
        context,
        CameraScreen(initialImagePath: picked.path),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeriden görüntü seçilemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HIZLI İŞLEMLER',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) => _ActionCard(
                    icon: Icons.camera_alt_outlined,
                    label: 'Kamera',
                    color: AppColors.accentBlue,
                    onTap: () {
                      AppNavigator.push(context, const CameraScreen());
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) => _ActionCard(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    color: AppColors.accentBlue,
                    onTap: () => _openGalleryAndRecognize(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) => _ActionCard(
                    icon: Icons.history_rounded,
                    label: 'Geçmiş',
                    color: AppColors.accentPurple,
                    onTap: () {
                      AppNavigator.push(context, const HistoryPage());
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
