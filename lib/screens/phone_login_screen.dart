import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'verify_phone_otp_screen.dart';
import 'splash_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  late TextEditingController _phoneController;
  String _selectedCountryCode = '+91';
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, String> _countryCodes = {
    '+1': '🇺🇸 United States',
    '+44': '🇬🇧 United Kingdom',
    '+91': '🇮🇳 India',
    '+92': '🇵🇰 Pakistan',
    '+880': '🇧🇩 Bangladesh',
    '+86': '🇨🇳 China',
    '+81': '🇯🇵 Japan',
    '+60': '🇲🇾 Malaysia',
    '+65': '🇸🇬 Singapore',
    '+62': '🇮🇩 Indonesia',
  };

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePhoneSignIn() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phoneNumber = '$_selectedCountryCode${_phoneController.text}';

    try {
      await AuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VerifyPhoneOtpScreen(
                  verificationId: verificationId,
                  phoneNumber: phoneNumber,
                  resendToken: resendToken,
                ),
              ),
            );
          }
        },
        onVerificationFailed: (FirebaseAuthException error) {
          setState(() {
            _isLoading = false;
            _errorMessage = error.message ?? 'Verification failed';
          });
        },
        onVerificationCompleted: (PhoneAuthCredential credential) {
          _signInWithPhoneCredential(credential);
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      await AuthService.signInWithPhoneCredential(credential: credential);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Sign-in failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Login with Phone',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B6CB0),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your phone number to receive OTP',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        _showCountryCodePicker();
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _countryCodes[_selectedCountryCode] ?? _selectedCountryCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedCountryCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _handlePhoneSignIn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2B6CB0),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Send OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outlined, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We\'ll send you an OTP via SMS. Standard rates apply.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryCodePicker() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ListView.builder(
            itemCount: _countryCodes.length,
            itemBuilder: (context, index) {
              final code = _countryCodes.keys.toList()[index];
              return ListTile(
                title: Text(_countryCodes[code]!),
                onTap: () {
                  setState(() {
                    _selectedCountryCode = code;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}
