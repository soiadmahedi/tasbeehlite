// lib/models/dua_model.dart
class DuaModel {
  String id;
  String nameKey; // Key for localization
  String arabicText;
  int targetCount;
  int currentCount;

  DuaModel({
    required this.id,
    required this.nameKey,
    required this.arabicText,
    required this.targetCount,
    this.currentCount = 0,
  });

  factory DuaModel.fromJson(Map<String, dynamic> json) {
    return DuaModel(
      id: json['id'],
      nameKey: json['nameKey'],
      arabicText: json['arabicText'] ?? '',
      targetCount: json['targetCount'],
      currentCount: json['currentCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
      'arabicText': arabicText,
      'targetCount': targetCount,
      'currentCount': currentCount,
    };
  }
}