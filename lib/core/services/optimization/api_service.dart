import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/token_manager.dart';

/// Example API service demonstrating efficient token usage
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final TokenManager _tokenManager = TokenManager();
  
  // Your API base URL
  static const String _baseUrl = 'https://your-api-server.com/api';

  /// Example: Get user data with proper token caching
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    return await _tokenManager.authenticatedApiCall<Map<String, dynamic>>(
      apiCall: (token) async {
        final response = await http.get(
          Uri.parse('$_baseUrl/users/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else if (response.statusCode == 401) {
          throw Exception('unauthorized'); // This will trigger token refresh
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      },
    );
  }

  /// Example: Create appointment with automatic token handling
  Future<Map<String, dynamic>?> createAppointment(Map<String, dynamic> appointmentData) async {
    return await _tokenManager.authenticatedApiCall<Map<String, dynamic>>(
      apiCall: (token) async {
        final response = await http.post(
          Uri.parse('$_baseUrl/appointments'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(appointmentData),
        );
        
        if (response.statusCode == 201) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else if (response.statusCode == 401) {
          throw Exception('unauthorized');
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      },
    );
  }

  /// Example: Update clinic data
  Future<bool> updateClinicData(String clinicId, Map<String, dynamic> data) async {
    final result = await _tokenManager.authenticatedApiCall<bool>(
      apiCall: (token) async {
        final response = await http.put(
          Uri.parse('$_baseUrl/clinics/$clinicId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(data),
        );
        
        if (response.statusCode == 200) {
          return true;
        } else if (response.statusCode == 401) {
          throw Exception('unauthorized');
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      },
    );
    
    return result ?? false;
  }

  /// Example: Get appointments with filtering
  Future<List<Map<String, dynamic>>?> getAppointments({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    
    final uri = Uri.parse('$_baseUrl/appointments').replace(queryParameters: queryParams);
    
    return await _tokenManager.authenticatedApiCall<List<Map<String, dynamic>>>(
      apiCall: (token) async {
        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data.cast<Map<String, dynamic>>();
        } else if (response.statusCode == 401) {
          throw Exception('unauthorized');
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      },
    );
  }

  /// Manual token refresh (rarely needed)
  Future<bool> refreshToken() async {
    final token = await _tokenManager.refreshToken();
    return token != null;
  }
}
