import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/models/debt.dart';
import 'presentation/providers/debt_provider.dart';
import 'presentation/pages/home_screen.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/hive_debt_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await initializeDateFormatting('id_ID', null);
  Hive.registerAdapter(DebtAdapter());

  final notificationService = NotificationService();
  final debtRepository = HiveDebtRepository();

  // Create provider instance but don't block everything with its init
  final debtProvider = DebtProvider(
    repository: debtRepository,
    notificationService: notificationService,
  );

  // Run notification and provider initialization in parallel
  await Future.wait([notificationService.initialize(), debtProvider.init()]);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: debtProvider)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catat Utang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      ),
      home: const HomeScreen(),
    );
  }
}
