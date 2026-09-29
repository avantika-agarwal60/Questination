import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color creamBg = Color(0xFFF4F1EA);
  static const Color oceanBlue = Color(0xFF1684A7);
  static const Color tealGreen = Color(0xFF0EA391);
  static const Color sunnyYellow = Color(0xFFFAF179);

  bool _isSignUp = false;
  bool _isLoading = false;
  String _selectedRole = 'tourist';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty ||
      password.isEmpty ||
      (_isSignUp && (username.isEmpty || phone.isEmpty))) {
      _showSnackBar('PLEASE FILL IN ALL REQUIRED FIELDS');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await ApiService.register(
          username: username,
          email: email,
          password: password,
          phone: phone,
          role: _selectedRole,
        );
      } else {
        await ApiService.login(email, password);
      }

      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: oceanBlue,
        content: Text(
          message.toUpperCase(),
          style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tealGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: oceanBlue, width: 2),
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: sunnyYellow,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'QUESTINATION',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 18,
                    color: tealGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _isSignUp ? 'REGISTER ADVENTURER' : 'ENTER THE QUEST',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: oceanBlue,
                  ),
                ),
                const SizedBox(height: 28),

                // Username Field (Sign up only)
                if (_isSignUp) ...[
                  _buildRetroTextField(
                    controller: _usernameController,
                    label: 'USERNAME',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 14),
                  _buildRetroTextField(
                    controller: _phoneController,
                    label: 'PHONE',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // Role Selector (Sign up only)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROLE',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 7,
                          color: oceanBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: oceanBlue, width: 2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 9,
                              color: Colors.black87,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'tourist',
                                child: Text('TOURIST'),
                              ),
                              DropdownMenuItem(
                                value: 'seller',
                                child: Text('SELLER'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRole = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Email Input
                _buildRetroTextField(
                  controller: _emailController,
                  label: 'EMAIL',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // Password Input
                _buildRetroTextField(
                  controller: _passwordController,
                  label: 'PASSWORD',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // Submit Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: oceanBlue, width: 2),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isSignUp ? 'CREATE ACCOUNT' : 'LOG IN',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Navigation Switch
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'ALREADY HAVE AN ACCOUNT? LOG IN'
                        : "NEW ADVENTURER? REGISTER",
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: oceanBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.pressStart2p(
            fontSize: 7,
            color: oceanBlue,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: oceanBlue, width: 2),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.pressStart2p(fontSize: 9, color: Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: tealGreen, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}