import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class ChartsTab extends StatefulWidget {
  final String? userId;

  const ChartsTab({super.key, required this.userId});

  @override
  State<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<ChartsTab> {
  String period = "weekly";
  bool loading = true;
  TaskStats? stats;
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    if (widget.userId == null) {
      setState(() => loading = false);
      return;
    }

    setState(() {
      loading = true;
      touchedIndex = null;
    });

    final data = await DashboardService.getTaskStats(widget.userId!, period);
    setState(() {
      stats = data;
      loading = false;
    });
  }

  List<_SliceInfo> get slices {
    if (stats == null) return [];
    return [
      _SliceInfo("Completed", stats!.taken, Colors.green),
      _SliceInfo("Pending", stats!.pending, Colors.orange),
      _SliceInfo("Other", stats!.skipped, Colors.red),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Medication Stats",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _periodButton("Weekly", "weekly"),
              _periodButton("Monthly", "monthly"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (loading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (stats == null)
          const Expanded(
            child: Center(child: Text("Could not load chart data")),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _summaryRow(),
                  const SizedBox(height: 20),
                  _touchInfoCard(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: _buildPieChart(),
                  ),
                  const SizedBox(height: 16),
                  _legend(),
                  const SizedBox(height: 8),
                  Text(
                    "Tap a slice to see details",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _periodButton(String label, String value) {
    final selected = period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => period = value);
          await loadStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0D47A1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow() {
    return Row(
      children: [
        _summaryChip("Completed", stats!.taken, Colors.green),
        const SizedBox(width: 8),
        _summaryChip("Pending", stats!.pending, Colors.orange),
        const SizedBox(width: 8),
        _summaryChip("Other", stats!.skipped, Colors.red),
      ],
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _touchInfoCard() {
    final total = stats!.taken + stats!.pending + stats!.skipped;

    if (touchedIndex == null || touchedIndex! >= slices.length) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          total == 0
              ? "No tasks in this period"
              : "Total tasks: $total — tap a slice for breakdown",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    final slice = slices[touchedIndex!];
    final percent = total == 0 ? 0 : ((slice.value / total) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: slice.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: slice.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            slice.label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: slice.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${slice.value} tasks ($percent%)",
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final data = slices.where((s) => s.value > 0).toList();
    final total = stats!.taken + stats!.pending + stats!.skipped;

    if (total == 0) {
      return const Center(child: Text("No data for this period"));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 48,
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: (event, response) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response == null ||
                  response.touchedSection == null) {
                touchedIndex = null;
                return;
              }
              final index = response.touchedSection!.touchedSectionIndex;
              final nonZeroSlices = slices.where((s) => s.value > 0).toList();
              if (index >= 0 && index < nonZeroSlices.length) {
                final label = nonZeroSlices[index].label;
                touchedIndex = slices.indexWhere((s) => s.label == label);
              }
            });
          },
        ),
        sections: _buildSections(data, total),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(List<_SliceInfo> data, int total) {
    return List.generate(data.length, (index) {
      final slice = data[index];
      final isTouched = touchedIndex != null &&
          slices[touchedIndex!].label == slice.label;
      final percent = ((slice.value / total) * 100).round();

      return PieChartSectionData(
        value: slice.value.toDouble(),
        color: slice.color,
        radius: isTouched ? 72 : 62,
        title: "$percent%",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _legend() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: Colors.green, label: "Completed"),
        SizedBox(width: 16),
        _LegendDot(color: Colors.orange, label: "Pending"),
        SizedBox(width: 16),
        _LegendDot(color: Colors.red, label: "Other"),
      ],
    );
  }
}

class _SliceInfo {
  final String label;
  final int value;
  final Color color;

  _SliceInfo(this.label, this.value, this.color);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
