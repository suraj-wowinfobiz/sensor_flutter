import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, ProviderScope, WidgetRef;
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/auth/global_login_screen.dart';
import 'main_page.dart';
import 'super_admin/core/providers/theme_riverpod_provider.dart';
import 'super_admin/screens/super_admin_login_screen.dart';
import 'user/screens/user_login_screen.dart';
import 'user_admin/screens/user_admin_login_screen.dart';
import 'engineer/screens/engineer_login_screen.dart';
import 'vendor/screens/vendor_login_screen.dart';
import 'analytics/screens/analytics_login_screen.dart';
import 'super_admin/providers/super_admin_riverpod_provider.dart';

TextTheme _compactTextTheme(TextTheme base) {
  final t = GoogleFonts.interTextTheme(base);
  return t.copyWith(
    displayLarge:
        t.displayLarge?.copyWith(fontSize: 46, fontWeight: FontWeight.w700),
    displayMedium:
        t.displayMedium?.copyWith(fontSize: 38, fontWeight: FontWeight.w700),
    displaySmall:
        t.displaySmall?.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
    headlineLarge:
        t.headlineLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
    headlineMedium:
        t.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
    headlineSmall:
        t.headlineSmall?.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
    titleLarge:
        t.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    titleMedium:
        t.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall:
        t.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: t.bodyLarge?.copyWith(fontSize: 14),
    bodyMedium: t.bodyMedium?.copyWith(fontSize: 13),
    bodySmall: t.bodySmall?.copyWith(fontSize: 12),
    labelLarge:
        t.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    labelMedium:
        t.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall:
        t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
  );
}

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

  ThemeData _withTypography(ThemeData theme) {
    return theme.copyWith(textTheme: _compactTextTheme(theme.textTheme));
  }

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
        theme: _withTypography(themeProvider.buildTheme(Brightness.light)),
        darkTheme: _withTypography(themeProvider.buildTheme(Brightness.dark)),
        themeMode: themeProvider.themeMode,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(themeProvider.textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const MainPage(),
        routes: {
          '/login': (context) => const GlobalLoginScreen(),
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
