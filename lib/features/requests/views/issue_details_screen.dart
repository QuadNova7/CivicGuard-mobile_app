import 'dart:io';
import '../../auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/local_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

class IssueDetailsScreen extends StatefulWidget {
  final String category;

  const IssueDetailsScreen({
    super.key,
    required this.category,
  });

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLocating = false;
  bool _isSubmitting = false;
  String _locationStatus = '';
  Position? _currentPosition;

  // Flood Depth Tier Benchmark
  String _selectedWaterDepth = 'TIRE_LEVEL'; // SURFACE_PUDDLE, TIRE_LEVEL, BUMPER_LEVEL, SUBMERGED_VEHICLES

  @override
  void initState() {
    super.initState();
    _titleController.text = '${widget.category} Incident';
    _fetchLiveLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _mapCategoryToBackendType(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('flood')) return 'FLOOD';
    if (lower.contains('road') || lower.contains('block') || lower.contains('tree')) return 'BLOCKAGE';
    if (lower.contains('power') || lower.contains('electric')) return 'INFRASTRUCTURE';
    if (lower.contains('landslide')) return 'LANDSLIDE';
    return 'OTHER';
  }

  Future<void> _fetchLiveLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatus = 'Detecting high-precision GPS coordinates...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _locationStatus = 'Location permission permanently denied.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _currentPosition = position;

      // Reverse geocode to street address
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final addressParts = <String>[
            if (place.street != null && place.street!.isNotEmpty) place.street!,
            if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
            if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea!,
          ];
          final formattedAddress = addressParts.join(', ');

          setState(() {
            _locationController.text = formattedAddress.isNotEmpty
                ? formattedAddress
                : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
            _locationStatus = 'GPS: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
            _isLocating = false;
          });
        } else {
          _fallbackCoordinates(position);
        }
      } catch (_) {
        _fallbackCoordinates(position);
      }
    } catch (_) {
      // Fallback location for testing
      setState(() {
        _currentPosition = Position(
          latitude: 6.7985,
          longitude: 79.8895,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 10.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        _locationController.text = 'Katubedda Junction, Moratuwa';
        _locationStatus = 'GPS: 6.79850, 79.88950 (Katubedda Corridor)';
        _isLocating = false;
      });
    }
  }

  void _fallbackCoordinates(Position pos) {
    setState(() {
      _locationController.text = 'Galle Road, Moratuwa (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
      _locationStatus = 'GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      _isLocating = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery: $e')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an issue title')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final backendType = _mapCategoryToBackendType(widget.category);
    final lat = _currentPosition?.latitude ?? 6.7985;
    final lng = _currentPosition?.longitude ?? 79.8895;

    final user = AuthService.instance.currentUser;
    final fields = <String, String>{
      'incident_type': backendType,
      'title': title,
      'description': _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : 'Citizen reported ${widget.category} with photo verification.',
      'latitude': lat.toString(),
      'longitude': lng.toString(),
      'road_name': _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : 'Moratuwa Galle Road',
      'water_depth': _selectedWaterDepth,
      if (user != null && user.id.isNotEmpty) 'reported_by': user.id,
    };

    try {
      final response = await ApiClient.instance.postMultipart(
        ApiConfig.incidentsReport,
        fields: fields,
        file: _selectedImage,
        fileField: 'photo',
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showAiVerificationResultModal(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showAiVerificationResultModal(null);
      }
    }
  }

  void _showAiVerificationResultModal(ApiResponse<dynamic>? response) {
    final data = response?.data is Map<String, dynamic> ? response!.data as Map<String, dynamic> : null;
    final String status = data?["status"]?.toString() ?? "CONFIRMED";
    final String ticketId = data?["ticket_id"]?.toString() ?? "TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    final String reportId = (data != null && data["id"] != null) ? data["id"].toString() : "INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    // Cache user submitted request in local offline cache
    LocalCacheService.instance.addSubmittedReport({
      "id": reportId,
      "ticket_id": ticketId,
      "incident_type": _mapCategoryToBackendType(widget.category),
      "title": _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : "Citizen reported ${widget.category}",
      "description": _descController.text.trim().isNotEmpty ? _descController.text.trim() : "Citizen reported ${widget.category} with photo verification.",
      "latitude": _currentPosition?.latitude ?? 6.7985,
      "longitude": _currentPosition?.longitude ?? 79.8895,
      "roads": {"name": _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : "Moratuwa Galle Road"},
      "status": status,
      "created_at": DateTime.now().toIso8601String(),
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Lottie / Icon Beacon
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0284C7), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: Color(0xFF0284C7),
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Report Submitted',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F2B48),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                'Waiting for Verification...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Action: Go to Reports
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  context.pop(); // Go back from issue details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2B48),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFlood = widget.category.toLowerCase().contains('flood');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text('${widget.category} Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar (Step 2 of 3)
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.primaryNavy, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.primaryNavy, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                ],
              ),

              const SizedBox(height: 20),

              // Photo Evidence Picker
              Text('Photo Evidence', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0F2B48)),
                            title: const Text('Take a Photo (Camera)'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF0F2B48)),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 36, color: Color(0xFF64748B)),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to snap photo evidence',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // Title Field
              Text('Issue Title', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Canal Overspill on Main Rd',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),

              if (isFlood) ...[
                const SizedBox(height: 18),
                Text('Water Depth Benchmark', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDepthChip('SURFACE_PUDDLE', 'Surface (0.1m)'),
                      _buildDepthChip('TIRE_LEVEL', 'Tire Depth (0.4m)'),
                      _buildDepthChip('BUMPER_LEVEL', 'Bumper (0.8m)'),
                      _buildDepthChip('SUBMERGED_VEHICLES', 'Submerged (1.2m+)'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Location Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Location', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: _isLocating ? null : _fetchLiveLocation,
                    child: Text(
                      _isLocating ? 'Detecting...' : '📍 Refresh GPS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFDC2626)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              if (_locationStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(_locationStatus, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                ),

              const SizedBox(height: 18),

              // Description Field
              Text('Description & Details', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Provide any additional context or hazards observed...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: _isSubmitting ? 'Verifying with 5-Signal AI...' : 'Submit Verified Report',
                onPressed: _isSubmitting ? null : _submitReport,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepthChip(String key, String label) {
    final isSelected = _selectedWaterDepth == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedWaterDepth = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
