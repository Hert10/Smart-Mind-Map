import 'package:flutter/material.dart';
import 'screens/home_page.dart'; 
import 'services/upload_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mind Map App',
      debugShowCheckedModeBanner: false,
      
      scaffoldMessengerKey: UploadManager.instance.scaffoldMessengerKey,
      navigatorKey: UploadManager.instance.navigatorKey,
      
      home: const HomePage(),
    );
  }
}