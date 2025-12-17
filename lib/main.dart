import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'splash_screen.dart';
import 'product_page.dart';
import 'sales_page.dart';
import 'analytics_page.dart';
import 'report_page.dart';
import 'help_page.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Main data structures for app state
  final List<Map<String, dynamic>> _inventory = []; // Stores all product data
  final List<Map<String, dynamic>> _receipts = []; // Stores all sales receipts

  @override
  void initState() {
    super.initState();
    _initializeData(); // Load persisted data on app startup
  }

  // Initialize app by loading both inventory and receipts from disk
  Future<void> _initializeData() async {
    await _loadInventory();
    await _loadReceipts();
  }

  // Load inventory from inventory.txt file
  // File format: product,price,quantity,category,sold (CSV)
  Future<void> _loadInventory() async {
    final filePath = await _getInventoryFilePath();
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
          int soldCount = int.tryParse(parts[4].trim()) ?? 0;

          // Prevent duplicate entries (case-insensitive check)
          bool productExists = _inventory.any((item) =>
          item['product'].toString().toLowerCase() == productName.toLowerCase());

          if (!productExists) {
            _inventory.add({
              'product': productName,
              'price': double.tryParse(parts[1].trim()) ?? 0.0,
              'quantity': int.tryParse(parts[2].trim()) ?? 0,
              'category': categoryName,
              'sold': soldCount,
            });
          }
        }
      }

      setState(() {}); // Trigger UI update
    }
  }

  // Get path to inventory.txt in app's documents directory
  Future<String> _getInventoryFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/inventory.txt';
  }

  // Persist inventory to disk
  // Writes all inventory items to inventory.txt in CSV format
  Future<void> _saveInventory() async {
    final filePath = await _getInventoryFilePath();
    final file = File(filePath);
    StringBuffer buffer = StringBuffer();

    for (var item in _inventory) {
      buffer.writeln(
          '${item['product']},${item['price']},${item['quantity']},${item['category']},${item['sold']}');
    }

    await file.writeAsString(buffer.toString());
  }

  // Load receipts from receipts.txt file
  // File format: ISO8601_date|JSON_encoded_content (pipe-delimited)
  Future<void> _loadReceipts() async {
    final filePath = await _getReceiptsFilePath();
    final file = File(filePath);

    if (await file.exists()) {
      final contents = await file.readAsString();
      final lines = contents.split('\n');

      for (var line in lines) {
        if (line.isNotEmpty) {
          final parts = line.split('|');
          if (parts.length < 2) continue; // Skip malformed lines

          DateTime date = DateTime.parse(parts[0].trim());
          String encodedContent = parts[1].trim();
          String decodedContent = jsonDecode(encodedContent); // Decode JSON string

          _receipts.add({
            'date': date,
            'content': decodedContent,
          });
        }
      }

      setState(() {}); // Trigger UI update
    }
  }

  // Get path to receipts.txt in app's documents directory
  Future<String> _getReceiptsFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/receipts.txt';
  }

  // Persist receipts to disk
  // Writes all receipts to receipts.txt with date and JSON-encoded content
  Future<void> _saveReceipts() async {
    final filePath = await _getReceiptsFilePath();
    final file = File(filePath);
    StringBuffer buffer = StringBuffer();

    for (var receipt in _receipts) {
      buffer.writeln('${receipt['date'].toIso8601String()}|${jsonEncode(receipt['content'])}');
    }

    await file.writeAsString(buffer.toString());
  }

  // Update inventory after a sale (callback from SalesPage)
  // Decrements quantity and increments sold count for the specified product
  void _updateInventory(String productName, int quantitySold) {
    setState(() {
      for (var item in _inventory) {
        if (item['product'].toString().toLowerCase() == productName.toLowerCase()) {
          item['quantity'] = (item['quantity'] as int) - quantitySold;
          item['sold'] = (item['sold'] as int) + quantitySold;
          if (item['quantity'] < 0) {
            item['quantity'] = 0; // Ensure quantity never goes negative
          }
          break;
        }
      }
    });
    _saveInventory(); // Persist changes immediately
  }

  // Add new receipt to the list (callback from ReportPage)
  void _addReceipt(Map<String, dynamic> receipt) {
    setState(() {
      _receipts.add(receipt);
    });
    _saveReceipts(); // Persist changes immediately
  }

  // Remove receipt at specified index (callback from ReportPage)
  void _removeReceiptAt(int index) {
    setState(() {
      _receipts.removeAt(index);
    });
    _saveReceipts(); // Persist changes immediately
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/app.jpg',
              width: 34,
              height: 34,
            ),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'MyFont',
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF007BA7),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              SystemNavigator.pop(); // Exit the app
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFfaf3e0),
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Navigation button: Products page
              _buildButton('Products', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductPage(inventory: _inventory),
                  ),
                );
              }, iconPath: 'assets/icons/product.png'),
              SizedBox(height: 20),
              // Navigation button: Sales page
              _buildButton('Sales    ', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SalesPage(
                          onSale: _updateInventory, // Pass callback to update inventory
                          inventory: _inventory,
                        ),
                  ),
                );
              }, iconPath: 'assets/icons/sale.png'),
              SizedBox(height: 20),
              // Navigation button: Analytics page
              _buildButton('Analytics', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AnalyticsPage(inventory: _inventory),
                  ),
                );
              }, iconPath: 'assets/icons/analytic.png'),
              SizedBox(height: 20),
              // Navigation button: Reports page
              _buildButton('Reports    ', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportPage(
                      inventory: _inventory,
                      addReceipt: _addReceipt, // Pass callback to add receipts
                      removeReceiptAt: _removeReceiptAt, // Pass callback to remove receipts
                      loadedReceipts: _receipts,
                    ),
                  ),
                );
              }, iconPath: 'assets/icons/report.png'),
              SizedBox(height: 20),
              // Navigation button: Help page
              _buildButton('Need Help?', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to create styled navigation buttons
  // Optional iconPath parameter adds an icon before the button text
  ElevatedButton _buildButton(String title, VoidCallback onPressed,
      {String? iconPath}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF007BA7),
        fixedSize: const Size(200, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPath != null) // Conditionally render icon if path provided
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                iconPath,
                width: 24,
                height: 24,
              ),
            ),
          Text(title),
        ],
      ),
    );
  }
}