// lib/features/meal/today_meal_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/neis_meal_api.dart';
import '../setup/setup_screen.dart';

class TodayMealScreen extends StatefulWidget {
  const TodayMealScreen({super.key});

  @override
  State<TodayMealScreen> createState() => _TodayMealScreenState();
}

class _TodayMealScreenState extends State<TodayMealScreen> {
  final _api = NeisMealApi();

  bool _loading = true;
  String? _error;
  List<String> _menuItems = [];
  String _mealType = '급식';

  @override
  void initState() {
    super.initState();
    _fetchMeal();
  }

  Future<void> _fetchMeal() async {
    setState(() {
      _loading = true;
      _error = null;
      _menuItems = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final atptCode = prefs.getString('atptCode') ?? 'J10';
      final schoolCode = prefs.getString('schoolCode') ?? '7531328';

      final today = DateTime.now();
      final result = await _api.fetchMeal(
        atptCode: atptCode,
        schoolCode: schoolCode,
        date: today,
      );

      if (result.message != null && result.menuItems.isEmpty) {
        setState(() {
          _error = result.message;
          _loading = false;
        });
      } else {
        setState(() {
          _mealType = result.mealType;
          _menuItems = result.menuItems;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '급식 정보를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdayNames[(today.weekday - 1).clamp(0, 6)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final size = shortest * 0.9; // 원형 화면 안쪽에 들어가도록 축소

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: _CircularMealContent(
              today: today,
              weekday: weekday,
              mealType: _mealType,
              menuItems: _menuItems,
              loading: _loading,
              error: _error,
              onRetry: _fetchMeal,
            ),
          ),
        );
      },
    );
  }
}

class _CircularMealContent extends StatelessWidget {
  final DateTime today;
  final String weekday;
  final String mealType;
  final List<String> menuItems;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _CircularMealContent({
    required this.today,
    required this.weekday,
    required this.mealType,
    required this.menuItems,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (loading) {
      body = const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                '다시 시도',
                style: TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      );
    } else if (menuItems.isEmpty) {
      body = const Center(
        child: Text(
          '급식 정보가 없습니다.',
          style: TextStyle(fontSize: 9),
        ),
      );
    } else {
      // 🔹 심플 카드 형태로 메뉴 표시 (불릿 없이 줄바꿈만)
      body = SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            menuItems.join('\n'), // 각 메뉴를 줄바꿈으로 연결
            style: const TextStyle(
              fontSize: 9,
              height: 1.2,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            mainTitle: '오늘 급식',
            dateLabel: '${today.month}월 ${today.day}일 ($weekday)',
            onRefresh: onRetry,
          ),
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                mealType, // 예: 중식, 석식
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String mainTitle;
  final String dateLabel;
  final VoidCallback onRefresh;

  const _Header({
    required this.mainTitle,
    required this.dateLabel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 제목 + 날짜
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainTitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // 설정 버튼 (시간표 화면과 동일 UX)
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SetupScreen()),
            );
          },
          icon: const Icon(Icons.settings, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 2),
        // 새로고침 버튼
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
