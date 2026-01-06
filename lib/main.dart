import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

// --- GŁÓWNA KONFIGURACJA APLIKACJI ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moje Podróże',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true, // Mobile-friendly UI (Wymóg na 3)
      ),
      home: const HomeScreen(),
    );
  }
}

// --- MODEL DANYCH (Wymóg na 3 - Kolekcja obiektów) ---
class TravelItem {
  final String id;
  String title;
  String description;
  String? imagePath; // Ścieżka do zdjęcia (Wymóg na 5)

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

// --- WIDOK 1: LISTA ELEMENTÓW (Wymóg na 3 - Routing, Usuwanie) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TravelItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems(); // Wczytanie danych przy starcie (Wymóg na 4)
  }

  // --- OBSŁUGA ZAPISU I ODCZYTU (Wymóg na 4) ---
  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    // Konwertujemy listę obiektów na listę stringów JSON
    final String encodedData = json.encode(
      _items.map((item) => item.toMap()).toList(),
    );
    await prefs.setString('travel_items', encodedData);
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('travel_items');
    if (encodedData != null) {
      final List<dynamic> decodedData = json.decode(encodedData);
      setState(() {
        _items = decodedData.map((item) => TravelItem.fromMap(item)).toList();
      });
    }
  }

  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
    _saveItems(); // Zapis po usunięciu
  }

  // Nawigacja do ekranu formularza
  void _navigateToForm({TravelItem? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormScreen(itemToEdit: item)),
    );

    if (result != null && result is TravelItem) {
      setState(() {
        if (item != null) {
          // Edycja: znajdź indeks i podmień
          final index = _items.indexWhere((element) => element.id == item.id);
          _items[index] = result;
        } else {
          // Dodawanie nowego
          _items.add(result);
        }
      });
      _saveItems(); // Zapis po dodaniu/edycji
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista Podróży')),
      body: _items.isEmpty
          ? const Center(child: Text('Brak notatek. Dodaj pierwszą!'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: item.imagePath != null
                        ? CircleAvatar(
                            backgroundImage: FileImage(File(item.imagePath!)),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.image_not_supported),
                          ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(item.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(item.id),
                    ),
                    onTap: () =>
                        _navigateToForm(item: item), // Edycja po kliknięciu
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- WIDOK 2: FORMULARZ (Wymóg na 3 - Dodawanie/Edycja/Walidacja + Wymóg na 5 - Kamera) ---
class FormScreen extends StatefulWidget {
  final TravelItem? itemToEdit;

  const FormScreen({super.key, this.itemToEdit});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Jeśli edytujemy, wypełniamy pola danymi
    if (widget.itemToEdit != null) {
      _titleController.text = widget.itemToEdit!.title;
      _descController.text = widget.itemToEdit!.description;
      if (widget.itemToEdit!.imagePath != null) {
        _selectedImage = File(widget.itemToEdit!.imagePath!);
      }
    }
  }

  // --- OBSŁUGA KAMERY (Wymóg na 5) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Wywołanie kamery
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource
          .camera, // Zmień na ImageSource.gallery aby pobrać z galerii
      maxWidth: 600,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _saveForm() {
    // Walidacja formularza (Wymóg na 3)
    if (_formKey.currentState!.validate()) {
      final newItem = TravelItem(
        id:
            widget.itemToEdit?.id ??
            const Uuid().v4(), // Zachowaj ID przy edycji lub generuj nowe
        title: _titleController.text,
        description: _descController.text,
        imagePath: _selectedImage?.path,
      );

      Navigator.pop(context, newItem); // Powrót do poprzedniego ekranu z danymi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemToEdit != null ? 'Edytuj Notatkę' : 'Nowa Notatka',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Pole Tytułu z walidacją
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tytuł miejsca',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać tytuł';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              // Pole Opisu
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.length < 5) {
                    return 'Opis musi mieć min. 5 znaków';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Podgląd zdjęcia i przycisk kamery
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.grey),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera),
                    label: const Text('Zrób zdjęcie'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveForm,
                  child: const Text('Zapisz', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
