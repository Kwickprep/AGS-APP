import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/user_insights_model.dart';
import '../../../../utils/date_formatter.dart';

class InquiriesTab extends StatelessWidget {
  final UserInquiries inquiries;

  const InquiriesTab({super.key, required this.inquiries});

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
    if (inquiries.total == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chips
          if (inquiries.byStatus.isNotEmpty) ...[
            Text('Status Distribution', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _buildStatusChips(),
            const SizedBox(height: 20),
            _buildDoughnutChart(),
            const SizedBox(height: 24),
          ],

          // Trend
          if (inquiries.trend.isNotEmpty) ...[
            Text('Monthly Trend', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _buildTrendChart(),
            const SizedBox(height: 24),
          ],

          // Recent
          if (inquiries.recent.isNotEmpty) ...[
            Text('Recent Inquiries', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            ...inquiries.recent.map(_buildRecentItem),
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
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No inquiries yet',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: inquiries.byStatus.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final color = _statusColor(s.status);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${s.status} (${s.count})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _colors[i % _colors.length],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'open':
        return AppColors.activeText;
      case 'pending':
        return AppColors.pendingText;
      case 'completed':
      case 'closed':
      case 'won':
        return AppColors.completedText;
      case 'cancelled':
      case 'lost':
        return AppColors.cancelledText;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildDoughnutChart() {
    final filtered = inquiries.byStatus.where((s) => s.count > 0).toList();
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
                      s.status,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
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
    if (inquiries.trend.isEmpty) return const SizedBox.shrink();

    final maxY = inquiries.trend.fold<double>(
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
                    if (idx < 0 || idx >= inquiries.trend.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _shortMonth(inquiries.trend[idx].month),
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
                spots: inquiries.trend.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                }).toList(),
                isCurved: true,
                color: const Color(0xFF6366F1),
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF6366F1),
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(InsightRecentInquiry inq) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inq.name,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (inq.company.isNotEmpty)
                  Text(
                    inq.company,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (inq.date != null)
                  Text(
                    formatDateShort(inq.date),
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          _buildStatusBadge(inq.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _shortMonth(String month) {
    if (month.length >= 3) return month.substring(0, 3);
    return month;
  }
}
