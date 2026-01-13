import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart'; 
import '../models/mind_map_models.dart';
import '../services/api_service.dart'; 
import 'mind_map_screen.dart';

class HomePageWeb extends StatefulWidget {
  const HomePageWeb({super.key});

  @override
  State<HomePageWeb> createState() => _HomePageWebState();
}

class _HomePageWebState extends State<HomePageWeb> {
  List<dynamic> _maps = [];

  @override
  void initState() {
    super.initState();
    _loadAssetMapsOnly();
  }

  Future<void> _loadAssetMapsOnly() async {
    List<dynamic> loadedMaps = [];
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final jsonPaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/') && key.endsWith('.json'))
          .toList();
      
      for (String path in jsonPaths) {
        final String content = await rootBundle.loadString(path);
        final dynamic data = json.decode(content);
        loadedMaps.add({
          'title': data['root_label'] ?? path.split('/').last,
          'date': 'Demo', 
          'data': data,
        });
      }
    } catch (e) {
      debugPrint("Asset load error: $e");
    }
    if (mounted) setState(() => _maps = loadedMaps);
  }

  Future<void> _handleNewMindMap() async {
    const String url = "https://alarmedly-intersegmental-sutton.ngrok-free.dev";

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, 
    );

    if (result != null) {
      PlatformFile file = result.files.single;

      showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      try {
        MindMapData? data = await ApiService.uploadPdf(url, file);
        Navigator.pop(context); 

        if (data != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MindMapScreen(data: data, title: file.name),
            ),
          );
        }
      } catch (e) {
         Navigator.pop(context);
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("WEB VERSION", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _handleNewMindMap,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload PDF & Generate Map"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: _maps.isEmpty 
                  ? const Center(child: Text("Select a PDF to begin"))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 1.2
                      ),
                      itemCount: _maps.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MindMapScreen(data: MindMapData.fromJson(_maps[index]['data']), title: _maps[index]['title']))),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.account_tree, size: 40, color: Colors.deepPurple),
                                const SizedBox(height: 10),
                                Text(_maps[index]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }
}