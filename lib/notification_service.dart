import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'main.dart' show CubeItem, MealLog;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _channelId = 'topping_baby_food_channel';
  static const String _channelName = '또핑 이유식 알림';
  static const String _channelDesc = '재고 소진 임박 및 소비기한 안내 알림';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();
      
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
        );
        await androidImpl.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  NotificationDetails _buildNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
      ),
    );
  }

  Future<void> showInstantNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await init();
      await _notificationsPlugin.show(
        id,
        title,
        body,
        _buildNotificationDetails(),
        payload: payload,
      );
    } catch (e) {
      debugPrint('showInstantNotification error: $e');
    }
  }

  Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 9999,
      title: '🔔 또핑 알림이 정상 작동 중입니다',
      body: '큐브 재고 소진(3개 이하) 및 소비기한 D-1 임박 시 스마트 푸시가 발송됩니다.',
    );
  }

  Future<void> syncScheduledNotifications({
    required List<CubeItem> cubes,
    required List<MealLog> mealLogs,
    required SharedPreferences prefs,
  }) async {
    try {
      await init();

      final pushEnabled = prefs.getBool('push_enabled') ?? true;
      if (!pushEnabled) {
        await _notificationsPlugin.cancelAll();
        return;
      }

      final checkLowStock = prefs.getBool('push_low_stock') ?? true;
      final checkExpiry = prefs.getBool('push_expiry') ?? true;
      final hour = prefs.getInt('push_hour') ?? 9;
      final minute = prefs.getInt('push_minute') ?? 0;

      // 1. 소비기한 임박 큐브 확인 (D-1 또는 D-Day)
      final expiringCubes = cubes.where((c) {
        if (c.isPlannedOnly || c.quantity <= 0) return false;
        return c.daysRemaining <= 1;
      }).toList();

      // 2. 재고 소진 임박 큐브 확인 (3개 이하)
      final lowStockCubes = cubes.where((c) {
        if (c.isPlannedOnly || c.quantity <= 0) return false;
        return c.quantity <= 3;
      }).toList();

      // 알림 내용 조합
      String? alertTitle;
      String? alertBody;

      if (checkExpiry && expiringCubes.isNotEmpty) {
        final names = expiringCubes.map((c) => c.name).take(3).join(', ');
        final extra = expiringCubes.length > 3 ? ' 외 ${expiringCubes.length - 3}건' : '';
        alertTitle = '⏳ [$names$extra] 기한 만료 임박';
        alertBody = '소비기한이 1일 이내로 다가온 큐브가 있어요! 오늘 급여하거나 기한을 연장해주세요.';
      } else if (checkLowStock && lowStockCubes.isNotEmpty) {
        final names = lowStockCubes.map((c) => c.name).take(3).join(', ');
        final extra = lowStockCubes.length > 3 ? ' 외 ${lowStockCubes.length - 3}건' : '';
        alertTitle = '🥩 [$names$extra] 큐브 재고 소진 임박';
        alertBody = '잔여 수량이 3개 이하입니다. 다음 식단을 위해 큐브를 미리 준비해보세요!';
      }

      if (alertTitle == null || alertBody == null) {
        // 알림 필요 항목 없음
        await _notificationsPlugin.cancel(1001);
        return;
      }

      // 정기 알림 시간 계산 (내일 또는 오늘의 지정 시각)
      final scheduledTime = _nextInstanceOfTime(hour, minute);

      await _notificationsPlugin.zonedSchedule(
        1001,
        alertTitle,
        alertBody,
        scheduledTime,
        _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('syncScheduledNotifications error: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
