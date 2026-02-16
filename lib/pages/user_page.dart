import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

// ===== DATABASE MODEL =====
class Sensor {
  final String id;
  final String name;
  final double tiltX;
  final double tiltY;
  final double total;
  final String status;
  final int battery;

  Sensor({
    required this.id,
    required this.name,
    required this.tiltX,
    required this.tiltY,
    required this.total,
    required this.status,
    required this.battery,
  });

  factory Sensor.random(int index) {
    final random = Random();
    double tiltX = random.nextDouble() * 2.5 + 0.4;
    double tiltY = random.nextDouble() * 2.3 + 0.3;
    double total = sqrt(tiltX * tiltX + tiltY * tiltY);
    String status =
        total > 4.0 ? 'critical' : (total > 2.6 ? 'warning' : 'normal');

    return Sensor(
      id: 'S-${1000 + index}',
      name: 'Tilt ${String.fromCharCode(65 + (index % 20))}',
      tiltX: double.parse(tiltX.toStringAsFixed(2)),
      tiltY: double.parse(tiltY.toStringAsFixed(2)),
      total: double.parse(total.toStringAsFixed(2)),
      status: status,
      battery: random.nextInt(30) + 70,
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late List<Sensor> sensors;
  List<Sensor> filteredSensors = [];
  double thresholdValue = 3.2;
  int criticalAlerts = 3;
  int warningAlerts = 7;
  bool _isDarkMode = false;
  bool isMenuOpen = false;
  String _selectedMenu = 'Dashboard';
  String _selectedRole = 'operator';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    sensors = List.generate(24, (index) => Sensor.random(index + 1));
    filteredSensors = List.from(sensors);
    updateAlertCounts();
  }

  void updateAlertCounts() {
    criticalAlerts = sensors.where((s) => s.status == 'critical').length;
    warningAlerts = sensors.where((s) => s.status == 'warning').length;
  }

  void filterSensors(String query) {
    if (query.isEmpty) {
      filteredSensors = List.from(sensors);
    } else {
      filteredSensors = sensors
          .where((s) =>
              s.id.toLowerCase().contains(query.toLowerCase()) ||
              s.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  void updateThreshold(double value) {
    setState(() {
      thresholdValue = value;
      criticalAlerts = (Random().nextInt(3) + 2);
      warningAlerts = (Random().nextInt(5) + 4);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final activeAlerts = sensors.where((s) => s.status != 'normal').length;
    final avgTilt =
        sensors.map((s) => s.total).reduce((a, b) => a + b) / sensors.length;
    final avgBattery =
        sensors.map((s) => s.battery).reduce((a, b) => a + b) / sensors.length;

    final pageTheme = Theme.of(context).copyWith(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E1B2A) : const Color(0xFFF5FAFF),
      textTheme: Theme.of(context).textTheme.apply(
            bodyColor: isDark ? Colors.white : const Color(0xFF0B1F33),
            displayColor: isDark ? Colors.white : const Color(0xFF0B1F33),
          ),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : const Color(0xFF0B1F33),
      ),
    );

    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0E1B2A) : const Color(0xFFF5FAFF),
        body: Stack(
          children: [
            // Main Content
            CustomScrollView(
              slivers: [
                // Navigation Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildNavBar(context),
                  ),
                ),

                // Welcome Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildWelcomeCard(context),
                  ),
                ),

                // Threshold Slider
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildThresholdCard(context),
                  ),
                ),

                // Stats Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildStatCard(
                        context,
                        icon: Icons.memory,
                        value: '${sensors.length}',
                        label: 'Total Sensors',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.warning_amber_rounded,
                        value: '$activeAlerts',
                        label: 'Active Alerts',
                        iconColor: const Color(0xFFF5A623),
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.show_chart,
                        value: '${avgTilt.toStringAsFixed(1)}°',
                        label: 'Average Tilt',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.battery_charging_full,
                        value: '${avgBattery.toStringAsFixed(0)}%',
                        label: 'Avg Battery',
                      ),
                    ]),
                  ),
                ),

                // Charts Grid
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildChartCard(context, 'Real-time Tilt', 0),
                      _buildChartCard(context, '30-Day Average', 1),
                      _buildChartCard(context, 'Status Distribution', 2),
                      _buildChartCard(context, 'Alerts by Hour', 3),
                      _buildChartCard(context, 'Threshold Analysis', 4),
                      _buildChartCard(context, 'X-Y Distribution', 5),
                    ]),
                  ),
                ),

                // Sensor Table
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSensorTable(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),

            // Overlay
            if (isMenuOpen)
              GestureDetector(
                onTap: () => setState(() => isMenuOpen = false),
                child: Container(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                    child: Container(),
                  ),
                ),
              ),

            // Sidebar Menu
            _buildSidebar(context),
          ],
        ),
      ),
    );
  }

  // ===== NAVIGATION BAR =====
  Widget _buildNavBar(BuildContext context) {
    final isDark = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A2C40).withOpacity(0.8)
            : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF1F7BCF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Hamburger Button
                GestureDetector(
                  onTap: () => setState(() => isMenuOpen = true),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A2C40).withOpacity(0.8)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.menu,
                      color: isDark ? Colors.white : const Color(0xFF0B1F33),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Logo
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1F7BCF),
                            isDark
                                ? const Color(0xFF6A9EFF)
                                : const Color(0xFF6A9EFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1F7BCF).withOpacity(0.3),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.memory,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'TILT OPERATOR',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
                const Spacer(),

                // Profile
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2C40).withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('Sarah Connor'),
                      const SizedBox(width: 12),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1F7BCF),
                              isDark
                                  ? const Color(0xFF6A9EFF)
                                  : const Color(0xFF6A9EFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1F7BCF).withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarChoice({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final isDark = _isDarkMode;
    final activeColor =
        isDark ? const Color(0xFF2D9C74) : const Color(0xFF1E8E6A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.2)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? activeColor
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.5)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: isActive
                        ? activeColor
                        : (isDark ? Colors.white70 : const Color(0xFF4F7B9C))),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? activeColor
                      : (isDark ? Colors.white70 : const Color(0xFF4F7B9C)),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== WELCOME CARD =====
  Widget _buildWelcomeCard(BuildContext context) {
    final isDark = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C3248).withOpacity(0.85)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Good afternoon, Sarah',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2C40).withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye,
                        color: isDark
                            ? const Color(0xFF4D9EFF)
                            : const Color(0xFF1F7BCF),
                      ),
                      const SizedBox(width: 8),
                      Text('${_roleLabel()} · Read Only',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== THRESHOLD CARD =====
  Widget _buildThresholdCard(BuildContext context) {
    final isDark = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C3248).withOpacity(0.85)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark ? const Color(0xFF4D9EFF) : const Color(0xFF1F7BCF),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E4165)
                            : const Color(0xFFE1F0FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: isDark
                            ? const Color(0xFF4D9EFF)
                            : const Color(0xFF1F7BCF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Temporary Alert Threshold',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: thresholdValue,
                        min: 2.0,
                        max: 5.0,
                        divisions: 30,
                        activeColor: isDark
                            ? const Color(0xFF4D9EFF)
                            : const Color(0xFF1F7BCF),
                        inactiveColor: Colors.grey.withOpacity(0.3),
                        onChanged: updateThreshold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF4D9EFF)
                            : const Color(0xFF1F7BCF),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? const Color(0xFF4D9EFF)
                                    : const Color(0xFF1F7BCF))
                                .withOpacity(0.3),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Text(
                        '${thresholdValue.toStringAsFixed(1)}°',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2C40).withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calculate,
                        color: isDark
                            ? const Color(0xFF4D9EFF)
                            : const Color(0xFF1F7BCF),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'If threshold was ${thresholdValue.toStringAsFixed(1)}°, there would be $criticalAlerts critical and $warningAlerts warning alerts.',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== STAT CARD =====
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
  }) {
    final isDark = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C3248).withOpacity(0.85)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E4165)
                        : const Color(0xFFE1F0FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ??
                        (isDark
                            ? const Color(0xFF4D9EFF)
                            : const Color(0xFF1F7BCF)),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(value,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF4F7B9C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== CHART CARD =====
  Widget _buildChartCard(BuildContext context, String title, int index) {
    final isDark = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C3248).withOpacity(0.85)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getChartIcon(index),
                      color: isDark
                          ? const Color(0xFF4D9EFF)
                          : const Color(0xFF1F7BCF),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildChart(index, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getChartIcon(int index) {
    const icons = [
      Icons.show_chart,
      Icons.show_chart,
      Icons.pie_chart,
      Icons.bar_chart,
      Icons.bar_chart,
      Icons.scatter_plot,
    ];
    return icons[index];
  }

  Widget _buildChart(int index, bool isDark) {
    switch (index) {
      case 0:
        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 2.1),
                  FlSpot(1, 2.5),
                  FlSpot(2, 1.8),
                  FlSpot(3, 3.0),
                  FlSpot(4, 2.7),
                ],
                isCurved: true,
                color:
                    isDark ? const Color(0xFF4D9EFF) : const Color(0xFF1F7BCF),
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        );
      case 1:
        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 2.2),
                  FlSpot(1, 2.4),
                  FlSpot(2, 2.1),
                  FlSpot(3, 2.7),
                  FlSpot(4, 2.5),
                ],
                isCurved: true,
                color: const Color(0xFF27A36A),
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        );
      case 2:
        return PieChart(
          PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 20,
            sections: [
              PieChartSectionData(
                value: 16,
                color: const Color(0xFF27A36A),
                radius: 30,
                showTitle: false,
              ),
              PieChartSectionData(
                value: 5,
                color: const Color(0xFFF5A623),
                radius: 30,
                showTitle: false,
              ),
              PieChartSectionData(
                value: 3,
                color: const Color(0xFFE54C4C),
                radius: 30,
                showTitle: false,
              ),
            ],
          ),
        );
      case 3:
        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(
                    toY: 2,
                    color: isDark
                        ? const Color(0xFF4D9EFF)
                        : const Color(0xFF1F7BCF))
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(
                    toY: 4,
                    color: isDark
                        ? const Color(0xFF4D9EFF)
                        : const Color(0xFF1F7BCF))
              ]),
              BarChartGroupData(x: 2, barRods: [
                BarChartRodData(
                    toY: 3,
                    color: isDark
                        ? const Color(0xFF4D9EFF)
                        : const Color(0xFF1F7BCF))
              ]),
              BarChartGroupData(x: 3, barRods: [
                BarChartRodData(
                    toY: 5,
                    color: isDark
                        ? const Color(0xFF4D9EFF)
                        : const Color(0xFF1F7BCF))
              ]),
            ],
          ),
        );
      case 4:
        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(toY: 2.9, color: const Color(0xFFF5A623))
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(toY: 3.2, color: const Color(0xFFF5A623))
              ]),
              BarChartGroupData(x: 2, barRods: [
                BarChartRodData(toY: 2.7, color: const Color(0xFFF5A623))
              ]),
            ],
          ),
        );
      case 5:
        return ScatterChart(
          ScatterChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            scatterSpots: [
              ScatterSpot(2.1, 1.8),
              ScatterSpot(2.9, 2.2),
              ScatterSpot(1.8, 2.7),
            ],
            scatterTouchData: ScatterTouchData(enabled: false),
          ),
        );
      default:
        return Container();
    }
  }

  // ===== SENSOR TABLE =====
  Widget _buildSensorTable(BuildContext context) {
    final isDark = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C3248).withOpacity(0.85)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E4165)
                                : const Color(0xFFE1F0FE),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.table_chart,
                            color: isDark
                                ? const Color(0xFF4D9EFF)
                                : const Color(0xFF1F7BCF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Live Sensor Readings',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A2C40).withOpacity(0.8)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF4F7B9C),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: searchController,
                              onChanged: filterSensors,
                              decoration: const InputDecoration(
                                hintText: 'Search sensors...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 80,
                    ),
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.1),
                        ),
                      ),
                      columnWidths: const {
                        0: FixedColumnWidth(100),
                        1: FixedColumnWidth(120),
                        2: FixedColumnWidth(80),
                        3: FixedColumnWidth(80),
                        4: FixedColumnWidth(80),
                        5: FixedColumnWidth(100),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E4165)
                                : const Color(0xFFE1F0FE),
                          ),
                          children: const [
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('ID',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700))),
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Name',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700))),
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Tilt X°',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700))),
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Tilt Y°',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700))),
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Total°',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700))),
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Status',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700))),
                          ],
                        ),
                        ...filteredSensors.take(8).map((sensor) {
                          return TableRow(
                            children: [
                              Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(sensor.id)),
                              Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(sensor.name)),
                              Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(sensor.tiltX.toString())),
                              Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(sensor.tiltY.toString())),
                              Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(sensor.total.toString())),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(sensor.status)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  child: Text(
                                    sensor.status,
                                    style: TextStyle(
                                      color: _getStatusColor(sensor.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2C40).withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.block, color: Colors.grey),
                      SizedBox(width: 12),
                      Text(
                          'Edit / delete actions are disabled for operator role.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'critical':
        return const Color(0xFFE54C4C);
      case 'warning':
        return const Color(0xFFF5A623);
      default:
        return const Color(0xFF27A36A);
    }
  }

  // ===== SIDEBAR MENU =====
  Widget _buildSidebar(BuildContext context) {
    final isDark = _isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(isMenuOpen ? 0 : -340, 0, 0),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C3248).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(40)),
            border: Border(
              right: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(40)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.memory,
                              color: isDark
                                  ? const Color(0xFF4D9EFF)
                                  : const Color(0xFF1F7BCF),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(_roleLabel(),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(() => isMenuOpen = false),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A2C40).withOpacity(0.8)
                                  : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                            child: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildMenuItem(
                        context, Icons.show_chart, 'Dashboard', isDark),
                    _buildMenuItem(context, Icons.memory, 'Sensors', isDark),
                    _buildMenuItem(
                        context, Icons.notifications, 'Alerts', isDark),
                    _buildMenuItem(
                        context, Icons.description, 'Reports', isDark),
                    _buildMenuItem(context, Icons.history, 'History', isDark),
                    const SizedBox(height: 16),
                    Container(
                        height: 1,
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text('THEME',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSidebarChoice(
                          context: context,
                          label: 'Light',
                          icon: Icons.light_mode,
                          isActive: !_isDarkMode,
                          onTap: () => setState(() => _isDarkMode = false),
                        ),
                        _buildSidebarChoice(
                          context: context,
                          label: 'Dark',
                          icon: Icons.dark_mode,
                          isActive: _isDarkMode,
                          onTap: () => setState(() => _isDarkMode = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('ROLE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSidebarChoice(
                          context: context,
                          label: 'Operator',
                          isActive: _selectedRole == 'operator',
                          onTap: () =>
                              setState(() => _selectedRole = 'operator'),
                        ),
                        _buildSidebarChoice(
                          context: context,
                          label: 'Engineer',
                          isActive: _selectedRole == 'engineer',
                          onTap: () =>
                              setState(() => _selectedRole = 'engineer'),
                        ),
                        _buildSidebarChoice(
                          context: context,
                          label: 'Admin',
                          isActive: _selectedRole == 'admin',
                          onTap: () => setState(() => _selectedRole = 'admin'),
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
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, bool isDark) {
    final isActive = _selectedMenu == title;
    final activeColor =
        isDark ? const Color(0xFF2D9C74) : const Color(0xFF1E8E6A);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.22) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? activeColor : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedMenu = title;
            isMenuOpen = false;
          }),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? activeColor
                      : (isDark ? Colors.white70 : const Color(0xFF4F7B9C)),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive
                        ? activeColor
                        : (isDark ? Colors.white : const Color(0xFF254A6B)),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel() {
    switch (_selectedRole) {
      case 'engineer':
        return 'Engineer';
      case 'admin':
        return 'Admin';
      default:
        return 'Operator';
    }
  }
}
