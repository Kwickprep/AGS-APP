import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/user_insights_model.dart';
import '../../../../utils/date_formatter.dart';

class ActivitiesTab extends StatelessWidget {
  final UserActivities activities;

  const ActivitiesTab({super.key, required this.activities});

  static const _colors = [
    Color(0xFF6366F1),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    if (activities.total == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // By Type
          if (activities.byType.isNotEmpty) ...[
            Text('By Type', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _buildPieChart(
              activities.byType.map((e) => _PieItem(e.type, e.count, e.percentage)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // By Source
          if (activities.bySource.isNotEmpty) ...[
            Text('By Source', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _buildPieChart(
              activities.bySource.map((e) => _PieItem(e.source, e.count, e.percentage)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Trend
          if (activities.trend.isNotEmpty) ...[
            Text('Monthly Trend', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _buildTrendChart(),
            const SizedBox(height: 24),
          ],

          // Recent
          if (activities.recent.isNotEmpty) ...[
            Text('Recent Activities', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            ...activities.recent.map(_buildRecentItem),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: AppColors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No activities yet',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<_PieItem> items) {
    final filtered = items.where((s) => s.count > 0).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: filtered.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return PieChartSectionData(
                    value: s.count.toDouble(),
                    title: '${s.percentage.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    color: _colors[i % _colors.length],
                    radius: 55,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.label,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${s.count}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    if (activities.trend.isEmpty) return const SizedBox.shrink();

    final maxY = activities.trend.fold<double>(
      0,
      (prev, e) => e.count > prev ? e.count.toDouble() : prev,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble().clamp(1, double.infinity) : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= activities.trend.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _shortMonth(activities.trend[idx].month),
                        style: const TextStyle(fontSize: 9, color: AppColors.textLight),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: maxY > 0 ? maxY * 1.2 : 5,
            lineBarsData: [
              LineChartBarData(
                spots: activities.trend.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                }).toList(),
                isCurved: true,
                color: const Color(0xFF22C55E),
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF22C55E),
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(InsightRecentActivity act) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, size: 16, color: Color(0xFF22C55E)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  act.typeName,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (act.companyName.isNotEmpty || act.inquiryName.isNotEmpty) ...[
            const SizedBox(height: 6),
            if (act.companyName.isNotEmpty)
              Text(act.companyName, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (act.inquiryName.isNotEmpty)
              Text(act.inquiryName, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          if (act.date != null) ...[
            const SizedBox(height: 4),
            Text(formatDateShort(act.date), style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }

  String _shortMonth(String month) {
    if (month.length >= 3) return month.substring(0, 3);
    return month;
  }
}

class _PieItem {
  final String label;
  final int count;
  final double percentage;
  _PieItem(this.label, this.count, this.percentage);
}
