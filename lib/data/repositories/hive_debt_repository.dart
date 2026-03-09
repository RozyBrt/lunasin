import 'package:hive/hive.dart';
import '../../domain/repositories/debt_repository.dart';
import '../models/debt.dart';

class HiveDebtRepository implements DebtRepository {
  static const String _boxName = 'debts_box';

  @override
  Future<List<Debt>> getDebts() async {
    final box = await Hive.openBox<Debt>(_boxName);
    return box.values.toList();
  }

  @override
  Future<void> addDebt(Debt debt) async {
    final box = Hive.box<Debt>(_boxName);
    await box.add(debt);
  }

  @override
  Future<void> updateDebt(int index, Debt debt) async {
    final box = Hive.box<Debt>(_boxName);
    await box.putAt(index, debt);
  }

  @override
  Future<void> deleteDebt(int index) async {
    final box = Hive.box<Debt>(_boxName);
    await box.deleteAt(index);
  }

  @override
  Future<void> togglePaid(int index) async {
    final box = Hive.box<Debt>(_boxName);
    final debt = box.getAt(index);
    if (debt != null) {
      debt.markAsPaid(!debt.isPaid);
      await debt.save();
    }
  }
}
