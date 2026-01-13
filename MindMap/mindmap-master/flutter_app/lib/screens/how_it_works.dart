import 'package:flutter/material.dart';
import '../utils/app_style.dart'; 

class HowItWorksPage extends StatefulWidget {
  const HowItWorksPage({super.key});

  @override
  State<HowItWorksPage> createState() => _HowItWorksPageState();
}

class _HowItWorksPageState extends State<HowItWorksPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      "title": "Upload PDF",
      "desc": "Select your course PDF. The AI analyzes the structure and key concepts automatically.",
      "icon": Icons.upload_file_rounded,
    },
    {
      "title": "AI Generation",
      "desc": "Watch as the Neural Tree grows. Branches represent chapters and leaves are key details.",
      "icon": Icons.auto_awesome_rounded,
    },
    {
      "title": "Edit & Study",
      "desc": "Long-press any node to edit text. Save your maps to the Gallery to review later.",
      "icon": Icons.edit_note_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _slides.length,
              itemBuilder: (context, index) => _buildSlide(_slides[index]),
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(slide['icon'], size: 80, color: Colors.deepPurple),
          ),
          const SizedBox(height: 40),
          Text(
            slide['title'],
            style: const TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87,
              letterSpacing: 1.2
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide['desc'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, 
              height: 1.5,
              color: Colors.grey[700]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.deepPurple : Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < _slides.length - 1) {
                _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(_currentPage == _slides.length - 1 ? "GOT IT" : "NEXT"),
          ),
        ],
      ),
    );
  }
}