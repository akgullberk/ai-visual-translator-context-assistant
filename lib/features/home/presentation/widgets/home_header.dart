import 'package:flutter/material.dart';
import 'package:bitirme_projesi/common/helper/navigator/app_navigator.dart';
import 'package:bitirme_projesi/core/configs/theme/app_colors.dart';
import 'package:bitirme_projesi/features/history/presentation/history_page.dart';

String _greetingForTimeOfDay() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'Günaydın 👋';
  }
  if (hour >= 12 && hour < 18) {
    return 'İyi günler 👋';
  }
  return 'İyi akşamlar 👋';
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingForTimeOfDay(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Visual Translator',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.history_rounded,
                onPressed: () {
                  AppNavigator.push(context, const HistoryPage());
                },
              ),
              const SizedBox(width: 10),
              _HeaderIconButton(
                icon: Icons.settings_outlined,

                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.textPrimary, size: 23),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
