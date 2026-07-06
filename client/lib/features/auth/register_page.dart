import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'providers/register_viewmodel.dart';

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
  final _confirmController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final _hasLetter = RegExp(r'[a-zA-Z]');
  static final _hasDigit = RegExp(r'[0-9]');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    ref.read(registerViewModelProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerViewModelProvider);

    ref.listen(registerViewModelProvider, (prev, next) {
      if (next.stage == RegisterStage.success) {
        context.goNamed(AppRoutes.chatTab);
      } else if (next.stage == RegisterStage.error && next.error != null) {
        final isDuplicateEmail = next.error == 'Email sudah terdaftar';

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                isDuplicateEmail
                    ? 'Email sudah terdaftar, silakan masuk'
                    : next.error!,
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              action: isDuplicateEmail
                  ? SnackBarAction(
                      label: 'Ke halaman login',
                      onPressed: () => context.goNamed(AppRoutes.login),
                    )
                  : next.error == 'Tidak ada koneksi internet'
                      ? SnackBarAction(
                          label: 'Coba lagi',
                          onPressed: _submit,
                        )
                      : null,
            ),
          );

        ref.read(registerViewModelProvider.notifier).reset();
      }
    });

    final isLoading = registerState.stage == RegisterStage.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Icon(
                Icons.person_add_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Buat Akun Baru',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Daftar untuk mulai belajar dengan AI',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Nama Lengkap',
                      hint: 'Budi Santoso',
                      controller: _nameController,
                      focusNode: _nameFocus,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _emailFocus.requestFocus(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Nama wajib diisi';
                        if (val.trim().length < 3) return 'Minimal 3 karakter';
                        if (val.trim().length > 50) return 'Maksimal 50 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Email',
                      hint: 'nama@email.com',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _passwordFocus.requestFocus(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                        if (!_emailRegex.hasMatch(val.trim())) return 'Email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Password',
                      hint: 'min. 8 karakter',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _confirmFocus.requestFocus(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Password wajib diisi';
                        if (val.length < 8) return 'Minimal 8 karakter';
                        if (!_hasLetter.hasMatch(val)) return 'Harus mengandung minimal 1 huruf';
                        if (!_hasDigit.hasMatch(val)) return 'Harus mengandung minimal 1 angka';
                        return null;
                      },
                      onChanged: (_) {
                        // Re-validate confirm field when password changes
                        if (_confirmController.text.isNotEmpty) {
                          _formKey.currentState?.validate();
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Konfirmasi Password',
                      hint: 'ulangi password',
                      controller: _confirmController,
                      focusNode: _confirmFocus,
                      obscureText: _obscureConfirm,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: isLoading ? null : _submit,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Konfirmasi password wajib diisi';
                        if (val != _passwordController.text) return 'Password tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: 'Daftar',
                isLoading: isLoading,
                onPressed: _submit,
              ),
              // const SizedBox(height: AppSpacing.sm),
              // Row(
              //   children: [
              //     const Expanded(child: Divider()),
              //     Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              //       child: Text('atau', style: AppTextStyles.caption),
              //     ),
              //     const Expanded(child: Divider()),
              //   ],
              // ),
              // const SizedBox(height: AppSpacing.lg),
              // SocialButton(
              //   text: 'Daftar dengan Google',
              //   onPressed: () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Google sign-in coming soon')),
              //     );
              //   },
              // ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? '),
                    TextButton(
                      onPressed: () => context.goNamed(AppRoutes.login),
                      child: const Text('Masuk', style: AppTextStyles.link),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
