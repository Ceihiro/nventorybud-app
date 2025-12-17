import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProductPage extends StatefulWidget {
  final List<Map<String, dynamic>> inventory;

  const ProductPage({super.key, required this.inventory});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // Text controllers for form inputs - must be disposed to prevent memory leaks
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _restockQuantityController = TextEditingController();

  // Category filter state - null means show all products
  String? _selectedCategory;
  final List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = null;
    _loadInventory();
  }

  // Returns path to inventory.txt in app's documents directory
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/inventory.txt';
  }

  // Persist inventory to disk in CSV format: product,price,quantity,category,sold
  Future<void> _saveInventory() async {
    final filePath = await _getFilePath();
    final file = File(filePath);
    StringBuffer buffer = StringBuffer();

    for (var item in widget.inventory) {
      final soldCount = item['sold'] ?? 0;
      buffer.writeln('${item['product']},${item['price']},${item['quantity']},${item['category']},$soldCount');
    }

    await file.writeAsString(buffer.toString());
  }

  // Load inventory from disk and populate _categories list for dropdown
  Future<void> _loadInventory() async {
    final filePath = await _getFilePath();
    final file = File(filePath);

    if (await file.exists()) {
      final contents = await file.readAsString();
      final lines = contents.split('\n');

      for (var line in lines) {
        if (line.isNotEmpty) {
          final parts = line.split(',');
          if (parts.length < 5) continue; // Skip malformed lines

          String productName = parts[0].trim();
          String categoryName = parts[3].trim();

          // Case-insensitive duplicate check
          bool productExists = widget.inventory.any((item) => item['product'].toString().toLowerCase() == productName.toLowerCase());

          if (!productExists) {
            widget.inventory.add({
              'product': productName,
              'price': double.tryParse(parts[1].trim()) ?? 0.0,
              'quantity': int.tryParse(parts[2].trim()) ?? 0,
              'category': categoryName,
              'sold': int.tryParse(parts[4].trim()) ?? 0,
            });
          }

          // Build unique categories list for dropdown (case-insensitive)
          if (!_categories.any((c) => c.toLowerCase() == categoryName.toLowerCase())) {
            _categories.add(categoryName);
          }
        }
      }

      setState(() {}); // Trigger UI rebuild
    }
  }

  // Add new product or update existing product (quantity accumulates, price/category updates)
  void _addProduct() {
    if (_productController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty &&
        _categoryController.text.isNotEmpty) {
      setState(() {
        String inputProductName = _productController.text.trim().toLowerCase();
        String inputCategoryName = _categoryController.text.trim();

        // Check if product already exists (case-insensitive)
        int existingIndex = widget.inventory.indexWhere((item) =>
        item['product'].toString().toLowerCase() == inputProductName);

        if (existingIndex != -1) {
          // Update existing product: add quantity, update price and category
          int existingQuantity = widget.inventory[existingIndex]['quantity'] ?? 0;
          int newQuantity = existingQuantity + int.parse(_quantityController.text);
          widget.inventory[existingIndex]['quantity'] = newQuantity;

          double? inputPrice = double.tryParse(_priceController.text);
          if (inputPrice != null) {
            widget.inventory[existingIndex]['price'] = inputPrice;
          }

          widget.inventory[existingIndex]['category'] = inputCategoryName;
        } else {
          // Add new product with initial sold count of 0
          widget.inventory.add({
            'product': inputProductName,
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'quantity': int.tryParse(_quantityController.text) ?? 0,
            'category': inputCategoryName,
            'sold': 0,
          });

          // Add category to dropdown if it's new
          if (!_categories.any((c) => c.toLowerCase() == inputCategoryName.toLowerCase())) {
            _categories.add(inputCategoryName);
          }
        }
      });

      _saveInventory(); // Persist changes to disk

      // Clear all input fields after successful add
      _productController.clear();
      _priceController.clear();
      _quantityController.clear();
      _categoryController.clear();
    }
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _productController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _restockQuantityController.dispose();
    super.dispose();
  }

  // Helper to build styled table header cells
  Widget buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter inventory by selected category (case-insensitive), or show all if null
    final filteredInventory = _selectedCategory == null
        ? widget.inventory
        : widget.inventory.where((item) =>
    item['category'].toString().toLowerCase() == _selectedCategory!.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'View Products',
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
            // Price input - numeric keyboard
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            // Quantity input - numeric keyboard
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            // Category input
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text('Add Product'),
            ),
            const SizedBox(height: 16),
            // Category filter dropdown - null value shows all products
            DropdownButton<String>(
              hint: const Text('Select Category'),
              value: _selectedCategory,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Scrollable product table with dynamic rows
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(3),
                    3: FlexColumnWidth(3),
                    4: FlexColumnWidth(3),
                  },
                  children: [
                    // Table header row
                    TableRow(
                      decoration: BoxDecoration(color: const Color(0xFF007BA7)),
                      children: [
                        buildHeaderCell('Products'),
                        buildHeaderCell('Price'),
                        buildHeaderCell('Quantity'),
                        buildHeaderCell('Category'),
                        buildHeaderCell('Add/Delete'),
                      ],
                    ),
                    // Generate table rows from filteredInventory
                    for (int i = 0; i < filteredInventory.length; i++)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(filteredInventory[i]['product']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(filteredInventory[i]['price']?.toString() ?? '0'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(filteredInventory[i]['quantity']?.toString() ?? '0'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(filteredInventory[i]['category']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                // Restock button - opens dialog to add quantity
                                Expanded(
                                  child: IconButton(
                                    icon: const Icon(Icons.add, color: Colors.green),
                                    onPressed: () {
                                      _showRestockDialog(i, filteredInventory);
                                    },
                                    tooltip: 'Restock product',
                                  ),
                                ),
                                // Delete button - removes product permanently
                                Expanded(
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteProduct(i);
                                    },
                                    tooltip: 'Delete product',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Increment product quantity by specified amount and persist changes
  void _restockProduct(int index, int quantity) {
    setState(() {
      widget.inventory[index]['quantity'] += quantity;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.inventory[index]['product']} has been restocked.')),
      );
    });

    _saveInventory();
  }

  // Remove product from inventory by index and persist changes
  void _deleteProduct(int index) {
    setState(() {
      widget.inventory.removeAt(index);
    });

    _saveInventory();
  }

  // Show dialog to input restock quantity
  // NOTE: Must map filteredInventory index back to widget.inventory index
  void _showRestockDialog(int index, List<Map<String, dynamic>> filteredInventory) {
    _restockQuantityController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restock'),
          content: TextField(
            controller: _restockQuantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                int quantityToAdd = int.tryParse(_restockQuantityController.text) ?? 0;
                if (quantityToAdd > 0) {
                  // Map filtered list index to original inventory index
                  int originalIndex = widget.inventory.indexOf(filteredInventory[index]);
                  _restockProduct(originalIndex, quantityToAdd);
                  _restockQuantityController.clear();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid quantity.')),
                  );
                }
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}