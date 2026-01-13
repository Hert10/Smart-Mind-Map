import 'package:flutter/material.dart';
import '../utils/app_style.dart';

class NodeVisual extends StatelessWidget {
  final String label;
  final Color color;
  final bool isRoot;
  final bool isLeaf;

  const NodeVisual({
    super.key, 
    required this.label, 
    required this.color, 
    this.isRoot = false, 
    this.isLeaf = false
  });

  @override
  Widget build(BuildContext context) {
    bool isWarning = isLeaf && color == AppStyle.warningColor;
    Color textColor = isWarning || isRoot ? AppStyle.textColor : AppStyle.darkTextColor;

    return Container(
      width: isRoot ? 180 : 160,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
          topRight: Radius.circular(isRoot ? 20 : 8),
          bottomLeft: Radius.circular(isRoot ? 20 : 8),
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(3, 5))
        ],
        border: isWarning ? Border.all(color: Colors.red.shade800, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: isRoot ? 16 : 14),
              maxLines: 3, overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isWarning) ...[const SizedBox(width: 8), Icon(Icons.warning_amber_rounded, color: AppStyle.textColor, size: 20)]
        ],
      ),
    );
  }
}