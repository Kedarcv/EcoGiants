import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For local dev: http://localhost:8000
  // For deployed: https://your-app-name.railway.app
  static String baseUrl = 'https://eco-giants-api-production.up.railway.app';

  static final ApiService instance = ApiService._();
  ApiService._();

  // ── Auth ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> register(String studentNumber, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_number': studentNumber, 'name': name}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> login(String studentNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_number': studentNumber}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUser(String studentNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/$studentNumber'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ── Points ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> addPoints({
    required String studentNumber,
    required int points,
    required String category,
    String itemName = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/points/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_number': studentNumber,
        'points': points,
        'category': category,
        'item_name': itemName,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> submitQuiz({
    required String studentNumber,
    required String lessonTopic,
    required int score,
    required int totalQuestions,
    required int pointsEarned,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/quiz/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_number': studentNumber,
        'lesson_topic': lessonTopic,
        'score': score,
        'total_questions': totalQuestions,
        'points_earned': pointsEarned,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ── Leaderboard ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/leaderboard'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── LiveKit Token ───────────────────────────────────────────────

  Future<Map<String, String>?> getLiveKitToken({
    required String studentNumber,
    String? roomName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/livekit/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_number': studentNumber,
        if (roomName != null) 'room_name': roomName,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'url': (data['url'] as String?) ?? '',
        'token': (data['token'] as String?) ?? '',
        'room': (data['room'] as String?) ?? '',
      };
    }
    return null;
  }
}
