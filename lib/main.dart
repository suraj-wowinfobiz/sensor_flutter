import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, ProviderScope, WidgetRef;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/auth/global_login_screen.dart';
import 'core/auth/session_check_screen.dart';
import 'core/theme/ops_theme.dart';
import 'super_admin/core/providers/theme_riverpod_provider.dart';
import 'super_admin/screens/super_admin_login_screen.dart';
import 'user/screens/user_login_screen.dart';
import 'user_admin/screens/user_admin_login_screen.dart';
import 'engineer/screens/engineer_login_screen.dart';
import 'vendor/screens/vendor_login_screen.dart';
import 'analytics/screens/analytics_login_screen.dart';
import 'super_admin/providers/super_admin_riverpod_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _AppRoot());
  }
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeChangeNotifierProvider);
    final superAdminDatabase =
        ref.watch(superAdminBackendChangeNotifierProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: superAdminDatabase),
      ],
      child: MaterialApp(
        title: 'Industrial Tilt Super Admin',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AppScrollBehavior(),
        theme: OpsTheme.light(),
        darkTheme: OpsTheme.light(),
        themeMode: ThemeMode.light,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(themeProvider.textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SessionCheckScreen(),
        routes: {
          '/login': (context) => const UserLoginScreen(),
          '/login/global': (context) => const GlobalLoginScreen(),
          '/login/user': (context) => const UserLoginScreen(),
          '/login/user-admin': (context) => const UserAdminLoginScreen(),
          '/login/engineer': (context) => const EngineerLoginScreen(),
          '/login/super-admin': (context) => const SuperAdminLoginScreen(),
          '/login/vendor': (context) => const VendorLoginScreen(),
          '/login/analytics': (context) => const AnalyticsLoginScreen(),
        },
      ),
    );
  }
}
