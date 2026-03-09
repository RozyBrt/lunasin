import 'package:flutter/material.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../data/models/debt.dart';
import '../../core/services/notification_service.dart';

class DebtProvider with ChangeNotifier {
  final DebtRepository _repository;
  final NotificationService _notificationService;

  List<Debt> _debts = [];

  DebtProvider({
    required DebtRepository repository,
    required NotificationService notificationService,
  }) : _repository = repository,
       _notificationService = notificationService;

  List<Debt> get debts => _debts;

  double get totalDebt =>
      _debts.where((d) => !d.isPaid).fold(0, (sum, item) => sum + item.amount);

  Future<void> init() async {
    _debts = await _repository.getDebts();

    // Schedule notifications for all existing debts with due dates
    for (var debt in _debts) {
      await _notificationService.scheduleDebtReminder(debt);
    }

    notifyListeners();
  }

  Future<void> addDebt(Debt debt) async {
    await _repository.addDebt(debt);
    _debts = await _repository.getDebts();

    // Schedule notification for the new debt (Hive key will be available after add)
    await _notificationService.scheduleDebtReminder(debt);

    notifyListeners();
  }

  Future<void> togglePaid(int index) async {
    await _repository.togglePaid(index);
    _debts = await _repository.getDebts();

    // Update notifications (cancel if paid, schedule if unpaid)
    // We use the updated debt from the list since togglePaid modifies it.
    await _notificationService.scheduleDebtReminder(_debts[index]);

    notifyListeners();
  }

  Future<void> updateDebt(int index, Debt updatedDebt) async {
    await _repository.updateDebt(index, updatedDebt);
    _debts = await _repository.getDebts();

    // Reschedule notifications with updated data
    await _notificationService.scheduleDebtReminder(updatedDebt);

    notifyListeners();
  }

  Future<void> deleteDebt(int index) async {
    final debt = _debts[index];
    // Cancel notifications before deleting
    await _notificationService.cancelDebtNotifications(debt);

    await _repository.deleteDebt(index);
    _debts = await _repository.getDebts();

    notifyListeners();
  }
}
