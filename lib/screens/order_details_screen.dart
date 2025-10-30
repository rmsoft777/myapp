import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<Map<String, dynamic>> _orderDetailsFuture;

  @override
  void initState() {
    super.initState();
    _orderDetailsFuture = _fetchOrderDetails();
  }

  Future<Map<String, dynamic>> _fetchOrderDetails() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('orders')
        .select('*, customer:customer_id(name, phone, address), items:order_items(*, item:menu_items(item_name)), payments:payments(*))')
        .eq('order_id', widget.orderId)
        .single();
    return response;
  }

  Future<void> _updateOrderStatus(String status) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('orders')
          .update({'status': status})
          .eq('order_id', widget.orderId);
      if (!mounted) return;
      setState(() {
        _orderDetailsFuture = _fetchOrderDetails();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $status')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $error')),
      );
    }
  }
  
  void _showPaymentDialog() {
    final amountController = TextEditingController();
    String? paymentStatus = 'partial';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Payment'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount Paid'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: paymentStatus,
                    items: ['partial', 'full'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        paymentStatus = newValue;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Payment Status'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || paymentStatus == null) {
                  return; // Or show an error
                }
                await _savePayment(amount, paymentStatus!);
                if(mounted) Navigator.of(context).pop();
              },
              child: const Text('Save Payment'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePayment(double amount, String status) async {
    try {
      final supabase = Supabase.instance.client;
      final adminId = supabase.auth.currentUser!.id;
      final orderDetails = await _orderDetailsFuture;
      final totalAmount = orderDetails['total_amount'] ?? 0;
      final existingPayments = await supabase.from('payments').select('paid_amount').eq('order_id', widget.orderId);
      final totalPaid = existingPayments.fold<double>(0, (sum, p) => sum + (p['paid_amount'] ?? 0));
      final newTotalPaid = totalPaid + amount;
      final remainingBalance = totalAmount - newTotalPaid;

      await supabase.from('payments').insert({
        'order_id': widget.orderId,
        'paid_amount': amount,
        'payment_status': status,
        'entered_by': adminId,
        'remaining_balance': remainingBalance,
      });
      if (!mounted) return;
      setState(() {
        _orderDetailsFuture = _fetchOrderDetails();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment saved successfully!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving payment: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _orderDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final order = snapshot.data!;
          final customer = order['customer'] ?? {};
          final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
          final payments = List<Map<String, dynamic>>.from(order['payments'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Customer Details'),
                _buildInfoCard(customer, order),
                const SizedBox(height: 20),
                _buildSectionTitle('Order Items'),
                _buildItemsCard(items),
                const SizedBox(height: 20),
                _buildSectionTitle('Payment History'),
                _buildPaymentsCard(payments),
                const SizedBox(height: 30),
                _buildActionButtons(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold));
  }

  Widget _buildInfoCard(Map<String, dynamic> customer, Map<String, dynamic> order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildInfoRow('Name', customer['name'] ?? 'N/A'),
          _buildInfoRow('Phone', customer['phone'] ?? 'N/A'),
          _buildInfoRow('Address', order['address'] ?? 'N/A'),
          _buildInfoRow('Event Date', order['event_date'] ?? 'N/A'),
          _buildInfoRow('Total Amount', '₹${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}'),
        ]),
      ),
    );
  }

  Widget _buildItemsCard(List<Map<String, dynamic>> items) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item['item']?['item_name'] ?? item['item_name_snapshot'] ?? 'N/A'),
            trailing: Text('Qty: ${item['quantity']}'),
          );
        },
        separatorBuilder: (_, __) => const Divider(),
      ),
    );
  }

  Widget _buildPaymentsCard(List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return const Card(child: ListTile(title: Text('No payments recorded yet.')));
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return ListTile(
            title: Text('Amount: ₹${payment['paid_amount']?.toStringAsFixed(2) ?? '0.00'}'),
            subtitle: Text('Status: ${payment['payment_status']}'),
            trailing: Text(payment['payment_date'] != null ? 'on ${payment['payment_date'].toString().substring(0,10)}' : ''),
          );
        },
        separatorBuilder: (_, __) => const Divider(),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    return Column(
      children: [
        if (order['status'] == 'pending')
          ElevatedButton(
            child: const Text('Accept Order'),
            onPressed: () => _updateOrderStatus('accepted'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        const SizedBox(height: 10),
        ElevatedButton(
          child: const Text('Enter Payment'),
          onPressed: _showPaymentDialog,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), Text(value)],
      ),
    );
  }

}
