import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _otpSent = false;
  bool _isStaffLogin = false;

  // Simulate sending OTP for customers
  Future<void> _sendOtp() async {
    // Basic validation
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number.')),
      );
      return;
    }
    setState(() {
      _otpSent = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the test OTP (225588).')),
      );
    }
  }

  // Simulate OTP verification for customers
  Future<void> _verifyOtp() async {
    if (_otpController.text == '225588') {
      if (mounted) {
        // For now, all OTP logins are considered customers
        context.go('/customer');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Use 225588')),
        );
      }
    }
  }

  // Sign in for Staff/Admin
  Future<void> _signInWithEmailAndPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('email', email)
          .eq('password_hash', password) // Plain text password check as requested
          .inFilter('role', ['staff', 'admin']).single();

      final role = response['role'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );

        // Navigate based on role
        switch (role) {
          case 'admin':
            context.go('/admin');
            break;
          case 'staff':
            context.go('/staff');
            break;
          default:
            // As a fallback, go to a generic home screen
            context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Login Failed: Invalid credentials or not authorized.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Image.asset('assets/images/logo.png', height: 120),
              const SizedBox(height: 24),
              _buildLoginToggle(),
              const SizedBox(height: 24),
              Text(
                _isStaffLogin
                    ? 'Staff & Admin Login'
                    : (_otpSent ? 'Verify your phone' : 'Customer Login'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (_isStaffLogin)
                _buildStaffInput()
              else if (!_otpSent)
                _buildPhoneInput(),
              if (!_isStaffLogin && _otpSent) _buildOtpInput(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isStaffLogin
                    ? _signInWithEmailAndPassword
                    : (_otpSent ? _verifyOtp : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(_isStaffLogin
                    ? 'Login'
                    : (_otpSent ? 'Verify OTP' : 'Send OTP')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginToggle() {
    return Center(
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(value: false, label: Text('Customer')),
          ButtonSegment<bool>(value: true, label: Text('Staff/Admin')),
        ],
        selected: {_isStaffLogin},
        onSelectionChanged: (newSelection) {
          setState(() {
            _isStaffLogin = newSelection.first;
            _otpSent = false; // Reset OTP state when toggling
          });
        },
        style: SegmentedButton.styleFrom(
          foregroundColor: Colors.black54,
          selectedForegroundColor: Colors.white,
          selectedBackgroundColor: Colors.deepOrange,
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixText: '+91 ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      keyboardType: TextInputType.phone,
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        Text(
          'Enter the OTP sent to +91 ${_phoneController.text}',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: 'OTP',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(),
        ),
      ],
    );
  }

  Widget _buildStaffInput() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email (Username)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          obscureText: true,
          style: GoogleFonts.poppins(),
        ),
      ],
    );
  }
}
