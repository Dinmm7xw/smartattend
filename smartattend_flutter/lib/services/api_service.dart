// SmartAttend — API Service (Synchronized with FastAPI port 8585 & Android Studio)

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/models.dart';
import 'app_session.dart';

class ApiService {
  // Production Cloud Backend (Render.com + Supabase)
  static const String cloudBackendUrl = 'https://smartattend-9b3f.onrender.com';

  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.contains('localhost') || host == '127.0.0.1') {
        return 'http://localhost:8585';
      }
      return cloudBackendUrl;
    }
    return cloudBackendUrl;
  }

  static const Duration timeout = Duration(seconds: 15);

  // ── Real Backend Login ─────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final userData = data['user'];
        AppSession.token = data['token']?.toString();
        AppSession.avatarUrl.value = userData['avatar_url']?.toString();
        return {
          'success': true,
          'user': UserModel(
            name: userData['full_name'] ?? '',
            email: userData['email'] ?? '',
            role: userData['role'] ?? 'STUDENT',
            studentId: userData['student_id'],
            department: userData['department'],
          ),
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? data['message'] ?? 'Қате логин немесе құпия сөз! Базадан табылмады.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Серверге қосылу қатесі: $e',
      };
    }
  }
  // ── Profile: change password ───────────────────────────────
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppSession.token ?? ''}',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 20));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true};
      return {'success': false, 'message': data['detail']?.toString() ?? 'Қате'};
    } catch (e) {
      return {'success': false, 'message': 'Серверге қосылу қатесі: $e'};
    }
  }

  // ── Profile: upload avatar ─────────────────────────────────
  static Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/users/me/avatar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppSession.token ?? ''}',
        },
        body: jsonEncode({'photo_base64': base64Encode(bytes)}),
      ).timeout(const Duration(seconds: 40));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        AppSession.avatarUrl.value = data['avatar_url']?.toString();
        return {'success': true};
      }
      return {'success': false, 'message': data['detail']?.toString() ?? 'Қате'};
    } catch (e) {
      return {'success': false, 'message': 'Серверге қосылу қатесі: $e'};
    }
  }


  // ── Health Check ──────────────────────────────────────────
  static Future<bool> checkBackendHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Lessons ───────────────────────────────────────────────
  static Future<List<LessonModel>> getActiveLessons() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/lessons/active'))
          .timeout(timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List list = decoded is Map && decoded['lessons'] != null
            ? decoded['lessons']
            : (decoded is List ? decoded : []);
        if (list.isNotEmpty) {
          return list.map((j) => LessonModel.fromJson(j)).toList();
        }
      }
    } catch (_) {}
    // Fallback demo data
    return _demoLessons();
  }

  static List<LessonModel> _demoLessons() => [
        const LessonModel(
          id: 1,
          subject: 'Информатика негіздері',
          teacher: 'Профессор А. Сейітов',
          room: '312-А',
          time: '14:00 - 15:30',
          group: 'ИС-21-01',
          isActive: true,
          attendedCount: 10,
          totalStudents: 12,
        ),
        const LessonModel(
          id: 2,
          subject: 'Жоғары математика',
          teacher: 'Профессор А. Сейітов',
          room: '210-Б',
          time: '16:00 - 17:30',
          group: 'ИС-21-01',
          isActive: false,
          attendedCount: 0,
          totalStudents: 12,
        ),
        const LessonModel(
          id: 3,
          subject: 'Физика',
          teacher: 'Доцент Б. Нұрғалиев',
          room: '105-В',
          time: '10:00 - 11:30',
          group: 'ИС-21-01',
          isActive: false,
          attendedCount: 0,
          totalStudents: 12,
        ),
      ];

  // ── Check-in ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkInStudent({
    required int lessonId,
    required String studentEmail,
    required String qrToken,
    required bool faceVerified,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/attendance/check-in'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'lesson_id': lessonId,
              'student_email': studentEmail,
              'qr_token': qrToken,
              'face_verified': faceVerified,
            }),
          )
          .timeout(timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {
      'student_name': studentEmail,
      'check_in_time': DateTime.now().toIso8601String(),
      'status': 'PRESENT',
      'delay_minutes': 0,
    };
  }

  // ── QR Token ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> generateQRToken(int lessonId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/lessons/$lessonId/qr-token'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {
      'token': 'SA-${lessonId.toString().padLeft(3, '0')}-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'expires_in': 15,
    };
  }

  // ── Live Attendance for Teacher ───────────────────────────
  static Future<Map<String, dynamic>> getLiveAttendance(int lessonId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/lessons/$lessonId/live-attendance'))
          .timeout(timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {'students': [], 'alerts': []};
  }

  // ── SOS Alert ─────────────────────────────────────────────
  static Future<void> sendSOSAlert({
    required String alertType,
    required String message,
    required String senderName,
    int? lessonId,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/sos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'alert_type': alertType,
              'message': message,
              'sender_name': senderName,
              'lesson_id': ?lessonId,
            }),
          )
          .timeout(timeout);
    } catch (_) {}
  }

  // ── Dean Stats ────────────────────────────────────────────
  static Future<DeanStats> getDeanStats() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/dean/overview'))
          .timeout(timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final stats = data['stats'] ?? data;
        final int present = stats['present'] ?? 38;
        final int late = stats['late'] ?? 4;
        final int attended = present + late;
        return DeanStats(
          totalStudents: 45,
          activeStudents: attended,
          avgAttendance: 88.5,
          totalLessonsToday: stats['classes'] ?? 4,
          sosPending: stats['sos'] ?? 0,
          departmentStats: List<Map<String, dynamic>>.from(data['group_stats'] ?? []),
        );
      }
    } catch (_) {}
    return const DeanStats(
      totalStudents: 45,
      activeStudents: 42,
      avgAttendance: 91.2,
      totalLessonsToday: 4,
      sosPending: 2,
      departmentStats: [
        {'name': 'ИС-21-01', 'total_students': 12, 'attended': 10},
        {'name': 'ВТиПО-20-02', 'total_students': 15, 'attended': 13},
        {'name': 'КБ-22-03', 'total_students': 10, 'attended': 8},
        {'name': 'АИ-21-01', 'total_students': 14, 'attended': 11},
      ],
    );
  }

  // ── CSV Export URL ────────────────────────────────────────
  static String getExportCsvUrl() => '$baseUrl/api/attendance/export-csv';

  // ── Базаға пайдаланушы тіркеу (Face ID-мен) ──────────────────
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String fullName,
    String role = 'STUDENT',
    String? iin,
    String? phone,
    String? studentId,
    String? groupName,
    String? curatorGroup,
    String? department,
    String? password,
    String? photoBase64,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'full_name': fullName,
          'role': role,
          'iin': iin,
          'phone': phone ?? iin,
          'student_id': studentId,
          'group_name': groupName,
          'curator_group': curatorGroup,
          'department': department ?? 'Ақпараттық технологиялар бөлімі',
          'password': password ?? '12345',
          'photo_base64': photoBase64,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && (data['success'] == true),
        'message': data['message'] ?? (res.statusCode == 200 ? 'Сәтті тіркелді' : 'Қате орын алды'),
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Сервермен байланыс қатесі: $e',
      };
    }
  }

  // ── Жаппай қызметкерлер тізімін қосу (Excel / CSV) ─────────
  static Future<Map<String, dynamic>> bulkImportStaff(List<Map<String, dynamic>> staffList) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/users/bulk-staff'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff': staffList}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && (data['success'] == true),
        'message': data['message'] ?? 'Қызметкерлер базаға енгізілді',
        'added_count': data['added_count'] ?? 0,
        'credentials': data['credentials'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Импорттау қатесі: $e',
        'credentials': [],
      };
    }
  }

  // ── Нағыз Face ID арқылы адамды тану ───────────────────────
  static Future<Map<String, dynamic>> verifyFace({
    required String emailOrId,
    required String frameBase64,
    int? lessonId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/face/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_or_id': emailOrId,
          'frame_base64': frameBase64,
          'lesson_id': lessonId,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      return {
        'verified': data['verified'] == true,
        'similarity': (data['similarity'] as num?)?.toDouble() ?? 0.0,
        'studentName': data['student_name'] ?? '',
        'message': data['message'] ?? '',
        'enrolled': data['enrolled'] ?? true,
      };
    } catch (e) {
      return {
        'verified': false,
        'similarity': 0.0,
        'studentName': '',
        'message': 'Face ID серверіне қосылу қатесі: $e',
        'enrolled': true,
      };
    }
  }

  // ── Save attendance journal entry (photo + timestamps) ──
  static Future<Map<String, dynamic>> saveAttendance({
    required String studentId,
    required String teacherId,
    required String scanTimestamp,
    required String verificationTimestamp,
    required Uint8List photoBytes,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/attendance/save'));
      request.fields['student_id'] = studentId;
      request.fields['teacher_id'] = teacherId;
      request.fields['scan_timestamp'] = scanTimestamp;
      request.fields['verification_timestamp'] = verificationTimestamp;
      request.files.add(http.MultipartFile.fromBytes('photo', photoBytes, filename: 'photo.jpg', contentType: MediaType('image', 'jpeg')));
      var streamed = await request.send().timeout(const Duration(seconds: 10));
      var response = await http.Response.fromStream(streamed);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error saving attendance: $e'};
    }
  }

  // ── Бетті базаға тіркеу (Enrollment) ─────────────────────────
  static Future<Map<String, dynamic>> enrollFace({
    required String emailOrId,
    required String photoBase64,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/face/enroll'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_or_id': emailOrId,
          'photo_base64': photoBase64,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && (data['success'] == true),
        'message': data['message'] ?? (res.statusCode == 200 ? 'Face ID тіркелді' : 'Қате орын алды'),
        'avatarUrl': data['avatar_url'] ?? '',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Face ID тіркеу қатесі: $e',
      };
    }
  }

  // ── Базадағы барлық қолданушылар тізімі ────────────────────
  static Future<List<Map<String, dynamic>>> getUsersList() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/users')).timeout(timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['users'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    return [];
  }

  // ── Директорға түскен кураторлық топтық өтініштер ──────────
  static Future<List<Map<String, dynamic>>> getGroupApplications() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/director/applications')).timeout(timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['applications'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    return [];
  }

  // ── Директор топты бекіту (ID + бір реттік пароль + Face ID) ─
  static Future<Map<String, dynamic>> approveGroupApplication(int appId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/director/applications/$appId/approve'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && (data['success'] == true),
        'message': data['message'] ?? '',
        'credentials': data['credentials'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Бекіту қатесі: $e',
        'credentials': [],
      };
    }
  }

  // ── Директор өтінішті кері қайтару ──────────────────────────
  static Future<bool> rejectGroupApplication(int appId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/director/applications/$appId/reject')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Куратор топтық өтініш жіберу (студенттер, фотолары) ─────
  static Future<Map<String, dynamic>> submitGroupApplication({
    required String groupName,
    required String curatorName,
    required List<Map<String, dynamic>> students,
    String? faculty,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/curator/applications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'group_name': groupName,
          'curator_name': curatorName,
          'faculty': faculty ?? 'Ақпараттық технологиялар бөлімі',
          'course_year': 2,
          'students': students,
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 && (data['success'] == true),
        'message': data['message'] ?? 'Өтініш сәтті жіберілді',
        'applicationId': data['application_id'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Өтініш жіберу қатесі: $e',
      };
    }
  }

  // ── Face ID фотосын алдын-ала тексеру (Face preview) ────────
  static Future<Map<String, dynamic>> previewFaceDetection(String photoBase64) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/face/detect_preview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'photo_base64': photoBase64}),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(res.body);
      return {
        'detected': data['detected'] == true,
        'confidence': (data['confidence'] as num?)?.toDouble() ?? 0.0,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {
        'detected': false,
        'confidence': 0.0,
        'message': 'Тексеру қатесі: $e',
      };
    }
  }

  // ── Smart AI Navigator & Assistant ───────────────────────
  static Future<Map<String, dynamic>> askAI({
    required String prompt,
    String role = 'STUDENT',
    String userName = 'Қолданушы',
    int currentFloor = 3,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/ai/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'role': role,
          'user_name': userName,
          'current_floor': currentFloor,
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return {
          'success': true,
          'reply': data['reply'] ?? '',
          'action': data['action'],
        };
      } else {
        return {
          'success': false,
          'reply': 'ИИ жауап беруде қателік туындады (${res.statusCode})',
          'action': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'reply': 'ИИ желілік қатесі: $e',
        'action': null,
      };
    }
  }

  // ── Smart AI Dean Schedule OCR ────────────────────────────
  static Future<Map<String, dynamic>> scanScheduleAI({
    required List<int> imageBytes,
    String filename = 'schedule.jpg',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/ai/schedule/scan-image'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedRes = await request.send().timeout(const Duration(seconds: 40));
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return {
          'success': true,
          'message': data['message'] ?? 'Кесте сәтті енгізілді!',
          'saved_count': data['saved_count'] ?? 0,
          'lessons': data['lessons'] ?? [],
        };
      } else {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return {
          'success': false,
          'message': data['detail'] ?? 'Кестені оқу сәтсіз аяқталды',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'ИИ кесте өңдеу қатесі: $e',
      };
    }
  }
}

