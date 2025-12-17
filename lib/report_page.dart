import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Report page displays sales analytics, generates receipts, and manages historical receipt data
/// Receives inventory data and receipt management callbacks from parent widget
class ReportPage extends StatefulWidget {
  final List<Map<String, dynamic>> inventory;
  final Function addReceipt; // Callback to persist new receipt to parent state/storage
  final Function removeReceiptAt; // Callback to delete receipt by index from parent state/storage
  final List<Map<String, dynamic>> loadedReceipts; // Previously generated receipts loaded from storage

  const ReportPage({
    super.key,
    required this.inventory,
    required this.addReceipt,
    required this.removeReceiptAt,
    required this.loadedReceipts,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  double _totalSales = 0.0;
  final List<Map<String, dynamic>> _filteredSales = []; // Items with sold > 0, sorted by revenue

  @override
  void initState() {
    super.initState();
    _calculateTotalSales();
  }

  /// Aggregates sales data from inventory:
  /// - Calculates total revenue across all products
  /// - Filters items with sales > 0
  /// - Sorts by total revenue (descending)
  void _calculateTotalSales() {
    _totalSales = 0.0;
    _filteredSales.clear();

    for (var item in widget.inventory) {
      final soldCount = (item['sold'] as int?) ?? 0;
      final price = (item['price'] as double?) ?? 0.0;

      _totalSales += price * soldCount;

      if (soldCount > 0) {
        _filteredSales.add({
          'product': item['product'],
          'sold': soldCount,
          'totalPrice': price * soldCount,
        });
      }
    }
    // Sort by revenue (highest first) for "Most Sold Items" display
    _filteredSales.sort(
            (a, b) => (b['totalPrice'] as double).compareTo(a['totalPrice'] as double));
  }

  /// Creates receipt snapshot of current sales state and adds to receipt history
  /// Receipt includes timestamp, total sales, and itemized breakdown
  void _generateReceipt() {
    if (_filteredSales.isEmpty) {
      widget.addReceipt({
        'date': DateTime.now(),
        'content': "No sales data available.",
      });
      return;
    }

    StringBuffer receiptBuffer = StringBuffer();
    String currentDate = DateFormat('yyyy-MM-dd – hh:mm a').format(DateTime.now());

    receiptBuffer.writeln("Total Sales Amount: ₱${_totalSales.toStringAsFixed(2)}\n");
    receiptBuffer.writeln("Most Sold Items:\n");

    for (var item in _filteredSales) {
      receiptBuffer.writeln(
          '${item['product']} - Sold: ${item['sold']} - Total Price: ₱${item['totalPrice'].toStringAsFixed(2)}');
    }

    // Delegate to parent widget to persist receipt (likely to SharedPreferences or database)
    widget.addReceipt({
      'date': DateTime.now(),
      'content': "Receipt\nDate: $currentDate\n${receiptBuffer.toString()}",
    });

    // Recalculate in case inventory was modified elsewhere
    _calculateTotalSales();
    setState(() {}); // Trigger UI rebuild to show new receipt
  }

  /// Shows confirmation dialog before deleting receipt
  /// Uses async/await pattern to handle user decision
  Future<void> _confirmDeleteReceipt(int index) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text(
            'Are you sure you want to delete this receipt?'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      widget.removeReceiptAt(index); // Delegate deletion to parent widget
      setState(() {}); // Refresh UI to remove deleted receipt from list
    }
  }

  /// Resets all 'sold' counts to 0 across inventory after confirmation
  /// Useful for starting new sales period while preserving product catalog
  Future<void> _confirmResetSoldProducts() async {
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Sold Products'),
        content: const Text('Are you sure you want to reset the sold products?'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              // Mutates inventory directly - parent widget holds reference to same list
              for (var item in widget.inventory) {
                item['sold'] = 0;
              }
              _calculateTotalSales(); // Recalculate to reflect zero sales
              Navigator.of(ctx).pop(true);
            },
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      setState(() {}); // Refresh UI to show zero sales data
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF007BA7);
    const Color bodyTextColor = Color(0xFF6B7280);
    final receipts = widget.loadedReceipts;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'View Reports',
          style: TextStyle(
            fontFamily: 'MyFont',
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: themeColor,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFfaf3e0),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200), // Responsive max width for larger screens
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Total Sales Section
                const Text(
                  'Total Sales',
                  style: TextStyle(
                    fontFamily: 'MyFont',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${_totalSales.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                // Most Sold Items Section
                const Text(
                  'Most Sold Items',
                  style: TextStyle(
                    fontFamily: 'MyFont',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (_filteredSales.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No sales items.',
                      style: TextStyle(fontSize: 16, color: bodyTextColor),
                    ),
                  ),
                // Map filtered sales to styled container cards
                ..._filteredSales.map((item) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      '${item['product']} — Sold: ${item['sold']} — Total: ₱${item['totalPrice'].toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, color: bodyTextColor),
                    ),
                  );
                }),
                const SizedBox(height: 36),
                // Generate Receipt Button - Creates snapshot of current sales
                ElevatedButton(
                  onPressed: _generateReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 5,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Generate Receipt'),
                ),
                const SizedBox(height: 16),
                // Reset Button - Clears all sold counts (destructive action)
                ElevatedButton(
                  onPressed: _confirmResetSoldProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 5,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Reset Sold Products'),
                ),
                const SizedBox(height: 48),
                // Historical Receipts Section - Shows all previously generated receipts
                if (receipts.isNotEmpty) ...[
                  const Text(
                    'Receipts',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListView.separated(
                    shrinkWrap: true, // Allow ListView to size itself within Column
                    physics: const NeverScrollableScrollPhysics(), // Disable independent scrolling
                    itemCount: receipts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final receipt = receipts[index];
                      final receiptDate =
                      DateFormat('yyyy-MM-dd – hh:mm a').format(receipt['date']);
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded( // Prevents overflow if date text is long
                                    child: Text(
                                      'Receipt - $receiptDate',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: themeColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8.0), // Increases touch target size
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 26,
                                      ),
                                      tooltip: 'Delete this receipt',
                                      onPressed: () => _confirmDeleteReceipt(index),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                receipt['content'], // Full receipt text including header and itemization
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.4, // Line height for readability
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}