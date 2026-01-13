import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'home_page_mobile.dart';
import 'home_page_web.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const HomePageWeb();
    } else {
      return const HomePageMobile();
    }
  }
}