import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DesignPlateScreen extends StatefulWidget {
  const DesignPlateScreen({super.key});

  @override
  State<DesignPlateScreen> createState() => _DesignPlateScreenState();
}

class _DesignPlateScreenState extends State<DesignPlateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _plateCategory;
  List<Map<String, dynamic>> _availableItems = [];
  List<Map<String, dynamic>> _selectedItems = [];
  double _totalPrice = 0.0;
  String _searchTerm = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableItems();
  }

  Future<void> _fetchAvailableItems() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('menu_items').select().eq('is_available', true);
    setState(() {
      _availableItems = List<Map<String, dynamic>>.from(response);
    });
  }

  void _addItemToPlate(Map<String, dynamic> item) {
    setState(() {
      _selectedItems.add(item);
      _totalPrice += item['price'];
    });
  }

  void _removeItemFromPlate(Map<String, dynamic> item) {
    setState(() {
      _selectedItems.remove(item);
      _totalPrice -= item['price'];
    });
  }

  Future<void> _savePlate() async {
    if (!_formKey.currentState!.validate() || _selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all fields and select at least one item.')),
        );
        return;
    }

    setState(() => _isLoading = true);

    try {
        final supabase = Supabase.instance.client;
        final adminId = supabase.auth.currentUser!.id;
        
        final plateResponse = await supabase.from('admin_designed_plates').insert({
            'plate_name': _plateNameController.text,
            'description': _descriptionController.text,
            'total_price': _totalPrice,
            'category': _plateCategory,
            'created_by': adminId,
        }).select();
        
        final newPlateId = plateResponse[0]['plate_id'];

        final plateItems = _selectedItems.map((item) => {
            'plate_id': newPlateId,
            'item_id': item['item_id'],
        }).toList();

        await supabase.from('plate_items').insert(plateItems);

        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plate designed successfully!')),
            );
            _formKey.currentState!.reset();
            setState(() {
                _plateNameController.clear();
                _descriptionController.clear();
                _plateCategory = null;
                _selectedItems.clear();
                _totalPrice = 0.0;
            });
        }
    } catch (error) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving plate: $error')),
            );
        }
    } finally {
        if (mounted) {
            setState(() => _isLoading = false);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _availableItems.where((item) {
        final itemName = item['item_name'].toString().toLowerCase();
        return itemName.contains(_searchTerm.toLowerCase());
    }).toList();

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
            key: _formKey,
            child: Column(
                children: [
                    _buildPlateDetailsForm(),
                    const SizedBox(height: 20),
                    Expanded(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                _buildAvailableItemsList(filteredItems),
                                const VerticalDivider(width: 20, thickness: 1),
                                _buildSelectedItemsList(),
                            ],
                        ),
                    ),
                    const SizedBox(height: 20),
                    _buildFooter(),
                ],
            ),
        ),
    );
  }

  Widget _buildPlateDetailsForm() {
    return Column(
        children: [
            TextFormField(
                controller: _plateNameController,
                decoration: const InputDecoration(labelText: 'Plate Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a plate name' : null,
            ),
            TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButtonFormField<String>(
                value: _plateCategory,
                hint: const Text('Select Category'),
                items: ['Veg', 'Non-Veg', 'Mixed'].map((String category) {
                    return DropdownMenuItem<String>(value: category, child: Text(category));
                }).toList(),
                onChanged: (newValue) => setState(() => _plateCategory = newValue),
                validator: (value) => value == null ? 'Select a category' : null,
            ),
        ],
    );
  }

  Widget _buildAvailableItemsList(List<Map<String, dynamic>> items) {
    return Expanded(
        child: Column(
            children: [
                Text('Available Menu Items', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(
                    onChanged: (value) => setState(() => _searchTerm = value),
                    decoration: const InputDecoration(labelText: 'Search...', suffixIcon: Icon(Icons.search)),
                ),
                Expanded(
                    child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                                title: Text(item['item_name']),
                                subtitle: Text('\₹${item['price'].toStringAsFixed(2)}'),
                                trailing: IconButton(
                                    icon: const Icon(Icons.add, color: Colors.green),
                                    onPressed: () => _addItemToPlate(item),
                                ),
                            );
                        },
                    ),
                ),
            ],
        ),
    );
  }

  Widget _buildSelectedItemsList() {
    return Expanded(
        child: Column(
            children: [
                Text('Selected Items', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                    child: _selectedItems.isEmpty
                        ? const Center(child: Text('No items selected.'))
                        : ListView.builder(
                            itemCount: _selectedItems.length,
                            itemBuilder: (context, index) {
                                final item = _selectedItems[index];
                                return ListTile(
                                    title: Text(item['item_name']),
                                    subtitle: Text('\₹${item['price'].toStringAsFixed(2)}'),
                                    trailing: IconButton(
                                        icon: const Icon(Icons.remove, color: Colors.red),
                                        onPressed: () => _removeItemFromPlate(item),
                                    ),
                                );
                            },
                        ),
                ),
            ],
        ),
    );
  }

  Widget _buildFooter() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Text('Total: \₹${_totalPrice.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _savePlate,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Plate'),
                ),
        ],
    );
  }
}
