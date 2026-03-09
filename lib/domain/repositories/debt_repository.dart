import '../../data/models/debt.dart';

abstract class DebtRepository {
  Future<List<Debt>> getDebts();
  Future<void> addDebt(Debt debt);
  Future<void> updateDebt(int index, Debt debt);
  Future<void> deleteDebt(int index);
  Future<void> togglePaid(int index);
}
