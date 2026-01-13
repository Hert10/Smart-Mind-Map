import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/mind_map_models.dart';
import 'mind_map_screen.dart';
import 'settings_page.dart';
import 'how_it_works.dart'; 
import '../services/upload_manager.dart';

class HomePageMobile extends StatefulWidget {
  const HomePageMobile({super.key});

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  List<dynamic> _maps = [];
  late PageController _pageController;
  int _currentPage = 0;
  
  bool _isListView = false; 

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75); 
    _loadAllMaps();
    UploadManager.instance.refreshMapsNotifier.addListener(_loadAllMaps);
  }

  @override
  void dispose() {
    UploadManager.instance.refreshMapsNotifier.removeListener(_loadAllMaps);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMaps() async {
    List<dynamic> loadedMaps = [];
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final jsonPaths = manifestMap.keys.where((k) => k.startsWith('assets/') && k.endsWith('.json')).toList();
      for (String path in jsonPaths) {
         final content = await rootBundle.loadString(path);
         loadedMaps.add({
           'title': json.decode(content)['root_label'] ?? 'Demo', 
           'date': 'Exemple', 
           'data': json.decode(content),
           'path': null 
         });
      }
    } catch (_) {}

    try {
      final directory = await getApplicationDocumentsDirectory();
      if (directory.existsSync()) {
        final files = directory.listSync();
        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        
        for (var file in files) {
          if (file.path.endsWith('.json')) {
            try {
              final content = await File(file.path).readAsString();
              final data = json.decode(content);
              String filename = file.path.split('/').last.replaceAll('.json', '');
              String displayTitle = filename.contains('_') 
                  ? filename.substring(0, filename.lastIndexOf('_')) 
                  : filename;

              loadedMaps.add({
                'title': data['root_label'] ?? displayTitle, 
                'date': 'Mes Cartes', 
                'data': data,
                'path': file.path
              });
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _maps = loadedMaps);
  }

  Future<void> _handleNewMindMap() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      UploadManager.instance.startUpload(result.files.single);
    }
  }

  void _openMap(int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MindMapScreen(
        data: MindMapData.fromJson(_maps[index]['data']), 
        title: _maps[index]['title'],
        filePath: _maps[index]['path'],
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.psychology, color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text('Mind Map AI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Colors.deepPurple),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded, color: Colors.deepPurple),
              title: const Text('How it Works'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HowItWorksPage()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Colors.grey),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(_isListView ? "MY LIST" : "GALLERY", style: const TextStyle(color: Colors.black87, letterSpacing: 3, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        
        actions: [
          IconButton(
            icon: Icon(_isListView ? Icons.grid_view_rounded : Icons.view_list_rounded, color: Colors.black87),
            tooltip: "Switch View",
            onPressed: () => setState(() => _isListView = !_isListView),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleNewMindMap,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Upload", style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
      body: _maps.isEmpty
          ? const Center(child: Text("No Map, Upload a PDF!", style: TextStyle(color: Colors.grey)))
          
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isListView ? _buildListView() : _buildCarouselView(),
            ),
    );
  }

  Widget _buildCarouselView() {
    return Column(
      key: const ValueKey("Carousel"),
      children: [
        const SizedBox(height: 40),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int index) => setState(() => _currentPage = index),
            itemCount: _maps.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 500,
                      width: Curves.easeOut.transform(value) * 450,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () => _openMap(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.account_tree_rounded, size: 60, color: Colors.deepPurple),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _maps[index]['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${(_maps[index]['data']['branches'] as List).length} Branches", 
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      key: const ValueKey("List"),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _maps.length,
      itemBuilder: (context, index) {
        final map = _maps[index];
        final int branchCount = (map['data']['branches'] as List).length;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => _openMap(index),
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade50,
              radius: 24,
              child: const Icon(Icons.account_tree_rounded, color: Colors.deepPurple),
            ),
            title: Text(
              map['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
           subtitle: Padding(
  padding: const EdgeInsets.only(top: 4.0),
  child: Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12, 
    runSpacing: 4, 
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_list_bulleted, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text("$branchCount Branches", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
      if (map['date'] != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(map['date'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
    ],
  ),
),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
        );
      },
    );
  }
}