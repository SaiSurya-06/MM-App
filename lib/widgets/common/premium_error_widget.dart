import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const PremiumErrorWidget({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark 
        ? const Color(0xFF09090E).withValues(alpha: 0.95) 
        : const Color(0xFFF5F5F7).withValues(alpha: 0.95);
        
    final cardBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.04) 
        : Colors.black.withValues(alpha: 0.02);
        
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.05);

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A26);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF6C6C7D);

    return Material(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE53935),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'An unexpected error has occurred in the application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSubColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        width: double.infinity,
                        child: SingleChildScrollView(
                          child: Text(
                            details.exceptionAsString(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (Navigator.of(context).canPop()) ...[
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.arrow_back, color: textColor),
                              label: Text('Go Back', style: TextStyle(color: textColor, fontFamily: 'Inter')),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          ElevatedButton.icon(
                            onPressed: () {
                              try {
                                GoRouter.of(context).go('/dashboard');
                              } catch (_) {
                                // Fallback if GoRouter is not ready
                                Navigator.of(context).pushWithSecondaryAnimation(
                                  MaterialPageRoute(
                                    builder: (_) => const Scaffold(
                                      body: Center(child: Text('Resetting...')),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try to Recover', style: TextStyle(fontFamily: 'Inter')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on NavigatorState {
  void pushWithSecondaryAnimation(Route<dynamic> route) {
    pushReplacement(route);
  }
}
