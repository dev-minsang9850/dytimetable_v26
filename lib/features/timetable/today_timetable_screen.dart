// lib/features/timetable/today_timetable_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/neis_timetable_api.dart';
import '../setup/setup_screen.dart';

/// NEIS 과목명을 시계에 표시할 짧은 이름으로 매핑
const Map<String, String> subjectShortNames = {
  '공통국어1': '국어',
  '공통영어1': '영어',
  '공통수학1': '수학',
  '통합사회1': '통사',
  '통합과학1': '통과',
  '한국사1': '한국사',
  '문학': '문학',
  '확률과 통계': '확통',

  // 외국어
  '영어Ⅰ': '영Ⅰ',
  '영어Ⅱ': '영Ⅱ',
  '일본어': '일본어',
  '중국어': '중국어',

  // 체육/예술
  '체육1': '체육',
  '스포츠 생활': '체육',
  '스포츠 문화': '스문',
  '미술': '미술',
  '발명과 디자인': '발디',
  '드로잉': '드로잉',
  '진로': '진로',

  // 상업/경영/회계
  '상업 경제': '상경',
  '창업 일반': '창업',
  '사무 관리': '사무',
  '기업 자원 통합 관리': 'ERP',
  '성공적인 직업생활': '성직',
  '고객관리': '고객',
  '문서관리': '문서',
  '문서작성': '문서',
  '자금관리': '자금',
  '원천징수': '원천',
  '대수': '대수',

  // 정보/공업/컴퓨터
  '정보': '정보',
  '정보 처리와 관리': '정처',
  '컴퓨터 그래픽': '컴그',
  '컴퓨터 그래픽 심화 실습': '컴그실',
  '프로그래밍(PYTHON)': '파이썬',
  '웹 프로그래밍 실무': '웹프실',
  '프로그래밍 언어 활용': '응프',
  '자료 구조': '자구',
  '자료구조 활용': '응프',
  '컴퓨터 구조': '컴구조',
  '정보 통신': '정통',
  'SQL작성': '데베',
  '빅데이터 프로그래밍': '빅프',
  '스마트문화앱 구현': '스문콘',
  '2D 캐릭터 제작': '캐릭',
  '데이터베이스 구현': '데베',
  '인공지능 수학': '인수',
  '인공지능과 미래사회': '인미사',

  // 보건/간호
  '인체 구조와 기능': '인체',
  '진료 보조 기초1': '진보',
  '기초 간호 임상 실무': '기간',
  '보건 간호': '보간',
  '공중 보건': '공보',
  '생활환경 위생관리': '위생',
  '화법과 작문': '화작',

  // 기타
  '비즈니스 엑셀': '엑셀',
  '언어생활과 한자': '한자',
  '환자이송지원': '이송',
  '진로활동': '진로',
  '자율·자치활동': '자율',
  '자율활동': '자율',
};

String shortSubject(String original) {
  // 별표(*) 같은 표시 제거
  final text = original.replaceAll('*', '').trim();
  if (text.isEmpty) return '';

  // 정확히 매핑되는 과목명 우선
  if (subjectShortNames.containsKey(text)) {
    return subjectShortNames[text]!;
  }

  // 매핑이 없으면 길이에 따라 앞 2~3글자만 사용
  if (text.length <= 3) return text;
  return text.substring(0, 3);
}

class TodayTimetableScreen extends StatefulWidget {
  const TodayTimetableScreen({super.key});

  @override
  State<TodayTimetableScreen> createState() => _TodayTimetableScreenState();
}

class _TodayTimetableScreenState extends State<TodayTimetableScreen> {
  final _api = NeisTimetableApi();

  bool _loading = true;
  String? _error;

  late DateTime _today;
  late DateTime _monday;
  late List<DateTime> _weekDays; // 월~금

  // grid[periodIndex][weekdayIndex] = 과목 문자열 (약어)
  // periodIndex: 0~6 (1~7교시), weekdayIndex: 0~4 (월~금)
  List<List<String>> _grid = List.generate(
    7,
    (_) => List.generate(5, (_) => ''),
  );

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    final weekday = _today.weekday; // 1=월 ... 7=일
    _monday = _today.subtract(Duration(days: weekday - 1));
    _weekDays = List.generate(
      5,
      (i) => _monday.add(Duration(days: i)),
    );
    _fetchWeekTimetable();
  }

  Future<void> _fetchWeekTimetable() async {
    setState(() {
      _loading = true;
      _error = null;
      _grid = List.generate(
        7,
        (_) => List.generate(5, (_) => ''),
      );
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final atptCode = prefs.getString('atptCode') ?? 'J10';
      final schoolCode = prefs.getString('schoolCode') ?? '7531328';
      final grade = prefs.getString('grade') ?? '';
      final classNm = prefs.getString('classNm') ?? '';

      final allRows = await _api.fetchWeekTimetable(
        atptCode: atptCode,
        schoolCode: schoolCode,
        anyDayInWeek: _today,
      );

      if (allRows.isEmpty) {
        setState(() {
          _loading = false;
          _error = '이번 주 시간표가 없습니다.';
        });
        return;
      }

      // 날짜 -> 요일 인덱스 (0=월 ... 4=금)
      String fmt(DateTime d) {
        final y = d.year.toString();
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        return '$y$m$day';
      }

      final dateToCol = <String, int>{};
      for (var i = 0; i < _weekDays.length; i++) {
        dateToCol[fmt(_weekDays[i])] = i;
      }

      for (final row in allRows) {
        // 학년/반 필터 (반은 contains로 조금 느슨하게)
        final matchGrade = grade.isEmpty ? true : row.grade == grade;
        final matchClass =
            classNm.isEmpty ? true : row.className.contains(classNm);
        if (!matchGrade || !matchClass) continue;

        final col = dateToCol[row.date];
        if (col == null) continue; // 월~금이 아닌 날짜

        final per = int.tryParse(row.period) ?? 0;
        if (per < 1 || per > 7) continue;
        final rowIdx = per - 1;

        // 과목명을 약어로 변환해서 표에 넣기
        _grid[rowIdx][col] = shortSubject(row.subject);
      }

      setState(() {
        _loading = false;
        final hasAny = _grid.any(
          (row) => row.any((cell) => cell.isNotEmpty),
        );
        if (!hasAny) {
          _error = '해당 학급 시간표가 없습니다.';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '시간표를 불러오지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final size = shortest * 0.82;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  _Header(
                    monday: _monday,
                    onRefresh: _fetchWeekTimetable,
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _fetchWeekTimetable,
              child: const Text(
                '다시 시도',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _WeekdayHeaderRow(weekDays: _weekDays),
          const SizedBox(height: 4),
          for (var periodIdx = 0; periodIdx < 7; periodIdx++)
            _PeriodRow(
              period: periodIdx + 1,
              subjects: _grid[periodIdx],
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime monday;
  final VoidCallback onRefresh;

  const _Header({
    required this.monday,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final friday = monday.add(const Duration(days: 4));
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이번 주 시간표',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${monday.month}월 ${monday.day}일 ~ ${friday.month}월 ${friday.day}일',
                style: const TextStyle(
                  fontSize: 7,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        // 설정 버튼: 학년/반 다시 설정
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SetupScreen()),
            );
          },
          icon: const Icon(Icons.settings, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 2),
        // 새로고침 버튼
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  final List<DateTime> weekDays; // 월~금

  const _WeekdayHeaderRow({required this.weekDays});

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['월', '화', '수', '목', '금'];

    return Row(
      children: [
        const SizedBox(
          width: 32,
          child: Text(
            '',
            style: TextStyle(fontSize: 10),
          ),
        ),
        for (var i = 0; i < 5; i++)
          Expanded(
            child: Center(
              child: Text(
                weekdayLabels[i],
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final int period; // 1~7
  final List<String> subjects; // 길이 5 (월~금)

  const _PeriodRow({
    required this.period,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '$period교시',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          for (var i = 0; i < 5; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  subjects[i],
                  style: const TextStyle(fontSize: 9),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
