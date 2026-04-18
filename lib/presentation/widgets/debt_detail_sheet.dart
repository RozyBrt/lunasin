import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../../data/models/debt.dart';

class DebtDetailSheet extends StatelessWidget {
  final Debt debt;
  final String Function(double) formatRupiah;

  const DebtDetailSheet({
    super.key,
    required this.debt,
    required this.formatRupiah,
  });

  Widget _buildDetailSection(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color ?? const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.isPaid ? "DIBAYAR LUNAS" : "STATUS: HUTANG",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: debt.isPaid
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(debt.amount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: debt.isPaid
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    debt.isPaid ? Icons.check_circle : Icons.timer_outlined,
                    color: debt.isPaid
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B),
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDetailSection(
              "Hutang Kepada",
              debt.name,
              Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              "Waktu Pinjam",
              DateFormat('dd MMMM yyyy HH:mm').format(debt.date),
              Icons.access_time,
            ),
            if (debt.isPaid && debt.paidDate != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                "Waktu Dibayar",
                DateFormat('dd MMMM yyyy HH:mm').format(debt.paidDate!),
                Icons.check_circle,
                color: Colors.green,
              ),
            ],
            if (!debt.isPaid && debt.dueDate != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                "Jatuh Tempo",
                DateFormat('dd MMMM yyyy').format(debt.dueDate!),
                Icons.event,
                color: debt.isPaid
                    ? null
                    : (debt.dueDate!.difference(DateTime.now()).inDays < 3
                          ? Colors.red
                          : null),
              ),
            ],
            if (debt.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection("Catatan", debt.note, Icons.notes_outlined),
            ],
            const SizedBox(height: 32),
            const Text(
              "Riwayat Perubahan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: debt.logs.length,
                itemBuilder: (context, i) {
                  final logStr = debt.logs[debt.logs.length - 1 - i];
                  final parts = logStr.split(' pada ');
                  String actionText = logStr;
                  String dateText = '';
                  if (parts.length > 1) {
                    dateText = parts.last;
                    actionText = parts
                        .sublist(0, parts.length - 1)
                        .join(' pada ');
                    try {
                      final parsedDate = DateTime.parse(dateText);
                      dateText = DateFormat(
                        'dd MMM yyyy HH:mm',
                      ).format(parsedDate);
                    } catch (_) {}
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2, right: 12),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history,
                            size: 14,
                            color: Colors.indigo,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                actionText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (dateText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    dateText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
