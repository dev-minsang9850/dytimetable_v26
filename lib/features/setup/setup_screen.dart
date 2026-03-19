// lib/features/setup/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _gradeController = TextEditingController();
  final _classNmController = TextEditingController();

  bool _saving = false;

  // 내 학교 기본값 (교육청/학교)
  static const String _defaultAtptCode = 'J10'; // 교육청 코드
  static const String _defaultSchoolCode = '7531328'; // 학교 코드

  // 학년별로 존재하는 반의 개수 정의 (예시)
  // 예: 1학년 1~3반, 2학년 1~9반, 3학년 1~9반
  final Map<int, int> _maxClassPerGrade = {
    1: 9, // 1학년 1~9반
    2: 10, // 2학년 1~10반 (예시)
    3: 9, // 3학년 1~9반 → 3학년 10반은 없는 반
  };

  Future<void> _save() async {
    if (_saving) return;

    final gradeText = _gradeController.text.trim();
    final classText = _classNmController.text.trim();

    final grade = int.tryParse(gradeText);
    final classNum = int.tryParse(classText);

    void _showError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 7, // 🔹 여기서 더 줄이기 (예: 9)
            ),
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 1) 숫자 여부 체크
    if (grade == null || classNum == null) {
      _showError('학년과 반은 숫자로 입력해 주세요.');
      return;
    }

    // 2) 기본 범위 체크
    if (grade < 1 || grade > 3) {
      _showError('학년은 1~3학년만 가능합니다.');
      return;
    }
    if (classNum < 1 || classNum > 10) {
      _showError('반은 1~10반까지만 가능합니다.');
      return;
    }

    // 3) 실제 존재하는 학년/반 조합인지 체크
    final maxClass = _maxClassPerGrade[grade];
    if (maxClass == null) {
      _showError('해당 학년은 지원되지 않습니다.');
      return;
    }
    if (classNum > maxClass) {
      _showError('$grade학년은 $maxClass반까지만 있습니다.');
      return;
    }

    // 여기까지 통과하면 유효
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('atptCode', _defaultAtptCode);
    await prefs.setString('schoolCode', _defaultSchoolCode);
    await prefs.setString('grade', grade.toString());
    await prefs.setString('classNm', classNum.toString());

    if (!mounted) return;
    setState(() => _saving = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showError(String message) {
    // 스낵바로 간단히 오류 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 11),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _classNmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 32,
        title: const Text(
          '기본 설정',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            const Text(
              '학년과 반을 입력해주세요!.\n',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160, // 가로 길이 줄인 입력 박스
                  child: TextField(
                    controller: _gradeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 11),
                    decoration: const InputDecoration(
                      labelText: '학년 (1~3)',
                      labelStyle: TextStyle(
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _classNmController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 11),
                    decoration: const InputDecoration(
                      labelText: '반 (1~10)',
                      labelStyle: TextStyle(
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '저장하고 시작하기',
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
