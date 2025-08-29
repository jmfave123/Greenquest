import 'package:flutter/material.dart';
import '../../shared/custom_drawer.dart';
import 'materials_detail_screen.dart';

class MaterialsListScreen extends StatefulWidget {
  const MaterialsListScreen({Key? key}) : super(key: key);

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  int selectedDrawerIndex = 3;
  @override
  Widget build(BuildContext context) {
    final materials = [
      {
        'title': 'Understanding Deforestation and its Impact',
        'date': 'January 1, 2025',
        'img': 'assets/images/engineering-supplies-blueprint 2.png',
      },
      {
        'title': 'The Role of Tress in Climate Change',
        'date': 'January 2, 2025',
        'img': 'assets/images/image 328.png',
      },
      {
        'title': 'The Role of Tress in Climate Change',
        'date': 'January 1, 2025',
        'img': 'assets/images/image 328.png',
      },
      {
        'title': 'Understanding Deforestation and its Impact',
        'date': 'January 1, 2025',
        'img': 'assets/images/engineering-supplies-blueprint 2.png',
      },
      {
        'title': 'Understanding Deforestation and its Impact',
        'date': 'January 1, 2025',
        'img': 'assets/images/engineering-supplies-blueprint 2.png',
      },
      {
        'title': 'The Role of Tress in Climate Change',
        'date': 'January 1, 2025',
        'img': 'assets/images/image 328.png',
      },
    ];
    return Scaffold(
      drawer: CustomDrawer(
        selectedIndex: selectedDrawerIndex,
        onSelect: (i) {
          setState(() => selectedDrawerIndex = i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Materials', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final crossAxisCount = isTablet ? 3 : 2;
          final childAspectRatio = isTablet ? 0.8 : 0.75;
          final imageHeight = isTablet ? 140.0 : 100.0;
          final gridPadding = isTablet ? 32.0 : 16.0;
          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(gridPadding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: gridPadding,
                    mainAxisSpacing: gridPadding,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: materials.length,
                  itemBuilder: (context, i) {
                    final m = materials[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialsDetailScreen()));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                              child: Image.asset(m['img']!, height: imageHeight, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Padding(
                              padding: EdgeInsets.all(isTablet ? 18 : 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['title']!,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTablet ? 17 : 15),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isTablet ? 14 : 10),
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                                  SizedBox(height: isTablet ? 14 : 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.circle, color: Color(0xFF34A853), size: 12),
                                      const SizedBox(width: 6),
                                      Text(m['date']!, style: TextStyle(color: Color(0xFF34A853), fontSize: isTablet ? 15 : 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 