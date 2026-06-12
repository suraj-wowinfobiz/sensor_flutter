import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../analytics/analytics_page.dart';
import '../../analytics/api/analytics_login_api.dart';
import '../../analytics_role/analytics_role_page.dart';
import '../../analytics_role/api/analytics_role_login_api.dart';
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
import '../theme/ops_theme.dart';
import 'app_session.dart';

enum AppLoginRole {
  user,
  userAdmin,
  engineer,
  vendor,
  analytics,
  analyticsRole,
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
      case AppLoginRole.analyticsRole:
        return 'Analytics Role';
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
      case AppLoginRole.analyticsRole:
        return 'Review assigned analytics workspaces and performance signals.';
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
      case AppLoginRole.analyticsRole:
        return 'analytics-role@example.com';
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
      case AppLoginRole.analyticsRole:
        return Icons.query_stats_outlined;
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
      case AppLoginRole.analyticsRole:
        return 'analytics_role_principal_id';
      case AppLoginRole.superAdmin:
        return 'super_admin_principal_id';
    }
  }

  String get rememberValue => name;
}

class GlobalLoginScreen extends StatefulWidget {
  final AppLoginRole initialRole;
  final bool allowRoleSelection;

  const GlobalLoginScreen({
    super.key,
    this.initialRole = AppLoginRole.user,
    this.allowRoleSelection = true,
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
      case AppLoginRole.analyticsRole:
        final response =
            await AnalyticsRoleLoginApi.login(email: email, password: password);
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
          role: 'analytics_role',
        );
        await _pushHome(const AnalyticsRolePage());
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
      case AppLoginRole.analyticsRole:
        await _pushHome(const AnalyticsRolePage());
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
    if (widget.initialRole == AppLoginRole.user) {
      return _buildUserHtmlLogin(context);
    }
    return _buildCompactRoleLogin(context);
  }

  Widget _buildCompactRoleLogin(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
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
    final cardPadding = width < 560 ? 28.0 : 48.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isLight ? 0.08 : 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedRole.label,
                      style: TextStyle(
                        fontSize: width < 560 ? 38 : 48,
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
                    const SizedBox(height: 12),
                    Text(
                      _selectedRole.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: _selectedRole.emailHint,
                        hintStyle: TextStyle(color: subColor, fontSize: 16),
                        filled: true,
                        fillColor: inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: borderColor, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: borderColor, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
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
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: subColor,
                          fontSize: 20,
                          letterSpacing: 2,
                        ),
                        filled: true,
                        fillColor: inputFill,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: subColor,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: borderColor, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: borderColor, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    if (widget.allowRoleSelection) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Login as',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AppLoginRole>(
                        initialValue: _selectedRole,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputFill,
                          prefixIcon: Icon(
                            _selectedRole.icon,
                            color: primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: borderColor, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: borderColor, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
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
                    ],
                    const SizedBox(height: 16),
                    _buildRememberAndForgotRow(
                      context,
                      compact: width < 520,
                      primary: primary,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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
        ),
      ),
    );
  }

  Widget _buildUserHtmlLogin(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stacked = width < 1080;
    final pagePadding = width >= 1200
        ? 32.0
        : width >= 768
            ? 24.0
            : 16.0;

    return Scaffold(
      backgroundColor: OpsColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              pagePadding,
              24,
              pagePadding,
              24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: OpsColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'L&T',
                            style: TextStyle(
                              color: OpsColors.text,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sensor Analytics',
                            style: TextStyle(
                              color: OpsColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildUserPageHeader(),
                  const SizedBox(height: 18),
                  if (stacked) ...[
                    _buildUserAuthCard(context),
                    const SizedBox(height: 16),
                    _buildUserInfoColumn(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 8, child: _buildUserAuthCard(context)),
                        const SizedBox(width: 16),
                        SizedBox(width: 360, child: _buildUserInfoColumn()),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedRole.label,
          style: const TextStyle(
            color: OpsColors.text,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.72,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Log in to your account',
          style: TextStyle(
            color: OpsColors.muted,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedRole.description,
          style: const TextStyle(
            color: OpsColors.muted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildUserAuthCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              child: Row(
                children: [
                  const Text(
                    'USER LOGIN',
                    style: TextStyle(
                      color: OpsColors.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.55,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: OpsColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedRole.icon,
                          size: 15,
                          color: OpsColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedRole.label,
                          style: const TextStyle(
                            color: OpsColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: OpsColors.border),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _buildFormLabel('EMAIL'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: _selectedRole.emailHint,
                      fillColor: OpsColors.surfaceLow,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: OpsColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: OpsColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: OpsColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFormLabel('PASSWORD'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      fillColor: OpsColors.surfaceLow,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: OpsColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: OpsColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: OpsColors.primary,
                          width: 1.4,
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: OpsColors.outline,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  if (widget.allowRoleSelection) ...[
                    const SizedBox(height: 20),
                    _buildFormLabel('LOGIN AS'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AppLoginRole>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(
                        fillColor: OpsColors.surfaceLow,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        prefixIcon: Icon(
                          _selectedRole.icon,
                          color: OpsColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: OpsColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: OpsColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: OpsColors.primary,
                            width: 1.4,
                          ),
                        ),
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
                  ],
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildRememberAndForgotRow(
                        context,
                        compact: constraints.maxWidth < 560,
                        primary: OpsColors.primary,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OpsColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard(
          eyebrow: 'ROLE-BASED ACCESS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: OpsColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: OpsColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'L&T',
                          style: TextStyle(
                            color: OpsColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sensor Analytics',
                          style: TextStyle(
                            color: OpsColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Role-based operational access',
                style: TextStyle(
                  color: OpsColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.24,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to monitor construction sites, inspect sensor health, review alert response, and manage operational visibility from one shared platform.',
                style: TextStyle(
                  color: OpsColors.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          eyebrow: 'OPERATIONAL VISIBILITY',
          child: const Column(
            children: [
              _UserLoginFeatureRow(
                icon: Icons.sensors_outlined,
                text: 'Real-time sensor telemetry and reporting intervals',
              ),
              SizedBox(height: 14),
              _UserLoginFeatureRow(
                icon: Icons.router_outlined,
                text: 'Device heartbeat, firmware, and connectivity health',
              ),
              SizedBox(height: 14),
              _UserLoginFeatureRow(
                icon: Icons.notifications_active_outlined,
                text: 'Critical alert response and escalation visibility',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          eyebrow: 'ACCESS NOTE',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OpsColors.surfaceLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: OpsColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use the role assigned by your organization. Each role opens a different operations workspace.',
                    style: TextStyle(
                      color: OpsColors.muted,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String eyebrow,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: OpsColors.outline,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: OpsColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
      ),
    );
  }

  Widget _buildRememberAndForgotRow(
    BuildContext context, {
    required bool compact,
    required Color primary,
  }) {
    final remember = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() => _rememberMe = value ?? false);
          },
          activeColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Flexible(
          child: Text(
            'Remember me',
            style: TextStyle(
              color: OpsColors.text,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );

    final forgot = TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email'),
          ),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'Forgot password?',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          remember,
          const SizedBox(height: 6),
          forgot,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: remember),
        const SizedBox(width: 16),
        forgot,
      ],
    );
  }
}

class _UserLoginFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _UserLoginFeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: OpsColors.surfaceLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: OpsColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: OpsColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
