import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/models/debt.dart';
import '../providers/debt_provider.dart';
import '../../core/services/pdf_service.dart';

class ReportPage extends StatelessWidget {
  final DebtProvider provider;

  const ReportPage({super.key, required this.provider});

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final debts = provider.debts;
    final totalAktif = debts.where((d) => !d.isPaid).fold(0.0, (sum, item) => sum + item.amount);
    final totalLunas = debts.where((d) => d.isPaid).fold(0.0, (sum, item) => sum + item.amount);
    final totalSemua = totalAktif + totalLunas;

    // Persentase
    final activePercent = totalSemua > 0 ? (totalAktif / totalSemua) * 100 : 0.0;
    final paidPercent = totalSemua > 0 ? (totalLunas / totalSemua) * 100 : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Laporan & Statistik', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF6366F1)),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sedang menyiapkan laporan PDF...'),
                  duration: Duration(seconds: 2),
                ),
              );
              await PdfService.generateAndShareDebtReport(debts);
            },
            tooltip: 'Ekspor PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(totalAktif, totalLunas),
            const SizedBox(height: 32),
            const Text(
              'Rasio Pelunasan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: totalAktif,
                      title: '${activePercent.toStringAsFixed(1)}%',
                      color: const Color(0xFFEF4444),
                      radius: 50,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: totalLunas,
                      title: '${paidPercent.toStringAsFixed(1)}%',
                      color: const Color(0xFF22C55E),
                      radius: 50,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Daftar Per Orangan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPersonStats(debts),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(double aktif, double lunas) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildRowStat('Belum Dibayar', _formatRupiah(aktif), Colors.red),
          const Divider(height: 24),
          _buildRowStat('Sudah Dibayar', _formatRupiah(lunas), Colors.green),
        ],
      ),
    );
  }

  Widget _buildRowStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildPersonStats(List<Debt> debts) {
    final Map<String, double> personMap = {};
    for (var d in debts) {
      if (!d.isPaid) {
        personMap[d.name] = (personMap[d.name] ?? 0) + d.amount;
      }
    }

    final sortedList = personMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedList.isEmpty) {
      return const Center(child: Text('Tidak ada hutang aktif', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: sortedList.take(5).map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
              child: Text(e.key[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(_formatRupiah(e.value), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }
}
