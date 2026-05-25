import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/chat_screen.dart';
import '../screens/tracker_screen.dart';
import '../screens/outreach_screen.dart';
import '../screens/pipeline_screen.dart';
import '../screens/mood_screen.dart';
import '../providers/auth_provider.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ChatScreen(),
    TrackerScreen(),
    OutreachScreen(),
    PipelineScreen(),
    MoodScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final founderName = ref.watch(founderNameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: _selectedIndex == 0
          ? null // Chat screen has its own custom high-fidelity header
          : AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D28D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getAppBarTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              actions: [
                // Displaying Founder Name + Sign out button
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'signout') {
                        ref.read(signInNotifierProvider.notifier).signOut();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signed out successfully. 👋'),
                            backgroundColor: Color(0xFF6D28D9),
                          ),
                        );
                      }
                    },
                    child: Chip(
                      backgroundColor: const Color(0xFFEDE9FE),
                      side: BorderSide.none,
                      avatar: const CircleAvatar(
                        backgroundColor: Color(0xFF6D28D9),
                        child: Icon(Icons.person_rounded, size: 14, color: Colors.white),
                      ),
                      label: Text(
                        founderName,
                        style: const TextStyle(
                          color: Color(0xFF6D28D9),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'signout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF6D28D9),
              unselectedItemColor: const Color(0xFF64748B),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology_outlined),
                  activeIcon: Icon(Icons.psychology_rounded),
                  label: 'Socio AI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  activeIcon: Icon(Icons.analytics_rounded),
                  label: 'Metrics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.outgoing_mail),
                  activeIcon: Icon(Icons.outgoing_mail),
                  label: 'Outreach',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.monetization_on_outlined),
                  activeIcon: Icon(Icons.monetization_on_rounded),
                  label: 'Pipeline',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border_rounded),
                  activeIcon: Icon(Icons.favorite_rounded),
                  label: 'Wellness',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Startup Metrics';
      case 2:
        return 'Cold Outreach';
      case 3:
        return 'Investor Pipeline';
      case 4:
        return 'Founder Wellness';
      default:
        return 'Socio';
    }
  }
}
