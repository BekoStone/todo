import '../../domain/entities/achievement_entity.dart';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  const AchievementModel({required this.id, required this.title, required this.description, required this.unlocked});

  AchievementEntity toEntity() =>
      AchievementEntity(id: id, title: title, description: description, unlocked: unlocked);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'unlocked': unlocked};

  factory AchievementModel.fromJson(Map<String, dynamic> json) => AchievementModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        unlocked: json['unlocked'] as bool,
      );
}
