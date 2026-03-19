// lib/data/services/neis_meal_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/secrets.dart'; // 🔹 추가

class NeisMealApi {
  Future<MealResult> fetchMeal({
    required String atptCode,
    required String schoolCode,
    required DateTime date,
  }) async {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final ymd = '$year$month$day';

    final uri = Uri.parse(
      'https://open.neis.go.kr/hub/mealServiceDietInfo'
      '?KEY=$neismealApiKey' // 🔹 여기 변경
      '&Type=json'
      '&ATPT_OFCDC_SC_CODE=$atptCode'
      '&SD_SCHUL_CODE=$schoolCode'
      '&MLSV_YMD=$ymd',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));

    if (data['mealServiceDietInfo'] == null) {
      return MealResult.empty('급식 정보가 없습니다.');
    }

    final rows = data['mealServiceDietInfo'][1]['row'] as List<dynamic>;
    if (rows.isEmpty) {
      return MealResult.empty('급식 정보가 없습니다.');
    }

    final first = rows.first as Map<String, dynamic>;
    final mealType = (first['MMEAL_SC_NM'] as String?) ?? '급식';
    final rawMenu = (first['DDISH_NM'] as String?) ?? '';

    final parts = rawMenu
        .split('<br/>')
        .map((e) => e.replaceAll(RegExp(r'\([^)]*\)'), '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return MealResult(
      mealType: mealType,
      menuItems: parts,
    );
  }
}

class MealResult {
  final String mealType;
  final List<String> menuItems;
  final String? message;

  MealResult({
    required this.mealType,
    required this.menuItems,
    this.message,
  });

  factory MealResult.empty(String msg) {
    return MealResult(
      mealType: '급식',
      menuItems: const [],
      message: msg,
    );
  }
}
