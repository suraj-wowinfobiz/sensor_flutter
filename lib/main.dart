import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/database_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Industrial Tilt Super Admin',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light().copyWith(
              scaffoldBackgroundColor: const Color(0xFFf4f9ff),
              textTheme: _compactTextTheme(ThemeData.light().textTheme),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1f7bcf),
                secondary: Color(0xFFe68a2e),
                surface: Color(0xFFffffff),
                error: Color(0xFFd64545),
              ),
              cardColor: Colors.white,
              dividerColor: const Color(0xFFd9e6f5),
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF0e1b2a),
              textTheme: _compactTextTheme(ThemeData.dark().textTheme),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3290df),
                secondary: Color(0xFFd97e2a),
                surface: Color(0xFF1d3852),
                error: Color(0xFFcc4a4a),
              ),
              cardColor: const Color(0xFF1d3852),
              dividerColor: const Color(0xFF315a7a),
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(0.92),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
