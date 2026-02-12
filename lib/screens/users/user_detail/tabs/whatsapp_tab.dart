import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/user_insights_model.dart';
import '../../../../utils/date_formatter.dart';

class WhatsappTab extends StatelessWidget {
  final UserWhatsApp whatsapp;

  const WhatsappTab({super.key, required this.whatsapp});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards
          _buildStatCards(),
          const SizedBox(height: 24),

          // Trend
          if (whatsapp.trend.isNotEmpty) ...[
            Text('Monthly Trend', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _buildTrendChart(),
            const SizedBox(height: 24),
          ],

          // Recent messages
          if (whatsapp.recentMessages.isNotEmpty) ...[
            Text('Recent Messages', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            ...whatsapp.recentMessages.map((m) => _buildChatBubble(m, context)),
          ],

          if (whatsapp.totalSent == 0 && whatsapp.totalReceived == 0 && whatsapp.recentMessages.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.chat_outlined, size: 64, color: AppColors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No WhatsApp messages yet',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final items = [
      _StatItem('Sent', whatsapp.totalSent, Icons.call_made, const Color(0xFF22C55E)),
      _StatItem('Received', whatsapp.totalReceived, Icons.call_received, const Color(0xFF3B82F6)),
      _StatItem('Unread', whatsapp.unread, Icons.mark_email_unread_outlined, const Color(0xFFF59E0B)),
      _StatItem(
        'Last Active',
        0,
        Icons.access_time,
        const Color(0xFF8B5CF6),
        subtitle: whatsapp.lastMessageAt != null ? formatDateShort(whatsapp.lastMessageAt) : 'N/A',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(10),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 20, color: item.color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle ?? item.value.toString(),
                    style: TextStyle(
                      fontSize: item.subtitle != null ? 14 : 22,
                      fontWeight: FontWeight.w700,
                      color: item.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendChart() {
    final maxY = whatsapp.trend.fold<double>(0, (prev, e) {
      final sent = (e.sent ?? 0).toDouble();
      final received = (e.received ?? 0).toDouble();
      final total = e.count.toDouble();
      final m = [sent, received, total].fold<double>(0, (a, b) => a > b ? a : b);
      return m > prev ? m : prev;
    });

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
                        if (idx < 0 || idx >= whatsapp.trend.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _shortMonth(whatsapp.trend[idx].month),
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
                  // Sent line
                  LineChartBarData(
                    spots: whatsapp.trend.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value.sent ?? e.value.count).toDouble());
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
                  ),
                  // Received line
                  LineChartBarData(
                    spots: whatsapp.trend.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value.received ?? 0).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF22C55E), 'Sent'),
              const SizedBox(width: 20),
              _legendDot(const Color(0xFF3B82F6), 'Received'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildChatBubble(InsightWhatsAppMessage msg, BuildContext context) {
    final isInbound = msg.isInbound;
    return Align(
      alignment: isInbound ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isInbound ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isInbound ? 4 : 16),
            bottomRight: Radius.circular(isInbound ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: isInbound ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              msg.body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.timestamp != null ? formatDate(msg.timestamp) : '',
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _shortMonth(String month) {
    if (month.length >= 3) return month.substring(0, 3);
    return month;
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  _StatItem(this.label, this.value, this.icon, this.color, {this.subtitle});
}
