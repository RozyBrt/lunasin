import 'package:flutter/material.dart';
import '../../../data/models/debt.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_item.dart';
import '../report_page.dart';

class DashboardSection extends StatelessWidget {
  final DebtProvider provider;
  final double totalAktif;
  final double totalLunas;
  final int recentDurationHours;
  final String Function(double) formatRupiah;
  final VoidCallback onViewAll;
  final Function(BuildContext, {Debt? debt, int? index}) onEdit;
  final Function(BuildContext, Debt debt) onShowDetail;

  const DashboardSection({
    super.key,
    required this.provider,
    required this.totalAktif,
    required this.totalLunas,
    required this.recentDurationHours,
    required this.formatRupiah,
    required this.onViewAll,
    required this.onEdit,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'LUNASIN',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          // MODIFIKASI: Tombol Laporan
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPage(provider: provider),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lihat Laporan & Statistik',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Analisis hutang & ekspor PDF',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (provider.debts.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text(
              'Kumpulan dosa kalo ga dibayar 😈',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            "Total Yang Harus Dibayar: ${formatRupiah(totalAktif)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'BELUM DIBAYAR',
                  amount: formatRupiah(totalAktif),
                  bgColor: const Color(0xFFFEE2E2),
                  textColor: const Color(0xFF991B1B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'TOTAL SUDAH DIBAYAR',
                  amount: formatRupiah(totalLunas),
                  bgColor: const Color(0xFFDCFCE7),
                  textColor: const Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catatan Pinjaman Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final now = DateTime.now();
              final recentItems = provider.debts
                  .asMap()
                  .entries
                  .where(
                    (e) =>
                        now.difference(e.value.date).inHours <
                        recentDurationHours,
                  )
                  .toList()
                  .reversed
                  .toList();

              if (recentItems.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Tidak ada catatan dalam $recentDurationHours jam terakhir",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentItems.length > 5 ? 5 : recentItems.length,
                itemBuilder: (context, index) {
                  final entry = recentItems[index];
                  return TransactionItem(
                    debt: entry.value,
                    index: entry.key,
                    provider: provider,
                    onEdit: onEdit,
                    onShowDetail: onShowDetail,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
