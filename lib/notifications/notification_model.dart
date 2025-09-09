import 'package:hive/hive.dart';

enum NotificationType { plain, event, location }

class AppNotification {
  final String id;
  final String? title;
  final String? body;
  final NotificationType type;
  final String? targetId;
  final DateTime receivedAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetId,
    required this.receivedAt,
  });

  factory AppNotification.fromFcmData({
    required String id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? receivedAt,
  }) {
    final String? rawType = (data?['type'] ?? data?['notification_type'])
        ?.toString();
    final String? rawId = (data?['id'] ?? data?['target_id'])?.toString();

    NotificationType parsedType = NotificationType.plain;
    if (rawType == 'event') parsedType = NotificationType.event;
    if (rawType == 'location' || rawType == 'place')
      parsedType = NotificationType.location;

    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: parsedType,
      targetId: rawId,
      receivedAt: receivedAt ?? DateTime.now(),
    );
  }
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 1;

  @override
  NotificationType read(BinaryReader reader) {
    final int value = reader.readByte();
    switch (value) {
      case 1:
        return NotificationType.event;
      case 2:
        return NotificationType.location;
      case 0:
      default:
        return NotificationType.plain;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.plain:
        writer.writeByte(0);
        break;
      case NotificationType.event:
        writer.writeByte(1);
        break;
      case NotificationType.location:
        writer.writeByte(2);
        break;
    }
  }
}

class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 2;

  @override
  AppNotification read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final Map<int, dynamic> fields = {
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppNotification(
      id: fields[0] as String,
      title: fields[1] as String?,
      body: fields[2] as String?,
      type: fields[3] as NotificationType,
      targetId: fields[4] as String?,
      receivedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.targetId)
      ..writeByte(5)
      ..write(obj.receivedAt);
  }
}
