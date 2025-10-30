import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _role;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Directly insert the new user into the public.users table
      await supabase.from('users').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'password_hash': _passwordController.text, // Storing as plain text to match login logic
        'phone': _phoneController.text,
        'address': _addressController.text,
        'role': _role,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully!')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _phoneController.clear();
          _addressController.clear();
          _role = null;
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database Error: ${error.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $error')),
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an email.';
                  if (!value.contains('@')) return 'Please enter a valid email.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a password.' : null,
              ),
               const SizedBox(height: 16),
               TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _role,
                hint: const Text('Select Role'),
                items: ['staff', 'admin'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role.capitalize()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _role = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a role.' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createUser,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Create User'),
                    ),
            ],
          ),
        ),
    );
  }
}

extension StringExtension on String {
    String capitalize() {
        if (isEmpty) return this;
        return "${this[0].toUpperCase()}${substring(1)}";
    }
}
