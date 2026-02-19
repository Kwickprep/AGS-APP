import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/permissions/permission_manager.dart';
import 'analytics_bloc.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsBloc? _bloc;
  late DateTimeRange _dateRange;
  bool _accessDenied = false;

  @override
  void initState() {
    super.initState();

    // Route guard — hidden for EMPLOYEE + CUSTOMER (matches web)
    if (PermissionManager().isRouteHidden('/whatsapp/analytics')) {
      _accessDenied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Admin only.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
      return;
    }

    _bloc = AnalyticsBloc();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    _loadData();
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  void _loadData() {
    if (_bloc == null) return;
    final fmt = DateFormat('yyyy-MM-dd');
    _bloc!.add(LoadAnalytics(
      fromDate: fmt.format(_dateRange.start),
      toDate: fmt.format(_dateRange.end),
    ));
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fmt = DateFormat('MMM d');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('WhatsApp Analytics'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: BlocProvider.value(
        value: _bloc!,
        child: Column(
          children: [
            // Date range bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.white,
              child: InkWell(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${fmt.format(_dateRange.start)} - ${fmt.format(_dateRange.end)}',
                        style: AppTextStyles.button,
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
                builder: (context, state) {
                  if (state is AnalyticsLoading || state is AnalyticsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is AnalyticsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
                          const SizedBox(height: 16),
                          Text(state.message, style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = (state as AnalyticsLoaded).data;
                  return RefreshIndicator(
                    onRefresh: () async => _loadData(),
                    child: _buildAnalyticsContent(data),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(Map<String, dynamic> data) {
    final overview = data['overview'] as Map<String, dynamic>? ?? {};
    final dailyVolume = data['dailyVolume'] as List<dynamic>? ?? [];
    final hourlyByDirection = data['hourlyByDirection'] as List<dynamic>? ?? [];
    final hourlyDistribution = data['hourlyDistribution'] as List<dynamic>? ?? [];
    final statusDistribution = data['statusDistribution'] as Map<String, dynamic>? ?? {};
    final topContacts = data['topContacts'] as List<dynamic>? ?? [];
    final campaignPerformance = data['campaignPerformance'] as List<dynamic>? ?? [];
    final recentFailures = data['recentFailures'] as List<dynamic>? ?? [];
    final responseTimeDistribution = data['responseTimeDistribution'] as List<dynamic>? ?? [];
    final dayOfWeekPerformance = data['dayOfWeekPerformance'] as List<dynamic>? ?? [];
    final templateVsCustom = data['templateVsCustom'] as Map<String, dynamic>? ?? {};
    final newVsReturning = data['newVsReturning'] as List<dynamic>? ?? [];
    final mediaTypePerformance = data['mediaTypePerformance'] as List<dynamic>? ?? [];
    final campaignSaturation = data['campaignSaturation'] as List<dynamic>? ?? [];
    final unrespondedMessages = data['unrespondedMessages'] as List<dynamic>? ?? [];
    final optOutTrend = data['optOutTrend'] as List<dynamic>? ?? [];
    final autoReplyHits = data['autoReplyHits'] as List<dynamic>? ?? [];
    final hourly = hourlyByDirection.isNotEmpty ? hourlyByDirection : hourlyDistribution;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI Cards (12 cards, 2 per row)
        _buildKpiSection(overview),
        const SizedBox(height: 24),

        // Status Distribution Pie Chart
        if (statusDistribution.isNotEmpty) ...[
          _buildSectionTitle('Status Distribution', 'Breakdown of outbound message statuses'),
          const SizedBox(height: 12),
          _buildStatusPieChart(statusDistribution),
          const SizedBox(height: 24),
        ],

        // Daily Volume Line Chart
        if (dailyVolume.isNotEmpty) ...[
          _buildSectionTitle('Daily Volume', 'Inbound (green) and outbound (blue) messages per day'),
          const SizedBox(height: 12),
          _buildDailyVolumeChart(dailyVolume),
          const SizedBox(height: 24),
        ],

        // Response Time Distribution
        if (responseTimeDistribution.isNotEmpty) ...[
          _buildSectionTitle('Response Time Distribution', 'How quickly you respond to inbound messages'),
          const SizedBox(height: 12),
          _buildResponseTimeChart(responseTimeDistribution),
          const SizedBox(height: 24),
        ],

        // Opt-out Trend
        if (optOutTrend.isNotEmpty) ...[
          _buildSectionTitle('Opt-out Trend', 'Daily STOP messages — rising trends indicate over-messaging'),
          const SizedBox(height: 12),
          _buildOptOutTrendChart(optOutTrend),
          const SizedBox(height: 24),
        ],

        // Hourly Distribution (split by direction)
        if (hourly.isNotEmpty) ...[
          _buildSectionTitle('Peak Hours', 'Message volume by hour of day'),
          const SizedBox(height: 12),
          _buildHourlyChart(hourly),
          const SizedBox(height: 24),
        ],

        // Day-of-Week Performance
        if (dayOfWeekPerformance.isNotEmpty) ...[
          _buildSectionTitle('Day-of-Week Performance', 'Delivery % and read % by day of week'),
          const SizedBox(height: 12),
          _buildDayOfWeekChart(dayOfWeekPerformance),
          const SizedBox(height: 24),
        ],

        // Template vs Custom
        if (templateVsCustom.isNotEmpty) ...[
          _buildSectionTitle('Template vs Custom', 'Compare template and custom message performance'),
          const SizedBox(height: 12),
          _buildTemplateVsCustomCard(templateVsCustom),
          const SizedBox(height: 24),
        ],

        // New vs Returning Contacts
        if (newVsReturning.isNotEmpty) ...[
          _buildSectionTitle('New vs Returning Contacts', 'New contacts (created that day) vs returning per day'),
          const SizedBox(height: 12),
          _buildNewVsReturningChart(newVsReturning),
          const SizedBox(height: 24),
        ],

        // Top Contacts
        if (topContacts.isNotEmpty) ...[
          _buildSectionTitle('Top Contacts', 'Most active contacts by message count'),
          const SizedBox(height: 12),
          _buildTopContacts(topContacts),
          const SizedBox(height: 24),
        ],

        // Campaign Performance
        if (campaignPerformance.isNotEmpty) ...[
          _buildSectionTitle('Campaign Performance', 'Per-campaign delivery metrics'),
          const SizedBox(height: 12),
          _buildCampaignPerformance(campaignPerformance),
          const SizedBox(height: 24),
        ],

        // Media Type Performance
        if (mediaTypePerformance.isNotEmpty) ...[
          _buildSectionTitle('Media Type Performance', 'Delivery & read rates by message type'),
          const SizedBox(height: 12),
          _buildMediaTypePerformance(mediaTypePerformance),
          const SizedBox(height: 24),
        ],

        // Campaign Saturation
        if (campaignSaturation.isNotEmpty) ...[
          _buildSectionTitle('Campaign Saturation', 'Top contacts receiving the most campaign messages'),
          const SizedBox(height: 12),
          _buildCampaignSaturation(campaignSaturation),
          const SizedBox(height: 24),
        ],

        // Auto-Reply Performance
        if (autoReplyHits.isNotEmpty) ...[
          _buildSectionTitle('Auto-Reply Performance', 'Which auto-reply rules triggered most'),
          const SizedBox(height: 12),
          _buildAutoReplyHits(autoReplyHits),
          const SizedBox(height: 24),
        ],

        // Unresponded Messages
        if (unrespondedMessages.isNotEmpty) ...[
          _buildSectionTitle('Unresponded Messages', 'Inbound messages with no reply in 24h — needs attention!'),
          const SizedBox(height: 12),
          _buildUnrespondedMessages(unrespondedMessages),
          const SizedBox(height: 24),
        ],

        // Recent Failures
        if (recentFailures.isNotEmpty) ...[
          _buildSectionTitle('Recent Failures', 'Last 20 failed messages with error details'),
          const SizedBox(height: 12),
          _buildRecentFailures(recentFailures),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, [String? subtitle]) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading3),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle, style: AppTextStyles.caption),
                ),
            ],
          ),
        ),
        if (subtitle != null)
          Tooltip(
            message: subtitle,
            child: const Icon(Icons.info_outline, size: 16, color: AppColors.textLight),
          ),
      ],
    );
  }

  Widget _buildKpiSection(Map<String, dynamic> overview) {
    final kpis = <_KpiData>[
      _KpiData('Total Messages', '${overview['totalMessages'] ?? 0}', Icons.message),
      _KpiData('Delivery Rate', '${overview['deliveryRate'] ?? 0}%', Icons.check_circle_outline),
      _KpiData('Read Rate', '${overview['readRate'] ?? 0}%', Icons.done_all),
      _KpiData('Failed', '${overview['failedCount'] ?? 0}', Icons.error_outline, isAlert: (overview['failedCount'] ?? 0) > 0),
      _KpiData('Avg Response', '${overview['avgResponseTimeMinutes'] ?? '-'} min', Icons.timer),
      _KpiData('Active Contacts', '${overview['activeContacts'] ?? 0}', Icons.people),
      _KpiData('New Contacts', '${overview['newContacts'] ?? 0}', Icons.person_add),
      _KpiData('Opt-outs', '${overview['optOuts'] ?? 0}', Icons.block),
      _KpiData('Unresponded', '${overview['unrespondedCount'] ?? 0}', Icons.mark_chat_unread, isAlert: (overview['unrespondedCount'] ?? 0) > 0),
      _KpiData('Trigger Match', '${overview['triggerMatchRate'] ?? 0}%', Icons.auto_fix_high),
      _KpiData('Reply Rate', '${overview['replyRate'] ?? 0}%', Icons.reply_all),
      _KpiData('Avg Read Time', '${overview['avgReadTimeMinutes'] ?? '-'} min', Icons.visibility),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: kpi.isAlert ? Border.all(color: AppColors.error.withValues(alpha: 0.3)) : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
            ],
          ),
          child: Row(
            children: [
              Icon(kpi.icon, color: kpi.isAlert ? AppColors.error : AppColors.primary, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kpi.value, style: kpi.isAlert ? AppTextStyles.heading3.copyWith(color: AppColors.error) : AppTextStyles.heading3),
                    Text(kpi.label, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPieChart(Map<String, dynamic> distribution) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      Colors.blue,
      AppColors.error,
      Colors.orange,
      AppColors.textLight,
    ];

    final entries = distribution.entries.toList();
    final total = entries.fold<num>(0, (sum, e) => sum + (e.value as num));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((e) {
                    final value = (e.value.value as num).toDouble();
                    return PieChartSectionData(
                      value: value,
                      title: '${(value / total * 100).toStringAsFixed(0)}%',
                      color: colors[e.key % colors.length],
                      radius: 60,
                      titleStyle: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[e.key % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${e.value.key} (${e.value.value})', style: AppTextStyles.caption),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyVolumeChart(List<dynamic> dailyVolume) {
    final inboundSpots = <FlSpot>[];
    final outboundSpots = <FlSpot>[];

    for (int i = 0; i < dailyVolume.length; i++) {
      final day = dailyVolume[i] as Map<String, dynamic>;
      inboundSpots.add(FlSpot(i.toDouble(), (day['inbound'] as num? ?? 0).toDouble()));
      outboundSpots.add(FlSpot(i.toDouble(), (day['outbound'] as num? ?? 0).toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: inboundSpots,
                isCurved: true,
                color: AppColors.success,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppColors.success.withValues(alpha: 0.1)),
              ),
              LineChartBarData(
                spots: outboundSpots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseTimeChart(List<dynamic> data) {
    return _buildCardContainer(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < data.length) {
                      final bucket = data[idx] as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(bucket['bucket'] ?? '', style: AppTextStyles.caption.copyWith(fontSize: 9)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((e) {
              final item = e.value as Map<String, dynamic>;
              final colors = [AppColors.success, Colors.blue, Colors.orange, Colors.purple, AppColors.error];
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (item['count'] as num? ?? 0).toDouble(),
                    color: colors[e.key % colors.length],
                    width: 28,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOptOutTrendChart(List<dynamic> data) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final item = data[i] as Map<String, dynamic>;
      spots.add(FlSpot(i.toDouble(), (item['count'] as num? ?? 0).toDouble()));
    }

    return _buildCardContainer(
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.error,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppColors.error.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyChart(List<dynamic> hourlyDistribution) {
    final hasDirection = hourlyDistribution.isNotEmpty && hourlyDistribution[0] is Map && (hourlyDistribution[0] as Map).containsKey('inbound');

    return _buildCardContainer(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() % 4 == 0) {
                      return Text('${value.toInt()}h', style: AppTextStyles.caption);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: hourlyDistribution.asMap().entries.map((e) {
              if (hasDirection) {
                final item = e.value as Map<String, dynamic>;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: (item['outbound'] as num? ?? 0).toDouble(),
                      color: Colors.blue,
                      width: 5,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                    BarChartRodData(
                      toY: (item['inbound'] as num? ?? 0).toDouble(),
                      color: AppColors.success,
                      width: 5,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ],
                );
              } else {
                final count = (e.value as num? ?? 0).toDouble();
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: count,
                      color: AppColors.primary,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDayOfWeekChart(List<dynamic> data) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return _buildCardContainer(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < dayNames.length) {
                      return Text(dayNames[idx], style: AppTextStyles.caption);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((e) {
              final item = e.value as Map<String, dynamic>;
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (item['deliveryRate'] as num? ?? 0).toDouble(),
                    color: Colors.blue,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                  BarChartRodData(
                    toY: (item['readRate'] as num? ?? 0).toDouble(),
                    color: AppColors.success,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateVsCustomCard(Map<String, dynamic> data) {
    final template = data['template'] as Map<String, dynamic>? ?? {};
    final custom = data['custom'] as Map<String, dynamic>? ?? {};

    return _buildCardContainer(
      child: Column(
        children: [
          _buildComparisonRow('Total', '${template['total'] ?? 0}', '${custom['total'] ?? 0}'),
          _buildComparisonRow('Delivery %', '${template['deliveredRate'] ?? 0}%', '${custom['deliveredRate'] ?? 0}%'),
          _buildComparisonRow('Read %', '${template['readRate'] ?? 0}%', '${custom['readRate'] ?? 0}%'),
          _buildComparisonRow('Failed', '${template['failed'] ?? 0}', '${custom['failed'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String templateVal, String customVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  Text(templateVal, style: AppTextStyles.button.copyWith(color: Colors.blue)),
                  Text('Template', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ]),
                Column(children: [
                  Text(customVal, style: AppTextStyles.button.copyWith(color: Colors.orange)),
                  Text('Custom', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewVsReturningChart(List<dynamic> data) {
    return _buildCardContainer(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((e) {
              final item = e.value as Map<String, dynamic>;
              return BarChartGroupData(
                x: e.key,
                barsSpace: 0,
                barRods: [
                  BarChartRodData(
                    toY: ((item['new'] as num? ?? 0) + (item['returning'] as num? ?? 0)).toDouble(),
                    color: AppColors.success,
                    width: 8,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    rodStackItems: [
                      BarChartRodStackItem(0, (item['new'] as num? ?? 0).toDouble(), Colors.blue),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopContacts(List<dynamic> contacts) {
    return _buildListContainer(
      itemCount: contacts.length > 10 ? 10 : contacts.length,
      itemBuilder: (context, index) {
        final c = contacts[index] as Map<String, dynamic>;
        return ListTile(
          title: Text(c['name'] ?? c['phone'] ?? 'Unknown', style: AppTextStyles.button),
          subtitle: Text('In: ${c['inbound'] ?? 0} | Out: ${c['outbound'] ?? 0}', style: AppTextStyles.caption),
          trailing: Text('${c['total'] ?? 0}', style: AppTextStyles.heading3),
        );
      },
    );
  }

  Widget _buildCampaignPerformance(List<dynamic> campaigns) {
    return _buildListContainer(
      itemCount: campaigns.length > 10 ? 10 : campaigns.length,
      itemBuilder: (context, index) {
        final c = campaigns[index] as Map<String, dynamic>;
        return ListTile(
          title: Text(c['name'] ?? 'Unknown', style: AppTextStyles.button),
          subtitle: Text(
            'Delivered: ${c['deliveredPercent'] ?? 0}% | Read: ${c['readPercent'] ?? 0}% | Failed: ${c['failedPercent'] ?? 0}%',
            style: AppTextStyles.caption,
          ),
        );
      },
    );
  }

  Widget _buildMediaTypePerformance(List<dynamic> data) {
    return _buildListContainer(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index] as Map<String, dynamic>;
        return ListTile(
          title: Text(_capitalize(item['type'] ?? 'text'), style: AppTextStyles.button),
          subtitle: Text(
            'Total: ${item['total'] ?? 0} | Delivery: ${item['deliveredRate'] ?? 0}% | Read: ${item['readRate'] ?? 0}%',
            style: AppTextStyles.caption,
          ),
          trailing: Text('${item['total'] ?? 0}', style: AppTextStyles.heading3),
        );
      },
    );
  }

  Widget _buildCampaignSaturation(List<dynamic> data) {
    return _buildListContainer(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index] as Map<String, dynamic>;
        final count = item['campaignMessageCount'] as num? ?? 0;
        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: count > 10 ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
            child: Text('${index + 1}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          ),
          title: Text(item['name'] ?? 'Unknown', style: AppTextStyles.button),
          subtitle: Text(item['phone'] ?? '', style: AppTextStyles.caption),
          trailing: Text('$count msgs', style: AppTextStyles.button.copyWith(color: count > 10 ? AppColors.error : AppColors.textPrimary)),
        );
      },
    );
  }

  Widget _buildAutoReplyHits(List<dynamic> data) {
    return _buildListContainer(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index] as Map<String, dynamic>;
        return ListTile(
          title: Text(item['name'] ?? '', style: AppTextStyles.button),
          subtitle: Text('Trigger: "${item['userMessage'] ?? ''}"', style: AppTextStyles.caption),
          trailing: Text('${item['count'] ?? 0}x', style: AppTextStyles.heading3),
        );
      },
    );
  }

  Widget _buildUnrespondedMessages(List<dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = data[index] as Map<String, dynamic>;
          return ListTile(
            tileColor: AppColors.error.withValues(alpha: 0.03),
            leading: const Icon(Icons.mark_chat_unread, color: AppColors.error, size: 20),
            title: Text(item['userName'] ?? 'Unknown', style: AppTextStyles.button),
            subtitle: Text(
              '${item['content'] ?? ''}'.length > 60 ? '${(item['content'] ?? '').toString().substring(0, 60)}...' : '${item['content'] ?? ''}',
              style: AppTextStyles.caption,
            ),
            trailing: Text(_formatTime(item['createdAt']), style: AppTextStyles.caption),
          );
        },
      ),
    );
  }

  Widget _buildRecentFailures(List<dynamic> failures) {
    return _buildListContainer(
      itemCount: failures.length > 10 ? 10 : failures.length,
      itemBuilder: (context, index) {
        final f = failures[index] as Map<String, dynamic>;
        return ListTile(
          tileColor: AppColors.error.withValues(alpha: 0.03),
          leading: const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          title: Text(f['user'] ?? f['phone'] ?? 'Unknown', style: AppTextStyles.button),
          subtitle: Text(f['failureReason'] ?? 'Unknown error', style: AppTextStyles.caption),
          trailing: Text(
            _formatTime(f['failedAt'] ?? f['createdAt']),
            style: AppTextStyles.caption,
          ),
        );
      },
    );
  }

  // --- Shared card/list helpers ---

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: child,
    );
  }

  Widget _buildListContainer({required int itemCount, required Widget Function(BuildContext, int) itemBuilder}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: itemBuilder,
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    try {
      return DateFormat('MMM d, HH:mm').format(DateTime.parse(time.toString()));
    } catch (_) {
      return time.toString();
    }
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final bool isAlert;

  _KpiData(this.label, this.value, this.icon, {this.isAlert = false});
}
