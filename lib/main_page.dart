import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'core/auth/global_login_screen.dart';
import 'core/theme/ops_theme.dart';
import 'user/screens/user_login_screen.dart';

void main() {
  runApp(const SiteGuardianApp());
}

class SiteGuardianApp extends StatelessWidget {
  const SiteGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Construction Sensor Analytics',
      debugShowCheckedModeBanner: false,
      theme: OpsTheme.light(),
      home: const MainPage(),
      routes: {
        '/login': (context) => const UserLoginScreen(),
        '/login/global': (context) => const GlobalLoginScreen(),
        '/global-login': (context) => const GlobalLoginScreen(),
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

  VideoPlayerController? _bgController;

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

  Widget _buildHeroMedia() {
    if (_bgController != null && _bgController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _bgController!.value.size.width,
          height: _bgController!.value.size.height,
          child: VideoPlayer(_bgController!),
        ),
      );
    }

    return Image.asset(
      'assets/images/construction.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _buildHeroContent({
    required bool isMobile,
    required bool isPhone,
    required BoxConstraints constraints,
    Color titleColor = Colors.white,
    Color bodyColor = Colors.white,
    bool showBadge = true,
    bool fullWidthButtons = false,
  }) {
    final contentWidth = isMobile ? constraints.maxWidth : 680.0;
    final compactCtas = fullWidthButtons || constraints.maxWidth < 460;
    final subtitleWidth = isMobile ? contentWidth : contentWidth * 0.8;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBadge) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: titleColor == Colors.white
                      ? Colors.white.withValues(alpha: .12)
                      : OpsColors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: titleColor == Colors.white
                        ? Colors.white.withValues(alpha: .24)
                        : OpsColors.primary.withValues(alpha: .20),
                  ),
                ),
                child: Text(
                  'LIVE CONSTRUCTION MONITORING',
                  style: TextStyle(
                    color: titleColor == Colors.white
                        ? Colors.white
                        : OpsColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Smart Sensors for Safer Construction Sites',
              softWrap: true,
              style: TextStyle(
                fontSize: isPhone
                    ? 28
                    : isMobile
                        ? 36
                        : 52,
                fontWeight: FontWeight.w800,
                color: titleColor,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: subtitleWidth),
              child: Text(
                'Track air quality, vibration, noise, and worker safety with one connected sensor platform built for industrial job sites.',
                softWrap: true,
                style: TextStyle(
                  fontSize: isPhone
                      ? 15
                      : isMobile
                          ? 16
                          : 18,
                  color: bodyColor.withValues(alpha: bodyColor == Colors.white
                      ? .88
                      : 1),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: compactCtas ? constraints.maxWidth : null,
                  child: ElevatedButton(
                    onPressed: _openLogin,
                    child: const Text('Login'),
                  ),
                ),
                SizedBox(
                  width: compactCtas ? constraints.maxWidth : null,
                  child: OutlinedButton(
                    onPressed: () => _scrollToSection('features'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: titleColor == Colors.white
                          ? Colors.white
                          : OpsColors.primary,
                      side: BorderSide(
                        color: titleColor == Colors.white
                            ? Colors.white.withValues(alpha: .42)
                            : OpsColors.primary.withValues(alpha: .30),
                      ),
                      backgroundColor: titleColor == Colors.white
                          ? Colors.white.withValues(alpha: .08)
                          : Colors.white,
                    ),
                    child: const Text('Explore Features'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _bgController = VideoPlayerController.asset('assets/images/background.mp4');
    _bgController!.initialize().then((_) {
      _bgController!.setLooping(true);
      _bgController!.setVolume(0);
      _bgController!.play();
      setState(() {});
    }).catchError((_) {
      // If video fails to initialize, we silently fall back to the image.
    });
  }

  @override
  void dispose() {
    _bgController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final isMobile = screenWidth < 900;
    final isPhone = screenWidth < 600;
    final heroHeight = isMobile
        ? (isPhone ? 500.0 : 560.0)
        : (screenSize.height * 0.78).clamp(560.0, 760.0);

    return Scaffold(
      backgroundColor: OpsColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            toolbarHeight: isPhone ? 68 : 76,
            backgroundColor: OpsColors.surface.withValues(alpha: .96),
            surfaceTintColor: Colors.transparent,
            title: const _Brand(),
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
                    color: OpsColors.text,
                  ),
                  onPressed: () {
                    setState(() => _isMobileMenuOpen = !_isMobileMenuOpen);
                  },
                ),
            ],
          ),
          if (isMobile && _isMobileMenuOpen)
            SliverToBoxAdapter(
              child: Container(
                color: OpsColors.surface,
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
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            key: _sectionKeys['home'],
            child: isPhone
                ? Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildHeroMedia(),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: .12),
                                      Colors.transparent,
                                      OpsColors.text.withValues(alpha: .12),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 22, 16, 30),
                          child: LayoutBuilder(
                            builder: (context, constraints) => _buildHeroContent(
                              isMobile: true,
                              isPhone: true,
                              constraints: constraints,
                              titleColor: OpsColors.text,
                              bodyColor: OpsColors.muted,
                              showBadge: true,
                              fullWidthButtons: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: heroHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: OpsColors.text,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildHeroMedia(),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  OpsColors.text.withValues(alpha: .78),
                                  OpsColors.primary.withValues(alpha: .62),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1280),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 32,
                                  vertical: isMobile ? 40 : 84,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) =>
                                      _buildHeroContent(
                                    isMobile: isMobile,
                                    isPhone: false,
                                    constraints: constraints,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            key: _sectionKeys['features'],
            child: _SectionBlock(
              title: 'What It Helps With',
              subtitle: 'Real-time monitoring for complete site safety',
              child: _ResponsiveCards(
                children: _helpCards
                    .map(
                      (card) => _FeatureCard(
                        icon: card.icon,
                        title: card.title,
                        description: card.description,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionBlock(
              backgroundColor: OpsColors.surface,
              title: 'Key Features',
              subtitle: 'Built for the toughest construction environments',
              child: _ResponsiveCards(
                children: _featureCards
                    .map(
                      (card) => _FeatureCard(
                        icon: card.icon,
                        title: card.title,
                        description: card.description,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            key: _sectionKeys['useCases'],
            child: _SectionBlock(
              title: 'Use Cases',
              subtitle: 'Trusted across the construction industry',
              child: _ResponsiveCards(
                children: _useCases
                    .map(
                      (card) => _FeatureCard(
                        icon: card.icon,
                        title: card.title,
                        description: card.description,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionBlock(
              backgroundColor: OpsColors.surfaceLow,
              title: 'How It Works',
              subtitle: 'Simple setup, powerful insights',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isRow = constraints.maxWidth >= 768;
                  final children =
                      _steps.map((step) => _StepTile(step: step)).toList();
                  if (!isRow) return Column(children: children);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children
                        .map((child) => Expanded(child: child))
                        .toList(),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: _SectionBlock(
              title: 'Dashboard Preview',
              subtitle: 'Real-time data at your fingertips',
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _DashboardCard(
                    title: 'Air quality',
                    icon: Icons.air,
                    value: 'PM2.5: 38 ug/m3 - Good',
                    chart: _MiniBarChart(),
                  ),
                  _DashboardCard(
                    title: 'Noise level',
                    icon: Icons.volume_down,
                    value: '76 dB - Moderate',
                    chart: _MiniProgress(value: .78),
                  ),
                  _DashboardCard(
                    title: 'Recent alerts',
                    icon: Icons.warning_amber_rounded,
                    value: '2 active alerts',
                    chart: _MiniAlerts(),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionBlock(
              backgroundColor: OpsColors.surface,
              title: 'Why Choose Us',
              subtitle: 'The intelligent choice for construction safety',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1100
                      ? 4
                      : constraints.maxWidth >= 640
                          ? 2
                          : 1;
                  final childAspectRatio = constraints.maxWidth >= 1100
                      ? 3.4
                      : constraints.maxWidth >= 640
                          ? 2.6
                          : 2.1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _benefits.length,
                    itemBuilder: (context, index) {
                      final benefit = _benefits[index];
                      return _BenefitItem(
                        icon: benefit.icon,
                        title: benefit.title,
                        description: benefit.description,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            key: _sectionKeys['contact'],
            child: const _ContactSection(),
          ),
          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 420;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: OpsColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WowGardian',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 18 : 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: OpsColors.text,
                ),
              ),
              Text(
                'SENSOR ANALYTICS',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 8.5 : 10,
                  fontWeight: FontWeight.w800,
                  color: OpsColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
        style: const TextStyle(
          color: OpsColors.text,
          fontWeight: FontWeight.w700,
        ),
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
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: onTap,
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
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    return Container(
      color: backgroundColor ?? OpsColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 16 : 24,
        vertical: isPhone ? 44 : 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: isPhone ? 28 : 34,
                      height: isPhone ? 36 / 28 : 42 / 34,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: OpsColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveCards extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveCards({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1100
            ? 280.0
            : constraints.maxWidth >= 640
                ? (constraints.maxWidth - 20) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
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
    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OpsColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: OpsColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: OpsColors.muted)),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final _InfoItem step;

  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: OpsColors.primary.withValues(alpha: .10),
            child: Icon(step.icon, color: OpsColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            step.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: const TextStyle(color: OpsColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final Widget chart;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: OpsColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          chart,
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OpsColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OpsColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(42),
          const SizedBox(width: 8),
          _bar(68),
          const SizedBox(width: 8),
          _bar(52),
        ],
      ),
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 35,
      height: height,
      decoration: BoxDecoration(
        color: OpsColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  final double value;

  const _MiniProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OpsColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: OpsColors.surfaceHigh,
        color: OpsColors.primary,
        borderRadius: BorderRadius.circular(20),
        minHeight: 12,
      ),
    );
  }
}

class _MiniAlerts extends StatelessWidget {
  const _MiniAlerts();

  @override
  Widget build(BuildContext context) {
    const alerts = [
      '10:32 AM - Dust level high',
      '09:15 AM - Noise exceedance',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OpsColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: alerts
            .map(
              (alert) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: OpsColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(alert, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OpsColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: OpsColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: OpsColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return _SectionBlock(
      backgroundColor: Colors.white,
      title: 'Contact',
      subtitle:
          'Reach our Thane, Mumbai team for demos, support, and business enquiries',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 860;
          final intro = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: OpsColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: OpsColors.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: OpsColors.primary.withValues(alpha: .14),
                    ),
                  ),
                  child: const Text(
                    'THANE, MUMBAI',
                    style: TextStyle(
                      color: OpsColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .9,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Let’s talk about smarter construction monitoring.',
                  style: TextStyle(
                    color: OpsColors.text,
                    fontSize: isPhone ? 24 : 30,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Connect with Wow Infobiz for product enquiries, site deployment support, or a walkthrough of our sensor analytics platform.',
                  style: TextStyle(
                    color: OpsColors.muted,
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          );

          const details = Column(
            children: [
              _ContactCard(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value:
                    '607-B, 803 Lodha Supremus, Business District 2, Kolshet, Thane (W), Mumbai - 400607',
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Divider(color: OpsColors.border, height: 1),
              ),
              _ContactCard(
                icon: Icons.phone_in_talk_outlined,
                label: 'Phone',
                value: '+91-9322600422',
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Divider(color: OpsColors.border, height: 1),
              ),
              _ContactCard(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: 'info@wowinfobiz.com',
              ),
            ],
          );

          if (!isWide) {
            return Column(
              children: [
                intro,
                const SizedBox(height: 20),
                const _ContactDetailsPanel(child: details),
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: intro),
                const SizedBox(width: 24),
                const Expanded(
                  child: _ContactDetailsPanel(child: details),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContactDetailsPanel extends StatelessWidget {
  final Widget child;

  const _ContactDetailsPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: OpsColors.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: OpsColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: OpsColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                  color: OpsColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              const Divider(color: OpsColors.border),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: OpsColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isRow = constraints.maxWidth >= 768;
                    const children = [
                      _FooterColumn(
                        title: 'WowGardian Sensor Analytics',
                        content:
                            'Smart sensor solutions for modern construction safety.',
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
                            children: children
                                .map((child) => Expanded(child: child))
                                .toList(),
                          )
                        : const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: children,
                          );
                  },
                ),
              ),
              const SizedBox(height: 40),
              const Divider(color: OpsColors.border),
              const SizedBox(height: 24),
              const Text(
                '2026 WowGardian Sensor Analytics - Intelligent construction safety. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: OpsColors.muted,
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

  const _FooterColumn({
    required this.title,
    this.content,
    this.links,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: OpsColors.text,
            ),
          ),
          const SizedBox(height: 16),
          if (content != null)
            Text(
              content!,
              style: const TextStyle(
                fontSize: 14,
                color: OpsColors.muted,
              ),
            ),
          if (links != null)
            ...links!.map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  link,
                  style: const TextStyle(
                    fontSize: 14,
                    color: OpsColors.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem(this.icon, this.title, this.description);
}

const _helpCards = [
  _InfoItem(
    Icons.air_rounded,
    'Dust and Air Quality',
    'Track PM2.5, PM10, and unsafe air conditions before they affect workers.',
  ),
  _InfoItem(
    Icons.volume_up_rounded,
    'Noise Monitoring',
    'Measure site noise exposure and detect threshold breaches in real time.',
  ),
  _InfoItem(
    Icons.thermostat_rounded,
    'Temperature and Humidity',
    'Watch environmental conditions across zones, floors, and equipment areas.',
  ),
  _InfoItem(
    Icons.vibration_rounded,
    'Vibration and Tilt',
    'Identify structural vibration, crane tilt, and foundation movement early.',
  ),
];

const _featureCards = [
  _InfoItem(
    Icons.dashboard_rounded,
    'Live Dashboard',
    'See sensor status, open alerts, site health, and trends from one place.',
  ),
  _InfoItem(
    Icons.notifications_active_rounded,
    'Smart Alerts',
    'Prioritize incidents by severity with source, time, and response owner.',
  ),
  _InfoItem(
    Icons.router_rounded,
    'Device Health',
    'Monitor gateway heartbeat, connectivity, firmware, and battery state.',
  ),
  _InfoItem(
    Icons.analytics_rounded,
    'Risk Analytics',
    'Compare sites, detect recurring breaches, and plan follow-up action.',
  ),
];

const _useCases = [
  _InfoItem(
    Icons.apartment_rounded,
    'High-rise Projects',
    'Monitor tower cranes, concrete zones, lift shafts, and facade activity.',
  ),
  _InfoItem(
    Icons.train_rounded,
    'Metro and Tunnels',
    'Track vibration, dust, and gateway status across long linear sites.',
  ),
  _InfoItem(
    Icons.factory_rounded,
    'Industrial Blocks',
    'Watch heavy equipment areas, temperature zones, and worker exposure.',
  ),
  _InfoItem(
    Icons.foundation_rounded,
    'Foundation Work',
    'Detect pile vibration, soil movement, tilt drift, and critical breaches.',
  ),
];

const _steps = [
  _InfoItem(
    Icons.sensors_rounded,
    'Deploy Sensors',
    'Install sensors across zones, gateways, and high-risk locations.',
  ),
  _InfoItem(
    Icons.cloud_sync_rounded,
    'Stream Data',
    'Readings flow continuously into the monitoring platform.',
  ),
  _InfoItem(
    Icons.crisis_alert_rounded,
    'Respond Faster',
    'Teams receive alerts with source, severity, and recommended action.',
  ),
];

const _benefits = [
  _InfoItem(
    Icons.verified_rounded,
    'Compliance Ready',
    'Support audits and safety reporting.',
  ),
  _InfoItem(
    Icons.speed_rounded,
    'Fast Visibility',
    'Understand site risk in seconds.',
  ),
  _InfoItem(
    Icons.groups_rounded,
    'Team Friendly',
    'Built for admins and operators.',
  ),
  _InfoItem(
    Icons.trending_down_rounded,
    'Lower Risk',
    'Reduce incidents and downtime.',
  ),
];
