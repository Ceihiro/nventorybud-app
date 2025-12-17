import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatefulWidget {
  final List<Map<String, dynamic>> inventory; // Reference to shared inventory data

  const AnalyticsPage({super.key, required this.inventory});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

// SingleTickerProviderStateMixin required for TabController animation
class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  String? _selectedCategory; // null = show all categories
  String? _selectedTrend; // null = no sorting applied
  final List<String> _categories = []; // Unique categories extracted from inventory
  final List<String> _trends = ['Most Sold', 'Least Sold']; // Sorting options for sold products

  // Calculated totals - updated when filters change
  double _totalInventoryPrice = 0.0; // Sum of (price * quantity) for all products
  double _totalSoldPrice = 0.0; // Sum of (price * sold) for all products

  late TabController _tabController; // Controls tab switching between Inventory and Sold Products

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _calculateTotalPrices();
    _tabController = TabController(length: 2, vsync: this); // 2 tabs: Inventory and Sold Products
  }

  // Extract unique categories from inventory using Set to prevent duplicates
  void _loadCategories() {
    final Set<String> categorySet = {};
    for (var item in widget.inventory) {
      if (item['category'] != null) {
        categorySet.add(item['category']);
      }
    }
    _categories.addAll(categorySet);
  }

  // Calculate total monetary values for inventory and sold products
  // Called on init and whenever filters change
  void _calculateTotalPrices() {
    _totalInventoryPrice = 0.0;
    _totalSoldPrice = 0.0;

    for (var item in widget.inventory) {
      final price = (item['price'] as double?) ?? 0.0;
      final quantity = (item['quantity'] as int?) ?? 0;

      _totalInventoryPrice += price * quantity;

      final soldCount = (item['sold'] as int?) ?? 0;
      _totalSoldPrice += price * soldCount;
    }
  }

  @override
  void dispose() {
    _tabController.dispose(); // Clean up to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate pie chart data on each build to reflect current state
    final List<PieChartSectionData> inventorySections = _createInventorySections();
    final List<PieChartSectionData> soldSections = _createSoldSections();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            fontFamily: 'MyFont',
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF007BA7),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'Inventory'),
            Tab(text: 'Sold Products'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/analyticsbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInventoryTab(inventorySections),
            _buildSoldProductsTab(soldSections),
          ],
        ),
      ),
    );
  }

  // Build Inventory tab with category filter and pie chart
  Widget _buildInventoryTab(List<PieChartSectionData> inventorySections) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Select Category',
              style: TextStyle(
                fontFamily: 'MyFont',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007BA7),
              ),
            ),
            // Category filter - null value shows all products
            DropdownButton<String>(
              hint: const Text(
                'Select Category',
                style: TextStyle(color: Colors.white),
              ),
              value: _selectedCategory,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _calculateTotalPrices(); // Recalculate totals when filter changes
                });
              },
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              dropdownColor: const Color(0xFF007BA7),
            ),
            const SizedBox(height: 20),
            const Text(
              'Inventory Status',
              style: TextStyle(
                fontFamily: 'MyFont',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007BA7),
              ),
            ),
            const SizedBox(height: 10),
            // Display total inventory value
            Text(
              'Total Inventory Price: ₱${_totalInventoryPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Pie chart visualization
            SizedBox(
              width: 300,
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: inventorySections,
                  centerSpaceRadius: 40, // Creates donut chart effect
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(enabled: true), // Enable tap interactions
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildLegend(inventorySections, 'Inventory'),
          ],
        ),
      ),
    );
  }

  // Build Sold Products tab with trend sorting and pie chart
  Widget _buildSoldProductsTab(List<PieChartSectionData> soldSections) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Select Sales Trend',
              style: TextStyle(
                fontFamily: 'MyFont',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007BA7),
              ),
            ),
            // Trend sorting dropdown - sorts by most/least sold
            DropdownButton<String>(
              hint: const Text(
                'Select Trend',
                style: TextStyle(color: Colors.white),
              ),
              value: _selectedTrend,
              onChanged: (value) {
                setState(() {
                  _selectedTrend = value;
                  _calculateTotalPrices(); // Recalculate totals when sort changes
                });
              },
              items: _trends.map((String trend) {
                return DropdownMenuItem<String>(
                  value: trend,
                  child: Text(
                    trend,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              dropdownColor: const Color(0xFF007BA7),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sold Products',
              style: TextStyle(
                fontFamily: 'MyFont',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007BA7),
              ),
            ),
            const SizedBox(height: 10),
            // Display total sales value
            Text(
              'Total Sold Price: ₱${_totalSoldPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Conditional rendering: show empty state or pie chart
            SizedBox(
              width: 300,
              height: 300,
              child: soldSections.isEmpty
                  ? const Center(
                child: Text(
                  'No sales yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE57373),
                  ),
                ),
              )
                  : PieChart(
                PieChartData(
                  sections: soldSections,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(enabled: true),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildLegend(soldSections, 'Sold Products'),
          ],
        ),
      ),
    );
  }

  // Generate pie chart sections for current inventory
  // Filters by _selectedCategory and excludes products with 0 quantity
  List<PieChartSectionData> _createInventorySections() {
    // Color palette - cycles through colors using modulo operator
    const List<Color> colorPalette = [
      Color(0xFF007BA7),
      Color(0xFF4DB6AC),
      Color(0xFFE57373),
      Color(0xFFFFB74D),
      Color(0xFF81C784),
      Color(0xFFBA68C8),
      Color(0xFFFF8A65),
      Color(0xFF64B5F6),
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    for (var item in widget.inventory) {
      final productName = item['product'] as String? ?? 'Unknown';
      final quantity = (item['quantity'] as int?)?.toDouble() ?? 0;

      // Apply category filter if selected
      if (_selectedCategory != null && item['category'] != _selectedCategory) {
        continue;
      }

      if (quantity <= 0) continue; // Exclude out-of-stock products from chart

      // Assign color from palette, wrap around using modulo
      Color color = colorPalette[colorIndex % colorPalette.length];
      colorIndex++;

      sections.add(
        PieChartSectionData(
          color: color,
          value: quantity, // Pie slice size based on quantity
          title: productName,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6, // Position label outside slice
        ),
      );
    }

    return sections;
  }

  // Generate pie chart sections for sold products
  // Filters by _selectedCategory, excludes products with 0 sales, applies trend sorting
  List<PieChartSectionData> _createSoldSections() {
    // Different color palette for sold products visualization
    const List<Color> colorPalette = [
      Color(0xFFE57373),
      Color(0xFFFF8A65),
      Color(0xFFFFB74D),
      Color(0xFF81C784),
      Color(0xFFBA68C8),
      Color(0xFF64B5F6),
      Color(0xFF007BA7),
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    // Filter: only products with sold > 0 and matching category (if selected)
    final soldItems = widget.inventory.where((item) {
      final soldCount = (item['sold'] as int?) ?? 0;
      return soldCount > 0 && (_selectedCategory == null || item['category'] == _selectedCategory);
    }).toList();

    // Apply sorting based on selected trend
    if (_selectedTrend == 'Most Sold') {
      soldItems.sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int)); // Descending
    } else if (_selectedTrend == 'Least Sold') {
      soldItems.sort((a, b) => (a['sold'] as int).compareTo(b['sold'] as int)); // Ascending
    }

    if (soldItems.isEmpty) {
      return sections; // Return empty list for empty state handling
    }

    for (var item in soldItems) {
      final productName = item['product'] as String? ?? 'Unknown';
      final soldCount = (item['sold'] as int?) ?? 0;

      Color color = colorPalette[colorIndex % colorPalette.length];
      colorIndex++;

      sections.add(
        PieChartSectionData(
          color: color,
          value: soldCount.toDouble(), // Pie slice size based on sold count
          title: productName,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );
    }

    return sections;
  }

  // Build legend with color indicators and calculated totals
  // Maps section data back to inventory to retrieve price information
  Widget _buildLegend(List<PieChartSectionData> sections, String title) {
    final List<Widget> legendItems = sections.map((section) {
      final productName = section.title;
      final quantity = (section.value).toInt();
      // Look up product price from inventory to calculate total
      final totalPrice = (quantity * (widget.inventory.firstWhere((item) => item['product'] == productName)['price'] as double)).toStringAsFixed(2);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // Color indicator box matching pie chart section
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: section.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            // Product details: name, quantity, total price
            Expanded(
              child: Text(
                '$productName - Quantity: $quantity - Total Price: ₱$totalPrice',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          ...legendItems, // Spread operator to insert all legend items
        ],
      ),
    );
  }
}