import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/services/location_helper.dart';

class IssueDetailsScreen extends StatefulWidget {
  final String category;

  const IssueDetailsScreen({super.key, required this.category});

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<XFile> _attachedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  bool _isLocating = false;
  String _locationStatus = '';

  @override
  void initState() {
    super.initState();
    // Auto-fetch real live location immediately upon opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLiveLocation();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- Photo Picker (Camera & Gallery) ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _attachedPhotos.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/files: $e')),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Photo Evidence',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a source to attach photo of the issue',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryNavy),
                  ),
                  title: Text('Take Photo (Camera)', style: AppTextStyles.bodyLarge),
                  subtitle: Text('Capture live photo with camera', style: AppTextStyles.bodySmall),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
                  ),
                  title: Text('Browse Files (Gallery)', style: AppTextStyles.bodyLarge),
                  subtitle: Text('Select image from device storage', style: AppTextStyles.bodySmall),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Live GPS Location Auto-Detection with Real Hardware Fix ---
  Future<void> _fetchLiveLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatus = 'Detecting live hardware GPS...';
    });

    try {
      final result = await LocationHelper.getCurrentLiveLocation();

      if (mounted) {
        setState(() {
          _locationController.text = result.formattedAddress;
          _locationStatus = 'Live GPS: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)} (Accuracy: ±±${result.accuracy.toStringAsFixed(1)}m)';
          _isLocating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.volunteerCardGreen,
            content: Text('📍 Live location auto-detected: ${result.formattedAddress}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Tap GPS icon to retry ($e)';
          _isLocating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade800,
            content: Text('$e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report an Issue'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Content Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2B48).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.category,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section Title
                      Text(
                        'Add Details',
                        style: AppTextStyles.headingMedium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Provide more information about the issue',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Photo Picker (Supports Camera & Files)
                      Text(
                        'Attach Photos',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Render attached photo thumbnails
                            ..._attachedPhotos.asMap().entries.map((entry) {
                              final index = entry.key;
                              final photo = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                  image: DecorationImage(
                                    image: FileImage(File(photo.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _attachedPhotos.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // Add Photo Action Button
                            GestureDetector(
                              onTap: _showImagePickerModal,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.primaryNavy,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primaryNavy,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Issue Title Field
                      Text(
                        'Title',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Broken water pipe / Fallen power cable',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description Field
                      Text(
                        'Description',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe what happened and any urgent hazards...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Location Section with Live GPS Auto-Detect Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Incident Location',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // Live Location Button (Tap to auto-detect GPS)
                          GestureDetector(
                            onTap: _isLocating ? null : _fetchLiveLocation,
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
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: const Color(0xFF0284C7),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location Interactive Card / Auto-filled field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _locationController,
                          maxLines: null,
                          minLines: 1,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.reportCardRed,
                              size: 22,
                            ),
                            suffixIcon: IconButton(
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryNavy,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.gps_fixed_rounded,
                                      color: AppColors.primaryNavy,
                                      size: 20,
                                    ),
                              onPressed: _fetchLiveLocation,
                              tooltip: 'Auto-detect live GPS location',
                            ),
                            hintText: 'Tap "Get Live GPS" to auto-detect',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      if (_locationStatus.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            _locationStatus,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Submit Button
              AppButton(
                text: 'Submit Report',
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an issue title')),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.volunteerCardGreen,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Report "${_titleController.text}" submitted to triage!'),
                          ),
                        ],
                      ),
                    ),
                  );
                  context.go('/main');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
