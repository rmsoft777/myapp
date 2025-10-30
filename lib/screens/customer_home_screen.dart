import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late Future<List<Map<String, dynamic>>> _pendingOrdersFuture;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _pendingOrdersFuture = _fetchPendingOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingOrders() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('orders')
        .select('*, users(name)')
        .eq('customer_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Panel',
            onPressed: () => context.go('/admin'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _pendingOrdersFuture = _fetchPendingOrders();
          });
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildCreateOrderSection(context),
            const SizedBox(height: 24),
            const Divider(thickness: 1.5),
            const SizedBox(height: 24),
            Text(
              'Your Pending Orders',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPendingOrdersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOrderSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Place a New Order',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Create a Custom Order'),
              onPressed: () => context.go('/create-order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepOrange,
                side: const BorderSide(color: Colors.deepOrange),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOrdersList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pendingOrdersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders = snapshot.data;
        if (orders == null || orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'You have no pending orders.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final eventDate = order['event_date'] != null
                ? DateFormat.yMMMd().format(DateTime.parse(order['event_date']))
                : 'N/A';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text('Order #${order['order_id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Event Date: $eventDate'),
                    Text('Total: \$${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}'),
                  ],
                ),
                trailing: Chip(
                  label: Text(
                    order['status'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange.shade700,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
