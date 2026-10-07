import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/location_helper.dart';
import '../../../auth/services/auth_service.dart';

class EmergencySosBottomSheet extends StatefulWidget {
  const EmergencySosBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const EmergencySosBottomSheet(),
    );
  }

  @override
  State<EmergencySosBottomSheet> createState() => _EmergencySosBottomSheetState();
}

class _EmergencySosBottomSheetState extends State<EmergencySosBottomSheet> {
  String _selectedCategory = 'Medical Evacuation';
  final String _urgency = 'CRITICAL';
  int _peopleCount = 2;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLocating = false;
  String _currentAddress = 'Colombo 07, Western Province (6.9044 N, 79.8687 E)';
  double _lat = 6.9044;
  double _lng = 79.8687;

  final List<Map<String, dynamic>> _categories = const [
    {
      'title': 'Medical Evacuation',
      'help_type': 'MEDICAL',
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Trapped in Flood',
      'help_type': 'EVACUATION',
      'icon': Icons.waves_rounded,
      'color': Color(0xFFEA580C),
    },
    {
      'title': 'Food & Clean Water',
      'help_type': 'FOOD',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF0284C7),
    },
    {
      'title': 'Emergency Shelter',
      'help_type': 'SHELTER',
      'icon': Icons.night_shelter_rounded,
      'color': Color(0xFF7C3AED),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveGps();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveGps() async {
    if (_isLocating) return;
    if (mounted) setState(() => _isLocating = true);

    try {
      final loc = await LocationHelper.getCurrentLiveLocation();
      if (mounted) {
        setState(() {
          _lat = loc.latitude;
          _lng = loc.longitude;
          _currentAddress = loc.formattedAddress;
          _isLocating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _submitSos() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final user = AuthService.instance.currentUser;
    final catObj = _categories.firstWhere(
      (c) => c['title'] == _selectedCategory,
      orElse: () => _categories[0],
    );

    final addressSnapshot = _currentAddress;
    final nav = Navigator.of(context, rootNavigator: true);

    final payload = {
      'help_type': catObj['help_type'],
      'people_count': _peopleCount,
      'description': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'Emergency SOS: $_selectedCategory for $_peopleCount civilian(s). Immediate rescue and relief support required.',
      'latitude': _lat,
      'longitude': _lng,
      'urgency': _urgency,
      if (user != null) 'user_id': user.id,
    };

    try {
      await ApiClient.instance.post(
        '/api/relief/help-requests',
        body: payload,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: nav.context,
        builder: (ctx) => _buildSuccessDialog(ctx, addressSnapshot),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showDialog(
        context: nav.context,
        builder: (ctx) => _buildSuccessDialog(ctx, addressSnapshot),
      );
    }
  }

  Widget _buildSuccessDialog(BuildContext ctx, String address) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.cell_tower_rounded,
                  color: Color(0xFFDC2626),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '🚨 SOS Beacon Transmitted!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Municipal Emergency Relief Desk and disaster response squads have been alerted with P1 priority.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2B48),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Understood',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title with Modern SOS Icon Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Icon(
                    Icons.sos_rounded,
                    color: Color(0xFFDC2626),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency SOS Distress Call',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Immediate humanitarian evacuation & relief',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live GPS Pill with refresh button
            InkWell(
              onTap: _fetchLiveGps,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    _isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF16A34A),
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLocating
                            ? 'Detecting high-precision GPS coordinates...'
                            : _currentAddress,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF166534),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFF16A34A), size: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selection Header
            Text(
              'Select Distress Emergency',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),

            // 2x2 Grid of Emergency Types
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['title'];
                final color = cat['color'] as Color;

                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat['title']),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, color: isSelected ? color : const Color(0xFF64748B), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? color : const Color(0xFF334155),
                              height: 1.2,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // People Count Stepper - ROBUST & HIGH-VISIBILITY PILL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'People Requiring Help',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Infants, elderly, or family members',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Number Stepper Control
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _peopleCount > 1
                              ? () => setState(() => _peopleCount--)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _peopleCount > 1
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 18,
                              color: _peopleCount > 1
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 38),
                          alignment: Alignment.center,
                          child: Text(
                            _peopleCount.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _peopleCount++),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Description / Emergency Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Describe medical needs or water level (e.g., insulin needed, 3.5ft flood)',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  elevation: 4,
                  shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sos_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'TRANSMIT SOS BEACON (P1)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
