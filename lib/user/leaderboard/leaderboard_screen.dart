import 'package:flutter/material.dart';
import '../../shared/custom_drawer.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  int selectedDrawerIndex = 2;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topUsers = [
      {
        'name': 'Andrei Vern',
        'points': 110,
        'img': 'assets/images/Photo (4).png',
        'bg': 'assets/images/Ellipse 91.png',
        'rank': 2,
      },
      {
        'name': 'John Mark',
        'points': 112,
        'img': 'assets/images/Photo.png',
        'bg': 'assets/images/Ellipse 97.png',
        'rank': 1,
      },
      {
        'name': 'Sofia Grey',
        'points': 99,
        'img': 'assets/images/Photo (2).png',
        'bg': 'assets/images/Ellipse 100.png',
        'rank': 3,
      },
    ];
    final users = [
      {'name': 'Mario Proktoso', 'points': 97, 'img': 'assets/images/image 311 (1).png'},
      {'name': 'Jane ame', 'points': 95, 'img': 'assets/images/image 313.png'},
      {'name': 'Princess', 'points': 93, 'img': 'assets/images/image 318 (1).png'},
      {'name': 'Sophia', 'points': 92, 'img': 'assets/images/image 319.png'},
      {'name': 'Rose Ann', 'points': 90, 'img': 'assets/images/image 321.png'},
      {'name': 'Marie Lyn', 'points': 88, 'img': 'assets/images/image 326.png'},
      {'name': 'Janna Mae', 'points': 85, 'img': 'assets/images/Avatar.png'},
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
        title: const Text('Leaderboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: Color(0xFF34A853), width: 3),
                ),
                labelColor: const Color(0xFF34A853),
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Assignments'),
                  Tab(text: 'Activities'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Top 3
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2nd place
              Column(
                children: [
                  SizedBox(
                              height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/images/Ellipse 97.png', width: 100),
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: AssetImage('assets/images/Photo (4).png'),
                        ),
                        Positioned(
                          bottom: -5,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset('assets/images/Group 1171274949.png', width: 45),
                              
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 90,
                    child: Column(
                      children: const [
                        Text('Andrei Vern',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          softWrap: true,
                          textAlign: TextAlign.center,
                        ),
                        Text('110 pts',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                          softWrap: true,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              // 1st place
              Column(
                children: [
                  SizedBox(
                              height: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/images/Ellipse 91.png', width: 120),
                        CircleAvatar(
                          radius: 54,
                          backgroundImage: AssetImage('assets/images/Photo.png'),
                        ),
                        Positioned(
                          top: -7,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset('assets/images/image 310 (1).png', width: 60),
                              
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 15,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset('assets/images/Group 1171274949 (2).png', width: 45),
                              
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 90,
                    child: Column(
                      children: const [
                        Text('John Mark',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          softWrap: true,
                          textAlign: TextAlign.center,
                        ),
                        Text('112 pts',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                          softWrap: true,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              // 3rd place
              Column(
                children: [
                  SizedBox(
                              height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/images/Ellipse 100.png', width: 100),
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: AssetImage('assets/images/Photo (2).png'),
                        ),
                        Positioned(
                          bottom: -7,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset('assets/images/Group 1171274949 (1).png', width: 45),
                              
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 90,
                    child: Column(
                      children: const [
                        Text('Sofia Grey',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          softWrap: true,
                          textAlign: TextAlign.center,
                        ),
                        Text('99 pts',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                          softWrap: true,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
         
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32),topRight: Radius.circular(32),),
                border: Border.all(color:  Colors.black12)
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i];
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text('#${i + 4}', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold)),
                          ),
                          CircleAvatar(
                            backgroundImage: AssetImage(u['img'] as String),
                            radius: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(u['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Text('${u['points']} pts', style: const TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
} 