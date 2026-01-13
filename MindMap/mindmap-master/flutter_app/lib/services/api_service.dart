import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/mind_map_models.dart';

class ApiService {
  
static Future<bool> checkConnection(String baseUrl) async {
    try {
      final String cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final Uri uri = Uri.parse('$cleanUrl/ping');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        print(" Connection Successful: ${response.body}");
        return true;
      } else {
        print(" Connection Failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print(" Connection Error: $e");
      return false;
    }
  }
  static Future<MindMapData?> uploadPdf(String baseUrl, PlatformFile file) async {
    final String cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final Uri uri = Uri.parse('$cleanUrl/analyze');

    var request = http.MultipartRequest('POST', uri);

    if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        file.bytes!, 
        filename: file.name
      ));
    } else if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        file.path!
      ));
    } else {
      print(" Error: File has no path and no bytes.");
      return null;
    }

    try {
      print(" Uploading...");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        return MindMapData.fromJson(decodedData);
      } else {
        print("Server Error: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("Connection Error: $e");
      return null;
    }
  }


  static Future<List<Leaf>> expandNode(String baseUrl, String concept, String context) async {
    final String cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final Uri uri = Uri.parse('$cleanUrl/expand');

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "concept": concept,
          "context": context
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> childrenJson = data['children'];
        return childrenJson.map((json) => Leaf.fromJson(json)).toList();
      }
    } catch (e) {
      print("Expansion Error: $e");
    }
    return [];
  }
}