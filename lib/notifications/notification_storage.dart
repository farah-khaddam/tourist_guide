import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'notification_model.dart';

class NotificationStorage {
  static const String boxName = 'app_notifications';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NotificationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppNotificationAdapter());
    }
    await Hive.openBox<AppNotification>(boxName);
  }

  static Box<AppNotification> _box() => Hive.box<AppNotification>(boxName);

  static Future<void> add(AppNotification notification) async {
    await _box().put(notification.id, notification);
  }

  static List<AppNotification> getAllDesc() {
    final List<AppNotification> items = _box().values.toList();
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return items;
  }

  static ValueListenable<Box<AppNotification>> listenable() {
    return _box().listenable();
  }

  static Future<void> clear() async {
    await _box().clear();
  }
}
