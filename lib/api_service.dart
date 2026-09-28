import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Base URL pointing directly to Railway host
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://questination-production.up.railway.app',
  );

  static String? accessToken;
  static String? refreshToken;

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  static String? get currentUserId {
    final token = accessToken;
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map ? payload['id']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  // POST /log-in
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/log-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      accessToken = data['token'];
      refreshToken = data['refreshtoken'];
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to log in');
    }
  }

  // POST /register
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String phone,
    String role = 'tourist',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      // Auto-login after successful registration to retrieve JWT tokens
      return await login(email, password);
    } else {
      throw Exception(data['message'] ?? 'Failed to register');
    }
  }

  // GET /quests
  static Future<List<dynamic>> getQuests({String? cityId}) async {
    final Uri uri = Uri.parse('$baseUrl/quests').replace(
      queryParameters: cityId != null ? {'city_id': cityId} : null,
    );

    final response = await http.get(uri, headers: authHeaders);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data is List) return data;
      if (data is Map && data['quests'] is List) {
        return data['quests'] as List<dynamic>;
      }
      throw const FormatException(
          'Unexpected response format from GET /quests');
    }
    final message = data is Map ? data['message'] : null;
    throw Exception(
        message ?? 'Failed to load quests (${response.statusCode})');
  }

  static Future<List<dynamic>> getCities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/quests/cities'),
      headers: authHeaders,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is Map && data['cities'] is List) {
      return data['cities'] as List<dynamic>;
    }
    final message = data is Map ? data['message'] : null;
    throw Exception(
        message ?? 'Failed to load cities (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> getQuestById(String questId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quests/$questId'),
      headers: authHeaders,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is Map && data['quest'] is Map) {
      return Map<String, dynamic>.from(data['quest'] as Map);
    }
    final message = data is Map ? data['message'] : null;
    throw Exception(message ?? 'Failed to load quest (${response.statusCode})');
  }

  static Future<String> uploadQuestPhoto({
    required String questId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    if (bytes.isEmpty) throw ArgumentError('The selected photo is empty.');

    final signedUrlResponse = await http.post(
      Uri.parse('$baseUrl/quests/photo-upload-url'),
      headers: {
        ...authHeaders,
      },
      body: jsonEncode({
        'questId': questId,
        'fileName': fileName,
        'contentType': contentType,
      }),
    );
    final dynamic signedData;
    try {
      signedData = jsonDecode(signedUrlResponse.body);
    } on FormatException {
      if (signedUrlResponse.body.trimLeft().startsWith('<')) {
        throw Exception(
          'The server returned an HTML error for photo upload '
          '(HTTP ${signedUrlResponse.statusCode}). Deploy the latest backend '
          'with POST /quests/photo-upload-url enabled.',
        );
      }
      throw const FormatException(
          'Photo upload service returned invalid JSON.');
    }
    if (signedUrlResponse.statusCode != 200 ||
        signedData is! Map ||
        signedData['uploadUrl'] is! String ||
        signedData['publicUrl'] is! String) {
      final message = signedData is Map ? signedData['message'] : null;
      throw Exception(message ?? 'Could not prepare photo upload');
    }

    final uploadResponse = await http.put(
      Uri.parse(signedData['uploadUrl'] as String),
      headers: {
        'Content-Type': contentType,
        'x-upsert': 'false',
      },
      body: bytes,
    );
    if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
      throw Exception('Photo upload failed (${uploadResponse.statusCode})');
    }

    return signedData['publicUrl'] as String;
  }

  static Future<Map<String, dynamic>> completeQuest({
    required String questId,
    required double latitude,
    required double longitude,
    required String qrCode,
    required String photoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quests/$questId/completion'),
      headers: authHeaders,
      body: jsonEncode({
        'lat': latitude,
        'lng': longitude,
        'qr_code': qrCode,
        'photoUrl': photoUrl,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    final message = data is Map ? data['message'] : null;
    throw Exception(
        message ?? 'Failed to complete quest (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> createJournalEntry({
    required String questId,
    required Uint8List photoBytes,
    required String fileName,
    required String contentType,
    String? caption,
    String? stickerId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/journal'),
    );
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    request.fields['quest_id'] = questId;
    if (caption?.trim().isNotEmpty == true) {
      request.fields['caption'] = caption!.trim();
    }
    if (stickerId?.isNotEmpty == true) {
      request.fields['sticker_id'] = stickerId!;
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'photos',
        photoBytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    final message = data is Map ? data['error'] ?? data['message'] : null;
    throw Exception(message ?? 'Failed to upload journal photo');
  }

  static Future<Map<String, dynamic>> getJournal({String? cityId}) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Log in to view your journal.');
    final uri = Uri.parse('$baseUrl/api/journal/$userId').replace(
      queryParameters: cityId == null ? null : {'city_id': cityId},
    );
    final response = await http.get(uri, headers: authHeaders);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    final message = data is Map ? data['error'] : null;
    throw Exception(message ?? 'Failed to load journal');
  }

  static Future<List<dynamic>> getCraftCategories(String cityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/preferences/cities/$cityId/craft-categories'),
      headers: authHeaders,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is List) return data;
    throw Exception('Failed to load craft categories');
  }

  static Future<void> saveCraftPreferences(
      List<String> craftCategoryIds) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Log in to save preferences.');
    final response = await http.post(
      Uri.parse('$baseUrl/api/preferences'),
      headers: authHeaders,
      body: jsonEncode({'craftCategoryIds': craftCategoryIds}),
    );
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(
          data is Map ? data['error'] : 'Failed to save preferences');
    }
  }

  static Future<List<dynamic>> getRecommendations() async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Log in to view recommendations.');
    final response = await http.get(
      Uri.parse('$baseUrl/api/recommendations/$userId'),
      headers: authHeaders,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is List) return data;
    throw Exception(
        data is Map ? data['error'] : 'Failed to load recommendations');
  }

  static Future<List<dynamic>> getArtisans(String cityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/artisans/city/$cityId'),
      headers: authHeaders,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is List) return data;
    throw Exception(data is Map ? data['error'] : 'Failed to load artisans');
  }

  static Future<Map<String, dynamic>> submitRating({
    required int rating,
    String? questId,
    String? sellerId,
    String? reviewText,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ratings'),
      headers: authHeaders,
      body: jsonEncode({
        'rating': rating,
        if (questId != null) 'questId': questId,
        if (sellerId != null) 'sellerId': sellerId,
        if (reviewText != null) 'reviewText': reviewText,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    final message = data is Map ? data['message'] : null;
    throw Exception(message ?? 'Failed to submit rating');
  }

  // POST /:questId/start
  static Future<Map<String, dynamic>> startQuiz(String questId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz/$questId/start'),
      headers: authHeaders,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to start quiz');
    }
  }

  // POST /:questId/answer
  static Future<Map<String, dynamic>> submitQuizAnswer({
    required String questId,
    required String attemptId,
    required String questionId,
    required String selectedOption,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz/$questId/answer'),
      headers: authHeaders,
      body: jsonEncode({
        'attemptId': attemptId,
        'questionId': questionId,
        'selectedOption': selectedOption,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to submit answer');
    }
  }

  // GET /:attemptId/finish
  static Future<Map<String, dynamic>> finishQuiz(String attemptId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quiz/$attemptId/finish'),
      headers: authHeaders,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to finish quiz');
    }
  }
}
