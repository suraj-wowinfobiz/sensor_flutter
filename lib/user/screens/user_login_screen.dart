import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../super_admin/api/api_client.dart';
import '../api/api_client.dart' as user_api_client;
import '../api/user_login_api.dart';
import '../user_page.dart';
import '../providers/user_riverpod_provider.dart';

class UserLoginScreen extends ConsumerStatefulWidget {
  const UserLoginScreen({super.key});

  @override
  ConsumerState<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends ConsumerState<UserLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    ref.read(userLoginLoadingStateProvider.notifier).state = true;

    try {
      final response = await UserLoginApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      if (response.status.toUpperCase() == 'SUCCESS') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_principal_id',
          response.body.principalId.trim(),
        );
        await user_api_client.ApiClient.setAuthToken(response.body.token);
        await ApiClient.setAuthToken(response.body.token);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) {
        ref.read(userLoginLoadingStateProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userLoginLoadingStateProvider);
    final obscurePassword = ref.watch(userLoginObscurePasswordStateProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor =
        isLight ? const Color(0xFF1A2B3C) : const Color(0xFFD7E8F6);
    final subColor =
        isLight ? const Color(0xFF5F7285) : const Color(0xFF9DB7D2);
    final labelColor =
        isLight ? const Color(0xFF2D3E50) : const Color(0xFFD7E8F6);
    final inputFill =
        isLight ? const Color(0xFFF8FAFB) : const Color(0xFF1E3A52);
    final borderColor = Theme.of(context).dividerColor;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to your account',
                  style: TextStyle(
                    fontSize: 18,
                    color: subColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'user@example.com',
                    hintStyle: TextStyle(color: subColor, fontSize: 16),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(
                        color: subColor, fontSize: 20, letterSpacing: 2),
                    filled: true,
                    fillColor: inputFill,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: subColor,
                      ),
                      onPressed: () => ref
                          .read(userLoginObscurePasswordStateProvider.notifier)
                          .state = !obscurePassword,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
