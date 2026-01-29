class Task {
  final String id;
  final String taskName;
  final String startTime;
  final String endTime;
  final String locationName;
  final String priority;
  final String status;
  final String lat;
  final String longg;
  final bool punchIn;
  final bool punchOut;
  final bool breakIn;
  final bool breakOut;
  final String day;
  final String date;
  final bool autoCheckin;
  final String totalWorkTime;

  Task({
    required this.id,
    required this.taskName,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.priority,
    required this.status,
    required this.lat,
    required this.longg,
    required this.punchIn,
    required this.punchOut,
    required this.breakIn,
    required this.breakOut,
    required this.day,
    required this.date,
    required this.autoCheckin,
    required this.totalWorkTime,
  });

  /// ✅ From API JSON
  factory Task.fromJson(Map<String, dynamic> json, {String? day, String? date}) {
    return Task(
      id: json['id'],
      taskName: json['task_name'],
      startTime: json['start_time'],
      endTime: json['end_time']??"",
      locationName: json['location_name'],
      priority: json['priority'],
      status: json['status'],
      lat: json['lat'],
      longg: json['long'],
      punchIn: json['punch_in'] == 1 || json['punch_in'] == true,
      punchOut: json['punch_out'] == 1 || json['punch_out'] == true,
      breakIn: json['break_in'] == 1 || json['break_in'] == true,
      breakOut: json['break_out'] == 1 || json['break_out'] == true,
      day: day ?? "",   // 🔑 fallback to empty string instead of crashing
      date: date ?? "",
      autoCheckin: json['auto_checkin'],   // ✅ important
      totalWorkTime: json['total_work_time'] ?? "0h 0m",

    );
  }

  /// ✅ From SQLite
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? "",
      taskName: map['task_name'] ?? "",
      startTime: map['start_time'] ?? "00:00",
      endTime: map['end_time'] ?? "",
      locationName: map['location_name'] ?? "",
      priority: map['priority'] ?? "",
      status: map['status'] ?? "",
      lat: map['lat'] ?? "0",
      longg: map['long'] ?? "0",
      punchIn: map['punch_in'] == 1,
      punchOut: map['punch_out'] == 1,
      breakIn: map['break_in'] == 1,
      breakOut: map['break_out'] == 1,
      day: map['day'] ?? "",   // ✅ load from DB correctly
      date: map['date'] ?? "",
      autoCheckin: map['auto_checkin'] == 1,        // ✅ NEW
      totalWorkTime: map['total_work_time'] ?? "0h 0m",
    );
  }


  /// ✅ Save to SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_name': taskName,
      'start_time': startTime,
      'end_time': endTime,
      'location_name': locationName,
      'priority': priority,
      'status': status,
      'lat':lat,
      'long':longg,
      'punch_in': punchIn ? 1 : 0,
      'punch_out': punchOut ? 1 : 0,
      'break_in': breakIn ? 1 : 0,
      'break_out': breakOut ? 1 : 0,
      'day': day,
      'date': date,
      'auto_checkin': autoCheckin ? 1 : 0,          // ✅ NEW
      'total_work_time': totalWorkTime,
    };
  }

  /// ✅ Utility
  String get duration {
    final start = DateTime.tryParse("2000-01-01 $startTime");
    final end = DateTime.tryParse("2000-01-01 $endTime");
    if (start != null && end != null) {
      final diff = end.difference(start);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
    return '0h 0m';
  }

  String get timeRange => "$startTime - $endTime";
  bool get isHighPriority => priority.toLowerCase() == 'high';
  bool get isCompleted => status.toLowerCase() == 'completed';
}
