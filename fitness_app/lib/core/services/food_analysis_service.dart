import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/food_analysis_model.dart';
import '../utils/storage_service.dart';

class FoodAnalysisService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Analisa uma imagem de comida e retorna informações nutricionais
  Future<FoodAnalysisModel?> analyzeFood(File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/nutrition/analyze-food-image');

      var request = http.MultipartRequest('POST', url);

      // Adiciona headers de autenticação
      final token = await StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Adiciona a imagem
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: 'food_image.jpg',
      );
      request.files.add(multipartFile);

      // Envia a requisição
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return FoodAnalysisModel.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Erro na análise da imagem');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro do servidor');
      }
    } catch (e) {
      debugPrint('Erro ao analisar imagem: $e');
      rethrow;
    }
  }

  /// Analisa uma imagem a partir de bytes
  Future<FoodAnalysisModel?> analyzeFoodFromBytes(
      Uint8List imageBytes, String filename) async {
    try {
      final url = Uri.parse('$baseUrl/nutrition/analyze-food-image');

      var request = http.MultipartRequest('POST', url);

      // Adiciona headers de autenticação
      final token = await StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Adiciona a imagem
      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      // Envia a requisição
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return FoodAnalysisModel.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Erro na análise da imagem');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro do servidor');
      }
    } catch (e) {
      debugPrint('Erro ao analisar imagem: $e');
      rethrow;
    }
  }

  /// Busca informações nutricionais de um alimento por nome
  Future<Map<String, dynamic>?> searchFood(String foodName) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(
          '$baseUrl/nutrition/food-search?q=${Uri.encodeComponent(foodName)}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData['data'];
        } else {
          throw Exception(jsonData['message'] ?? 'Erro na busca');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro do servidor');
      }
    } catch (e) {
      debugPrint('Erro ao buscar alimento: $e');
      rethrow;
    }
  }

  /// Obtém o histórico de análises do usuário
  Future<List<FoodAnalysisHistoryModel>> getAnalysisHistory(
      {int limit = 20}) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('$baseUrl/nutrition/analysis-history?limit=$limit');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'] ?? [];
          return data
              .map((item) => FoodAnalysisHistoryModel.fromJson(item))
              .toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Erro ao buscar histórico');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro do servidor');
      }
    } catch (e) {
      debugPrint('Erro ao buscar histórico: $e');
      rethrow;
    }
  }

  /// Salva uma análise favorita (opcional - implementar se necessário)
  Future<bool> saveFavoriteAnalysis(FoodAnalysisModel analysis) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('$baseUrl/nutrition/save-favorite');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(analysis.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao salvar favorito: $e');
      return false;
    }
  }

  // Métodos utilitários para seleção de imagens
  Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<File?> pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Validações
  bool isValidImageFormat(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'bmp', 'webp'].contains(extension);
  }

  bool isValidImageSize(File file) {
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    return sizeInMB <= 10; // Limite de 10MB
  }

  /// Busca histórico completo de análises do usuário
  Future<List<FoodAnalysisModel>> getFullAnalysisHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/nutrition/analysis/history');
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = url.replace(queryParameters: queryParams);

      final token = await StorageService.getToken();
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((item) => FoodAnalysisModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar histórico: $e');
      return [];
    }
  }

  /// Deleta uma análise do histórico
  Future<bool> deleteAnalysis(int analysisId) async {
    try {
      final url = Uri.parse('$baseUrl/nutrition/analysis/$analysisId');

      final token = await StorageService.getToken();
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao deletar análise: $e');
      return false;
    }
  }
}
