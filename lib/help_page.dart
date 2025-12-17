import 'package:flutter/material.dart';

/// Stateless help/tutorial page that provides user guidance for app features
/// No state management needed - displays static instructional content
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Help Center',
          style: TextStyle(
            fontFamily: 'MyFont',
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF007BA7),
      ),
      body: Container(
        color: const Color(0xFFfaf3e0), // Cream background matching app theme
        width: double.infinity, // Fill available width
        height: double.infinity, // Fill available height
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Enables scrolling for content overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App branding section
              const Text(
                'Welcome to NventoryBud!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your buddy for smarter sales and inventory', // App tagline/value proposition
                style: TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              // Feature guide section header
              const Text(
                'How to Use the App:',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Feature 1: Product management instructions
              _buildHelpItem(
                '1. Products:',
                'assets/icons/product.png',
                'Navigate to the Products page to add new items to your inventory. Fill in the product name, price, quantity, and category, then click "Add Product".',
              ),
              const SizedBox(height: 10),
              // Feature 2: Sales recording instructions
              _buildHelpItem(
                '2. Sales:',
                'assets/icons/sale.png',
                'Record sales by entering the product name and quantity sold. The inventory will be updated automatically.',
              ),
              const SizedBox(height: 10),
              // Feature 3: Analytics viewing instructions
              _buildHelpItem(
                '3. Analytics:',
                'assets/icons/analytic.png',
                'View your inventory status and sales data through the Analytics page. This will help you understand your sales trends and inventory levels.',
              ),
              const SizedBox(height: 10),
              // Feature 4: Report generation instructions
              _buildHelpItem(
                '4. Reports:',
                'assets/icons/report.png',
                'Generate reports to get insights into your inventory and sales performance.',
              ),
              const SizedBox(height: 20),
              // Support contact section
              const Text(
                'Need Further Assistance?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Support contact information (Note: phone number is masked with asterisks)
              const Text(
                'If you have any questions, need further assistance, or find any issues or errors, please contact our support team at 09**-***-****.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a reusable help item widget with icon, title, and description
  /// Used to maintain consistent formatting across all feature explanations
  ///
  /// @param title - Feature number and name (e.g., "1. Products:")
  /// @param iconPath - Asset path to feature icon (must exist in pubspec.yaml)
  /// @param description - Instructional text explaining how to use the feature
  Widget _buildHelpItem(String title, String iconPath, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align icon to top of text content
      children: [
        // Feature icon (24x24 standard size for inline icons)
        Image.asset(
          iconPath,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 8),
        // Feature text content (title + description)
        Expanded( // Prevents text overflow by wrapping within available space
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}