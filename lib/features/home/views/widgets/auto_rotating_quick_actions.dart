import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AutoRotatingQuickActions extends StatefulWidget {
  const AutoRotatingQuickActions({super.key});

  @override
  State<AutoRotatingQuickActions> createState() => _AutoRotatingQuickActionsState();
}

class _AutoRotatingQuickActionsState extends State<AutoRotatingQuickActions>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _animController;
  bool _isUserInteracting = false;

  final List<Map<String, dynamic>> _actions = const [
    {
      'title': 'Donate Aid',
      'subtitle': 'Food, medical & relief funds',
      'icon': Icons.favorite_rounded,
      'iconColor': Color(0xFFEF4444),
      'iconBg': Color(0xFFFEE2E2),
      'route': '/donate-categories',
    },
    {
      'title': 'Track Reports',
      'subtitle': 'Live status & council audits',
      'icon': Icons.assignment_outlined,
      'iconColor': Color(0xFF0284C7),
      'iconBg': Color(0xFFE0F2FE),
      'route': '/my-reports',
    },
    {
      'title': 'Disaster Map',
      'subtitle': 'Safe detours & hazard zones',
      'icon': Icons.map_rounded,
      'iconColor': Color(0xFF16A34A),
      'iconBg': Color(0xFFDCFCE7),
      'route': '/map',
    },
    {
      'title': 'Relief Centers',
      'subtitle': 'Emergency shelters & hubs',
      'icon': Icons.location_city_rounded,
      'iconColor': Color(0xFFD97706),
      'iconBg': Color(0xFFFEF3C7),
      'route': '/map',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
    _animController.repeat();
  }

  void _tick() {
    if (!_isUserInteracting && mounted && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      if (currentScroll >= maxScroll - 50) {
        _scrollController.jumpTo(0);
      } else {
        // Silky smooth, perfectly balanced sub-pixel linear glide
        _scrollController.jumpTo(currentScroll + 1.25);
      }
    }
  }

  @override
  void didUpdateWidget(covariant AutoRotatingQuickActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_animController.isAnimating) {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.removeListener(_tick);
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Relief Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F2B48),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2B48).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_rounded, size: 10, color: Color(0xFF0F2B48)),
                    const SizedBox(width: 3),
                    Text(
                      'LIVE FEED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F2B48),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Continuous Horizontal Infinite Smooth Marquee
        SizedBox(
          height: 54,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserInteracting = true;
              } else if (notification is ScrollEndNotification) {
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) {
                    _isUserInteracting = false;
                  }
                });
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 10000,
              itemBuilder: (context, index) {
                final action = _actions[index % _actions.length];
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F2B48).withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push(action['route'] as String),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: action['iconBg'] as Color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                action['icon'] as IconData,
                                color: action['iconColor'] as Color,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action['title'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F2B48),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    action['subtitle'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Color(0xFFCBD5E1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
