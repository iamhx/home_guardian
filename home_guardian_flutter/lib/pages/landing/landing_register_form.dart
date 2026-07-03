import 'package:flutter/material.dart';
import 'package:home_guardian/pages/dashboard/dashboard_page.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/shared_widgets.dart';
import 'landing_helpers.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: buildAppInputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: validateUsername,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: buildAppInputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icons.email_outlined,
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: authProvider.obscureRegisterPassword,
                  decoration: buildAppInputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        authProvider.obscureRegisterPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: authProvider.toggleRegisterPasswordVisibility,
                    ),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: authProvider.obscureConfirmPassword,
                  decoration: buildAppInputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        authProvider.obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: authProvider.toggleConfirmPasswordVisibility,
                    ),
                  ),
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
                LoadingButton(
                  isLoading: authProvider.isLoading,
                  onPressed: () => _handleRegister(authProvider),
                  label: 'Create Account',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleRegister(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      try {
        await authProvider.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          showSuccessSnackbar(context, 'Account created successfully!');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              buildSlidePageRoute(const DashboardPage()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackbar(context, 'Registration failed: $e');
        }
      }
    }
  }
}
