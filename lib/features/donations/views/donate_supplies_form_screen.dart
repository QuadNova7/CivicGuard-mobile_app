import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_helper.dart';
import '../../auth/services/auth_service.dart';

class DonateSuppliesFormScreen extends StatefulWidget {
  final String category;
  final int? iconCode;
  final int? iconColorValue;

  const DonateSuppliesFormScreen({
    super.key,
    required this.category,
    this.iconCode,
    this.iconColorValue,
  });

  @override
  State<DonateSuppliesFormScreen> createState() => _DonateSuppliesFormScreenState();
}

class _DonateSuppliesFormScreenState extends State<DonateSuppliesFormScreen> {
  late String _currentCategory;
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  int _quantity = 50;
  String _selectedUnit = 'Bottles';
  final List<String> _units = [
    'Bottles',
    'Packs',
    'Boxes',
    'kg',
    'Items',
    'Units',
    'Bags',
    'Liters',
    'Cans',
    'Cartons',
  ];

  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLocating = false;
  bool _isSubmitting = false;
  String _locationStatus = '';

  // Shelters & Help Requests State
  List<Map<String, dynamic>> _shelters = [];
  String _selectedShelterId = 'd1111111-1111-1111-1111-111111111111';
  String _selectedShelterName = 'Havelock Community Center Shelter';

  List<Map<String, dynamic>> _helpRequests = [];
  String? _selectedHelpRequestId;
  String? _selectedHelpRequestDesc;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
    if (_currentCategory == 'Food & Water') {
      _itemNameController.text = 'Bottled Water';
      _descriptionController.text = 'Sealed bottled water (500ml)';
      _selectedUnit = 'Bottles';
      _quantity = 50;
    } else if (_currentCategory == 'Clothing & Blankets') {
      _itemNameController.text = 'Warm Blankets';
      _selectedUnit = 'Packs';
      _quantity = 20;
    } else if (_currentCategory == 'Medical Supplies') {
      _itemNameController.text = 'First Aid Kits';
      _selectedUnit = 'Boxes';
      _quantity = 15;
    }

    // Auto-detect live GPS location on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
      _fetchSheltersAndRequests();
    });
  }

  Future<void> _fetchSheltersAndRequests() async {
    // 1. Fetch Shelters
    try {
      final res = await ApiClient.instance.get(ApiConfig.reliefShelters);
      if (res.success && res.data is Map && res.data['shelters'] is List) {
        final list = (res.data['shelters'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (list.isNotEmpty && mounted) {
          setState(() {
            _shelters = list;
            _selectedShelterId = list[0]['id']?.toString() ?? _selectedShelterId;
            _selectedShelterName = list[0]['name']?.toString() ?? _selectedShelterName;
          });
        }
      }
    } catch (_) {}

    // 2. Fetch Open Help Requests
    try {
      final resReq = await ApiClient.instance.get(ApiConfig.reliefHelpRequests);
      if (resReq.success && resReq.data is Map && resReq.data['requests'] is List) {
        final listReq = (resReq.data['requests'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (listReq.isNotEmpty && mounted) {
          setState(() {
            _helpRequests = listReq;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedPhotos.add(File(picked.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access ${source == ImageSource.camera ? "camera" : "gallery"}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.camera_alt_rounded, color: Color(0xFF0284C7)),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatus = 'Detecting live hardware GPS...';
    });
    try {
      final result = await LocationHelper.getCurrentLiveLocation();
      if (mounted) {
        setState(() {
          _locationController.text = result.formattedAddress;
          _locationStatus =
              'Live GPS: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)} (Accuracy: ±${result.accuracy.toStringAsFixed(1)}m)';
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Tap GPS icon to retry ($e)';
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _submitDonation() async {
    final itemName = _itemNameController.text.trim();
    if (itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an item name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify a pickup or drop-off location'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Strict Auth Guard: User must be signed in or registered before submitting donation
    final isLoggedIn = AuthService.instance.isLoggedIn;
    final user = AuthService.instance.currentUser;

    if (!isLoggedIn || user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in or register to submit your donation pledge.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0F2B48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _showDonationAuthModal(context);
      return;
    }

    final donorId = user.id;

    setState(() => _isSubmitting = true);

    // Map Category to Backend Enum
    String resourceType = 'FOOD';
    if (_currentCategory.contains('Water') || _currentCategory.contains('Food')) {
      resourceType = 'FOOD';
    } else if (_currentCategory.contains('Medical') || _currentCategory.contains('Medicine')) {
      resourceType = 'MEDICAL';
    } else if (_currentCategory.contains('Cloth') || _currentCategory.contains('Blanket')) {
      resourceType = 'BEDDING';
    }

    final payload = {
      'resource_name': itemName,
      'quantity': _quantity,
      'unit': _selectedUnit,
      'resource_type': resourceType,
      'shelter_id': _selectedShelterId,
      'help_request_id': _selectedHelpRequestId,
      'user_id': donorId,
      'assigned_by': donorId,
      'donor_id': donorId,
    };

    try {
      await ApiClient.instance.post(
        ApiConfig.reliefResources,
        body: payload,
      );
    } catch (_) {}

    // CACHE IMMEDIATELY IN LOCAL STORAGE
    await LocalCacheService.instance.addDonation({
      'resource_name': itemName,
      'quantity': _quantity,
      'unit': _selectedUnit,
      'resource_type': resourceType,
      'shelter_name': _selectedShelterName,
      'shelter_id': _selectedShelterId,
      'help_request_id': _selectedHelpRequestId,
      'help_request_desc': _selectedHelpRequestDesc,
      'status': 'AVAILABLE',
      'created_at': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.push(
      '/donation-success',
      extra: {
        'category': _currentCategory,
        'itemName': itemName,
        'quantity': '$_quantity $_selectedUnit',
        'location': location,
        'shelterName': _selectedShelterName,
        'description': _descriptionController.text.trim(),
      },
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Food & Water':
        return Icons.restaurant_rounded;
      case 'Clothing & Blankets':
        return Icons.checkroom_rounded;
      case 'Medical Supplies':
        return Icons.medical_services_rounded;
      case 'Shelter Materials':
      case 'Shelter & Tools':
        return Icons.roofing_rounded;
      case 'Hygiene & Sanitation':
        return Icons.sanitizer_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Donate Supplies',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Auth Ribbon
            _buildAuthBanner(context),
            const SizedBox(height: 16),

            // 2. Category Selector Pill
            Text(
              'Donation Category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Icon(
                      _getCategoryIcon(_currentCategory),
                      color: const Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentCategory,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Verified Emergency Supplies',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Target Shelter Center Dropdown
            Row(
              children: [
                const Icon(Icons.domain_rounded, color: Color(0xFF0284C7), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Target Relief Shelter / Center *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedShelterId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                  items: (_shelters.isNotEmpty
                          ? _shelters
                          : [
                              {
                                'id': 'd1111111-1111-1111-1111-111111111111',
                                'name': 'Havelock Community Center Shelter (Colombo 05)',
                              },
                              {
                                'id': 'd2222222-2222-2222-2222-222222222222',
                                'name': 'Royal College Sports Pavilion (Colombo 07)',
                              },
                              {
                                'id': 'd3333333-3333-3333-3333-333333333333',
                                'name': 'Getambe Cultural Hall Relief Center (Kandy)',
                              },
                            ])
                      .map((s) {
                    final id = s['id']?.toString() ?? '';
                    final name = s['name']?.toString() ?? 'Relief Center';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedShelterId = val;
                        final found = _shelters.firstWhere((s) => s['id'] == val, orElse: () => {'name': val});
                        _selectedShelterName = found['name']?.toString() ?? val;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Link to Emergency SOS Help Request (Optional)
            Row(
              children: [
                const Icon(Icons.sos_rounded, color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Fulfill Open SOS Help Request (Optional)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedHelpRequestId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'General Shelter Inventory (No specific SOS request)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    ..._helpRequests.map((req) {
                      final id = req['id']?.toString() ?? '';
                      final type = req['help_type']?.toString() ?? 'SOS';
                      final desc = req['description']?.toString() ?? 'Emergency request';
                      final count = req['people_count'] ?? 1;
                      return DropdownMenuItem<String?>(
                        value: id,
                        child: Text(
                          '[$type - $count people] $desc',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedHelpRequestId = val;
                      if (val != null) {
                        final found = _helpRequests.firstWhere((r) => r['id'] == val, orElse: () => {});
                        _selectedHelpRequestDesc = found['description']?.toString();
                      } else {
                        _selectedHelpRequestDesc = null;
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. Item Name
            Text(
              'Item Name *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _itemNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Bottled Water, Dry Rations, Blankets',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13.5),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 6. Quantity and Units
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quantity *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Unit *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Quantity Counter Box
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, color: Color(0xFF64748B), size: 20),
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() {
                              _quantity = _quantity <= 10
                                  ? _quantity - 1
                                  : _quantity <= 50
                                      ? _quantity - 5
                                      : _quantity - 10;
                            });
                          }
                        },
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, color: Color(0xFF64748B), size: 20),
                        onPressed: () {
                          setState(() {
                            _quantity = _quantity < 10
                                ? _quantity + 1
                                : _quantity < 50
                                    ? _quantity + 5
                                    : _quantity + 10;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Unit Selector Dropdown
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 7. Description / Notes
            Text(
              'Description & Expiry Notes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Unopened cartons, expiry in 6 months, clean packaging',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13.5),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 8. Photo Attachments
            Text(
              'Add Item Photos',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List.generate(_selectedPhotos.length, (idx) {
                    return Container(
                      width: 76,
                      height: 76,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedPhotos[idx]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPhotos.removeAt(idx);
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _showImageSourcePicker,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, color: Color(0xFF64748B), size: 24),
                          const SizedBox(height: 2),
                          Text(
                            'Add Photo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 9. Pickup / Drop-off Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pickup / Drop-off Location *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: _isLocating ? null : _getCurrentLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLocating
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0284C7),
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: Color(0xFF0284C7),
                                size: 15,
                              ),
                        const SizedBox(width: 5),
                        Text(
                          _isLocating ? 'Detecting...' : 'Get Live GPS',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0284C7),
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              maxLines: null,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Tap "Get Live GPS" to auto-detect location',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13.5),
                prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 22),
                suffixIcon: IconButton(
                  icon: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                        )
                      : const Icon(Icons.gps_fixed_rounded, color: Color(0xFF0284C7), size: 20),
                  onPressed: _isLocating ? null : _getCurrentLocation,
                  tooltip: 'Auto-detect live GPS location',
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                ),
              ),
            ),
            if (_locationStatus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _locationStatus,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 10. Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Submit Donation Pledge',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

    void _showDonationAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2B48), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              'Sign In Required to Donate',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F2B48),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please sign in or register an account before submitting to link this donation to your verified citizen profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2B48), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login?tab=0&role=CITIZEN&redirect=/donate-categories');
                },
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Sign In to Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981), width: 1.3),
              ),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login?tab=1&role=CITIZEN&redirect=/donate-categories');
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF059669), size: 18),
                label: Text(
                  'Register as Citizen / Donor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthBanner(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final isLoggedIn = AuthService.instance.isLoggedIn;

        if (!isLoggedIn || user == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest Mode',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        'Sign in or register before submitting to link donation to your profile.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showDonationAuthModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donor: ${user.name} (${user.district})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    Text(
                      'Contribution will be logged under your verified relief account.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
