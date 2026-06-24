class ActivityLog {
  final int? id;
  final String roomName;
  final String eventType;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityLog({
    this.id,
    required this.roomName,
    required this.eventType,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as int?,
      roomName: json['room_name'] as String,
      eventType: json['event_type'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'room_name': roomName,
      'event_type': eventType,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
