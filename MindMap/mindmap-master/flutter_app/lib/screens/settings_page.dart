import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlController = TextEditingController();
  bool _isChecking = false;
  String? _statusMessage;
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('api_url') ?? '';
    });
  }

  Future<void> _saveUrl() async {
    setState(() {
      _isChecking = true;
      _statusMessage = "Testing connection...";
      _statusColor = Colors.blue;
    });

    String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _isChecking = false;
        _statusMessage = "URL cannot be empty";
        _statusColor = Colors.red;
      });
      return;
    }

    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

    bool isConnected = await ApiService.checkConnection(url);

    if (isConnected) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_url', url);
      
      if (mounted) {
        setState(() {
          _isChecking = false;
          _statusMessage = " Connected & Saved!";
          _statusColor = Colors.green;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true); 
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _statusMessage = " Could not connect. Check URL.";
          _statusColor = Colors.red;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Server Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Colab Ngrok URL",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Paste the new link from your Python script here.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: "https://xxxx.ngrok-free.app",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 24),
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _statusColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _statusColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_statusMessage!, style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _saveUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isChecking 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Test & Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}