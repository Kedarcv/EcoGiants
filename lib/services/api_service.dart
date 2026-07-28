import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = 'https://eco-giants-api-production.up.railway.app';

  static final ApiService instance = ApiService._();
  ApiService._();

  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>?> register(String studentNumber, String name) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'student_number': studentNumber, 'name': name}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server unreachable. Please try again later.');
    }
    return null;
  }

  Future<Map<String, dynamic>?> login(String studentNumber) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'student_number': studentNumber}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server unreachable. Please try again later.');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUser(String studentNumber) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/user/$studentNumber'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server unreachable. Please try again later.');
    }
    return null;
  }

  Future<Map<String, dynamic>?> addPoints({
    required String studentNumber,
    required int points,
    required String category,
    String itemName = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/points/add'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_number': studentNumber,
              'points': points,
              'category': category,
              'item_name': itemName,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } on SocketException {
      throw Exception('No internet connection.');
    } on HttpException {
      throw Exception('Server unreachable.');
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
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/quiz/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_number': studentNumber,
              'lesson_topic': lessonTopic,
              'score': score,
              'total_questions': totalQuestions,
              'points_earned': pointsEarned,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } on SocketException {
      throw Exception('No internet connection.');
    } on HttpException {
      throw Exception('Server unreachable.');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/leaderboard'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } on SocketException {
      throw Exception('No internet connection.');
    } on HttpException {
      throw Exception('Server unreachable.');
    }
    return [];
  }

}
