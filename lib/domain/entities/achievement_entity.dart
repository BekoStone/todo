class AchievementEntity {
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  const AchievementEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  AchievementEntity copyWith({bool? unlocked}) =>
      AchievementEntity(id: id, title: title, description: description, unlocked: unlocked ?? this.unlocked);
}
