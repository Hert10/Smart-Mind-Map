import 'package:flutter/material.dart';
import '../models/mind_map_models.dart';

class TreePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final MindMapData data;
  final double animationValue;

  TreePainter({required this.positions, required this.data, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (!positions.containsKey('root')) return;
    Offset rootPos = positions['root']!;

    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (animationValue < 0.1) return;

    for (var branch in data.branches) {
      if (!positions.containsKey(branch.name)) continue;
      Offset branchPos = positions[branch.name]!;

      if (animationValue > 0.3) {
        drawOrganicCurve(canvas, rootPos, branchPos, paint);
      }

      if (animationValue > 0.6) {
        for (var leaf in branch.children) {
          String leafKey = "${branch.name}_${leaf.label}";
          if (!positions.containsKey(leafKey)) continue;
          
          Offset leafPos = positions[leafKey]!;
          drawOrganicCurve(canvas, branchPos, leafPos, paint);

      
          if (leaf.children.isNotEmpty) { 
             for (var sub in leaf.children) {
                String subKey = "${leafKey}_${sub.label}";
                if (positions.containsKey(subKey)) {
                   drawOrganicCurve(canvas, leafPos, positions[subKey]!, paint);
                }
             }
          }
        }
      }
    }
  }

  void drawOrganicCurve(Canvas canvas, Offset start, Offset end, Paint paint) {
    Path path = Path();
    path.moveTo(start.dx, start.dy);
    double midX = start.dx + (end.dx - start.dx) / 2;
    path.cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TreePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.positions.length != positions.length;
  }
}