import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Show side panel only on screens wider than 1024px
    final isWideScreen = screenWidth > 1024;
    // Medium screens (768-1024px) get smaller side panel
    final isMediumScreen = screenWidth > 768 && screenWidth <= 1024;

    return Scaffold(
      body: Row(
        children: [
          // Left side - Branding (only on wide/medium screens)
          if (isWideScreen || isMediumScreen)
            Expanded(
              flex: isWideScreen ? 2 : 1, // Smaller on medium screens
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isWideScreen ? 80 : 60,
                          height: isWideScreen ? 80 : 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.edit_note,
                            size: isWideScreen ? 40 : 30,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'SellScribe',
                          style: TextStyle(
                            fontSize: isWideScreen ? 32 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (isWideScreen) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Start creating amazing\nproduct listings today',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Feature list
                          _buildFeatureItem(Icons.auto_awesome, '5 free generations'),
                          const SizedBox(height: 12),
                          _buildFeatureItem(Icons.speed, 'Instant AI-powered copy'),
                          const SizedBox(height: 12),
                          _buildFeatureItem(Icons.shopping_cart, 'Shopify optimized'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Right side - Register form
          Expanded(
            flex: isWideScreen ? 3 : (isMediumScreen ? 2 : 1), // Form gets more space
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Show logo only on narrow screens (no side panel)
                        if (!isWideScreen && !isMediumScreen) ...[
                          const Icon(
                            Icons.edit_note,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Create an account',
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: (isWideScreen || isMediumScreen) ? TextAlign.left : TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get 5 free listing generations',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: (isWideScreen || isMediumScreen) ? TextAlign.left : TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Error message
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.errorMessage != null) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppTheme.errorColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        auth.errorMessage!,
                                        style: const TextStyle(
                                          color: AppTheme.errorColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => auth.clearError(),
                                      color: AppTheme.errorColor,
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        
                        AppTextField(
                          label: 'Name',
                          hint: 'Enter your name',
                          semanticsLabel: 'name-input',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          semanticsLabel: 'email-input',
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Password',
                          hint: 'Create a password',
                          semanticsLabel: 'password-create-input',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          semanticsLabel: 'password-confirm-input',
                          controller: _confirmPasswordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return AppButton(
                              text: 'Create Account',
                              semanticsLabel: 'create-account-button',
                              onPressed: _handleRegister,
                              isLoading: auth.status == AuthStatus.loading,
                              fullWidth: true,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            Semantics(
                              label: 'sign-in-link',
                              child: TextButton(
                                onPressed: () => context.go(AppRoutes.login),
                                child: const Text('Sign in'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
