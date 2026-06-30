import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, ProviderScope, WidgetRef;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'common/platform/core/providers/theme_riverpod_provider.dart';
import 'common/platform/providers/super_admin_riverpod_provider.dart';
import 'core/auth/app_role.dart';
import 'core/auth/global_login_screen.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/auth/session_check_screen.dart';
import 'core/theme/ops_theme.dart';

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
        ref.read(superAdminBackendChangeNotifierProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: superAdminDatabase),
      ],
      child: MaterialApp(
        title: 'Industrial Tilt Platform',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [appRouteObserver],
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
          '/login': (context) => const GlobalLoginScreen(),
          '/login/global': (context) => const GlobalLoginScreen(),
          '/login/user': (context) => const GlobalLoginScreen(
                initialRole: AppLoginRole.user,
                allowRoleSelection: false,
              ),
          '/login/user-admin': (context) => const GlobalLoginScreen(
                initialRole: AppLoginRole.userAdmin,
                allowRoleSelection: false,
              ),
          '/login/engineer': (context) => const GlobalLoginScreen(
                initialRole: AppLoginRole.engineer,
                allowRoleSelection: false,
              ),
          '/login/admin': (context) => const GlobalLoginScreen(
                initialRole: AppLoginRole.admin,
                allowRoleSelection: false,
              ),
          '/login/super-admin': (context) => const GlobalLoginScreen(
                initialRole: AppLoginRole.admin,
                allowRoleSelection: false,
              ),
          '/login/vendor': (context) => const GlobalLoginScreen(
                initialRole: AppLoginRole.vendor,
                allowRoleSelection: false,
              ),
          '/login/analytics': (context) => const GlobalLoginScreen(
                initialRole: AppLoginRole.analytics,
                allowRoleSelection: false,
              ),
        },
      ),
    );
  }
}
