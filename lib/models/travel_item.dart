class TravelItem {
  final String id;
  String title;
  String description;
  String? imagePath;
  DateTime date;

  TravelItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.imagePath,
  });

  // Konwersja do Mapy (potrzebne do zapisu JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
    };
  }

  // Tworzenie obiektu z Mapy (potrzebne do odczytu JSON)
  factory TravelItem.fromMap(Map<String, dynamic> map) {
    return TravelItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imagePath: map['imagePath'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    );
  }
}
