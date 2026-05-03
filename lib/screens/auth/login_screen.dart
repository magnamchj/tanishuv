import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos elektron pochta va parolni kiriting'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _loading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signInAnonymously();
    if (mounted) setState(() => _loading = false);
  }

  Future<String?> _getSavedReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('referralCode');
    if (code != null && code.isNotEmpty) {
      // Clear it after reading so it's only used once
      await prefs.remove('referralCode');
      return code;
    }
    return null;
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final referralCode = await _getSavedReferralCode();
    final user = await authService.signInWithGoogle(referralCode);
    if (mounted) {
      setState(() => _loading = false);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google orqali kirishda xatolik'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final referralCode = await _getSavedReferralCode();
    final user = await authService.signInWithApple(referralCode);
    if (mounted) {
      setState(() => _loading = false);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple orqali kirishda xatolik'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Deep dark black
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Modern Logo
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Tanishuv',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Tanishish va muloqot qilish uchun',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              
              // Email Field
              _buildField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Parol',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF151515),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.pinkAccent),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    if (_emailController.text.isNotEmpty) {
                      Provider.of<AuthService>(context, listen: false)
                          .sendPasswordReset(_emailController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Parolni tiklash so\'rovi yuborildi')),
                      );
                    }
                  },
                  child: const Text('Parolni unutdingizmi?', style: TextStyle(color: Colors.white54)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Login Button
              ElevatedButton(
                onPressed: _loading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text(
                        'Kirish',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
              ),
              
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Yoki', style: TextStyle(color: Colors.white54)),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                ],
              ),
              const SizedBox(height: 32),
              
              // Social Auth
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    onTap: _signInWithGoogle,
                    iconPath: 'assets/google.png', // We map standard icon or just use flutter icons
                    icon: Icons.g_mobiledata,
                    bgColor: Colors.white,
                    iconColor: Colors.black,
                  ),
                  const SizedBox(width: 24),
                  _buildSocialButton(
                    onTap: _signInWithApple,
                    icon: Icons.apple,
                    bgColor: const Color(0xFF151515),
                    iconColor: Colors.white,
                    borderColor: Colors.white10,
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Register Link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Hisobingiz yo\'qmi? ',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                      children: [
                        TextSpan(
                          text: 'Ro\'yxatdan o\'tish',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Anonymous
              Center(
                child: TextButton.icon(
                  onPressed: _loading ? null : _signInAnonymously,
                  icon: const Icon(Icons.person_outline, color: Colors.white38),
                  label: const Text('Anonim kirish', style: TextStyle(color: Colors.white38)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF151515),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.pinkAccent),
        ),
        prefixIcon: Icon(icon, color: Colors.white54),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required IconData icon,
    String? iconPath,
    required Color bgColor,
    required Color iconColor,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 36),
        ),
      ),
    );
  }
}
