import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  late Future<List<Map<String, dynamic>>> _menuItemsFuture;
  final Map<int, int> _cart = {};
  final Map<int, Map<String, dynamic>> _itemDetails = {};

  @override
  void initState() {
    super.initState();
    _menuItemsFuture = _fetchMenuItems();
  }

  Future<List<Map<String, dynamic>>> _fetchMenuItems() async {
    final response = await Supabase.instance.client
        .from('menu_items')
        .select()
        .eq('is_available', true);
    final items = List<Map<String, dynamic>>.from(response);
    for (var item in items) {
      _itemDetails[item['item_id']] = item;
    }
    return items;
  }

  void _addToCart(int itemId) {
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + 1;
    });
  }

  void _removeFromCart(int itemId) {
    setState(() {
      if (_cart.containsKey(itemId)) {
        _cart[itemId] = _cart[itemId]! - 1;
        if (_cart[itemId]! <= 0) {
          _cart.remove(itemId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _menuItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No menu items available.'));
          }
          final menuItems = snapshot.data!;
          return ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final itemId = item['item_id'];
              final quantity = _cart[itemId] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 3.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['item_name'],
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['description'] ?? '',
                              style: GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${item['price']}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.deepOrange),
                            onPressed: quantity > 0 ? () => _removeFromCart(itemId) : null,
                          ),
                          Text(
                            '$quantity',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                            onPressed: () => _addToCart(itemId),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final orderDetails = {
                  'cart': _cart,
                  'itemDetails': _itemDetails,
                };
                context.go('/review-order', extra: orderDetails);
              },
              label: const Text('Review Order'),
              icon: const Icon(Icons.shopping_cart),
              backgroundColor: Colors.deepOrange,
            ),
    );
  }
}
