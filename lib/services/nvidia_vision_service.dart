import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:deep_waste/services/livekit_config.dart';

/// Service for classifying waste images using NVIDIA's vision model
class NvidiaVisionService {
  /// Classify a waste image using NVIDIA's Llama 3.2 Vision model
  /// Returns the predicted category and confidence
  static Future<Map<String, dynamic>> classifyImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = '''You are a waste classification AI. Analyze this image and classify the waste item into one of these categories:
- Recyclable (plastic, paper, cardboard, glass, metal that can be recycled)
- Organic (food scraps, yard waste, compostable materials)
- E-Waste (electronics, batteries, phones, computers)
- Hazardous (chemicals, paint, batteries, medical waste)
- General (non-recyclable items that go to landfill)

Respond with ONLY a JSON object in this exact format:
{"category": "Recyclable", "confidence": 0.95, "itemName": "Plastic bottle", "binColor": "blue", "disposalTip": "Rinse before recycling"}

Do not include any other text, just the JSON object.''';

      final response = await http.post(
        Uri.parse('${NvidiaConfig.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${NvidiaConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'meta/llama-3.2-11b-vision-instruct',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'temperature': 0.3,
          'max_tokens': 256,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['choices'][0]['message']['content'];
        
        // Parse the JSON response
        final result = _parseClassificationResponse(content);
        return result;
      } else {
        print('Vision API error: ${response.statusCode}');
        return _getDefaultResult();
      }
    } catch (e) {
      print('Error classifying image: $e');
      return _getDefaultResult();
    }
  }

  static Map<String, dynamic> _parseClassificationResponse(String content) {
    try {
      // Try to extract JSON from response
      String jsonStr = content.trim();
      
      // Remove markdown code fences if present
      jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // Find JSON object
      final startIndex = jsonStr.indexOf('{');
      final endIndex = jsonStr.lastIndexOf('}');
      
      if (startIndex != -1 && endIndex != -1) {
        jsonStr = jsonStr.substring(startIndex, endIndex + 1);
        final Map<String, dynamic> parsed = jsonDecode(jsonStr);
        
        // Validate required fields
        final category = parsed['category'] ?? 'General';
        final confidence = (parsed['confidence'] ?? 0.8).toDouble();
        final itemName = parsed['itemName'] ?? 'Unknown item';
        final binColor = parsed['binColor'] ?? 'black';
        final disposalTip = parsed['disposalTip'] ?? 'Dispose properly';
        
        return {
          'category': _normalizeCategory(category),
          'confidence': confidence.clamp(0.0, 1.0),
          'itemName': itemName,
          'binColor': binColor,
          'disposalTip': disposalTip,
        };
      }
    } catch (e) {
      print('Error parsing response: $e');
    }
    
    return _getDefaultResult();
  }

  static String _normalizeCategory(String category) {
    final normalized = category.toLowerCase().trim();
    if (normalized.contains('recycl')) return 'Recyclable';
    if (normalized.contains('organic') || normalized.contains('compost')) return 'Organic';
    if (normalized.contains('e-waste') || normalized.contains('electronic')) return 'E-Waste';
    if (normalized.contains('hazard') || normalized.contains('chemical')) return 'Hazardous';
    return 'General';
  }

  static Map<String, dynamic> _getDefaultResult() {
    return {
      'category': 'General',
      'confidence': 0.5,
      'itemName': 'Unknown item',
      'binColor': 'black',
      'disposalTip': 'Check local disposal guidelines',
    };
  }
}
