import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _getHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  /// Standard GET Request
  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.url(path));
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(uri, headers: _getHeaders(extraHeaders: headers))
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timed out. Please check your network connection.',
        statusCode: 408,
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'Cannot reach server at ${ApiConfig.baseUrl}.',
        statusCode: 503,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected network error: $e',
        statusCode: 500,
      );
    }
  }

  /// Standard POST Request
  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.url(path));
      final response = await http
          .post(
            uri,
            headers: _getHeaders(extraHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timed out.',
        statusCode: 408,
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'Cannot reach server at ${ApiConfig.baseUrl}.',
        statusCode: 503,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected network error: $e',
        statusCode: 500,
      );
    }
  }

  /// Standard PATCH Request
  Future<ApiResponse<dynamic>> patch(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.url(path));
      final response = await http
          .patch(
            uri,
            headers: _getHeaders(extraHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  /// Multipart POST (For Photo Evidence & Incident Ingestion)
  Future<ApiResponse<dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    File? file,
    String fileField = 'photo',
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.url(path));
      final request = http.MultipartRequest('POST', uri);

      // Add Headers
      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      if (headers != null) {
        request.headers.addAll(headers);
      }

      // Add string fields
      request.fields.addAll(fields);

      // Add file attachment
      if (file != null && await file.exists()) {
        final multipartFile = await http.MultipartFile.fromPath(
          fileField,
          file.path,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Upload timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to upload report: $e',
        statusCode: 500,
      );
    }
  }

  ApiResponse<dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'] == true ||
            (response.statusCode >= 200 && response.statusCode < 300);
        return ApiResponse(
          success: success,
          data: decoded['data'] ?? decoded,
          message: decoded['message'] as String?,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        data: decoded,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        data: response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
