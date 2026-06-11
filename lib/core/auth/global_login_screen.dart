import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../analytics/analytics_page.dart';
import '../../analytics/api/analytics_login_api.dart';
import '../../engineer/api/api_client.dart' as engineer_api_client;
import '../../engineer/api/engineer_login_api.dart';
import '../../engineer/engineer_page.dart';
import '../../super_admin/api/api_client.dart' as super_admin_api_client;
import '../../super_admin/api/super_admin_login_api.dart';
import '../../super_admin/screens/admin_screen.dart';
import '../../user/api/api_client.dart' as user_api_client;
import '../../user/api/user_login_api.dart';
import '../../user/user_page.dart';
import '../../user_admin/api/api_client.dart' as user_admin_api_client;
import '../../user_admin/api/user_admin_login_api.dart';
import '../../user_admin/user_admin_page.dart';
import '../../vendor/api/api_client.dart' as vendor_api_client;
import '../../vendor/api/vendor_login_api.dart';
import '../../vendor/vendor_page.dart';
import 'app_session.dart';

enum AppLoginRole {
  user,
  userAdmin,
  engineer,
  vendor,
  analytics,
  superAdmin,
}

extension AppLoginRoleX on AppLoginRole {
  String get label {
    switch (this) {
      case AppLoginRole.user:
        return 'User';
      case AppLoginRole.userAdmin:
        return 'User Admin';
      case AppLoginRole.engineer:
        return 'Engineer';
      case AppLoginRole.vendor:
        return 'Vendor';
      case AppLoginRole.analytics:
        return 'Analytics';
      case AppLoginRole.superAdmin:
        return 'Super Admin';
    }
  }

  String get description {
    switch (this) {
      case AppLoginRole.user:
        return 'Monitor sensors, devices, alerts, and live site activity.';
      case AppLoginRole.userAdmin:
        return 'Manage users, organizations, and operational access.';
      case AppLoginRole.engineer:
        return 'Configure devices, sensors, and engineering workflows.';
      case AppLoginRole.vendor:
        return 'Access vendor operations, customers, and support tools.';
      case AppLoginRole.analytics:
        return 'Review analytics dashboards and site performance trends.';
      case AppLoginRole.superAdmin:
        return 'Control platform-wide configuration and administration.';
    }
  }

  String get emailHint {
    switch (this) {
      case AppLoginRole.user:
        return 'user@example.com';
      case AppLoginRole.userAdmin:
        return 'useradmin@example.com';
      case AppLoginRole.engineer:
        return 'engineer@example.com';
      case AppLoginRole.vendor:
        return 'vendor@example.com';
      case AppLoginRole.analytics:
        return 'analytics@example.com';
      case AppLoginRole.superAdmin:
        return 'admin@example.com';
    }
  }

  IconData get icon {
    switch (this) {
      case AppLoginRole.user:
        return Icons.person_outline;
      case AppLoginRole.userAdmin:
        return Icons.admin_panel_settings_outlined;
      case AppLoginRole.engineer:
        return Icons.engineering_outlined;
      case AppLoginRole.vendor:
        return Icons.storefront_outlined;
      case AppLoginRole.analytics:
        return Icons.insights_outlined;
      case AppLoginRole.superAdmin:
        return Icons.security_outlined;
    }
  }

  String get principalKey {
    switch (this) {
      case AppLoginRole.user:
        return 'user_principal_id';
      case AppLoginRole.userAdmin:
        return 'user_admin_principal_id';
      case AppLoginRole.engineer:
        return 'engineer_principal_id';
      case AppLoginRole.vendor:
        return 'vendor_principal_id';
      case AppLoginRole.analytics:
        return 'analytics_principal_id';
      case AppLoginRole.superAdmin:
        return 'super_admin_principal_id';
    }
  }

  String get rememberValue => name;
}

class GlobalLoginScreen extends StatefulWidget {
  final AppLoginRole initialRole;

  const GlobalLoginScreen({
    super.key,
    this.initialRole = AppLoginRole.user,
  });

  @override
  State<GlobalLoginScreen> createState() => _GlobalLoginScreenState();
}

class _GlobalLoginScreenState extends State<GlobalLoginScreen> {
  static const _rememberEmailKey = 'global_login_email';
  static const _rememberRoleKey = 'global_login_role';
  static const _rememberEnabledKey = 'global_login_remember';
  static const _apiEnabledKey = 'global_login_api_enabled';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AppLoginRole _selectedRole;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _useApiAuth = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberEnabledKey) ?? true;
    final useApiAuth = prefs.getBool(_apiEnabledKey) ?? true;
    final rememberedEmail = prefs.getString(_rememberEmailKey) ?? '';
    final rememberedRole = prefs.getString(_rememberRoleKey);
    AppLoginRole? matchedRole;
    for (final role in AppLoginRole.values) {
      if (role.rememberValue == rememberedRole) {
        matchedRole = role;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _rememberMe = rememberMe;
      _useApiAuth = useApiAuth;
      if (rememberMe && rememberedEmail.isNotEmpty) {
        _emailController.text = rememberedEmail;
      }
      if (widget.initialRole == AppLoginRole.user && matchedRole != null) {
        _selectedRole = matchedRole;
      }
    });
  }

  Future<void> _storePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberEnabledKey, _rememberMe);
    await prefs.setBool(_apiEnabledKey, _useApiAuth);
    await prefs.setString(_rememberRoleKey, _selectedRole.rememberValue);

    if (_rememberMe) {
      await prefs.setString(_rememberEmailKey, _emailController.text.trim());
    } else {
      await prefs.remove(_rememberEmailKey);
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _storePreferences();
      if (_useApiAuth) {
        await _loginWithApi();
      } else {
        await _openBypassPage();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithApi() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    switch (_selectedRole) {
      case AppLoginRole.user:
        final response =
            await UserLoginApi.login(email: email, password: password);
        if (response.status.toUpperCase() != 'SUCCESS') {
          throw response.message;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _selectedRole.principalKey, response.body.principalId.trim());
        await user_api_client.ApiClient.setAuthToken(response.body.token);
        await super_admin_api_client.ApiClient.setAuthToken(
            response.body.token);
        await AppSession.saveSession(
          token: response.body.token,
          username: email,
          role: 'user',
        );
        await _pushHome(const UserPage());
        return;
      case AppLoginRole.userAdmin:
        final response =
            await UserAdminLoginApi.login(email: email, password: password);
        if (response.status.toUpperCase() != 'SUCCESS') {
          throw response.message;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _selectedRole.principalKey, response.body.principalId.trim());
        await user_admin_api_client.ApiClient.setAuthToken(response.body.token);
        await AppSession.saveSession(
          token: response.body.token,
          username: email,
          role: 'user_admin',
        );
        await _pushHome(const UserAdminPage());
        return;
      case AppLoginRole.engineer:
        final response =
            await EngineerLoginApi.login(email: email, password: password);
        if (response.status.toUpperCase() != 'SUCCESS') {
          throw response.message;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _selectedRole.principalKey, response.body.principalId.trim());
        await engineer_api_client.ApiClient.setAuthToken(response.body.token);
        await AppSession.saveSession(
          token: response.body.token,
          username: email,
          role: 'engineer',
        );
        await _pushHome(const EngineerPage());
        return;
      case AppLoginRole.vendor:
        final response =
            await VendorLoginApi.login(email: email, password: password);
        if (response.status.toUpperCase() != 'SUCCESS') {
          throw response.message;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _selectedRole.principalKey, response.body.principalId.trim());
        await vendor_api_client.ApiClient.setAuthToken(response.body.token);
        await super_admin_api_client.ApiClient.setAuthToken(
            response.body.token);
        await AppSession.saveSession(
          token: response.body.token,
          username: email,
          role: 'vendor',
        );
        await _pushHome(const VendorPage());
        return;
      case AppLoginRole.analytics:
        if (email == 'analytics' && password == '123456') {
          try {
            final response =
                await AnalyticsLoginApi.login(email: email, password: password);
            if (response.status.toUpperCase() == 'SUCCESS') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                  _selectedRole.principalKey, response.body.principalId.trim());
              await super_admin_api_client.ApiClient.setAuthToken(
                  response.body.token);
              await AppSession.saveSession(
                token: response.body.token,
                username: email,
                role: 'analytics',
              );
            }
          } catch (_) {
            await AppSession.saveSession(
              token: 'hardcoded_analytics_token',
              username: email,
              role: 'analytics',
            );
          }
          await _pushHome(const AnalyticsPage());
          return;
        }

        final response =
            await AnalyticsLoginApi.login(email: email, password: password);
        if (response.status.toUpperCase() != 'SUCCESS') {
          throw response.message;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _selectedRole.principalKey, response.body.principalId.trim());
        await super_admin_api_client.ApiClient.setAuthToken(
            response.body.token);
        await AppSession.saveSession(
          token: response.body.token,
          username: email,
          role: 'analytics',
        );
        await _pushHome(const AnalyticsPage());
        return;
      case AppLoginRole.superAdmin:
        final response =
            await SuperAdminLoginApi.login(email: email, password: password);
        if (response.status.toUpperCase() != 'SUCCESS') {
          throw response.message;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _selectedRole.principalKey, response.body.principalId.trim());
        await super_admin_api_client.ApiClient.setAuthToken(
            response.body.token);
        await AppSession.saveSession(
          token: response.body.token,
          username: email,
          role: 'super_admin',
        );
        await _pushHome(const AdminScreen());
        return;
    }
  }

  Future<void> _openBypassPage() async {
    switch (_selectedRole) {
      case AppLoginRole.user:
        await _pushHome(const UserPage());
        return;
      case AppLoginRole.userAdmin:
        await _pushHome(const UserAdminPage());
        return;
      case AppLoginRole.engineer:
        await _pushHome(const EngineerPage());
        return;
      case AppLoginRole.vendor:
        await _pushHome(const VendorPage());
        return;
      case AppLoginRole.analytics:
        await _pushHome(const AnalyticsPage());
        return;
      case AppLoginRole.superAdmin:
        await _pushHome(const AdminScreen());
        return;
    }
  }

  Future<void> _pushHome(Widget page) async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FC), Color(0xFFEEF2F8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(48),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 45,
                        offset: const Offset(0, 30),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isWide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  flex: 12, child: _buildBrandPanel(context)),
                              Expanded(
                                flex: 10,
                                child:
                                    _buildFormPanel(context, isMobile: false),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildFormPanel(context, isMobile: true),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              Icon(
                Icons.construction,
                color: Color(0xFFF5A623),
                size: 32,
              ),
              SizedBox(width: 8),
              Text(
                'Wow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Guardian',
                style: TextStyle(
                  color: Color(0xFFF5A623),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'WELCOME AGAIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Monitor your site in real-time and prevent risks before they happen. Reduce incidents, ensure compliance, and protect your workforce with smart sensor technology.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          const _FeatureRow(
            icon: Icons.show_chart,
            text: 'Real-time sensor analytics',
          ),
          const _FeatureRow(
            icon: Icons.shield_outlined,
            text: 'Enterprise-grade security',
          ),
          const _FeatureRow(
            icon: Icons.notifications_outlined,
            text: 'Instant safety alerts',
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: isMobile ? 52 : 60,
                  height: isMobile ? 52 : 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A1A), Color(0xFFF5A623)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.construction,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Login',
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access your dashboard to monitor construction sites',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: _selectedRole.emailHint,
                    prefixIcon: const Icon(Icons.person_outline,
                        color: Color(0xFFF5A623)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFE8EAED), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFE8EAED), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFF5A623), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFFF5A623)),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFE8EAED), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFE8EAED), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFF5A623), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login as',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<AppLoginRole>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      _selectedRole.icon,
                      color: const Color(0xFFF5A623),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFE8EAED), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFE8EAED), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48),
                      borderSide: const BorderSide(
                          color: Color(0xFFF5A623), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  items: AppLoginRole.values
                      .map(
                        (role) => DropdownMenuItem<AppLoginRole>(
                          value: role,
                          child: Text(role.label),
                        ),
                      )
                      .toList(),
                  onChanged: (role) {
                    if (role == null) return;
                    setState(() => _selectedRole = role);
                  },
                ),
                const SizedBox(height: 24),
                if (!isMobile) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                              activeColor: const Color(0xFFF5A623),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Password reset link sent to your email'),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF5A623),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Forgot your password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ] else
                  const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: const Color(0xFF0A0A0A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(48),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0A0A0A)),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login, size: 20),
                              const SizedBox(width: 10),
                              Text(_isLoading ? 'Signing in...' : 'Log in'),
                            ],
                          ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 28),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have any account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                        TextButton(
                          onPressed: () => AppSession.logoutToLanding(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF5A623),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF5A623), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
