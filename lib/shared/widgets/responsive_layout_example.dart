import 'package:flutter/material.dart';
import 'responsive_layout.dart';

/// Example of how to use the responsive layout components
/// This file demonstrates the usage patterns for the responsive widgets
class ResponsiveLayoutExample extends StatelessWidget {
  const ResponsiveLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Responsive text
          const ResponsiveText(
            'Welcome to GreenQuest',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            textAlign: TextAlign.center,
          ),

          ResponsiveSpacing(height: 24),

          // Responsive card
          ResponsiveCard(
            child: Column(
              children: [
                const Icon(Icons.school, size: 48, color: Color(0xFF34A853)),
                ResponsiveSpacing(height: 16),
                const ResponsiveText(
                  'Educational Platform',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(height: 8),
                const ResponsiveText(
                  'Learn and grow with our comprehensive educational system',
                  fontSize: 14,
                  color: Colors.grey,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          ResponsiveSpacing(height: 32),

          // Responsive buttons
          ResponsiveButton(
            onPressed: () {
              // Handle button press
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34A853),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const ResponsiveText(
              'Get Started',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          ResponsiveSpacing(height: 16),

          ResponsiveButton(
            onPressed: () {
              // Handle secondary button press
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF34A853),
              side: const BorderSide(color: Color(0xFF34A853)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
            child: const ResponsiveText(
              'Learn More',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF34A853),
            ),
          ),
        ],
      ),
    );
  }
}

/// Example of using ResponsiveLayout with custom padding
class CustomPaddingExample extends StatelessWidget {
  const CustomPaddingExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: const ResponsiveText(
        'This layout uses custom padding',
        fontSize: 16,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Example of using ResponsiveLayout without scroll view
class NoScrollExample extends StatelessWidget {
  const NoScrollExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      useScrollView: false,
      child: const ResponsiveText(
        'This layout doesn\'t use scroll view',
        fontSize: 16,
        textAlign: TextAlign.center,
      ),
    );
  }
}
