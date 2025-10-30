import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      print('Erro ao analisar imagem: $e');
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
      print('Erro ao analisar imagem: $e');
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
      print('Erro ao buscar alimento: $e');
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
      print('Erro ao buscar histórico: $e');
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
      print('Erro ao salvar favorito: $e');
      return false;
    }
  }
}
