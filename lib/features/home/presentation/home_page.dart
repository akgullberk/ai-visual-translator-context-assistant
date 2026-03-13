import 'package:flutter/material.dart';
import 'package:bitirme_projesi/features/home/presentation/widgets/home_header.dart';
import 'package:bitirme_projesi/features/home/presentation/widgets/quick_actions.dart';
import 'package:bitirme_projesi/features/home/presentation/widgets/scan_translate_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(),
            SizedBox(height: 16),
            ScanTranslateCard(),
            SizedBox(height: 24),
            QuickActions(),
          ],
        ),
      ),
    );
  }
}
