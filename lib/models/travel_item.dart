class TravelItem {
  final String id;
  String title;
  String description;
  String? imagePath;

  TravelItem({
    required this.id,
    required this.title,
    required this.description,
    this.imagePath,
  });

  // Konwersja do Mapy (potrzebne do zapisu JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
    };
  }

  // Tworzenie obiektu z Mapy (potrzebne do odczytu JSON)
  factory TravelItem.fromMap(Map<String, dynamic> map) {
    return TravelItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imagePath: map['imagePath'],
    );
  }
}
