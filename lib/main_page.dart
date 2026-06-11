import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const SiteGuardianApp());
}

class SiteGuardianApp extends StatelessWidget {
  const SiteGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WowGuardian - Construction Safety',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFF5A623),
          primaryContainer: Color(0xFFFEF3E2),
          secondary: Color(0xFF1A1A1A),
          surface: Color(0xFFFAFBFC),
          surfaceContainerHighest: Color(0xFFE8EAED),
          onPrimary: Color(0xFF0A0A0A),
          onSurface: Color(0xFF0A0A0A),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: Color(0xFFE8EAED), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFFF5A623), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5A623),
            foregroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(48),
            ),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(48),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const MainPage(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'home': GlobalKey(),
    'features': GlobalKey(),
    'useCases': GlobalKey(),
    'contact': GlobalKey(),
  };

  bool _isMobileMenuOpen = false;

  void _scrollToSection(String section) {
    final context = _sectionKeys[section]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      alignment: 0.1,
    );
    setState(() => _isMobileMenuOpen = false);
  }

  void _openLogin() {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Sticky Navbar
          SliverAppBar(
            pinned: true,
            elevation: 0,
            toolbarHeight: 76,
            backgroundColor: Colors.white.withValues(alpha: 0.96),
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A1A), Color(0xFFF5A623)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.construction,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    text: 'Wow',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: 'Guardian',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF5A623),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (!isMobile) ...[
                _NavAction(
                  label: 'Home',
                  onTap: () => _scrollToSection('home'),
                ),
                _NavAction(
                  label: 'Features',
                  onTap: () => _scrollToSection('features'),
                ),
                _NavAction(
                  label: 'Use Cases',
                  onTap: () => _scrollToSection('useCases'),
                ),
                _NavAction(
                  label: 'Contact',
                  onTap: () => _scrollToSection('contact'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _openLogin,
                  child: const Text('Login'),
                ),
                const SizedBox(width: 20),
              ],
              if (isMobile)
                IconButton(
                  icon: Icon(
                    _isMobileMenuOpen ? Icons.close : Icons.menu,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    setState(() => _isMobileMenuOpen = !_isMobileMenuOpen);
                  },
                ),
            ],
          ),
          // Mobile Menu Overlay
          if (isMobile && _isMobileMenuOpen)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _MobileNavItem(
                      label: 'Home',
                      onTap: () => _scrollToSection('home'),
                    ),
                    _MobileNavItem(
                      label: 'Features',
                      onTap: () => _scrollToSection('features'),
                    ),
                    _MobileNavItem(
                      label: 'Use Cases',
                      onTap: () => _scrollToSection('useCases'),
                    ),
                    _MobileNavItem(
                      label: 'Contact',
                      onTap: () => _scrollToSection('contact'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _openLogin,
                      child: const Text('Request Demo'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _openLogin,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF5A623)),
                      ),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
          // Hero Section
          SliverToBoxAdapter(
            key: _sectionKeys['home'],
            child: Container(
              height: 550,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black87, Colors.black54],
                ),
                image: DecorationImage(
                  image: const AssetImage('assets/images/construction.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.5),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                  child: SizedBox(
                    width: isMobile ? double.infinity : 620,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Sensors for Safer Construction Sites',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 36 : 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Monitor your site in real-time and prevent risks before they happen. Reduce incidents, ensure compliance, and protect your workforce.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ElevatedButton(
                              onPressed: _openLogin,
                              child: const Text('Request Demo'),
                            ),
                            OutlinedButton(
                              onPressed: () => _scrollToSection('contact'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.white, width: 2),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Contact Us'),
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
          // What It Helps With Section
          SliverToBoxAdapter(
            key: _sectionKeys['features'],
            child: _SectionBlock(
              title: 'What It Helps With',
              subtitle: 'Real-time monitoring for complete site safety',
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: _helpCards
                    .map((card) => SizedBox(
                          width: (MediaQuery.of(context).size.width >= 1100)
                              ? 280
                              : (MediaQuery.of(context).size.width >= 640)
                                  ? (MediaQuery.of(context).size.width - 88) / 2
                                  : MediaQuery.of(context).size.width - 48,
                          child: _FeatureCard(
                            icon: card['icon'],
                            title: card['title'],
                            description: card['description'],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          // Key Features Section
          SliverToBoxAdapter(
            child: _SectionBlock(
              backgroundColor: Colors.white,
              title: 'Key Features',
              subtitle: 'Built for the toughest construction environments',
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: _featureCards
                    .map((card) => SizedBox(
                          width: (MediaQuery.of(context).size.width >= 1100)
                              ? 280
                              : (MediaQuery.of(context).size.width >= 640)
                                  ? (MediaQuery.of(context).size.width - 88) / 2
                                  : MediaQuery.of(context).size.width - 48,
                          child: _FeatureCard(
                            icon: card['icon'],
                            title: card['title'],
                            description: card['description'],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          // Use Cases Section
          SliverToBoxAdapter(
            key: _sectionKeys['useCases'],
            child: _SectionBlock(
              title: 'Use Cases',
              subtitle: 'Trusted across the construction industry',
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: _useCases
                    .map((card) => SizedBox(
                          width: (MediaQuery.of(context).size.width >= 1100)
                              ? 280
                              : (MediaQuery.of(context).size.width >= 640)
                                  ? (MediaQuery.of(context).size.width - 88) / 2
                                  : MediaQuery.of(context).size.width - 48,
                          child: _FeatureCard(
                            icon: card['icon'],
                            title: card['title'],
                            description: card['description'],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          // How It Works Section
          SliverToBoxAdapter(
            child: _SectionBlock(
              backgroundColor: const Color(0xFFF7F9FC),
              title: 'How It Works',
              subtitle: 'Simple setup, powerful insights',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isRow = constraints.maxWidth >= 768;
                  final children =
                      _steps.map((step) => _StepTile(step: step)).toList();
                  return isRow
                      ? Row(
                          children:
                              children.map((e) => Expanded(child: e)).toList())
                      : Column(children: children);
                },
              ),
            ),
          ),
          // Dashboard Preview Section
          SliverToBoxAdapter(
            child: _SectionBlock(
              title: 'Dashboard Preview',
              subtitle: 'Real-time data at your fingertips',
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: const [
                  _DashboardCard(
                    title: 'Air quality',
                    icon: Icons.air,
                    value: 'PM2.5: 38 µg/m³ · Good',
                    showChart: true,
                  ),
                  _DashboardCard(
                    title: 'Noise level',
                    icon: Icons.volume_down,
                    value: '76 dB · Moderate',
                    showChart: false,
                    progressValue: 0.78,
                  ),
                  _DashboardCard(
                    title: 'Recent alerts',
                    icon: Icons.warning_amber,
                    value: '2 active alerts',
                    showChart: false,
                    alerts: [
                      '10:32 AM - Dust level high',
                      '09:15 AM - Noise exceedance'
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Why Choose Us Section
          SliverToBoxAdapter(
            child: _SectionBlock(
              backgroundColor: Colors.white,
              title: 'Why Choose Us',
              subtitle: 'The intelligent choice for construction safety',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1100
                      ? 4
                      : constraints.maxWidth >= 640
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 3.8,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _benefits.length,
                    itemBuilder: (context, index) {
                      final benefit = _benefits[index];
                      return _BenefitItem(
                        icon: benefit['icon'],
                        title: benefit['title'],
                        description: benefit['description'],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // Final CTA Section
          SliverToBoxAdapter(
            key: _sectionKeys['contact'],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F0F0F), Color(0xFF1E1E1E)],
                  ),
                  borderRadius: BorderRadius.circular(48),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'Make Your Site Safer Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join hundreds of construction teams using WowGuardian to prevent incidents and protect workers.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _openLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                      ),
                      child: const Text('Get Started →'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          SliverToBoxAdapter(
            child: _Footer(),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _helpCards = [
    {
      'icon': Icons.air,
      'title': 'Track dust & air quality',
      'description': 'Real-time particulate monitoring for respiratory safety.'
    },
    {
      'icon': Icons.volume_up,
      'title': 'Monitor noise levels',
      'description': 'Ensure compliance and protect hearing health.'
    },
    {
      'icon': Icons.warning_amber,
      'title': 'Detect unsafe conditions',
      'description': 'Gas leaks, vibrations, structural risks instantly.'
    },
    {
      'icon': Icons.construction,
      'title': 'Improve worker safety',
      'description': 'Proactive alerts reduce accidents.'
    },
  ];

  final List<Map<String, dynamic>> _featureCards = [
    {
      'icon': Icons.notifications_active,
      'title': 'Real-time alerts',
      'description': 'Instant push notifications to safety managers.'
    },
    {
      'icon': Icons.power,
      'title': 'Easy setup',
      'description': 'Plug-and-play sensors, ready in minutes.'
    },
    {
      'icon': Icons.engineering,
      'title': 'Works in harsh environments',
      'description': 'Dust-proof, water-resistant, wide temp range.'
    },
    {
      'icon': Icons.dashboard,
      'title': 'Mobile-friendly dashboard',
      'description': 'Access live data from any device.'
    },
  ];

  final List<Map<String, dynamic>> _useCases = [
    {
      'icon': Icons.apartment,
      'title': 'Building construction',
      'description': 'Multi-story sites benefit from dust & noise control.'
    },
    {
      'icon': Icons.route,
      'title': 'Road projects',
      'description': 'Monitor heavy machinery vibration and air quality.'
    },
    {
      'icon': Icons.architecture,
      'title': 'Infrastructure sites',
      'description': 'Tunnels and bridges get structural monitoring.'
    },
    {
      'icon': Icons.terrain,
      'title': 'Mining areas',
      'description': 'Track hazardous gases and particulate levels.'
    },
  ];

  final List<Map<String, String>> _steps = [
    {
      'number': '1',
      'title': 'Place sensors',
      'description': 'Deploy wireless sensors across key zones.'
    },
    {
      'number': '2',
      'title': 'Sensors collect data',
      'description': 'Continuous monitoring of air, noise, vibration.'
    },
    {
      'number': '3',
      'title': 'Get alerts on phone',
      'description': 'Instant SMS, email or app alerts.'
    },
    {
      'number': '4',
      'title': 'Take action',
      'description': 'Respond quickly and prevent incidents.'
    },
  ];

  final List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.engineering,
      'title': 'Built for construction sites',
      'description': 'Rugged and reliable.'
    },
    {
      'icon': Icons.thumb_up,
      'title': 'Easy to use',
      'description': 'Intuitive interface.'
    },
    {
      'icon': Icons.shield,
      'title': 'Reliable in tough conditions',
      'description': 'IP67 rated.'
    },
    {
      'icon': Icons.assignment,
      'title': 'Helps meet safety standards',
      'description': 'OSHA & ISO compliant.'
    },
  ];
}

class _NavAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style:
            const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MobileNavItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Color? backgroundColor;

  const _SectionBlock({
    required this.title,
    required this.subtitle,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: const Color(0xFFF5A623)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final Map<String, String> step;

  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF5A623),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step['number']!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              step['title']!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              step['description']!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final bool showChart;
  final double? progressValue;
  final List<String>? alerts;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.value,
    this.showChart = false,
    this.progressValue,
    this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF5A623), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (showChart)
            Container(
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                      width: 35, height: 42, color: const Color(0xFFF5A623)),
                  const SizedBox(width: 8),
                  Container(
                      width: 35, height: 68, color: const Color(0xFFF5A623)),
                  const SizedBox(width: 8),
                  Container(
                      width: 35, height: 52, color: const Color(0xFFF5A623)),
                ],
              ),
            ),
          if (progressValue != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFFF5A623),
                    borderRadius: BorderRadius.circular(20),
                    minHeight: 12,
                  ),
                  const SizedBox(height: 8),
                  Text(value),
                ],
              ),
            ),
          if (alerts != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: alerts!
                    .map((alert) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 8, color: Color(0xFFF5A623)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(alert,
                                      style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 30, color: const Color(0xFFF5A623)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isRow = constraints.maxWidth >= 768;
                  final children = [
                    _FooterColumn(
                      title: 'WowGuardian',
                      content:
                          'Smart sensor solutions for modern construction safety.',
                      showSocial: true,
                    ),
                    _FooterColumn(
                      title: 'Quick Links',
                      links: ['Home', 'Features', 'Use Cases', 'Login'],
                    ),
                    _FooterColumn(
                      title: 'Resources',
                      links: ['Safety Guides', 'Case Studies', 'Support'],
                    ),
                  ];
                  return isRow
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children)
                      : Column(children: children);
                },
              ),
              const SizedBox(height: 40),
              const Divider(color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                '© 2025 WowGuardian — Intelligent construction safety. All rights reserved.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final String? content;
  final List<String>? links;
  final List<String>? contacts;
  final bool showSocial;

  const _FooterColumn({
    required this.title,
    this.content,
    this.links,
    this.contacts,
    this.showSocial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (content != null)
              Text(
                content!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            if (links != null)
              ...links!.map((link) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      link,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )),
            if (contacts != null)
              ...contacts!.map((contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      contact,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )),
            if (showSocial) const SizedBox(height: 16),
            if (showSocial)
              const Row(
                children: [
                  Icon(Icons.business, color: Colors.grey, size: 22),
                  SizedBox(width: 16),
                  Icon(Icons.alternate_email, color: Colors.grey, size: 22),
                  SizedBox(width: 16),
                  Icon(Icons.facebook, color: Colors.grey, size: 22),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Login Page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Please enter both email and password', isError: true);
      return;
    }

    // Demo authentication
    if ((email == 'demo@sitesafe.com' || email == 'admin@siteguardian.com') &&
        password == 'Suraj@123') {
      _showSnackbar('Login successful! Welcome to WowGuardian dashboard.');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      _showSnackbar('Invalid credentials. Use demo@sitesafe.com / Suraj@123',
          isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A1A), Color(0xFFF5A623)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.crop_square,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      text: 'Wow',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: 'Guardian',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF5A623),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Email Field
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'site@guardian.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(
                              () => _isPasswordVisible = !_isPasswordVisible);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Remember me & Forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                            activeColor: const Color(0xFFF5A623),
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          _showSnackbar(
                              'Password reset link sent to your email');
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: Color(0xFFF5A623)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          const Text('Sign In', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Demo credentials
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Demo Access',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Text('demo@sitesafe.com',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Text('Suraj@123',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '← Back to Home',
                      style: TextStyle(color: Color(0xFFF5A623)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
