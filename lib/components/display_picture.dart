import 'dart:io';
import 'dart:math';
import 'package:deep_waste/components/default_button.dart';
import 'package:deep_waste/constants/app_properties.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/Item.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/screens/QRScannerScreen.dart';
import 'package:deep_waste/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DisplayPicture extends StatefulWidget {
  final File image;
  final List<Item> items;

  const DisplayPicture({
    super.key,
    required this.image,
    required this.items,
  });

  @override
  State<DisplayPicture> createState() => _DisplayPictureState();
}

class _DisplayPictureState extends State<DisplayPicture> {
  String? prediction;
  String? predictedResult;
  bool predicted = false;
  bool confidenceLow = false;

  Interpreter? _interpreter;
  List<String> _labels = [];

  static const int _inputImageSize = 224;

  // Category mapping from TFLite labels to Eco-Giants categories
  final Map<String, String> _categoryMapping = {
    'plastic': 'Recyclable',
    'paper': 'Recyclable',
    'cardboard': 'Recyclable',
    'glass': 'Recyclable',
    'metal': 'Recyclable',
    'trash': 'General',
    'biological': 'Organic',
  };

  // Educational factoids per category
  final Map<String, List<String>> _factoids = {
    'Recyclable': [
      "Recycling one aluminum can saves enough energy to power a TV for 3 hours!",
      "Plastic bottles take 450 years to decompose in landfills.",
      "Recycling paper saves 17 trees per ton!",
    ],
    'Organic': [
      "Composting reduces landfill waste by up to 30%.",
      "Food waste in landfills produces methane, 25x more potent than CO2.",
    ],
    'E-Waste': [
      "E-waste contains toxic materials like lead and mercury.",
      "Only 17% of global e-waste is properly recycled.",
    ],
    'General': [
      "Reducing waste is even better than recycling!",
    ],
    'Hazardous': [
      "Batteries can leak toxic chemicals into soil and water.",
      "Always return hazardous waste to designated collection points.",
    ],
  };

  String? _selectedCategory;
  String? _factoid;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> loadModel() async {
    const String modelPath = "assets/models/garbage_model.tflite";
    const String labelPath = "assets/labels/labels.txt";

    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      final labelData = await rootBundle.loadString(labelPath);
      _labels = labelData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      debugPrint("Model and labels loaded successfully. Labels: $_labels");
    } catch (e) {
      debugPrint("Error initializing tflite_flutter: $e");
    }
  }

  Future<void> updateItem(List<Item> items, String itemName) async {
    try {
      final matchedItem = items.firstWhere(
        (item) => item.name.toLowerCase() == itemName.toLowerCase(),
      );
      matchedItem.count++;
      await DatabaseManager.instance.updateItem(matchedItem);
    } catch (_) {
      debugPrint("Item not found: $itemName");
    }
  }

  String _mapToEcoCategory(String label) {
    final lower = label.toLowerCase();
    return _categoryMapping[lower] ?? 'General';
  }

  String _getRandomFactoid(String category) {
    final facts = _factoids[category] ?? _factoids['General']!;
    return facts[Random().nextInt(facts.length)];
  }

  Future<void> uploadImage(BuildContext context) async {
    if (_interpreter == null || _labels.isEmpty) {
      EasyLoading.showError('Model not ready yet.');
      return;
    }

    EasyLoading.show(status: 'Classifying...');

    try {
      final Uint8List imageBytes = await widget.image.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        EasyLoading.dismiss();
        return;
      }

      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: _inputImageSize,
        height: _inputImageSize
      );

      var inputTensor = List.generate(
        1,
        (_) => List.generate(
          _inputImageSize,
          (_) => List.generate(
            _inputImageSize,
            (_) => List.filled(3, 0.0),
          ),
        ),
      );

      for (int y = 0; y < _inputImageSize; y++) {
        for (int x = 0; x < _inputImageSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputTensor[0][y][x][0] = pixel.r / 255.0;
          inputTensor[0][y][x][1] = pixel.g / 255.0;
          inputTensor[0][y][x][2] = pixel.b / 255.0;
        }
      }

      var outputTensor = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      _interpreter!.run(inputTensor, outputTensor);

      List<double> probabilities = outputTensor.first.cast<double>();
      double maxProbability = -1.0;
      int highestConfidenceIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          highestConfidenceIndex = i;
        }
      }

      EasyLoading.dismiss();

      if (maxProbability < 0.2) {
        setState(() {
          predicted = true;
          confidenceLow = true;
          predictedResult = "Unknown";
          prediction = "Could not confidently identify waste item.";
          _selectedCategory = null;
        });
        return;
      }

      final String finalLabel = _labels[highestConfidenceIndex];
      final double confidence = getNumber(maxProbability, precision: 2);
      final ecoCategory = _mapToEcoCategory(finalLabel);

      setState(() {
        predicted = true;
        confidenceLow = confidence < 0.5;
        predictedResult = finalLabel;
        _selectedCategory = ecoCategory;
        _factoid = _getRandomFactoid(ecoCategory);
        prediction =
            "Predicted: $finalLabel (${(confidence * 100).toStringAsFixed(0)}% confidence)\nCategory: $ecoCategory";
      });

    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("Inference failed: $e");
      EasyLoading.showError('Classification failed.');
    }
  }

  void _selectCategoryManually(String category) {
    setState(() {
      _selectedCategory = category;
      _factoid = _getRandomFactoid(category);
      predictedResult = category;
      confidenceLow = false;
      prediction = "Manual selection: $category";
    });
  }

  @override
  Widget build(BuildContext context) {
    final ecoCategories = ['Recyclable', 'Organic', 'E-Waste', 'General', 'Hazardous'];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Waste Classification'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image Preview
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(getProportionateScreenWidth(20)),
                height: getProportionateScreenHeight(280),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                  image: DecorationImage(
                    image: FileImage(widget.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Result Card
              if (predicted)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(getProportionateScreenWidth(16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (confidenceLow) ...[
                          Row(
                            children: [
                              const Icon(Icons.warning_amber, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Low confidence. Please select manually:",
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(14),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: getProportionateScreenHeight(12)),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ecoCategories.map((cat) {
                              final points = User.pointsByCategory[cat] ?? 10;
                              return ChoiceChip(
                                label: Text('$cat (+$points pts)'),
                                selected: _selectedCategory == cat,
                                onSelected: (_) => _selectCategoryManually(cat),
                                selectedColor: Colors.teal.shade100,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == cat
                                      ? Colors.teal.shade800
                                      : Colors.black87,
                                  fontWeight: _selectedCategory == cat
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                        ] else if (_selectedCategory != null) ...[
                          // Classification Result
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(_selectedCategory!),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _selectedCategory!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '+${User.pointsByCategory[_selectedCategory] ?? 10} pts',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: getProportionateScreenHeight(12)),
                          if (_factoid != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💡', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _factoid!,
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(13),
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: getProportionateScreenHeight(16)),
                          // QR Scan CTA
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_selectedCategory != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QRScannerScreen(
                                        expectedCategory: _selectedCategory!,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text(
                                'I\'m at the Bin - Scan QR',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ] else
                          Text(
                            prediction ?? "",
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(16),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: getProportionateScreenHeight(20)),

              // Predict button
              if (!predicted)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(20),
                  ),
                  child: DefaultButton(
                    text: "Classify Waste",
                    press: () => uploadImage(context),
                  ),
                ),

              SizedBox(height: getProportionateScreenHeight(30)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return Colors.blue;
      case 'organic':
        return Colors.green;
      case 'e-waste':
        return Colors.purple;
      case 'general':
        return Colors.grey;
      case 'hazardous':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }
}
