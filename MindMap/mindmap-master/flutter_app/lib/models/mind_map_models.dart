class MindMapData {
  final String rootLabel;
  final List<Branch> branches;
  
  MindMapData({required this.rootLabel, required this.branches});
  
  MindMapData copyWith({String? rootLabel, List<Branch>? branches}) {
    return MindMapData(
      rootLabel: rootLabel ?? this.rootLabel,
      branches: branches ?? this.branches,
    );
  }

  factory MindMapData.fromJson(Map<String, dynamic> json) {
    return MindMapData(
      rootLabel: json['root_label'] ?? 'Racine',
      branches: (json['branches'] as List).map((b) => Branch.fromJson(b)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'root_label': rootLabel,
    'branches': branches.map((b) => b.toJson()).toList(),
  };
}

class Branch {
  final String name;
  final List<Leaf> children;
  
  Branch({required this.name, required this.children});
  
  Branch copyWith({String? name, List<Leaf>? children}) {
    return Branch(
      name: name ?? this.name,
      children: children ?? this.children,
    );
  }
  
  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      name: json['name'] ?? 'Branche',
      children: (json['children'] as List).map((l) => Leaf.fromJson(l)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'children': children.map((c) => c.toJson()).toList(),
  };
}

class Leaf {
  final String label;
  final String fullText;
  final String status;
  final String? correction;
  final List<Leaf> children; 

  Leaf({
    required this.label, 
    required this.fullText, 
    required this.status, 
    this.correction,
    this.children = const [],
  });
  
  Leaf copyWith({String? label, String? fullText, String? status, String? correction, List<Leaf>? children}) {
    return Leaf(
      label: label ?? this.label,
      fullText: fullText ?? this.fullText,
      status: status ?? this.status,
      correction: correction ?? this.correction,
      children: children ?? this.children,
    );
  }
  
  factory Leaf.fromJson(Map<String, dynamic> json) {
    var childrenJson = json['children'] as List?;
    return Leaf(
      label: json['label'] ?? 'Info',
      fullText: json['full_text'] ?? '',
      status: json['status'] ?? 'correct',
      correction: json['correction'],
      children: childrenJson != null 
          ? childrenJson.map((x) => Leaf.fromJson(x)).toList() 
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'full_text': fullText,
    'status': status,
    'correction': correction,
    'children': children.map((c) => c.toJson()).toList(),
  };
}