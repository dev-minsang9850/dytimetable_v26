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
  int _currentIndex = 0; // 0: 시간표, 1: 급식

  void _setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 상단에는 아무 탭도 두지 않고, 바로 콘텐츠
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  TodayTimetableScreen(),
                  TodayMealScreen(),
                ],
              ),
            ),

            // 🔹 아래쪽 전환 버튼 영역
            const SizedBox(height: 2),
            _BottomSwitchBar(
              currentIndex: _currentIndex,
              onTap: _setIndex,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _BottomSwitchBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomSwitchBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BottomSwitchButton(
              label: '시간표',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _BottomSwitchButton(
              label: '급식',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSwitchButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomSwitchButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
