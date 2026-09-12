import 'package:flutter/material.dart';

class RequestCategoryModel {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color activeBorderColor;

  const RequestCategoryModel({
    required this.id,
    required this.title,
    required this.icon,
    this.iconColor = const Color(0xFF0284C7),
    this.iconBgColor = const Color(0xFFE0F2FE),
    this.activeBorderColor = const Color(0xFF0284C7),
  });
}
