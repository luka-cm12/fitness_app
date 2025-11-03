import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileService {
  static const String baseUrl = 'http://localhost:3000/api/users';

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      // Remover campos vazios/null
      final cleanData = <String, dynamic>{};
      profileData.forEach((key, value) {
        if (value != null && value != '') {
          cleanData[key] = value;
        }
      });

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode(cleanData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao atualizar perfil');
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-avatar'),
      );

      request.headers['Authorization'] = 'Bearer ${await _getAuthToken()}';

      var multipartFile = await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['profile_image'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao fazer upload da imagem');
      }
    } catch (error) {
      throw Exception('Erro ao fazer upload: $error');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar perfil');
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  static Future<String> _getAuthToken() async {
    const storage = FlutterSecureStorage();
    const tokenKey = 'auth_token';
    return await storage.read(key: tokenKey) ?? '';
  }
}
