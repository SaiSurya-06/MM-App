import 'package:flutter/material.dart';

class ToastNotification {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    final scaffold = ScaffoldMessenger.of(context);
    
    // Determine background color
    Color bgColor = const Color(0xFF1E1E2E); // Default dark surface
    IconData icon = Icons.check_circle_outline;
    Color iconColor = Colors.green;

    if (isError) {
      bgColor = const Color(0xFFE53935); // Brand Red
      icon = Icons.error_outline;
      iconColor = Colors.white;
    } else if (isWarning) {
      bgColor = const Color(0xFFFB8C00); // Orange
      icon = Icons.warning_amber_outlined;
      iconColor = Colors.white;
    }

    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError || isWarning ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}
