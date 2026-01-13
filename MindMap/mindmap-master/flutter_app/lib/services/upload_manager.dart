import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mind_map_models.dart';
import 'api_service.dart';
import '../screens/mind_map_screen.dart';

class UploadManager {
  static final UploadManager _instance = UploadManager._internal();
  static UploadManager get instance => _instance;
  UploadManager._internal();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<bool> refreshMapsNotifier = ValueNotifier(false);

  Future<void> startUpload(PlatformFile file) async {
    final prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('api_url');

    if (url == null || url.isEmpty) {
      
        _showError("Aucune URL configurée. Allez dans les réglages.");
        return;
    }

    _showNotification("Analyse de ${file.name} en cours...", isLoading: true);
    _processFile(url, file);
  }

  Future<void> _processFile(String url, PlatformFile file) async {
    try {
      MindMapData? data = await ApiService.uploadPdf(url, file);

      if (data != null) {
        if (!kIsWeb) {
          await _saveMapLocally(data, file.name);
        }
        
        refreshMapsNotifier.value = !refreshMapsNotifier.value;
        _showSuccessNotification(data, file.name);
      } else {
        _showError("Échec de l'analyse. Vérifiez le serveur.");
      }
    } catch (e) {
      _showError("Erreur : $e");
    }
  }

  Future<void> _saveMapLocally(MindMapData data, String originalFilename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String safeName = originalFilename.replaceAll('.pdf', '').replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final file = File('${directory.path}/$safeName.json');
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (e) {
      print("Erreur sauvegarde locale: $e");
    }
  }

  void _showNotification(String message, {bool isLoading = false}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading) ...[
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> overwriteFile(String filePath, MindMapData data) async {
    try {
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data.toJson()));
      
      refreshMapsNotifier.value = !refreshMapsNotifier.value;
      _showNotification("Sauvegarde effectuée !");
    } catch (e) {
      _showError("Erreur de sauvegarde : $e");
    }
  }

  void _showSuccessNotification(MindMapData data, String title) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text("Mind Map prête !"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "VOIR",
          textColor: Colors.white,
          onPressed: () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => MindMapScreen(data: data, title: title),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }
}