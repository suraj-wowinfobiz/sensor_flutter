import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';

final themeChangeNotifierProvider =
    ChangeNotifierProvider<ThemeProvider>((ref) => ThemeProvider());
