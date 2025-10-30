import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateMenuScreen extends StatefulWidget {
  const CreateMenuScreen({super.key});

  @override
  State<CreateMenuScreen> createState() => _CreateMenuScreenState();
}

class _CreateMenuScreenState extends State<CreateMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _categoryId;
  bool _isAvailable = true;
  bool _isLoading = false;
  late final Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('menu_category').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _createMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('menu_items').insert({
        'item_name': _itemNameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'category_id': _categoryId,
        'is_available': _isAvailable,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item created successfully!')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _itemNameController.clear();
          _priceController.clear();
          _descriptionController.clear();
          _categoryId = null;
          _isAvailable = true;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating menu item: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _itemNameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the item name.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the price.';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading categories: ${snapshot.error}'));
                }
                final categories = snapshot.data ?? [];
                return DropdownButtonFormField<int>(
                  value: _categoryId,
                  hint: const Text('Select Category'),
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category['category_id'] as int,
                      child: Text(category['category_name'] as String),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _categoryId = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category.';
                    }
                    return null;
                  },
                );
              },
            ),
            SwitchListTile(
              title: const Text('Is Available'),
              value: _isAvailable,
              onChanged: (bool value) {
                setState(() {
                  _isAvailable = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _createMenuItem,
                    child: const Text('Create Item'),
                  ),
          ],
        ),
      ),
    );
  }
}
