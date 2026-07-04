import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'providers/splash_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    debugPrint('[Splash] Starting auth check...');
    
    try {
      final stage = await ref.read(splashProvider.notifier).check();
      debugPrint('[Splash] Stage result: $stage');
      
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (stage == SplashStage.authenticated) {
        context.goNamed(AppRoutes.homeTab);
      } else {
        context.goNamed(AppRoutes.login);
      }
    } catch (e, st) {
      debugPrint('[Splash] ERROR: $e');
      debugPrint('[Splash] STACK: $st');
      if (mounted) context.goNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_toy_rounded,
                size: 96,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('EduLearn AI', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Smart Academic Learning Assistant',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
