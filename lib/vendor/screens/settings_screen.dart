import 'package:flutter/material.dart';

import '../../super_admin/widgets/admin_account_settings_panel.dart';

class VendorSettingsScreen extends StatelessWidget {
  const VendorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAccountSettingsPanel(
      roleLabel: 'Vendor',
      userName: 'vendor.operator',
      userEmail: 'vendor.operator@live.com',
    );
  }
}
