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
  String _quickFillCategory = 'ALL';

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
    _role = widget.initialRole ?? 'COMMUNITY_VOLUNTEER';
    _isRegisterMode = widget.initialTabIndex == 1 && _role != 'FIELD_CREW';
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

  Future<void> _submitLogin() async {
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
    final res = await AuthService.instance.login(
      email: email,
      password: password,
      role: _role,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      _handleSuccess('Signed in successfully as ' + (res.data?.name ?? 'User') + '!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Login failed. Please check credentials.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.alertCoral,
        ),
      );
    }
  }

  Future<void> _submitRegister() async {
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
    final res = await AuthService.instance.register(
      name: name,
      email: email,
      phone: phone.isNotEmpty ? phone : null,
      district: _regDistrict,
      role: _role,
      password: password,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      _handleSuccess('Account registered successfully! Welcome ' + (res.data?.name ?? 'Volunteer') + '.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Registration failed. Please try again.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.alertCoral,
        ),
      );
    }
  }

  
  Widget _buildCategoryFilterChip(String categoryKey, String label) {
    final bool isSelected = _quickFillCategory == categoryKey;
    return InkWell(
      onTap: () => setState(() => _quickFillCategory = categoryKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? AppColors.primaryNavy : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredQuickFillPersonas() {
    final List<Map<String, dynamic>> all = [
      // 1. Water Rescue
      {
        'category': 'WATER',
        'label': '🌊 Sunil Shantha (Water #01 Lead)',
        'email': 'sunil.water@cmc.gov.lk',
        'bg': const Color(0xFFE0F2FE),
        'border': const Color(0xFFBAE6FD),
        'textColor': const Color(0xFF0369A1),
      },
      {
        'category': 'WATER',
        'label': '🤿 Roshan Silva (Water #02 Lead)',
        'email': 'crew.colombo.02@civicguard.lk',
        'bg': const Color(0xFFE0F2FE),
        'border': const Color(0xFFBAE6FD),
        'textColor': const Color(0xFF0369A1),
      },
      {
        'category': 'WATER',
        'label': '🤿 Kasun Bandara (Rescue Diver)',
        'email': 'kasun.diver@cmc.gov.lk',
        'bg': const Color(0xFFE0F2FE),
        'border': const Color(0xFFBAE6FD),
        'textColor': const Color(0xFF0284C7),
      },
      {
        'category': 'WATER',
        'label': '⛵ Nuwan Pradeep (Boat Pilot)',
        'email': 'nuwan.boat@cmc.gov.lk',
        'bg': const Color(0xFFE0F2FE),
        'border': const Color(0xFFBAE6FD),
        'textColor': const Color(0xFF0284C7),
      },

      // 2. 4x4 Debris Clearance
      {
        'category': '4X4',
        'label': '🚜 Sanjeewa (4x4 #01 Lead)',
        'email': 'crew.colombo.03@civicguard.lk',
        'bg': const Color(0xFFFEF3C7),
        'border': const Color(0xFFFDE68A),
        'textColor': const Color(0xFFB45309),
      },
      {
        'category': '4X4',
        'label': '🚛 Bandara (4x4 #02 Lead)',
        'email': 'crew.colombo.04@civicguard.lk',
        'bg': const Color(0xFFFEF3C7),
        'border': const Color(0xFFFDE68A),
        'textColor': const Color(0xFFB45309),
      },
      {
        'category': '4X4',
        'label': '🔧 Amila Perera (Winch Crew)',
        'email': 'amila.4x4@cmc.gov.lk',
        'bg': const Color(0xFFFEF3C7),
        'border': const Color(0xFFFDE68A),
        'textColor': const Color(0xFFD97706),
      },

      // 3. Medical Triage
      {
        'category': 'MEDICAL',
        'label': '🩺 Dr. Priyantha (Medical #01 Lead)',
        'email': 'crew.colombo.05@civicguard.lk',
        'bg': const Color(0xFFFEE2E2),
        'border': const Color(0xFFFECACA),
        'textColor': const Color(0xFFB91C1C),
      },
      {
        'category': 'MEDICAL',
        'label': '🏥 Dr. Nimal (Medical #02 Lead)',
        'email': 'crew.colombo.06@civicguard.lk',
        'bg': const Color(0xFFFEE2E2),
        'border': const Color(0xFFFECACA),
        'textColor': const Color(0xFFB91C1C),
      },

      // 4. Drone, Hazmat & Comms
      {
        'category': 'TECH',
        'label': '🚁 Tharindu (Drone UAV #01 Lead)',
        'email': 'crew.colombo.07@civicguard.lk',
        'bg': const Color(0xFFEDE9FE),
        'border': const Color(0xFFDDD6FE),
        'textColor': const Color(0xFF6D28D9),
      },
      {
        'category': 'TECH',
        'label': '🛰️ Kamal Perera (Mapping #02 Lead)',
        'email': 'crew.colombo.08@civicguard.lk',
        'bg': const Color(0xFFEDE9FE),
        'border': const Color(0xFFDDD6FE),
        'textColor': const Color(0xFF6D28D9),
      },
      {
        'category': 'TECH',
        'label': '☣️ Dinesh Kumara (Hazmat #01 Lead)',
        'email': 'crew.colombo.09@civicguard.lk',
        'bg': const Color(0xFFFFEDD5),
        'border': const Color(0xFFFED7AA),
        'textColor': const Color(0xFFC2410C),
      },
      {
        'category': 'TECH',
        'label': '📻 Ruwan Fernando (HAM Comms #01 Lead)',
        'email': 'crew.colombo.10@civicguard.lk',
        'bg': const Color(0xFFD1FAE5),
        'border': const Color(0xFFA7F3D0),
        'textColor': const Color(0xFF047857),
      },
    ];

    if (_quickFillCategory == 'ALL') return all;
    return all.where((p) => p['category'] == _quickFillCategory).toList();
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

        const SizedBox(height: 16),

        // Pre-assigned Crew Notice & Quick-Fill (Only for Response Crew)
        if (isCrew) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.primaryNavy, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Pre-Assigned Crews (Quick-Fill):',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '13 Accounts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryFilterChip('ALL', 'All (13)'),
                      const SizedBox(width: 4),
                      _buildCategoryFilterChip('WATER', '💧 Water Rescue (4)'),
                      const SizedBox(width: 4),
                      _buildCategoryFilterChip('4X4', '🚜 4x4 Debris (3)'),
                      const SizedBox(width: 4),
                      _buildCategoryFilterChip('MEDICAL', '🩺 Medical (2)'),
                      const SizedBox(width: 4),
                      _buildCategoryFilterChip('TECH', '🚁 Tech/Hazmat/Radio (4)'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Pre-Assigned Personas Wrap
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _getFilteredQuickFillPersonas().map((p) {
                    final bool isSelected = _loginEmailController.text == p['email'];
                    return ActionChip(
                      backgroundColor: isSelected ? (p['bg'] as Color).withValues(alpha: 0.9) : (p['bg'] as Color),
                      side: BorderSide(
                        color: isSelected ? (p['textColor'] as Color) : (p['border'] as Color),
                        width: isSelected ? 1.6 : 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      label: Text(
                        p['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: p['textColor'] as Color,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _loginEmailController.text = p['email'] as String;
                          _loginPasswordController.text = 'Crew@123';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergency Response accounts are pre-assigned by Council Officers. Public self-registration is disabled.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],

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
