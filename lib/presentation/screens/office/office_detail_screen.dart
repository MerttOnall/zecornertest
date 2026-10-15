import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:zecorner/router/app_router.dart';

class OfficeDetailScreen extends StatefulWidget {
  const OfficeDetailScreen({super.key});

  @override
  State<OfficeDetailScreen> createState() => _OfficeDetailScreenState();
}

class _OfficeDetailScreenState extends State<OfficeDetailScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = true;
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;
  late final AnimationController _pulseController;
  late final Animation<double> _floatingAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openDrawer();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackgroundWidget(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
            return RoleSidebar(currentPage: 'Ofisler');
          },
        ),
        onDrawerChanged: (isOpened) {
          setState(() {
            _isDrawerOpen = isOpened;
          });
        },
        drawerScrimColor: Colors.black54,
        drawerEdgeDragWidth: 0,
        appBar: AdminPanelAppBar(
          title: "Ofisler",
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: GestureDetector(
          onTap: () {
            if (_isDrawerOpen) {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
          child: AbsorbPointer(
            absorbing: _isDrawerOpen,
            child: Stack(
              children: [
                // Sağ üst animasyon
                Positioned(
                  right: -150,
                  top: -150,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_rotationController, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE53935).withOpacity(0.08),
                            const Color(0xFFE53935).withOpacity(0.05),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Sol alt animasyon
                Positioned(
                  left: -120,
                  bottom: -120,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_rotationController, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_rotationController.value * 2 * math.pi,
                        child: Transform.scale(
                          scale: _pulseAnimation.value * 0.8,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE53935).withOpacity(0.08),
                            const Color(0xFFE53935).withOpacity(0.05),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Orta animasyon
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 200,
                  top: MediaQuery.of(context).size.height / 2 - 200,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_rotationController, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * math.pi,
                        child: Transform.scale(
                          scale: _pulseAnimation.value * 0.9,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE53935).withOpacity(0.07),
                            const Color(0xFFE53935).withOpacity(0.04),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOperationStatusChart(),
                      _buildOfficeIncomeChart(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    dropdownColor: Colors.white,
                                    value: "Tümü",
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    items: ["Tümü", "Aktif", "Pasif", "Onay Bekleyen"]
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ))
                                        .toList(),
                                    onChanged: (value) {},
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Ofis Ara",
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.addOffice);
                          },
                          icon: const Icon(Icons.business, size: 30, color: Colors.white),
                          label: const Text("Yeni Ofis Ekle", style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return _buildOfficeCard();
                        },
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

  Widget _buildOfficeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 187, 186, 186)),
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(238, 46, 36, 1),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DveB Emlak Ofisi",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "info@dveb.com.tr",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
                color: Colors.grey[400],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  icon: Icons.phone_outlined,
                  title: "Telefon",
                  value: "+90 (850) 123-4567",
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  title: "Şehir",
                  value: "İstanbul",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Aktif Ofis",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfficeIncomeChart() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Zecorner Ofisleri Gelir Grafiği",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Yıl',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: '2024',
                    items: ['2024', '2023'].map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Ay',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: 'Aralık',
                    items: ['Aralık', 'Kasım', 'Ekim'].map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1200000,
                  backgroundColor: Colors.transparent,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      // tooltipBgColor: Colors.white,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '₺${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Color.fromRGBO(238, 46, 36, 1), fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt() + 1} Aralık',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₺${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // borderData: FlBorderData(show: false),
                // gridData: FlGridData(show: false),
                // barGroups: [
                //   BarChartGroupData(
                //     x: 0,
                //     barRods: [
                //       BarChartRodData(
                //         toY: 1000000,
                //         color: const Color(0xFFE53935),
                //         width: 20,
                //         borderRadius: BorderRadius.circular(4),
                //       ),
                //     ],
                //   ),
                // ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Toplam Net Kazanç:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "₺1.000.000,00",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationStatusChart() {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ofis Operasyon Durumu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 30,
                      color: Colors.blue,
                      title: 'Yayında',
                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                    PieChartSectionData(
                      value: 10,
                      color: Colors.green,
                      title: 'Satıldı',
                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                    PieChartSectionData(
                      value: 25,
                      color: Colors.amber,
                      title: 'Kiralandı',
                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                    PieChartSectionData(
                      value: 15,
                      color: Colors.red,
                      title: 'Reddedildi',
                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                    PieChartSectionData(
                      value: 12,
                      color: Colors.lightBlue,
                      title: 'İptal Edildi',
                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                    PieChartSectionData(
                      value: 8,
                      color: Colors.teal,
                      title: 'Değişiklik',
                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('Yayında', Colors.blue),
                _buildLegendItem('Satıldı', Colors.green),
                _buildLegendItem('Kiralandı', Colors.amber),
                _buildLegendItem('Reddedildi', Colors.red),
                _buildLegendItem('İptal Edildi', Colors.lightBlue),
                _buildLegendItem('Değişiklik', Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
} 