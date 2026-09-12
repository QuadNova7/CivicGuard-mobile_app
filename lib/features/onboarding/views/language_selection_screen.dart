import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../models/language_model.dart';
import 'widgets/language_card.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedCode = 'en';

  final List<LanguageModel> _languages = const [
    LanguageModel(code: 'si', nativeName: 'සිංහල', englishName: 'Sinhala', flagEmoji: '🇱🇰'),
    LanguageModel(code: 'en', nativeName: 'English', englishName: 'English', flagEmoji: '🇬🇧'),
    LanguageModel(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil', flagEmoji: '🇮🇳'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Step Progress Indicator
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text('Welcome!', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Choose your preferred language\nSelect a language to continue',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 36),

              // Language List Cards
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    return LanguageCard(
                      language: lang,
                      isSelected: _selectedCode == lang.code,
                      onTap: () => setState(() => _selectedCode = lang.code),
                    );
                  },
                ),
              ),

              // Continue Button
              AppButton(
                text: 'Continue',
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  context.go('/main');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
