import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import 'crew_assignments_screen.dart';

class CrewAssignmentDetailsScreen extends StatefulWidget {
  final CrewAssignment assignment;

  const CrewAssignmentDetailsScreen({
    super.key,
    required this.assignment,
  });

  @override
  State<CrewAssignmentDetailsScreen> createState() => _CrewAssignmentDetailsScreenState();
}

class _CrewAssignmentDetailsScreenState extends State<CrewAssignmentDetailsScreen> {
  late String _currentStatus;
  late Color _statusColor;
  late Color _statusBg;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _evidencePhotos = [];
  final TextEditingController _sitrepNotesController = TextEditingController();
  int _evacuatedCount = 4;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.assignment.status;
    _statusColor = widget.assignment.statusColor;
    _statusBg = widget.assignment.statusBg;
  }

  @override
  void dispose() {
    _sitrepNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidencePhoto(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 75);
      if (photo != null) {
        setState(() {
          _evidencePhotos.add(photo);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Field evidence photo attached to SitRep!'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera: $e')),
        );
      }
    }
  }

  void _showStatusBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Update Tactical Operation Status',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Broadcast real-time deployment status to Central Operations Command.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusOption(
                title: 'En Route / Mobilizing',
                subtitle: 'Unit is on the road moving toward incident sector',
                icon: Icons.directions_car_rounded,
                color: const Color(0xFF1E40AF),
                bg: const Color(0xFFDBEAFE),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _currentStatus = 'En Route';
                    _statusColor = const Color(0xFF1E40AF);
                    _statusBg = const Color(0xFFDBEAFE);
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                title: 'On Scene / Rescue Active',
                subtitle: 'Crew arrived on site, operations actively underway',
                icon: Icons.run_circle_outlined,
                color: const Color(0xFFD97706),
                bg: const Color(0xFFFEF3C7),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _currentStatus = 'On Scene';
                    _statusColor = const Color(0xFFD97706);
                    _statusBg = const Color(0xFFFEF3C7);
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                title: 'Mission Accomplished / Resolved',
                subtitle: 'All victims extracted and area made safe',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF16A34A),
                bg: const Color(0xFFDCFCE7),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _currentStatus = 'Completed';
                    _statusColor = const Color(0xFF16A34A);
                    _statusBg = const Color(0xFFDCFCE7);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryNavy, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Dispatch Mission Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          // 1. Top Incident Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.asset(
                    widget.assignment.imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.assignment.priorityBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.assignment.priority,
                              style: GoogleFonts.plusJakartaSans(
                                color: widget.assignment.priorityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.assignment.district} District',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.assignment.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.assignment.location,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.assignment.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: const Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Tactical Status Stepper Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tactical Mission Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    InkWell(
                      onTap: _showStatusBottomSheet,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentStatus,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _statusColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_rounded, size: 12, color: _statusColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Stepper Visual
                Row(
                  children: [
                    _buildStepNode('Assigned', true),
                    _buildStepLine(_currentStatus != 'Assigned'),
                    _buildStepNode('En Route', _currentStatus == 'En Route' || _currentStatus == 'On Scene' || _currentStatus == 'Completed'),
                    _buildStepLine(_currentStatus == 'On Scene' || _currentStatus == 'Completed'),
                    _buildStepNode('On Scene', _currentStatus == 'On Scene' || _currentStatus == 'Completed'),
                    _buildStepLine(_currentStatus == 'Completed'),
                    _buildStepNode('Done', _currentStatus == 'Completed'),
                  ],
                ),
              ],
            ),
          ),

          // 3. Ground SitRep & Evidence Photo Uploader
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field Situation Report (SitRep)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                // Rescued Civilians Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Civilians Rescued / Evacuated:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _evacuatedCount > 0 ? () => setState(() => _evacuatedCount--) : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          color: const Color(0xFF64748B),
                        ),
                        Text(
                          '$_evacuatedCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _evacuatedCount++),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Photo Attachment Row
                Text(
                  'Attach Live On-Scene Evidence Photos:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickEvidencePhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickEvidencePhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 16),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                if (_evidencePhotos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _evidencePhotos.length,
                      itemBuilder: (ctx, i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_evidencePhotos[i].path),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _sitrepNotesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter on-ground tactical notes (e.g. water receded by 1ft)...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Field SitRep transmitted to Operations Command!'),
                          backgroundColor: Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Transmit Ground SitRep'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(String label, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: isActive ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
          child: Icon(Icons.check, size: 12, color: isActive ? Colors.white : Colors.transparent),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }
}
