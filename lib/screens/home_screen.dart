import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/travel_item.dart';
import 'form_screen.dart';
import 'package:flutter/foundation.dart';

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
    _loadItems();
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
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
    _saveItems();
  }

  void _navigateToForm({TravelItem? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormScreen(itemToEdit: item)),
    );

    if (result != null && result is TravelItem) {
      setState(() {
        if (item != null) {
          final index = _items.indexWhere((element) => element.id == item.id);
          _items[index] = result;
        } else {
          _items.add(result);
        }
      });
      _saveItems();
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
                            backgroundImage: kIsWeb
                                ? NetworkImage(item.imagePath!)
                                      as ImageProvider // WEB
                                : FileImage(File(item.imagePath!)), // MOBILE
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
                    onTap: () => _navigateToForm(item: item),
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
