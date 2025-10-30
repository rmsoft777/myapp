import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  late final Future<List<Map<String, dynamic>>> _ordersFuture;
  late final Future<List<Map<String, dynamic>>> _staffFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
    _staffFuture = _fetchStaff();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('orders')
        .select('*, customer:customer_id(name), staff:assigned_staff_id(name)');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchStaff() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('users').select().eq('role', 'staff');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    final supabase = Supabase.instance.client;
    await supabase.from('orders').update({'status': status}).eq('order_id', orderId);
    setState(() {
      _ordersFuture = _fetchOrders(); // Refresh the orders
    });
  }

  Future<void> _assignStaff(int orderId, int staffId) async {
    final supabase = Supabase.instance.client;
    await supabase.from('orders').update({'assigned_staff_id': staffId}).eq('order_id', orderId);
    setState(() {
      _ordersFuture = _fetchOrders(); // Refresh the orders
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }
        final orders = snapshot.data!;
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final customerName = order['customer'] != null ? order['customer']['name'] : 'N/A';
            final staffName = order['staff'] != null ? order['staff']['name'] : 'Unassigned';
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order['order_id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Customer: $customerName'),
                    Text('Event Date: ${order['event_date']}'),
                    Text('Status: ${order['status']}'),
                    Text('Assigned to: $staffName'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusDropdown(order),
                        _buildStaffDropdown(order),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusDropdown(Map<String, dynamic> order) {
    final statuses = ['pending', 'accepted', 'in_progress', 'completed', 'cancelled'];
    return DropdownButton<String>(
      value: order['status'],
      hint: const Text('Update Status'),
      items: statuses.map((String status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          _updateOrderStatus(order['order_id'], newValue);
        }
      },
    );
  }

  Widget _buildStaffDropdown(Map<String, dynamic> order) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _staffFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink(); // Or a loading indicator
        }
        final staffList = snapshot.data!;
        return DropdownButton<int>(
          hint: const Text('Assign Staff'),
          items: staffList.map((staff) {
            return DropdownMenuItem<int>(
              value: staff['user_id'],
              child: Text(staff['name']),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              _assignStaff(order['order_id'], newValue);
            }
          },
        );
      },
    );
  }
}
