import 'dart:io'; // Potrzebne dla Android/iOS
import 'package:flutter/foundation.dart'; // Potrzebne do kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/travel_item.dart';

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

  // Zmiana: Przechowujemy ścieżkę jako String, a nie obiekt File
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _titleController.text = widget.itemToEdit!.title;
      _descController.text = widget.itemToEdit!.description;
      // Wczytujemy istniejącą ścieżkę
      _selectedImagePath = widget.itemToEdit!.imagePath;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Na Web to zwróci Blob URL, na Mobile ścieżkę do pliku
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera, // Lub ImageSource.gallery
      maxWidth: 600,
    );

    if (pickedFile != null) {
      setState(() {
        // Zapisujemy samą ścieżkę (String), to jest bezpieczne na każdej platformie
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newItem = TravelItem(
        id: widget.itemToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descController.text,
        imagePath: _selectedImagePath,
      );

      Navigator.pop(context, newItem);
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tytuł miejsca',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Proszę podać tytuł'
                    : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => (value == null || value.length < 5)
                    ? 'Opis musi mieć min. 5 znaków'
                    : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // --- TUTAJ JEST KLUCZOWA ZMIANA ---
                    child: _selectedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                // Jeśli WEB: używamy Image.network
                                ? Image.network(
                                    _selectedImagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(Icons.error),
                                  )
                                // Jeśli MOBILE: używamy Image.file
                                : Image.file(
                                    File(_selectedImagePath!),
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
