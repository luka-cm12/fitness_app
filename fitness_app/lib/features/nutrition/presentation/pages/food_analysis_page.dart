import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/food_analysis_model.dart';
import '../../providers/food_analysis_provider.dart';
import '../widgets/bottom_navigation.dart';
import 'food_analysis_result_page.dart';
import 'food_analysis_history_page.dart';

class FoodAnalysisPage extends ConsumerStatefulWidget {
  const FoodAnalysisPage({super.key});

  @override
  ConsumerState<FoodAnalysisPage> createState() => _FoodAnalysisPageState();
}

class _FoodAnalysisPageState extends ConsumerState<FoodAnalysisPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise Nutricional'),
        actions: [
          IconButton(
            onPressed: () => _navigateToHistory(),
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com informações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Análise Nutricional por Foto',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tire uma foto do seu prato e descubra as informações nutricionais em segundos!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botões de ação
            if (!_isAnalyzing) ...[
              _buildActionButton(
                icon: Icons.camera_alt,
                label: 'Tirar Foto',
                subtitle: 'Use a câmera para fotografar seu prato',
                onPressed: () => _takePhoto(),
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.photo_library,
                label: 'Escolher da Galeria',
                subtitle: 'Selecione uma foto existente',
                onPressed: () => _pickFromGallery(),
                color: Colors.green,
              ),
            ] else ...[
              // Loading durante análise
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Analisando sua imagem...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Isso pode levar alguns segundos',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Dicas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dicas para melhores resultados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                        'Certifique-se de que a comida esteja bem iluminada'),
                    _buildTip('Tire a foto de cima, mostrando todo o prato'),
                    _buildTip('Evite sombras ou reflexos na imagem'),
                    _buildTip('Mantenha o prato centralizado na foto'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        await _analyzeImage(File(photo.path));
      }
    } catch (e) {
      _showErrorDialog('Erro ao tirar foto: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _analyzeImage(File(image.path));
      }
    } catch (e) {
      _showErrorDialog('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final foodAnalysisService = ref.read(foodAnalysisServiceProvider);
      final FoodAnalysisModel? analysis =
          await foodAnalysisService.analyzeFood(imageFile);

      if (analysis != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FoodAnalysisResultPage(
              analysis: analysis,
              imageFile: imageFile,
            ),
          ),
        );
      } else {
        _showErrorDialog(
            'Não foi possível analisar a imagem. Tente novamente.');
      }
    } catch (e) {
      _showErrorDialog('Erro na análise: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _navigateToHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FoodAnalysisHistoryPage(),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
