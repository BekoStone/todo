T enumFromName<T extends Enum>(Iterable<T> values, String name) =>
    values.firstWhere((e) => e.name == name);

extension EnumToName on Enum {
  String get nameLower => name.toLowerCase();
}
