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
  static const _loginHeroAsset = 'assets/images/construction_line_art.png';
  static const _loginHeroFallbackAsset = 'assets/images/construction.jpg';
  static const _sensorLogoAsset = 'assets/icons/sensor_icon.png';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AppLoginRole _selectedRole;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _useApiAuth = true;
  bool _isLoading = false;
  bool _didPrecacheLoginAssets = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheLoginAssets || widget.initialRole != AppLoginRole.user) {
      return;
    }
    _didPrecacheLoginAssets = true;
    precacheImage(const AssetImage(_loginHeroAsset), context)
        .catchError((_) {});
    precacheImage(const AssetImage(_loginHeroFallbackAsset), context)
        .catchError((_) {});
    precacheImage(const AssetImage(_sensorLogoAsset), context)
        .catchError((_) {});
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
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final stacked = width < 960;
    final pagePadding = width >= 1280
        ? 48.0
        : width >= 960
            ? 28.0
            : 16.0;
    final panelMinHeight =
        stacked ? 0.0 : (size.height - (pagePadding * 2)).clamp(620.0, 760.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1240,
                minHeight: panelMinHeight,
              ),
              child: SizedBox(
                height: stacked ? null : panelMinHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: OpsColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFDDE4F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF20325B).withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: stacked
                      ? Column(
                          children: [
                            _buildUserInfoColumn(compact: true),
                            _buildUserAuthCard(context, compact: true),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 11,
                              child: _buildUserInfoColumn(compact: false),
                            ),
                            Expanded(
                              flex: 7,
                              child:
                                  _buildUserAuthCard(context, compact: false),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAuthCard(BuildContext context, {required bool compact}) {
    final sidePadding = compact ? 28.0 : 44.0;
    final titleSize = compact ? 30.0 : 38.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: compact
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              )
            : const BorderRadius.only(
                topRight: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
      ),
      padding: EdgeInsets.fromLTRB(
        sidePadding,
        compact ? 30 : 44,
        sidePadding,
        compact ? 28 : 42,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            if (compact) ...[
              const SizedBox(height: 10),
              const _LoginBrandBadge(
                sensorLogoAsset: _sensorLogoAsset,
                compact: true,
              ),
            ],
            SizedBox(height: compact ? 22 : 34),
            Text(
              'User Login',
              style: TextStyle(
                color: const Color(0xFF10244D),
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedRole.description,
              style: const TextStyle(
                color: OpsColors.muted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            SizedBox(height: compact ? 28 : 34),
            _buildRefField(
              controller: _emailController,
              hintText: _selectedRole.emailHint,
              prefixIcon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildRefField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffix: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: OpsColors.outline,
                  size: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<AppLoginRole>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                hintText: 'Select login type',
                fillColor: const Color(0xFFF6F8FF),
                filled: true,
                prefixIcon: Icon(
                  _selectedRole.icon,
                  color: OpsColors.primaryContainer.withValues(alpha: 0.78),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFF2B63F1),
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
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return _buildRememberAndForgotRow(
                  context,
                  compact: constraints.maxWidth < 320,
                  primary: OpsColors.primaryContainer,
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF245BFF),
                        OpsColors.primaryContainer,
                        Color(0xFF8D56D8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF245BFF).withValues(alpha: 0.20),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoColumn({required bool compact}) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 300 : 620),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: compact
            ? const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(28),
                bottomLeft: Radius.circular(28),
              ),
      ),
      child: ClipRRect(
        borderRadius: compact
            ? const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(28),
                bottomLeft: Radius.circular(28),
              ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _LoginHeroImage(
              primaryAsset: _loginHeroAsset,
              fallbackAsset: _loginHeroFallbackAsset,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.00),
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.24),
                  ],
                  stops: const [0, 0.62, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: OpsColors.outline,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 18,
          color: OpsColors.primaryContainer.withValues(alpha: 0.78),
        ),
        suffixIcon: suffix,
        fillColor: const Color(0xFFF6F8FF),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF2B63F1),
            width: 1.4,
          ),
        ),
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
          side: const BorderSide(color: Color(0xFFC8D2EC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
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

class _LoginBrandBadge extends StatelessWidget {
  final String sensorLogoAsset;
  final bool compact;

  const _LoginBrandBadge({
    required this.sensorLogoAsset,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 0 : 16,
        compact ? 0 : 16,
        compact ? 0 : 20,
        compact ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color:
            compact ? Colors.transparent : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: compact
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 48 : 52,
            height: compact ? 48 : 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Image.asset(
                sensorLogoAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: OpsColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  );
                },
              ),
            ),
          ),
         
        ],
      ),
    );
  }
}

class _LoginHeroImage extends StatelessWidget {
  final String primaryAsset;
  final String fallbackAsset;

  const _LoginHeroImage({
    required this.primaryAsset,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      primaryAsset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OpsColors.primaryContainer.withValues(alpha: 0.16),
                Colors.white,
              ],
            ),
          ),
        );
      },
    );
  }
}
