import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  String _gender = 'Erkak';
  double _age = 22;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _hasReferralFromLink = false;

  @override
  void initState() {
    super.initState();
    _gender = 'Erkak';
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('pending_referral');
    if (code != null && code.isNotEmpty) {
      setState(() {
        _referralController.text = code;
        _hasReferralFromLink = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }
  
  Future<void> _savePendingReferral(String? code) async {
    if (code == null || code.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_referral', code);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final referralCode = _referralController.text.trim().isEmpty ? null : _referralController.text.trim();
    
    await _savePendingReferral(referralCode);

    final error = await authService.createUserWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim(),
      age: _age.toInt(),
      gender: _gender,
      invitedByCode: referralCode,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final referralCode = _referralController.text.trim().isEmpty ? null : _referralController.text.trim();
    
    await _savePendingReferral(referralCode);

    final user = await authService.signInWithGoogle(referralCode);
    if (mounted) {
      setState(() => _loading = false);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xatolik yuz berdi'), backgroundColor: Colors.redAccent),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final referralCode = _referralController.text.trim().isEmpty ? null : _referralController.text.trim();
    
    await _savePendingReferral(referralCode);

    final user = await authService.signInWithApple(referralCode);
    if (mounted) {
      setState(() => _loading = false);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xatolik yuz berdi'), backgroundColor: Colors.redAccent),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Ro\'yxatdan o\'tish',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 48),
                  child: Text(
                    'Profil yaratish uchun ma\'lumotlarni kiriting',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildInput(
                  controller: _nameController,
                  label: 'To\'liq ismingiz',
                  icon: Icons.person_outline,
                  validator: (v) => v!.trim().isEmpty ? 'Ismingizni kiriting' : null,
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _nicknameController,
                  label: 'Username',
                  icon: Icons.alternate_email,
                  validator: (v) => v!.trim().isEmpty ? 'Username tanlang' : null,
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? 'To\'g\'ri email kiriting' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Parol (min 6)',
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
                  validator: (v) => v!.length < 6 ? 'Kamida 6 belgi' : null,
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _referralController,
                  label: 'Taklif kodi (ixtiyoriy)',
                  icon: Icons.card_giftcard,
                  readOnly: _hasReferralFromLink,
                ),

                const SizedBox(height: 24),
                const Text('Jinsi', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: ['Erkak', 'Ayol', 'Boshqa'].map((g) {
                    final selected = _gender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? Colors.pinkAccent : const Color(0xFF151515),
                            borderRadius: BorderRadius.circular(16),
                            border: selected ? null : Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            g,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Yosh', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_age.toInt()}',
                        style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _age,
                  min: 18,
                  max: 60,
                  divisions: 42,
                  activeColor: Colors.pinkAccent,
                  inactiveColor: const Color(0xFF151515),
                  onChanged: (v) => setState(() => _age = v),
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Hisob yaratish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),

                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      onTap: _signInWithGoogle,
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

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Oldin ro\'yxatdan o\'tganmisiz? Kirish', style: TextStyle(color: Colors.white54)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.white54 : Colors.white),
      decoration: InputDecoration(
        hintText: label,
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
      validator: validator,
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required IconData icon,
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
