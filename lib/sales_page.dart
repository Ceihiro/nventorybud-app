import 'package:flutter/material.dart';

class SalesPage extends StatefulWidget {
  final Function(String, int) onSale; // Callback to parent for inventory updates
  final List<Map<String, dynamic>> inventory; // Reference to shared inventory data

  const SalesPage({super.key, required this.onSale, required this.inventory});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String? _errorText; // Stores validation error messages, null when no error

  // Validate sale inputs and update inventory via callback
  // Performs multiple validation checks before allowing sale to proceed
  void _processSale() {
    String productName = _productController.text.trim();
    int? quantitySold = int.tryParse(_quantityController.text);

    // Validation 1: Product name must not be empty
    if (productName.isEmpty) {
      setState(() {
        _errorText = 'Please enter a product name.';
      });
      return;
    }

    // Validation 2: Quantity must be a positive integer
    if (quantitySold == null || quantitySold <= 0) {
      setState(() {
        _errorText = 'Please enter a valid quantity greater than zero.';
      });
      return;
    }

    // Find product in inventory (case-insensitive search)
    Map<String, dynamic>? product;
    for (var item in widget.inventory) {
      if (item['product'].toString().toLowerCase() == productName.toLowerCase()) {
        product = item;
        break;
      }
    }

    // Validation 3: Product must exist in inventory
    if (product == null) {
      setState(() {
        _errorText = 'Product not found in inventory.';
      });
      return;
    }

    int currentQuantity = product['quantity'] ?? 0;

    // Validation 4: Product must have stock available
    if (currentQuantity == 0) {
      setState(() {
        _errorText = 'Product is sold out. Please add more quantity.';
      });
      return;
    }

    // Validation 5: Sufficient quantity must be available
    if (quantitySold > currentQuantity) {
      setState(() {
        _errorText = 'Not enough quantity in inventory. Available: $currentQuantity';
      });
      return;
    }

    // All validations passed - trigger inventory update via callback
    // Parent (main.dart) handles actual inventory modification and persistence
    widget.onSale(productName, quantitySold);

    // Clear form and error state after successful sale
    setState(() {
      _errorText = null;
      _productController.clear();
      _quantityController.clear();
    });

    // Show success notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sold $quantitySold of $productName. Inventory updated.')),
    );

    // Re-fetch product to check if now sold out (quantity reached 0)
    var updatedProduct = widget.inventory.firstWhere(
          (item) => item['product'].toString().toLowerCase() == productName.toLowerCase(),
      orElse: () => {}, // Return empty map if not found
    );

    if (updatedProduct.isNotEmpty && (updatedProduct['quantity'] ?? 0) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$productName is now sold out.')),
      );
    }
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _productController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Record Sale',
          style: TextStyle(
            fontFamily: 'MyFont',
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF007BA7),
      ),
      body: Container(
        color: const Color(0xFFfaf3e0),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Product name input
            TextField(
              controller: _productController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),

            // Quantity input - numeric keyboard for easier input
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity Sold'),
              keyboardType: TextInputType.number,
            ),

            // Conditional error message display - only shows when _errorText is not null
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),

            // Process sale button - triggers validation and inventory update
            ElevatedButton(
              onPressed: _processSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BA7),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Sold',
                style: TextStyle(
                  fontFamily: 'MyFont',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}