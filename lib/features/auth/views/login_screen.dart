import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectPath;
  final int initialTabIndex;
  final String? initialRole;

  const LoginScreen({
    super.key,
    this.redirectPath,
    this.initialTabIndex = 0,
    this.initialRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _isRegisterMode;
  late String _role;

  // Sign In Form Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;
  bool _rememberMe = true;

  // Register Form Controllers (Community Volunteers)
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  bool _regObscurePassword = true;
  String _regDistrict = 'Colombo';

  bool _isLoading = false;

  final List<String> _districts = const [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar',
    'Vavuniya', 'Mullaitivu', 'Batticaloa', 'Ampara', 'Trincomalee',
    'Kurunegala', 'Puttalam', 'Anuradhapura', 'Polonnaruwa', 'Badulla',
    'Monaragala', 'Ratnapura', 'Kegalle'
  ];

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialTabIndex == 1;
    _role = widget.initialRole ?? 'COMMUNITY_VOLUNTEER';
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _handleSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );

    final defaultTarget = _role == 'FIELD_CREW' ? '/crew-assignments' : '/main';
    final target = widget.redirectPath ?? defaultTarget;
    if (context.mounted) {
      context.go(target);
    }
  }

  void _submitLogin() {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email and password.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.alertCoral,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        AuthService.instance.loginWithCredentials(email, password, role: _role);
        _handleSuccess('Signed in successfully!');
      }
    });
  }

  void _submitRegister() {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.alertCoral,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);

        final newUser = UserModel(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          email: email,
          phone: phone.isNotEmpty ? phone : '+94 77 000 0000',
          role: 'COMMUNITY_VOLUNTEER',
          district: _regDistrict,
          crewName: null,
          specialty: null,
          equipment: [],
        );

        AuthService.instance.loginAs(newUser);
        _handleSuccess('Volunteer account registered successfully!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCrew = _role == 'FIELD_CREW';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        context.pop();
                      } else {
                        context.go('/main');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryNavy, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCrew ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isCrew ? const Color(0xFFBAE6FD) : const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCrew ? Icons.emergency_rounded : Icons.shield_rounded,
                          color: isCrew ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isRegisterMode
                              ? 'VOLUNTEER REGISTER'
                              : (isCrew ? 'CREW SIGN IN' : 'VOLUNTEER SIGN IN'),
                          style: GoogleFonts.plusJakartaSans(
                            color: isCrew ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Main Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Description
                    Text(
                      _isRegisterMode
                          ? 'Register as Volunteer'
                          : (isCrew ? 'Response Crew Sign In' : 'Welcome to CivicGuard'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRegisterMode
                          ? 'Join the community relief network to assist with supply distribution and local aid.'
                          : (isCrew
                              ? 'Sign in with your officer-assigned credentials to access active dispatches.'
                              : 'Sign in to access your volunteer profile and community relief tasks.'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Active Form (Sign In OR Register)
                    _isRegisterMode ? _buildRegisterForm() : _buildSignInForm(isCrew),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SIGN IN FORM
  // ===========================================================================
  Widget _buildSignInForm(bool isCrew) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email
        _buildFieldLabel('Email Address'),
        const SizedBox(height: 6),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            hint: isCrew ? 'e.g. sunil.water@cmc.gov.lk' : 'name@example.com',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 14),

        // Password
        _buildFieldLabel('Password'),
        const SizedBox(height: 6),
        TextField(
          controller: _loginPasswordController,
          obscureText: _loginObscurePassword,
          decoration: _inputDecoration(
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                setState(() => _loginObscurePassword = !_loginObscurePassword);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Remember Me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: AppColors.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remember me',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0284C7)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    isCrew ? 'Sign In to Crew Account' : 'Sign In to Account',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Switch to Register Mode (Only for Volunteers)
        if (!isCrew)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _isRegisterMode = true),
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(
                      text: 'Register as Volunteer',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0284C7), fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // REGISTER FORM (COMMUNITY VOLUNTEER)
  // ===========================================================================
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name
        _buildFieldLabel('Full Name *'),
        const SizedBox(height: 6),
        TextField(
          controller: _regNameController,
          decoration: _inputDecoration(
            hint: 'e.g. Kasun Silva',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),

        // Email
        _buildFieldLabel('Email Address *'),
        const SizedBox(height: 6),
        TextField(
          controller: _regEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            hint: 'e.g. kasun@example.com',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 14),

        // Phone
        _buildFieldLabel('Mobile Phone Number'),
        const SizedBox(height: 6),
        TextField(
          controller: _regPhoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            hint: '+94 77 123 4567',
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 14),

        // District Dropdown
        _buildFieldLabel('Your Administrative District *'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _regDistrict,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _districts.map((d) {
                return DropdownMenuItem(
                  value: d,
                  child: Text('$d District', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _regDistrict = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Password
        _buildFieldLabel('Create Password *'),
        const SizedBox(height: 6),
        TextField(
          controller: _regPasswordController,
          obscureText: _regObscurePassword,
          decoration: _inputDecoration(
            hint: 'At least 8 characters',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _regObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                setState(() => _regObscurePassword = !_regObscurePassword);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Create Account Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Create Volunteer Account',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Switch to Sign In Mode
        Center(
          child: TextButton(
            onPressed: () => setState(() => _isRegisterMode = false),
            child: RichText(
              text: TextSpan(
                text: "Already have an account? ",
                style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0284C7), fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5)),
    );
  }
}
