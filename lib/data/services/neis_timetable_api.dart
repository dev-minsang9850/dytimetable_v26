// lib/data/services/neis_timetable_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/secrets.dart'; // 🔹 추가

class NeisTimetableApi {
  Future<List<TimetableRow>> fetchWeekTimetable({
    required String atptCode,
    required String schoolCode,
    required DateTime anyDayInWeek,
  }) async {
    final weekday = anyDayInWeek.weekday; // 1=월 ... 7=일
    final monday = anyDayInWeek.subtract(Duration(days: weekday - 1));
    final friday = monday.add(const Duration(days: 4));

    String fmt(DateTime d) {
      final y = d.year.toString();
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y$m$day';
    }

    final fromYmd = fmt(monday);
    final toYmd = fmt(friday);

    final uri = Uri.parse(
      'https://open.neis.go.kr/hub/hisTimetable'
      '?KEY=$neistimeApiKey' // 🔹 여기 변경
      '&Type=json'
      '&pIndex=1'
      '&pSize=1000'
      '&ATPT_OFCDC_SC_CODE=$atptCode'
      '&SD_SCHUL_CODE=$schoolCode'
      '&TI_FROM_YMD=$fromYmd'
      '&TI_TO_YMD=$toYmd',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));

    if (data['hisTimetable'] == null) {
      return [];
    }

    final rows = data['hisTimetable'][1]['row'] as List<dynamic>;
    return rows
        .map((e) => TimetableRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class TimetableRow {
  final String date; // ALL_TI_YMD
  final String grade; // GRADE
  final String className; // CLASS_NM
  final String period; // PERIO
  final String subject; // ITRT_CNTNT

  TimetableRow({
    required this.date,
    required this.grade,
    required this.className,
    required this.period,
    required this.subject,
  });

  factory TimetableRow.fromJson(Map<String, dynamic> json) {
    return TimetableRow(
      date: json['ALL_TI_YMD'] as String? ?? '',
      grade: json['GRADE'] as String? ?? '',
      className: json['CLASS_NM'] as String? ?? '',
      period: json['PERIO'] as String? ?? '',
      subject: json['ITRT_CNTNT'] as String? ?? '',
    );
  }
}
