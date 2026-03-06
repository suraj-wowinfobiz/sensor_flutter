import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef LoadUserById = Future<Map<String, dynamic>> Function(String userId);
typedef UpdateUserById = Future<Map<String, dynamic>> Function({
  required String userId,
  required String name,
  required String email,
  required String password,
  required String organizationId,
  required int maxUsersAllowed,
  required bool active,
});

class RoleProfileSettingsPanel extends StatefulWidget {
  final String title;
  final String principalIdPreferenceKey;
  final LoadUserById loadUserById;
  final UpdateUserById updateUserById;

  const RoleProfileSettingsPanel({
    super.key,
    required this.title,
    required this.principalIdPreferenceKey,
    required this.loadUserById,
    required this.updateUserById,
  });

  @override
  State<RoleProfileSettingsPanel> createState() =>
      _RoleProfileSettingsPanelState();
}

class _RoleProfileSettingsPanelState extends State<RoleProfileSettingsPanel> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _organizationIdController = TextEditingController();
  final _maxUsersAllowedController = TextEditingController();

  String? _userId;
  bool _active = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _organizationIdController.dispose();
    _maxUsersAllowedController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString(widget.principalIdPreferenceKey)?.trim() ?? '';
      if (userId.isEmpty) {
        throw Exception('User id not found. Please login again.');
      }
      final data = await widget.loadUserById(userId);

      _userId = userId;
      _nameController.text = (data['name'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      _organizationIdController.text =
          (data['organizationId'] ?? data['organization_id'] ?? '').toString();
      _maxUsersAllowedController.text =
          (data['maxUsersAllowed'] ?? data['max_users_allowed'] ?? '0')
              .toString();
      _active = (data['active'] ?? true) == true;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_userId == null || _userId!.isEmpty) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final organizationId = _organizationIdController.text.trim();
    final maxUsersAllowed =
        int.tryParse(_maxUsersAllowedController.text.trim());

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        organizationId.isEmpty ||
        maxUsersAllowed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fill name, email, password, organizationId, maxUsersAllowed',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.updateUserById(
        userId: _userId!,
        name: name,
        email: email,
        password: password,
        organizationId: organizationId,
        maxUsersAllowed: maxUsersAllowed,
        active: _active,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      _passwordController.clear();
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.title} Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isLight
                          ? const Color(0xFF0f202d)
                          : const Color(0xFFd4e4ef),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Profile is connected to backend APIs',
                    style: TextStyle(
                      fontSize: 14,
                      color: isLight
                          ? const Color(0xFF4e6473)
                          : const Color(0xFF9db7d2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _field('name', _nameController),
                  const SizedBox(height: 10),
                  _field('email', _emailController),
                  const SizedBox(height: 10),
                  _field('password', _passwordController, obscureText: true),
                  const SizedBox(height: 10),
                  _field('organizationId', _organizationIdController),
                  const SizedBox(height: 10),
                  _field(
                    'maxUsersAllowed',
                    _maxUsersAllowedController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: const Text('active'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
