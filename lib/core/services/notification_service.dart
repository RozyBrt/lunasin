import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../data/models/debt.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  static String lastLog = "Not Initialized";

  static const int _scheduledIdRange = 0;
  static const int _instantIdRange = 100000;

  /// Inisialisasi penuh: timezone + sistem notifikasi.
  /// Aman dipanggil berkali-kali — notifikasi hanya diinisialisasi sekali,
  /// tapi timezone selalu di-refresh setiap kali dipanggil.
  Future<bool> initialize() async {
    try {
      // 1. Selalu refresh timezone setiap kali initialize dipanggil
      await _refreshTimezone();

      // 2. Inisialisasi sistem notifikasi (hanya sekali)
      if (!_notificationsInitialized) {
        const androidSettings = AndroidInitializationSettings('notif_icon');
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _notifications.initialize(initSettings);

        try {
          await _requestPermissions();
          lastLog = "Initialized & Permissions Requested";
        } catch (e) {
          lastLog = "Initialized, but Permission Request Failed: $e";
          debugPrint("Minor: Permission request failed: $e");
        }

        _notificationsInitialized = true;
        debugPrint("NotificationService fully initialized.");
      }

      return true;
    } catch (e) {
      lastLog = "FATAL Error: $e";
      debugPrint("FATAL: Notification initialization failed: $e");
      return false;
    }
  }

  /// Refresh timezone dari sistem OS tanpa perlu reinit notifikasi.
  /// Dipanggil saat app resume agar timezone selalu up-to-date.
  Future<void> refreshTimezone() async {
    await _refreshTimezone();
  }

  Future<void> _refreshTimezone() async {
    try {
      // Inisialisasi database timezone (idempoten, aman dipanggil berkali-kali)
      tz.initializeTimeZones();

      // flutter_timezone membaca IANA timezone name langsung dari OS
      // Contoh: "Asia/Jakarta", "Asia/Makassar", "America/New_York"
      // Jauh lebih akurat daripada parsing DateTime.now().timeZoneName
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final String tzName = tzInfo.identifier;
      tz.setLocalLocation(tz.getLocation(tzName));

      lastLog = "Success (TZ: $tzName)";
      debugPrint("Timezone refreshed: $tzName");
    } catch (e) {
      // Fallback ke Asia/Jakarta jika gagal (misal emulator tanpa timezone)
      const fallback = 'Asia/Jakarta';
      try {
        tz.setLocalLocation(tz.getLocation(fallback));
      } catch (_) {}
      lastLog = "TZ Error (fallback: $fallback): $e";
      debugPrint("Timezone refresh error, fallback to $fallback: $e");
    }
  }

  Future<bool?> _requestPermissions() async {
    return await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDebtReminder(Debt debt, [int? fallbackId]) async {
    if (debt.dueDate == null || debt.isPaid) {
      await cancelDebtNotifications(debt);
      return;
    }

    final int baseId = (debt.key is int)
        ? (debt.key as int)
        : (fallbackId ?? 0);
    final now = DateTime.now();
    final dueDate = debt.dueDate!;

    await _cancelById(baseId);

    final schedules = [
      {'days': 3, 'title': '3 Hari Lagi!'},
      {'days': 1, 'title': 'Besok Jatuh Tempo!'},
      {'days': 0, 'title': 'Hari Ini Jatuh Tempo!'},
    ];

    for (var s in schedules) {
      final daysBefore = s['days'] as int;
      DateTime notifDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - daysBefore,
        9,
        0,
      );

      if (notifDate.isBefore(now)) {
        final eveningRescue = DateTime(now.year, now.month, now.day, 19, 0);
        bool isSameDayAsNotif =
            notifDate.year == now.year &&
            notifDate.month == now.month &&
            notifDate.day == now.day;

        if (isSameDayAsNotif && eveningRescue.isAfter(now)) {
          notifDate = eveningRescue;
        }
      }

      if (notifDate.isAfter(now)) {
        final finalId = _generateId(baseId, daysBefore);
        await _notifications.zonedSchedule(
          finalId,
          s['title'] as String,
          'Ke ${debt.name}: ${_formatCurrency(debt.amount)}',
          tz.TZDateTime.from(notifDate, tz.local),
          _notifDetails('debt_reminders', 'Pengingat Hutang'),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelDebtNotifications(Debt debt) async {
    if (debt.key is int) {
      await _cancelById(debt.key as int);
    }
  }

  Future<void> _cancelById(int baseId) async {
    for (int i = 0; i <= 3; i++) {
      await _notifications.cancel(_generateId(baseId, i));
    }
  }

  int _generateId(int baseId, int offset) {
    return _scheduledIdRange + (baseId * 10) + offset;
  }

  Future<void> showInstantNotification(String title, String body) async {
    try {
      if (!_notificationsInitialized) {
        lastLog = "Not initialized, trying now...";
        final ok = await initialize();
        if (!ok) {
          lastLog = "Auto-init failed";
          return;
        }
      }

      final int instantId =
          _instantIdRange + (DateTime.now().millisecondsSinceEpoch % 10000);
      lastLog = "Showing notif: $instantId";

      await _notifications.show(
        instantId,
        title,
        body,
        _notifDetails(
          'instant_notifications',
          'Notifikasi Instan',
          importance: Importance.max,
        ),
      );
      lastLog = "Show called successfully";
    } catch (e) {
      lastLog = "Show error: $e";
      debugPrint("Error showing notification: $e");
    }
  }

  NotificationDetails _notifDetails(
    String id,
    String name, {
    Importance importance = Importance.high,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        id,
        name,
        channelDescription: 'Pemberitahuan aplikasi',
        importance: importance,
        priority: Priority.max,
        icon: 'notif_icon',
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> cancelAll() async => await _notifications.cancelAll();
}
