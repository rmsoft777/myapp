import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('orders')
        .select('*, customer:customer_id(name, phone)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending orders found.'));
          }
          final orders = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshOrders(),
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final customer = order['customer'];
                final customerName = customer != null ? customer['name'] : 'N/A';
                final customerPhone = customer != null ? customer['phone'] : 'N/A';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text('Order #${order['order_id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Customer: $customerName', style: GoogleFonts.poppins()),
                        Text('Phone: $customerPhone', style: GoogleFonts.poppins()),
                        Text('Event Date: ${order['event_date']}', style: GoogleFonts.poppins()),
                        Text('Status: ${order['status']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      context.go('/admin/order/${order['order_id']}');
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
