import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../models/mind_map_models.dart';
import '../utils/app_style.dart';
import '../widgets/node_visual.dart';
import '../widgets/tree_painter.dart';
import '../services/upload_manager.dart';
import '../services/api_service.dart'; 

class MindMapScreen extends StatefulWidget {
  final MindMapData data;
  final String title;
  final String? filePath; 

  const MindMapScreen({
    super.key, 
    required this.data, 
    required this.title, 
    this.filePath
  });

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> with SingleTickerProviderStateMixin {
  late MindMapData _currentData; 
  final Map<String, Offset> nodePositions = {};
  late AnimationController _controller;
  final TransformationController _transformationController = TransformationController();
  final Set<String> _collapsedNodes = {};
  double _dynamicCanvasHeight = 3000.0;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.data;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    
    _controller.addListener(() {
      setState(() {});
    });

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnRoot());
  }

  void _centerOnRoot() {
    if (!mounted) return;
    final Size screenSize = MediaQuery.of(context).size;
    double rootX = 100.0; 
    double rootY = _dynamicCanvasHeight / 2; 
    double x = (screenSize.width / 2) - rootX;
    double y = (screenSize.height / 2) - rootY;
    _transformationController.value = Matrix4.identity()..translate(x, y);
    setState(() {});
  }

  Future<void> _saveChanges() async {
    if (widget.filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demo maps cannot be saved.")));
      return;
    }
    await UploadManager.instance.overwriteFile(widget.filePath!, _currentData);
    setState(() => _hasUnsavedChanges = false);
  }

  void _editNodeDialog(String id, String currentLabel, bool isBranch, {Branch? branchObj, Leaf? leafObj}) {
    if (widget.filePath == null) return; 

    TextEditingController textCtrl = TextEditingController(text: currentLabel);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit ${isBranch ? 'Branch' : 'Leaf'}"),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(labelText: "Label", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                if (id == 'root') {
                  _currentData = _currentData.copyWith(rootLabel: textCtrl.text);
                } else if (isBranch && branchObj != null) {
                  int idx = _currentData.branches.indexOf(branchObj);
                  if (idx != -1) {
                    List<Branch> newBranches = List.from(_currentData.branches);
                    newBranches[idx] = branchObj.copyWith(name: textCtrl.text);
                    _currentData = _currentData.copyWith(branches: newBranches);
                  }
                } else if (!isBranch && leafObj != null && branchObj != null) {
                   int bIdx = _currentData.branches.indexOf(branchObj);
                   if (bIdx != -1) {
                     List<Branch> newBranches = List.from(_currentData.branches);
                     Branch targetBranch = newBranches[bIdx];
                     
                     int lIdx = targetBranch.children.indexOf(leafObj);
                     if (lIdx != -1) {
                        List<Leaf> newLeaves = List.from(targetBranch.children);
                        newLeaves[lIdx] = leafObj.copyWith(label: textCtrl.text);
                        newBranches[bIdx] = targetBranch.copyWith(children: newLeaves);
                        _currentData = _currentData.copyWith(branches: newBranches);
                     }
                   }
                }
                _hasUnsavedChanges = true;
              });
              Navigator.pop(ctx);
            },
            child: const Text("SAVE"),
          )
        ],
      ),
    );
  }

Future<void> _handleDeepDive(Leaf leaf, Branch parentBranch) async {
    final prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('api_url');
    
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(" URL non configurée")));
      return;
    }

    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(" Recherche en profondeur..."), duration: Duration(seconds: 2))
    );

    print(" Sending Deep Dive request for: ${leaf.label}"); 

    List<Leaf> newSubLeaves = await ApiService.expandNode(url, leaf.label, parentBranch.name);

    print(" Received ${newSubLeaves.length} items from AI"); 

    if (newSubLeaves.isNotEmpty) {
      setState(() {
        List<Branch> newBranches = List.from(_currentData.branches);
        int bIdx = newBranches.indexOf(parentBranch);
        
        if (bIdx != -1) {
          List<Leaf> newLeaves = List.from(parentBranch.children);
          int lIdx = newLeaves.indexOf(leaf);
          
          if (lIdx != -1) {
             print(" Updating tree structure for node ${leaf.label}"); 
             newLeaves[lIdx] = leaf.copyWith(children: newSubLeaves);
             newBranches[bIdx] = parentBranch.copyWith(children: newLeaves);
             _currentData = _currentData.copyWith(branches: newBranches);
          } else {
             print(" Error: Leaf not found in branch");
          }
        } else {
           print(" Error: Branch not found");
        }
      });
      _saveChanges(); 
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" L'IA n'a rien renvoyé. Réessayez."), backgroundColor: Colors.orange)
        );
      }
    }
  }

  void _showDetails(Leaf leaf, Branch parentBranch) { 
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(leaf.label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                if (leaf.children.isEmpty) 
                  ElevatedButton.icon(
                    onPressed: () => _handleDeepDive(leaf, parentBranch),
                    icon: const Icon(Icons.psychology, size: 18),
                    label: const Text("DEEP DIVE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  )
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Text(leaf.fullText),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.deepPurple),
              onPressed: _saveChanges,
            )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)],
              )
            ),
            child: InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(2000),
              minScale: 0.1, maxScale: 4.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double contentHeight = _calculateTreeLayout();
                  _dynamicCanvasHeight = math.max(2000.0, contentHeight + 500.0);
                  final Size canvasSize = Size(4000.0, _dynamicCanvasHeight);

                  return SizedBox(
                    width: canvasSize.width,
                    height: canvasSize.height,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: canvasSize,
                          painter: TreePainter(
                            positions: nodePositions,
                            data: _currentData,
                            animationValue: _controller.value,
                          ),
                        ),
                        ..._buildAnimatedNodes(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTreeLayout() {
    double levelGapX = 400.0;
    double gapY = 160.0;
    double currentY = 100.0;

    nodePositions.clear();
    double branchX = 100.0 + levelGapX;
    double leafX = branchX + levelGapX;
    double subLeafX = leafX + levelGapX; 

    for (var branch in _currentData.branches) {
      bool isCollapsed = _collapsedNodes.contains(branch.name);
      
      double branchHeight = 0;
      if (!isCollapsed) {
        for (var leaf in branch.children) {
           int subCount = leaf.children.isEmpty ? 1 : leaf.children.length;
           branchHeight += subCount * gapY;
        }
      } else {
        branchHeight = gapY; 
      }

      double branchCenterY = currentY + (branchHeight / 2) - (gapY / 2);
      nodePositions[branch.name] = Offset(branchX, branchCenterY);

      if (!isCollapsed) {
        double leafY = currentY;
        for (var leaf in branch.children) {
          String key = "${branch.name}_${leaf.label}";
          
          int subCount = leaf.children.isEmpty ? 1 : leaf.children.length;
          double leafBlockHeight = subCount * gapY;
          double leafCenterY = leafY + (leafBlockHeight / 2) - (gapY / 2);
          
          nodePositions[key] = Offset(leafX, leafCenterY);

          if (leaf.children.isNotEmpty) {
             double subY = leafY;
             for (var sub in leaf.children) {
                String subKey = "${key}_${sub.label}";
                nodePositions[subKey] = Offset(subLeafX, subY);
                subY += gapY;
             }
          }

          leafY += leafBlockHeight;
        }
        currentY = leafY + 80.0; 
      } else {
        currentY += gapY + 80.0;
      }
    }
    double totalHeight = currentY;
    nodePositions['root'] = Offset(100.0, totalHeight / 2);
    return totalHeight;
  }

  List<Widget> _buildAnimatedNodes() {
    List<Widget> widgets = [];
    
    widgets.add(_buildNode(
      id: 'root',
      label: _currentData.rootLabel,
      color: AppStyle.centerColor,
      isRoot: true,
      onLongPress: () => _editNodeDialog('root', _currentData.rootLabel, false),
    ));

    for (int i = 0; i < _currentData.branches.length; i++) {
      var branch = _currentData.branches[i];
      Color color = AppStyle.branchColors[i % AppStyle.branchColors.length];
      bool isCollapsed = _collapsedNodes.contains(branch.name);
      String displayLabel = isCollapsed ? "${branch.name} (+)" : branch.name;

      widgets.add(_buildNode(
        id: branch.name,
        label: displayLabel,
        color: color,
        isBranch: true,
        onTap: () {
           setState(() {
             if (_collapsedNodes.contains(branch.name)) {
               _collapsedNodes.remove(branch.name);
             } else {
               _collapsedNodes.add(branch.name);
             }
           });
        },
        onLongPress: () => _editNodeDialog(branch.name, branch.name, true, branchObj: branch),
      ));

      if (!isCollapsed) {
        for (int j = 0; j < branch.children.length; j++) {
          var leaf = branch.children[j];
          String key = "${branch.name}_${leaf.label}";
          Color leafCol = leaf.status == 'warning' ? AppStyle.warningColor : AppStyle.leafColor;

          widgets.add(_buildNode(
            id: key,
            label: leaf.label,
            color: leafCol,
            isLeaf: true,
            onTap: () => _showDetails(leaf, branch), 
            onLongPress: () => _editNodeDialog(key, leaf.label, false, branchObj: branch, leafObj: leaf),
          ));

          for (var sub in leaf.children) {
            String subKey = "${key}_${sub.label}";
            widgets.add(_buildNode(
              id: subKey,
              label: sub.label,
              color: AppStyle.leafColor.withOpacity(0.9), 
              isLeaf: true,
              onTap: () => _showDetails(sub, branch), 
              onLongPress: () {}, 
            ));
          }
        }
      }
    }
    return widgets;
  }

  Widget _buildNode({
    required String id,
    required String label,
    required Color color,
    bool isRoot = false,
    bool isBranch = false,
    bool isLeaf = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    if (!nodePositions.containsKey(id)) return const SizedBox();
    Offset pos = nodePositions[id]!;

    return Positioned(
      left: pos.dx - (isRoot ? 90 : 75), 
      top: pos.dy - 35,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress, 
        child: NodeVisual(label: label, color: color, isRoot: isRoot, isLeaf: isLeaf),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }
}