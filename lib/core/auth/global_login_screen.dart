import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/pages/platform_shell_page.dart';
import '../../common/platform/api/api_client.dart';
import '../../common/platform/core/api/auth_api.dart';
import '../theme/ops_theme.dart';
import '../widgets/route_aware_asset_video.dart';
import 'app_role.dart';
import 'app_session.dart';

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
  static const _loginHeroFallbackAsset = 'assets/images/construction.jpg';
  static const _sensorLogoAsset = 'assets/icons/sensor_icon.png';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AppLoginRole _selectedRole;
  bool _obscurePassword = true;
  bool _rememberMe = true;
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
    final rememberedEmail = prefs.getString(_rememberEmailKey) ?? '';
    final rememberedRole = prefs.getString(_rememberRoleKey);
    final matchedRole = rememberedRole == null
        ? null
        : appLoginRoleFromStoredValue(rememberedRole);

    if (!mounted) return;
    setState(() {
      _rememberMe = rememberMe;
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
    precacheImage(const AssetImage(_loginHeroFallbackAsset), context)
        .catchError((_) {});
    precacheImage(const AssetImage(_sensorLogoAsset), context)
        .catchError((_) {});
  }

  Future<void> _storePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberEnabledKey, _rememberMe);
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
      await _loginWithApi();
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
    final response = await AuthApi.login(
      LoginRequest(
        email: email,
        password: password,
        role: _selectedRole.loginRoleValue,
      ),
    );
    if (response.status.toUpperCase() != 'SUCCESS') {
      throw response.message;
    }

    final prefs = await SharedPreferences.getInstance();
    final principalId = response.body.principalId.trim();
    if (principalId.isNotEmpty) {
      await prefs.setString(_selectedRole.principalKey, principalId);
    }

    await ApiClient.setAuthToken(response.body.token);
    await AppSession.saveSession(
      token: response.body.token,
      username: email,
      role: _selectedRole.sessionValue,
    );
    await _pushHome(_homePageForRole(_selectedRole));
  }

  Future<void> _pushHome(Widget page) async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Widget _homePageForRole(AppLoginRole role) {
    switch (role) {
      case AppLoginRole.user:
        return const PlatformShellPage(role: AppLoginRole.user);
      case AppLoginRole.userAdmin:
        return const PlatformShellPage(role: AppLoginRole.userAdmin);
      case AppLoginRole.engineer:
        return const PlatformShellPage(role: AppLoginRole.engineer);
      case AppLoginRole.vendor:
        return const PlatformShellPage(role: AppLoginRole.vendor);
      case AppLoginRole.analytics:
        return const PlatformShellPage(role: AppLoginRole.analytics);
      case AppLoginRole.analyticsRole:
        return const PlatformShellPage(role: AppLoginRole.analyticsRole);
      case AppLoginRole.admin:
        return const PlatformShellPage(role: AppLoginRole.admin);
    }
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
    final isPhone = width < 420;
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
    final cardPadding = width < 400
        ? 20.0
        : width < 560
            ? 28.0
            : 48.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isPhone ? 16 : 24),
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
                        fontSize: width < 400
                            ? 30
                            : width < 560
                                ? 38
                                : 48,
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
                    Row(
                      children: isPhone
                          ? [
                              Expanded(
                                child: SizedBox(
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
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
                              ),
                            ]
                          : [
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
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
    final isPhone = width < 420;
    final pagePadding = width >= 1280
        ? 48.0
        : width >= 960
            ? 28.0
            : width >= 640
                ? 20.0
                : isPhone
                    ? 0.0
                    : 16.0;
    final panelMinHeight =
        stacked ? 0.0 : (size.height - (pagePadding * 2)).clamp(620.0, 760.0);

    return Scaffold(
      backgroundColor: isPhone ? Colors.white : const Color(0xFFF6F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(pagePadding),
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1240,
                  minHeight:
                      stacked ? (isPhone ? size.height : 0) : panelMinHeight,
                ),
                child: stacked
                    ? Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: OpsColors.surface,
                          borderRadius: BorderRadius.circular(isPhone ? 0 : 28),
                          border: isPhone
                              ? null
                              : Border.all(color: const Color(0xFFDDE4F0)),
                          boxShadow: isPhone
                              ? const []
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF20325B)
                                        .withValues(alpha: 0.08),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildUserInfoColumn(
                              compact: true,
                              fullscreenPhone: isPhone,
                            ),
                            Transform.translate(
                              offset: const Offset(0, -26),
                              child: _buildUserAuthCard(
                                context,
                                compact: true,
                                fullscreenPhone: isPhone,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: panelMinHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: OpsColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFDDE4F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF20325B)
                                    .withValues(alpha: 0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Row(
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
      ),
    );
  }

  Widget _buildUserAuthCard(
    BuildContext context, {
    required bool compact,
    bool fullscreenPhone = false,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 420;
    final sidePadding = compact ? (isPhone ? 18.0 : 28.0) : 44.0;
    final titleSize = compact ? (isPhone ? 26.0 : 30.0) : 38.0;
    final compactPanelRadius = fullscreenPhone ? 34.0 : 30.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: fullscreenPhone
            ? BorderRadius.vertical(
                top: Radius.circular(compactPanelRadius),
              )
            : compact
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
        boxShadow: compact
            ? [
                BoxShadow(
                  color: const Color(0xFF20325B).withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, -4),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.fromLTRB(
        sidePadding,
        compact ? 26 : 44,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 34,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B63FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedRole.label} Login',
                          style: TextStyle(
                            color: const Color(0xFF10244D),
                            fontSize: isPhone ? 24 : 26,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedRole.description,
                          style: const TextStyle(
                            color: OpsColors.muted,
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: EdgeInsets.fromLTRB(
                  isPhone ? 14 : 16,
                  isPhone ? 14 : 16,
                  isPhone ? 14 : 16,
                  isPhone ? 18 : 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE6EBF5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF20325B).withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (widget.allowRoleSelection) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<AppLoginRole>(
                        initialValue: _selectedRole,
                        decoration: InputDecoration(
                          hintText: 'Select login type',
                          fillColor: const Color(0xFFF6F8FF),
                          filled: true,
                          prefixIcon: Icon(
                            _selectedRole.icon,
                            color: OpsColors.primaryContainer
                                .withValues(alpha: 0.78),
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
                    ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildRememberAndForgotRow(
                          context,
                          compact: constraints.maxWidth < 420,
                          primary: OpsColors.primaryContainer,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final loginButton = SizedBox(
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
                                  color: const Color(0xFF245BFF)
                                      .withValues(alpha: 0.20),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                        return SizedBox(
                          width: double.infinity,
                          child: loginButton,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
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
              const SizedBox(height: 34),
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
                    compact: constraints.maxWidth < 420,
                    primary: OpsColors.primaryContainer,
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final loginButton = SizedBox(
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
                            color:
                                const Color(0xFF245BFF).withValues(alpha: 0.20),
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
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                  return SizedBox(
                    width: double.infinity,
                    child: loginButton,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoColumn({
    required bool compact,
    bool fullscreenPhone = false,
  }) {
    return Container(
      height: compact ? 220.0 : null,
      constraints: compact ? null : const BoxConstraints(minHeight: 620),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: fullscreenPhone
            ? BorderRadius.zero
            : compact
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
        borderRadius: fullscreenPhone
            ? BorderRadius.zero
            : compact
                ? const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _LoginHeroImage(
                videoAsset: 'assets/images/login_background.mp4',
                fallbackAsset: _loginHeroFallbackAsset,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.00),
                    ],
                    stops: const [0, 0.42, 1],
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

class _LoginHeroImage extends StatelessWidget {
  final String videoAsset;
  final String fallbackAsset;

  const _LoginHeroImage({
    required this.videoAsset,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    return RouteAwareAssetVideo(
      videoAsset: videoAsset,
      fallbackAsset: fallbackAsset,
      startDelay: const Duration(milliseconds: 700),
    );
  }
}
