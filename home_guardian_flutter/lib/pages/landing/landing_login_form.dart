import 'package:flutter/material.dart';
import 'package:home_guardian/pages/dashboard/dashboard_page.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/shared_widgets.dart';
import 'forgot_password_page.dart';
import 'landing_helpers.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  obscureText: authProvider.obscureLoginPassword,
                  decoration: buildAppInputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        authProvider.obscureLoginPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: authProvider.toggleLoginPasswordVisibility,
                    ),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  isLoading: authProvider.isLoading,
                  onPressed: () => _handleLogin(authProvider),
                  label: 'Login',
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      buildSlidePageRoute(const ForgotPasswordPage()),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: kPrimaryBlue),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLogin(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      try {
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          showSuccessSnackbar(context, 'Login successful!');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              buildSlidePageRoute(const DashboardPage()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackbar(context, 'Login failed: $e');
        }
      }
    }
  }
}
