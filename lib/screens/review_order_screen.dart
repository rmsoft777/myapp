import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewOrderScreen extends StatefulWidget {
  final Map<String, dynamic> orderDetails;

  const ReviewOrderScreen({super.key, required this.orderDetails});

  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  late final Map<int, int> _cart;
  late final Map<int, Map<String, dynamic>> _itemDetails;
  late final double _totalAmount;

  @override
  void initState() {
    super.initState();
    _cart = widget.orderDetails['cart'];
    _itemDetails = widget.orderDetails['itemDetails'];
    _totalAmount = _calculateTotal();
  }

  double _calculateTotal() {
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = _itemDetails[itemId]!;
      total += (item['price'] as num) * quantity;
    });
    return total;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields and select a date.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderResponse = await supabase.from('orders').insert({
        'customer_id': user.id,
        'address': _addressController.text,
        'event_date': _selectedDate!.toIso8601String(),
        'total_amount': _totalAmount,
        'status': 'pending',
      }).select('order_id');

      final orderId = orderResponse[0]['order_id'];

      final orderItems = _cart.entries.map((entry) {
        final item = _itemDetails[entry.key]!;
        return {
          'order_id': orderId,
          'item_id': entry.key,
          'quantity': entry.value,
          'item_name_snapshot': item['item_name'],
          'item_price_snapshot': item['price'],
          'subtotal': (item['price'] as num) * entry.value,
        };
      }).toList();

      await supabase.from('order_items').insert(orderItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green),
        );
        context.go('/customer');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $error'), backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Your Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Order Summary',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildCartList(),
              const Divider(thickness: 2, height: 32),
              _buildTotalSection(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Enter the full address for the event',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the delivery address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No date selected'
                          : 'Event Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Choose Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Confirm & Place Order'),
              ),
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cart.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final itemId = _cart.keys.elementAt(index);
        final quantity = _cart[itemId]!;
        final item = _itemDetails[itemId]!;
        final subtotal = (item['price'] as num) * quantity;

        return ListTile(
          title: Text(item['item_name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text('Quantity: $quantity'),
          trailing: Text('\$${subtotal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        );
      },
    );
  }

  Widget _buildTotalSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total Amount', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('\$${_totalAmount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
      ],
    );
  }
}
