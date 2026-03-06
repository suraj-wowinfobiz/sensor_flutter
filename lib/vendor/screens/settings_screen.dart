import 'package:flutter/material.dart';

import 'vendor_account_settings_panel.dart';

class VendorSettingsScreen extends StatelessWidget {
  const VendorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VendorAccountSettingsPanel(
      roleLabel: 'Vendor',
      userName: 'vendor.operator',
      userEmail: 'vendor.operator@live.com',
    );
  }
}
