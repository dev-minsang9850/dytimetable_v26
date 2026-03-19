// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';

import '../meal/today_meal_screen.dart';
import '../timetable/today_timetable_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController();
  int _currentIndex = 0; // 0: 시간표, 1: 급식

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDotTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              children: const [
                TodayTimetableScreen(),
                TodayMealScreen(),
              ],
            ),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PageDot(
                      selected: _currentIndex == 0,
                      onTap: () => _onDotTap(0),
                    ),
                    const SizedBox(width: 6),
                    _PageDot(
                      selected: _currentIndex == 1,
                      onTap: () => _onDotTap(1),
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
}

class _PageDot extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _PageDot({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? 10 : 6,
        height: selected ? 10 : 6,
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.grey.shade600,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
