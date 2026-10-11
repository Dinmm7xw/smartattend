// SmartAttend — User & Lesson Models

class UserModel {
  final String name;
  final String email;
  final String role; // STUDENT | TEACHER | DEAN
  final String? studentId;
  final String? group;
  final String? department;

  const UserModel({
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.group,
    this.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'STUDENT',
        studentId: json['student_id'],
        group: json['group'],
        department: json['department'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'role': role,
        if (studentId != null) 'student_id': studentId,
        if (group != null) 'group': group,
        if (department != null) 'department': department,
      };
}

class LessonModel {
  final int id;
  final String subject;
  final String teacher;
  final String room;
  final String time;
  final String group;
  final bool isActive;
  final int attendedCount;
  final int totalStudents;

  const LessonModel({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.time,
    required this.group,
    this.isActive = false,
    this.attendedCount = 0,
    this.totalStudents = 30,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    String formattedTime = json['time'] ?? '';
    if (formattedTime.isEmpty && json['start_time'] != null) {
      formattedTime = "${json['start_time']} - ${json['end_time'] ?? ''}";
    }

    return LessonModel(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? json['title'] ?? 'Сабақ',
      teacher: json['teacher'] ?? json['teacher_name'] ?? 'Оқытушы',
      room: json['room'] ?? json['classroom'] ?? '312-А',
      time: formattedTime,
      group: json['group'] ?? json['group_name'] ?? 'ИС-21-01',
      isActive: json['is_active'] ?? json['is_qr_active'] ?? false,
      attendedCount: json['attended_count'] ?? json['attended'] ?? 0,
      totalStudents: json['total_students'] ?? 30,
    );
  }

  double get attendanceRate =>
      totalStudents > 0 ? (attendedCount / totalStudents) * 100 : 0;
}

class AttendanceRecord {
  final String studentName;
  final String studentId;
  final String lessonSubject;
  final DateTime checkInTime;
  final bool faceVerified;

  const AttendanceRecord({
    required this.studentName,
    required this.studentId,
    required this.lessonSubject,
    required this.checkInTime,
    this.faceVerified = false,
  });
}

class DeanStats {
  final int totalStudents;
  final int activeStudents;
  final double avgAttendance;
  final int totalLessonsToday;
  final int sosPending;
  final List<Map<String, dynamic>> departmentStats;

  const DeanStats({
    required this.totalStudents,
    required this.activeStudents,
    required this.avgAttendance,
    required this.totalLessonsToday,
    required this.sosPending,
    required this.departmentStats,
  });
}
