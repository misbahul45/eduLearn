import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/social_button.dart';
import 'providers/auth_notifier.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (prev, next) {
      if (next.stage == AuthFormStage.success && next.authStatus?.isAuthenticated == true) {
        context.goNamed(AppRoutes.home);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const Text('Create Account', style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Start your learning journey',
                  style: AppTextStyles.subtitle,
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Nama wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email wajib diisi';
                    if (!val.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password wajib diisi';
                    if (val.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Konfirmasi password';
                    if (val != _passwordController.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: 'Create Account',
                  isLoading: authState.stage == AuthFormStage.loading,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(authNotifierProvider.notifier).register(
                        _nameController.text.trim(),
                        _emailController.text.trim(),
                        _passwordController.text,
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('or continue with', style: AppTextStyles.caption),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SocialButton(
                  text: 'Continue with Google',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google sign-in coming soon')),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTextStyles.body),
                      TextButton(
                        onPressed: () => context.goNamed(AppRoutes.login),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
