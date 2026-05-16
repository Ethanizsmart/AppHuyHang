// lib/main.dart
import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';

void main() {
  runApp(const WasteApp());
}

class WasteApp extends StatelessWidget {
  const WasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste / Hủy hàng Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/* ----------------------------
 Models
---------------------------- */

class BatchRecipe {
  final String name;
  final double yieldAmount; // e.g. 7125
  final String yieldUnit; // e.g. 'ml'
  final List<RecipeLine> components; // base ingredients only for batch

  BatchRecipe({
    required this.name,
    required this.yieldAmount,
    required this.yieldUnit,
    required this.components,
  });
}

class MenuItem {
  final String name;
  final String unit; // unit of the menu item (e.g. 'tô', 'ly')
  final List<RecipeLine> components; // components can reference batch by name

  MenuItem({
    required this.name,
    required this.unit,
    required this.components,
  });
}

class RecipeLine {
  final String name;
  final double amount;
  final String unit;
  final bool isBatchRef;

  RecipeLine({
    required this.name,
    required this.amount,
    required this.unit,
    this.isBatchRef = false,
  });

  @override
  String toString() => '$name | $amount $unit ${isBatchRef ? "(batchRef)" : ""}';
}

class AggregatedIngredient {
  double amount;
  String unit;
  AggregatedIngredient({required this.amount, required this.unit});
}

class WasteRecord {
  final DateTime date;
  final String menuName;
  final double menuQty;
  final String menuUnit;
  final Map<String, AggregatedIngredient> aggregated;
  final String? reason;

  WasteRecord({
    required this.date,
    required this.menuName,
    required this.menuQty,
    required this.menuUnit,
    required this.aggregated,
    this.reason,
  });
}

// Ingredient model
class IngredientItem {
  final String name;
  String unit;
  IngredientItem({required this.name, required this.unit});
}

/* ----------------------------
 Demo data
---------------------------- */

final List<BatchRecipe> demoBatches = [
  BatchRecipe(
    name: 'Kaeshi かえし',
    yieldAmount: 7125,
    yieldUnit: 'ml',
    components: [
      RecipeLine(name: 'Nước mắm', amount: 6000, unit: 'ml'),
      RecipeLine(name: 'Muối', amount: 200, unit: 'g'),
      RecipeLine(name: 'Đường', amount: 300, unit: 'g'),
      RecipeLine(name: 'Mirin', amount: 1000, unit: 'ml'),
    ],
  ),
  BatchRecipe(
    name: 'Sốt mabo 麻婆豆腐',
    yieldAmount: 7125,
    yieldUnit: 'ml',
    components: [
      RecipeLine(name: 'Nước mắm', amount: 6000, unit: 'ml'),
      RecipeLine(name: 'Muối', amount: 200, unit: 'g'),
      RecipeLine(name: 'Đường', amount: 300, unit: 'g'),
      RecipeLine(name: 'Mirin', amount: 1000, unit: 'ml'),
    ],
  ),
  BatchRecipe(
    name: 'Dầu ớt tự làm 自家製チリオイル',
    yieldAmount: 3000,
    yieldUnit: 'g',
    components: [
      RecipeLine(name: 'Tỏi ニンニク', amount: 300, unit: 'g'),
      RecipeLine(name: 'Gừng 生姜', amount: 300, unit: 'g'),
      RecipeLine(name: 'Hành lá 白ネギみじん切り', amount: 300, unit: 'g'),
      RecipeLine(name: 'Ớt bột Thái プリックポン', amount: 100, unit: 'g'),
      RecipeLine(name: 'Ớt Hàn Quốc 韓国唐辛子', amount: 150, unit: 'g'),
      RecipeLine(name: 'Dầu 油', amount: 2000, unit: 'g'),
    ],
  ),
  BatchRecipe(
    name: 'Nước sốt yakiniku 焼肉のたれ',
    yieldAmount: 860,
    yieldUnit: 'g',
    components: [
      RecipeLine(name: 'Hành tây bào おろし玉ねぎ', amount: 80, unit: 'g'),
      RecipeLine(name: 'Tỏi にんにく', amount: 60, unit: 'g'),
      RecipeLine(name: 'Gừng 生姜', amount: 60, unit: 'g'),
      RecipeLine(name: 'Nước tương 醤油', amount: 300, unit: 'g'),
      RecipeLine(name: 'Rượu mirin みりん', amount: 180, unit: 'g'),
      RecipeLine(name: 'Rượu sake 酒', amount: 180, unit: 'g'),
      RecipeLine(name: 'Đường さとう', amount: 90, unit: 'g'),
    ],
  ),
];

final List<MenuItem> demoMenus = [
  MenuItem(
    name: 'Mì Tonkotsu 豚骨ラーメン',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi mảnh 博多麵', amount: 80, unit: 'g'),
      RecipeLine(name: 'Kaeshi かえし', amount: 25, unit: 'cc', isBatchRef: true),
      RecipeLine(name: 'Dầu tỏi gà ニンニク油', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Soup Tonkontsu 豚骨スープ', amount: 270, unit: 'cc'),
      RecipeLine(name: 'Tỏi băm ニンニクみじん切り', amount: 0.5, unit: 'g'),
      RecipeLine(name: 'Thịt Chashu チャーシュー', amount: 1, unit: 'miếng 枚'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Nấm mèo きくらげ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương', amount: 0.5, unit: 'quả 個'),
      RecipeLine(name: 'Mè ごま', amount: 1, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Mì Tonkotsu Chashu 豚骨チャーシューラーメン',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi mảnh 博多麵', amount: 80, unit: 'g'),
      RecipeLine(name: 'Kaeshi かえし', amount: 25, unit: 'cc', isBatchRef: true),
      RecipeLine(name: 'Dầu tỏi gà ニンニク油', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Soup Tonkontsu 豚骨スープ', amount: 270, unit: 'cc'),
      RecipeLine(name: 'Tỏi băm ニンニクみじん切り', amount: 0.5, unit: 'g'),
      RecipeLine(name: 'Thịt Chashu チャーシュー', amount: 3, unit: 'miếng 枚'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Nấm mèo きくらげ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương', amount: 0.5, unit: 'quả 個'),
      RecipeLine(name: 'Mè ごま', amount: 1, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Mì Tonkotsu cay 辛味豚骨ラーメン',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì 麵', amount: 80, unit: 'g'),
      RecipeLine(name: 'Kaeshi かえし', amount: 25, unit: 'cc', isBatchRef: true),
      RecipeLine(name: 'Dầu ớt チリオイル', amount: 10, unit: 'cc'),
      RecipeLine(name: 'Dầu tỏi gà ニンニク油', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Soup Tonkontsu 豚骨スープ', amount: 270, unit: 'cc'),
      RecipeLine(name: 'Tỏi băm ニンニクみじん切り', amount: 0.5, unit: 'g'),
      RecipeLine(name: 'Thịt Chashu チャーシュー', amount: 1, unit: 'miếng 枚'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Nấm mèo きくらげ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương', amount: 0.5, unit: 'quả 個'),
      RecipeLine(name: 'Mè ごま', amount: 1, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Mì Tonkotsu Chashu cay 辛味豚骨チャーシューメン',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi mảnh 博多麵', amount: 80, unit: 'g'),
      RecipeLine(name: 'Kaeshi かえし', amount: 25, unit: 'cc', isBatchRef: true),
      RecipeLine(name: 'Dầu ớt チリオイル', amount: 10, unit: 'cc'),
      RecipeLine(name: 'Dầu tỏi gà ニンニク油', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Soup Tonkontsu 豚骨スープ', amount: 270, unit: 'cc'),
      RecipeLine(name: 'Tỏi băm ニンニクみじん切り', amount: 0.5, unit: 'g'),
      RecipeLine(name: 'Thịt Chashu チャーシュー', amount: 3, unit: 'miếng 枚'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Nấm mèo きくらげ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương', amount: 0.5, unit: 'quả 個'),
      RecipeLine(name: 'Mè ごま', amount: 1, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Mì Tomyum (Chashu) トムヤムラーメン（チャーシュー）',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi trung 麵', amount: 90, unit: 'g'),
      RecipeLine(name: 'Tomyum Soup', amount: 270, unit: 'cc'),
      RecipeLine(name: 'Thịt Chashu チャーシュー', amount: 1, unit: 'miếng 枚'),
      RecipeLine(name: 'Giá もやし', amount: 40, unit: 'g'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Hành tím 赤玉ねぎ', amount: 3, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương 味玉', amount: 0.5, unit: 'quả 個'),
    ],
  ),
  MenuItem(
    name: 'Mì Tomyum (Tôm) トムヤムラーメン（えび）',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi trung 麵', amount: 90, unit: 'g'),
      RecipeLine(name: 'Tomyum Soup', amount: 270, unit: 'cc'),
      RecipeLine(name: 'Tôm えび', amount: 2, unit: 'con 匹'),
      RecipeLine(name: 'Giá もやし', amount: 40, unit: 'g'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Hành tím 赤玉ねぎ', amount: 3, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương', amount: 0.5, unit: 'quả 個'),
    ],
  ),
  MenuItem(
    name: 'Mì Curry ChiangMai カオソイ（チャーシュー）',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi trung 面', amount: 90, unit: 'g'),
      RecipeLine(name: 'Kaosoi Soup', amount: 270, unit: 'cc'),
      RecipeLine(name: 'Thịt Chashu チャーシュー', amount: 1, unit: 'miếng 枚'),
      RecipeLine(name: 'Giá もやし', amount: 40, unit: 'g'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Hành tím 赤玉ねぎ', amount: 3, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương 味玉', amount: 0.5, unit: 'quả 個'),
      RecipeLine(name: 'Mì chiên giòn あげ麵', amount: 20, unit: 'g'),
      RecipeLine(name: 'Cải chua たかな', amount: 5, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Mì cà ri gà chiên xù チキンカツカレーラーメン',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi trung 面', amount: 90, unit: 'g'),
      RecipeLine(name: 'Kaosoi Soup', amount: 270, unit: 'cc'),
      RecipeLine(name: 'Gà chiên xù チキンカツ', amount: 1, unit: 'miếng 枚'),
      RecipeLine(name: 'Giá もやし', amount: 40, unit: 'g'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương', amount: 0.5, unit: 'quả 個'),
    ],
  ),
  MenuItem(
    name: 'Mì trộn dầu 油そば',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi trung 面', amount: 90, unit: 'g'),
      RecipeLine(name: 'Kaeshi かえし', amount: 10, unit: 'cc', isBatchRef: true),
      RecipeLine(name: 'Dầu tỏi gà ニンニク油', amount: 10, unit: 'cc'),
      RecipeLine(name: 'Dầu ớt ラー油', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Giấm 酢', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Thịt Chashu チャーシュー', amount: 1, unit: 'miếng 枚'),
      RecipeLine(name: 'Giá もやし', amount: 40, unit: 'g'),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Nấm mèo きくらげ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Trứng ngâm tương', amount: 0.5, unit: 'quả 個'),
    ],
  ),
  MenuItem(
    name: 'Mì trộn mabo 汁なし麻婆麺',
    unit: 'tô',
    components: [
      RecipeLine(name: 'Mì sợi trung 面', amount: 90, unit: 'g'),
      RecipeLine(name: 'Dầu mè ごま油', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Dầu ớt ラー油', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Giấm 酢', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Sốt mabo 麻婆豆腐', amount: 1, unit: 'pc', isBatchRef: true),
      RecipeLine(name: 'Hành lá 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Giá もやし', amount: 40, unit: 'g'),
      RecipeLine(name: 'Bột hoa tiêu 花椒パウダー', amount: 1, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Set cơm gà karaage 唐揚げ定食',
    unit: 'set',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 160, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Khoai tây nghiền ポテサラ', amount: 30, unit: 'g'),
      RecipeLine(name: 'Trứng cuộn たまごやき', amount: 30, unit: 'g'),
      RecipeLine(name: 'Gà Karaage 唐揚げ', amount: 4, unit: 'pcs'),
      RecipeLine(name: 'Bắp cải キャベツ', amount: 15, unit: 'g'),
      RecipeLine(name: 'Dầu mè ごまドレッシング', amount: 5, unit: 'cc'),
      RecipeLine(name: 'Sốt Tomyum Mayo', amount: 30, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Nộm củ cải trắng và cà rốt なます',
    unit: 'đĩa',
    components: [
      RecipeLine(name: 'Củ cải trắng thái sợi 大根', amount: 500, unit: 'g'),
      RecipeLine(name: 'Cà rốt thái sợi 人参', amount: 250, unit: 'g'),
      RecipeLine(name: 'Muối 塩', amount: 6, unit: 'g'),
      RecipeLine(name: 'Giấm 酢', amount: 40, unit: 'g'),
      RecipeLine(name: 'Đường 砂糖', amount: 25, unit: 'g'),
      RecipeLine(name: 'Nước mắm ナンプラー', amount: 35, unit: 'g'),
      RecipeLine(name: 'Nước 水', amount: 30, unit: 'g'),
      RecipeLine(name: 'Hondashi ほんだし', amount: 5, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Set thịt xào rau 肉野菜炒め定食',
    unit: 'set',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 160, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Món phụ ① おかず①', amount: 40, unit: 'g'),
      RecipeLine(name: 'Món phụ ② おかず②', amount: 40, unit: 'g'),
      RecipeLine(name: 'Thịt ba chỉ 豚バラ肉', amount: 80, unit: 'g'),
      RecipeLine(name: 'Bắp cải cắt キャベツカット', amount: 50, unit: 'g'),
      RecipeLine(name: 'Hành tây cắt 玉ねぎカット', amount: 30, unit: 'g'),
      RecipeLine(name: 'Cà rốt にんじん', amount: 10, unit: 'g'),
      RecipeLine(name: 'Cải thìa 青梗菜', amount: 15, unit: 'g'),
      RecipeLine(name: 'Giá もやし', amount: 30, unit: 'g'),
      RecipeLine(name: 'Nấm mèo キクラゲ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Nước sốt yakiniku 焼肉ソース', amount: 25, unit: 'cc'),
      RecipeLine(name: 'Bắp cải và sốt mayonnaise キャベツ＆マヨネーズ', amount: 15, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Set thịt heo xào sốt yakiniku 豚焼肉定食',
    unit: 'set',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 160, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Món phụ ① おかず①', amount: 40, unit: 'g'),
      RecipeLine(name: 'Món phụ ② おかず②', amount: 40, unit: 'g'),
      RecipeLine(name: 'Thịt ba chỉ 豚バラ肉', amount: 100, unit: 'g'),
      RecipeLine(name: 'Hành tây cắt 玉ねぎカット', amount: 50, unit: 'g'),
      RecipeLine(name: 'Nước sốt yakiniku 焼肉ソース', amount: 25, unit: 'cc'),
      RecipeLine(name: 'Dầu mè ごま油', amount: 3, unit: 'g'),
      RecipeLine(name: 'Bắp cải và sốt mayonnaise キャベツ＆マヨネーズ', amount: 15, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Set thịt heo nướng kim chi 豚キムチ焼肉定食',
    unit: 'set',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 160, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Món phụ ① おかず①', amount: 40, unit: 'g'),
      RecipeLine(name: 'Món phụ ② おかず②', amount: 40, unit: 'g'),
      RecipeLine(name: 'Thịt ba chỉ 豚バラ肉', amount: 100, unit: 'g'),
      RecipeLine(name: 'Hành tây cắt 玉ねぎカット', amount: 50, unit: 'g'),
      RecipeLine(name: 'Nước sốt yakiniku 焼肉ソース', amount: 25, unit: 'cc'),
      RecipeLine(name: 'Dầu mè ごま油', amount: 3, unit: 'g'),
      RecipeLine(name: 'Kim chi キムチ', amount: 40, unit: 'g'),
      RecipeLine(name: 'Bắp cải và sốt mayonnaise キャベツ＆マヨネーズ', amount: 15, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Set ba chỉ bò nướng 牛焼肉定食',
    unit: 'set',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 160, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Món phụ ① おかず①', amount: 40, unit: 'g'),
      RecipeLine(name: 'Món phụ ② おかず②', amount: 40, unit: 'g'),
      RecipeLine(name: 'Thịt ba chỉ bò 牛バラ肉', amount: 100, unit: 'g'),
      RecipeLine(name: 'Hành tây cắt 玉ねぎカット', amount: 50, unit: 'g'),
      RecipeLine(name: 'Nước sốt yakiniku 焼肉ソース', amount: 25, unit: 'cc'),
      RecipeLine(name: 'Dầu mè ごま油', amount: 3, unit: 'g'),
      RecipeLine(name: 'Bắp cải và sốt mayonnaise キャベツ＆マヨネーズ', amount: 15, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Set ba chỉ bò nướng kim chi 牛キムチ焼肉定食',
    unit: 'set',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 160, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Món phụ ① おかず①', amount: 40, unit: 'g'),
      RecipeLine(name: 'Món phụ ② おかず②', amount: 40, unit: 'g'),
      RecipeLine(name: 'Thịt ba chỉ bò 牛バラ肉', amount: 100, unit: 'g'),
      RecipeLine(name: 'Hành tây cắt 玉ねぎカット', amount: 50, unit: 'g'),
      RecipeLine(name: 'Nước sốt yakiniku 焼肉ソース', amount: 25, unit: 'cc'),
      RecipeLine(name: 'Dầu mè ごま油', amount: 3, unit: 'g'),
      RecipeLine(name: 'Kim chi キムチ', amount: 40, unit: 'g'),
      RecipeLine(name: 'Bắp cải và sốt mayonnaise キャベツ＆マヨネーズ', amount: 15, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Set gà katsu チキンカツ定食',
    unit: 'set',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 160, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Món phụ ① おかず①', amount: 40, unit: 'g'),
      RecipeLine(name: 'Món phụ ② おかず②', amount: 40, unit: 'g'),
      RecipeLine(name: 'Gà katsu チキンカツ', amount: 1, unit: '枚'),
      RecipeLine(name: 'Sốt tonkatsu とんかつソース', amount: 30, unit: 'g'),
      RecipeLine(name: 'Mè ごま', amount: 25, unit: 'cc'),
      RecipeLine(name: 'Bắp cải và sốt mayonnaise キャベツ＆マヨネーズ', amount: 15, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Set gà katsu đôi ダブルチキンカツ定食',
    unit: 'set',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 160, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Món phụ ① おかず①', amount: 40, unit: 'g'),
      RecipeLine(name: 'Món phụ ② おかず②', amount: 40, unit: 'g'),
      RecipeLine(name: 'Gà katsu チキンカツ', amount: 2, unit: '枚'),
      RecipeLine(name: 'Sốt tonkatsu とんかつソース', amount: 40, unit: 'g'),
      RecipeLine(name: 'Mè ごま', amount: 25, unit: 'cc'),
      RecipeLine(name: 'Bắp cải và sốt mayonnaise キャベツ＆マヨネーズ', amount: 15, unit: 'g'),
    ],
  ),
  MenuItem(
    name: 'Cơm đậu phụ sốt mabo 麻婆豆腐丼',
    unit: 'bát',
    components: [
      RecipeLine(name: 'Cơm ごはん', amount: 180, unit: 'g'),
      RecipeLine(name: 'Canh miso 味噌汁', amount: 120, unit: 'cc'),
      RecipeLine(name: 'Sốt mabo 麻婆ソース', amount: 165, unit: 'g'),
      RecipeLine(name: 'Đậu phụ 豆腐', amount: 12, unit: 'pieces'),
      RecipeLine(name: 'Hành lá cắt nhỏ 青ネギ', amount: 5, unit: 'g'),
      RecipeLine(name: 'Dầu ớt ラー油', amount: 1, unit: '杯'),
      RecipeLine(name: 'Bột hoa tiêu 花椒パウダー', amount: 1, unit: 'g'),
    ],
  ),
];

  // (Bạn có thể chép thêm các menu khác như trước nếu cần)

/* ----------------------------
 Utils
---------------------------- */

String _normalizeUnit(String u) {
  final low = u.trim().toLowerCase();
  if (low == 'cc') return 'ml';
  return u.trim();
}

Map<String, AggregatedIngredient> expandRecipe({
  required MenuItem menu,
  required double menuQty,
  required List<BatchRecipe> batches,
}) {
  final Map<String, AggregatedIngredient> agg = {};

  void addAgg(String name, double amount, String unit) {
    final normUnit = _normalizeUnit(unit);
    final keyName = name.trim();
    if (agg.containsKey(keyName)) {
      final e = agg[keyName]!;
      if (e.unit == normUnit) {
        e.amount += amount;
      } else {
        final altKey = '$keyName ($normUnit)';
        if (agg.containsKey(altKey)) {
          agg[altKey]!.amount += amount;
        } else {
          agg[altKey] = AggregatedIngredient(amount: amount, unit: normUnit);
        }
      }
    } else {
      agg[keyName] = AggregatedIngredient(amount: amount, unit: normUnit);
    }
  }

  void expandLine(RecipeLine line, double multiplier) {
    if (!line.isBatchRef) {
      addAgg(line.name, line.amount * multiplier, line.unit);
    } else {
      final br = batches.firstWhere(
        (b) => b.name.toLowerCase() == line.name.toLowerCase(),
        orElse: () => throw Exception('Batch "${line.name}" not found'),
      );
      final double ratio = (line.amount * multiplier) / br.yieldAmount;
      for (final c in br.components) {
        addAgg(c.name, c.amount * ratio, c.unit);
      }
    }
  }

  for (final line in menu.components) {
    expandLine(line, menuQty);
  }

  return agg;
}

/* ----------------------------
 Aggregation helpers
---------------------------- */

Map<String, Map<String, AggregatedIngredient>> _aggregateByDay(List<WasteRecord> records) {
  final Map<String, Map<String, AggregatedIngredient>> out = {};
  for (final r in records) {
    final day = DateFormat('yyyy-MM-dd').format(r.date);
    out.putIfAbsent(day, () => {});
    final map = out[day]!;
    for (final e in r.aggregated.entries) {
      final key = '${e.key}||${e.value.unit}'; // unique by unit
      if (map.containsKey(key)) {
        map[key]!.amount += e.value.amount;
      } else {
        map[key] = AggregatedIngredient(amount: e.value.amount, unit: e.value.unit);
      }
    }
  }
  return out;
}

Map<String, Map<String, AggregatedIngredient>> _aggregateByMonth(List<WasteRecord> records) {
  final Map<String, Map<String, AggregatedIngredient>> out = {};
  for (final r in records) {
    final m = DateFormat('yyyy-MM').format(r.date);
    out.putIfAbsent(m, () => {});
    final map = out[m]!;
    for (final e in r.aggregated.entries) {
      final key = '${e.key}||${e.value.unit}';
      if (map.containsKey(key)) {
        map[key]!.amount += e.value.amount;
      } else {
        map[key] = AggregatedIngredient(amount: e.value.amount, unit: e.value.unit);
      }
    }
  }
  return out;
}

/* ----------------------------
 UI
---------------------------- */

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Directory> _resolveOutputDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return getApplicationDocumentsDirectory();
  }

  try {
    final dl = await getDownloadsDirectory();
    return dl ?? await getApplicationDocumentsDirectory();
  } catch (_) {
    return await getApplicationDocumentsDirectory();
  }
}

Future<void> _downloadWebFile(String filename, List<int> bytes) async {
  final blob = html.Blob([Uint8List.fromList(bytes)]);

  final url = html.Url.createObjectUrlFromBlob(blob);

  try {
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    await Future<void>.delayed(const Duration(milliseconds: 100));
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
  final List<MenuItem> menus = [...demoMenus];
  final List<BatchRecipe> batches = [...demoBatches];
  final List<WasteRecord> records = [];
  final List<IngredientItem> ingredients = [];

  String _search = '';
  final DateFormat _df = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _initIngredientsFromRecipes();
  }

  void _initIngredientsFromRecipes() {
    final Map<String, String> map = {};
    for (final m in menus) {
      for (final c in m.components) {
        final key = c.name.trim();
        if (!map.containsKey(key)) map[key] = _normalizeUnit(c.unit);
      }
    }
    for (final b in batches) {
      for (final c in b.components) {
        final key = c.name.trim();
        if (!map.containsKey(key)) map[key] = _normalizeUnit(c.unit);
      }
    }
    ingredients.clear();
    map.forEach((k, v) => ingredients.add(IngredientItem(name: k, unit: v)));
    ingredients.sort((a, b) => a.name.compareTo(b.name));
  }

  List<MenuItem> get filteredMenus {
    final k = _search.trim().toLowerCase();
    if (k.isEmpty) return menus;
    return menus.where((m) => m.name.toLowerCase().contains(k)).toList();
  }

  static String _formatDouble(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    if ((v * 10).roundToDouble() == (v * 10)) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  String _ingredientsSummary(Map<String, AggregatedIngredient> agg) {
    final parts = agg.entries.map((e) {
      final name = e.key.replaceAll(',', ' ');
      return '$name ${_formatDouble(e.value.amount)} ${e.value.unit}';
    }).toList();
    return parts.join(' ; ');
  }

  /* ----------------------------
   Export CSV (compact detailed + daily + monthly)
  ---------------------------- */
  Future<void> _exportCsv() async {
  if (records.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không có bản ghi để xuất')),
    );
    return;
  }

  try {
    final now = DateTime.now();
    final baseName = 'waste_log_${DateFormat('yyyyMMdd_HHmmss').format(now)}';

    final sbDetail = StringBuffer();
    sbDetail.writeln('Ngày,Món,Số lượng,Đơn vị,Nguyên liệu (tóm tắt),Lý do');
    for (final r in records) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(r.date);
      final ingSummary = _ingredientsSummary(r.aggregated).replaceAll('"', '\'');
      final reason = r.reason?.replaceAll(',', ' ') ?? '';
      sbDetail.writeln(
        '$dateStr,${r.menuName},${_formatDouble(r.menuQty)},${r.menuUnit},"$ingSummary",$reason',
      );
    }

    final daily = _aggregateByDay(records);
    final sbDaily = StringBuffer();
    sbDaily.writeln('Ngày,Nguyên liệu,Khối lượng,Đơn vị');
    final sortedDays = daily.keys.toList()..sort();
    for (final day in sortedDays) {
      final map = daily[day]!;
      final sortedKeys = map.keys.toList()..sort();
      for (final k in sortedKeys) {
        final parts = k.split('||');
        final name = parts[0];
        final unit = parts.length > 1 ? parts[1] : map[k]!.unit;
        sbDaily.writeln('$day,$name,${_formatDouble(map[k]!.amount)},$unit');
      }
    }

    final monthly = _aggregateByMonth(records);
    final sbMonthly = StringBuffer();
    sbMonthly.writeln('Tháng,Nguyên liệu,Khối lượng,Đơn vị');
    final sortedMonths = monthly.keys.toList()..sort();
    for (final m in sortedMonths) {
      final map = monthly[m]!;
      final sortedKeys = map.keys.toList()..sort();
      for (final k in sortedKeys) {
        final parts = k.split('||');
        final name = parts[0];
        final unit = parts.length > 1 ? parts[1] : map[k]!.unit;
        sbMonthly.writeln('$m,$name,${_formatDouble(map[k]!.amount)},$unit');
      }
    }

    if (kIsWeb) {
      await _downloadWebFile('$baseName.csv', utf8.encode(sbDetail.toString()));
      await _downloadWebFile('${baseName}_daily_summary.csv', utf8.encode(sbDaily.toString()));
      await _downloadWebFile('${baseName}_monthly_summary.csv', utf8.encode(sbMonthly.toString()));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tải 3 file CSV')),
      );
      return;
    }

    final targetDir = await _resolveOutputDirectory();

    final fileDetail = File('${targetDir.path}/$baseName.csv');
    await fileDetail.writeAsBytes(utf8.encode(sbDetail.toString()), flush: true);

    final fileDaily = File('${targetDir.path}/${baseName}_daily_summary.csv');
    await fileDaily.writeAsBytes(utf8.encode(sbDaily.toString()), flush: true);

    final fileMonthly = File('${targetDir.path}/${baseName}_monthly_summary.csv');
    await fileMonthly.writeAsBytes(utf8.encode(sbMonthly.toString()), flush: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu:\n${fileDetail.path}\n${fileDaily.path}\n${fileMonthly.path}',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi khi xuất CSV: $e')),
    );
  }
}

  /* ----------------------------
   Export XLSX (compact detailed + daily + monthly sheets)
  ---------------------------- */
  Future<void> _exportXlsx() async {
  if (records.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không có bản ghi để xuất')),
    );
    return;
  }

  try {
    final now = DateTime.now();
    final filename = 'waste_log_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';

    final excel = Excel.createExcel();

    final sheetDetail = excel['Waste'];
    sheetDetail.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Món'),
      TextCellValue('Số lượng'),
      TextCellValue('Đơn vị'),
      TextCellValue('Nguyên liệu (tóm tắt)'),
      TextCellValue('Lý do'),
    ]);

    for (final r in records) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(r.date);
      final ingSummary = _ingredientsSummary(r.aggregated);
      final reason = r.reason?.replaceAll(',', ' ') ?? '';

      sheetDetail.appendRow([
        TextCellValue(dateStr),
        TextCellValue(r.menuName),
        DoubleCellValue(r.menuQty),
        TextCellValue(r.menuUnit),
        TextCellValue(ingSummary),
        TextCellValue(reason),
      ]);
    }

    final daily = _aggregateByDay(records);
    final sheetDaily = excel['Daily Summary'];
    sheetDaily.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Nguyên liệu'),
      TextCellValue('Khối lượng'),
      TextCellValue('Đơn vị'),
    ]);

    final sortedDays = daily.keys.toList()..sort();
    for (final day in sortedDays) {
      final map = daily[day]!;
      final sortedKeys = map.keys.toList()..sort();
      for (final k in sortedKeys) {
        final parts = k.split('||');
        final name = parts[0];
        final unit = parts.length > 1 ? parts[1] : map[k]!.unit;
        sheetDaily.appendRow([
          TextCellValue(day),
          TextCellValue(name),
          DoubleCellValue(map[k]!.amount),
          TextCellValue(unit),
        ]);
      }
    }

    final monthly = _aggregateByMonth(records);
    final sheetMonthly = excel['Monthly Summary'];
    sheetMonthly.appendRow([
      TextCellValue('Tháng'),
      TextCellValue('Nguyên liệu'),
      TextCellValue('Khối lượng'),
      TextCellValue('Đơn vị'),
    ]);

    final sortedMonths = monthly.keys.toList()..sort();
    for (final m in sortedMonths) {
      final map = monthly[m]!;
      final sortedKeys = map.keys.toList()..sort();
      for (final k in sortedKeys) {
        final parts = k.split('||');
        final name = parts[0];
        final unit = parts.length > 1 ? parts[1] : map[k]!.unit;
        sheetMonthly.appendRow([
          TextCellValue(m),
          TextCellValue(name),
          DoubleCellValue(map[k]!.amount),
          TextCellValue(unit),
        ]);
      }
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('Không tạo được file excel.');
    }

    if (kIsWeb) {
      await _downloadWebFile(filename, fileBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải file: $filename')),
      );
      return;
    }

    final targetDir = await _resolveOutputDirectory();
    final file = File('${targetDir.path}/$filename');
    await file.writeAsBytes(fileBytes, flush: true);

    try {
      await OpenFile.open(file.path);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu: ${file.path}')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi khi xuất Excel: $e')),
    );
  }
}

  /* ----------------------------
   Ingredients manager + quick search cancel
  ---------------------------- */

  void _showIngredientsManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final nameC = TextEditingController();
        final unitC = TextEditingController(text: 'g');
        return StatefulBuilder(builder: (context, setStateSheet) {
          void addIngredient() {
            final nm = nameC.text.trim();
            final un = unitC.text.trim();
            if (nm.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên nguyên liệu trống')));
              return;
            }
            final exists = ingredients.any((it) => it.name.toLowerCase() == nm.toLowerCase());
            if (exists) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nguyên liệu đã tồn tại')));
              return;
            }
            setState(() {
              ingredients.add(IngredientItem(name: nm, unit: un.isEmpty ? 'g' : un));
              ingredients.sort((a, b) => a.name.compareTo(b.name));
            });
            nameC.clear();
            unitC.text = 'g';
            setStateSheet(() {});
          }

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(child: Text('Kho nguyên liệu (${ingredients.length})', style: Theme.of(context).textTheme.titleLarge)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Tên nguyên liệu'))),
                        const SizedBox(width: 8),
                        SizedBox(width: 100, child: TextField(controller: unitC, decoration: const InputDecoration(labelText: 'Đơn vị'))),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: addIngredient, child: const Text('Thêm')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ingredients.isEmpty
                        ? const Center(child: Text('Chưa có nguyên liệu'))
                        : ListView.builder(
                            itemCount: ingredients.length,
                            itemBuilder: (context, i) {
                              final it = ingredients[i];
                              return ListTile(
                                title: Text(it.name),
                                subtitle: Text('Đơn vị: ${it.unit}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      tooltip: 'Hủy nhanh nguyên liệu',
                                      onPressed: () => _quickCancelIngredient(it),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        final ctrl = TextEditingController(text: it.unit);
                                        showDialog<void>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Sửa đơn vị: ${it.name}'),
                                            content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Đơn vị')),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    it.unit = ctrl.text.trim().isEmpty ? it.unit : ctrl.text.trim();
                                                  });
                                                  setStateSheet(() {});
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Lưu'),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever),
                                      onPressed: () {
                                        setState(() {
                                          ingredients.removeAt(i);
                                        });
                                        setStateSheet(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Quick cancel by tapping ingredient (keeps existing dialog)
  void _quickCancelIngredient(IngredientItem item) async {
    final amtC = TextEditingController(text: '0');
    DateTime selectedDate = DateTime.now();
    String? reason;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hủy nguyên liệu: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amtC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Số lượng (${item.unit})')),
            const SizedBox(height: 8),
            TextField(onChanged: (v) => reason = v, decoration: const InputDecoration(labelText: 'Lý do (tuỳ chọn)')),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Ngày: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                const Spacer(),
                TextButton(
                  child: const Text('Chọn ngày'),
                  onPressed: () async {
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (dt != null) selectedDate = dt;
                  },
                )
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final am = double.tryParse(amtC.text.trim()) ?? 0;
              if (am <= 0) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập số lượng hợp lệ')));
                return;
              }
              final agg = <String, AggregatedIngredient>{};
              agg[item.name] = AggregatedIngredient(amount: am, unit: item.unit);
              final rec = WasteRecord(date: selectedDate, menuName: 'Nguyên liệu: ${item.name}', menuQty: 0, menuUnit: item.unit, aggregated: agg, reason: reason);
              setState(() => records.insert(0, rec));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu hủy nguyên liệu')));
              Navigator.pop(context);
            },
            child: const Text('Xác nhận'),
          )
        ],
      ),
    );
  }

  // New: quick search dialog that lets you type name, pick ingredient, enter grams and confirm
  void _showQuickCancelSearchDialog() async {
    final searchC = TextEditingController();
    final amountC = TextEditingController(text: '0');
    final unitC = TextEditingController();
    IngredientItem? selected;
    DateTime selectedDate = DateTime.now();
    String? reason;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          final query = searchC.text.trim().toLowerCase();
          final matches = query.isEmpty ? ingredients : ingredients.where((it) => it.name.toLowerCase().contains(query)).toList();

          return AlertDialog(
            title: const Text('Hủy nguyên liệu nhanh (search)'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchC,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm tên nguyên liệu...'),
                    onChanged: (_) => setStateDialog(() {}),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: matches.isEmpty
                        ? const Center(child: Text('Không có kết quả'))
                        : ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, i) {
                              final it = matches[i];
                              final isSelected = selected != null && selected!.name == it.name;
                              return ListTile(
                                title: Text(it.name),
                                subtitle: Text('Đơn vị: ${it.unit}'),
                                selected: isSelected,
                                onTap: () {
                                  setStateDialog(() {
                                    selected = it;
                                    unitC.text = it.unit;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(controller: amountC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Số lượng')),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 100, child: TextField(controller: unitC, decoration: const InputDecoration(labelText: 'Đơn vị'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(onChanged: (v) => reason = v, decoration: const InputDecoration(labelText: 'Lý do (tùy chọn)')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Ngày: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                      const Spacer(),
                      TextButton(
                        child: const Text('Chọn ngày'),
                        onPressed: () async {
                          final dt = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (dt != null) setStateDialog(() => selectedDate = dt);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  final am = double.tryParse(amountC.text.trim()) ?? 0;
                  final unitText = unitC.text.trim();
                  if (selected == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa chọn nguyên liệu')));
                    return;
                  }
                  if (am <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập số lượng hợp lệ')));
                    return;
                  }
                  final agg = <String, AggregatedIngredient>{};
                  agg[selected!.name] = AggregatedIngredient(amount: am, unit: unitText.isEmpty ? selected!.unit : unitText);
                  final rec = WasteRecord(date: selectedDate, menuName: 'Nguyên liệu: ${selected!.name}', menuQty: 0, menuUnit: unitText, aggregated: agg, reason: reason);
                  setState(() => records.insert(0, rec));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu hủy nguyên liệu')));
                  Navigator.pop(context);
                },
                child: const Text('Xác nhận'),
              ),
            ],
          );
        });
      },
    );
  }

  /* ----------------------------
   Other dialogs (add menu, add batch, cancel menu, manual ingredient cancel)
   implemented here (kept reasonable and balanced)
  ---------------------------- */

  void _showAddMenuDialog() {
    final nameC = TextEditingController();
    final unitC = TextEditingController(text: 'đơn vị');
    final compsC = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm món mới (đơn giản)'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Tên món')),
              TextField(controller: unitC, decoration: const InputDecoration(labelText: 'Đơn vị món (vd: tô, ly)')),
              const SizedBox(height: 8),
              const Text('Thành phần (mỗi dòng: Tên | lượng | đơn vị | batchRef? (true/false))'),
              TextField(
                controller: compsC,
                decoration: const InputDecoration(hintText: 'Ví dụ:\nKaeshi かえし | 25 | cc | true\nMì 面 | 80 | g | false'),
                keyboardType: TextInputType.multiline,
                minLines: 4,
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final name = nameC.text.trim();
              final unit = unitC.text.trim();
              final lines = compsC.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty);
              final comps = <RecipeLine>[];
              for (final l in lines) {
                final parts = l.split('|').map((p) => p.trim()).toList();
                if (parts.length < 3) continue;
                final nm = parts[0];
                final am = double.tryParse(parts[1]) ?? 0;
                final un = parts[2];
                final isRef = parts.length >= 4 ? (parts[3].toLowerCase() == 'true') : false;
                comps.add(RecipeLine(name: nm, amount: am, unit: un, isBatchRef: isRef));
              }
              if (name.isNotEmpty && comps.isNotEmpty) {
                setState(() {
                  menus.add(MenuItem(name: name, unit: unit.isEmpty ? 'đv' : unit, components: comps));
                  _initIngredientsFromRecipes();
                });
                Navigator.pop(context);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập tên và ít nhất 1 thành phần')));
              }
            },
            child: const Text('Thêm'),
          )
        ],
      ),
    );
  }

  void _showAddBatchDialog() {
    final nameC = TextEditingController();
    final yieldC = TextEditingController();
    final yieldUnitC = TextEditingController(text: 'ml');
    final compsC = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm batch / bán thành phẩm'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Tên batch (vd: Kaeshi かえし)')),
              TextField(controller: yieldC, decoration: const InputDecoration(labelText: 'Yield (vd: 7125)')),
              TextField(controller: yieldUnitC, decoration: const InputDecoration(labelText: 'Unit của yield (vd: ml)')),
              const SizedBox(height: 8),
              const Text('Thành phần của batch (mỗi dòng: Tên | lượng | đơn vị)'),
              TextField(
                controller: compsC,
                keyboardType: TextInputType.multiline,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(hintText: 'Ví dụ:\nNước mắm | 6000 | ml\nMuối | 200 | g'),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final name = nameC.text.trim();
              final yieldAmount = double.tryParse(yieldC.text.trim()) ?? 0;
              final yUnit = yieldUnitC.text.trim();
              final comps = compsC.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty);
              final lines = <RecipeLine>[];
              for (final l in comps) {
                final parts = l.split('|').map((p) => p.trim()).toList();
                if (parts.length < 3) continue;
                final nm = parts[0];
                final am = double.tryParse(parts[1]) ?? 0;
                final un = parts[2];
                lines.add(RecipeLine(name: nm, amount: am, unit: un));
              }
              if (name.isNotEmpty && yieldAmount > 0 && lines.isNotEmpty) {
                setState(() {
                  batches.add(BatchRecipe(name: name, yieldAmount: yieldAmount, yieldUnit: yUnit.isEmpty ? 'ml' : yUnit, components: lines));
                  _initIngredientsFromRecipes();
                });
                Navigator.pop(context);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập đầy đủ thông tin batch')));
              }
            },
            child: const Text('Thêm batch'),
          )
        ],
      ),
    );
  }

  void _showRecords() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final topInset = MediaQuery.of(context).padding.top;
        final height = MediaQuery.of(context).size.height * 0.85;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: topInset, left: 8, right: 8),
                  color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bản ghi hủy (${records.length})',
                            style: Theme.of(context).primaryTextTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Export CSV',
                          icon: const Icon(Icons.file_download),
                          onPressed: _exportCsv,
                        ),
                        IconButton(
                          tooltip: 'Export Excel',
                          icon: const Icon(Icons.grid_on),
                          onPressed: _exportXlsx,
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: records.isEmpty
                      ? const Center(child: Text('Không có bản ghi'))
                      : ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, i) {
                            final r = records[i];
                            return ListTile(
                              title: Text('${r.menuName} — ${_formatDouble(r.menuQty)} ${r.menuUnit}'),
                              subtitle: Text('${_df.format(r.date)}${r.reason != null && r.reason!.isNotEmpty ? ' • ${r.reason}' : ''}'),
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Chi tiết: ${r.menuName}'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Nguyên liệu đã hủy:'),
                                          const SizedBox(height: 6),
                                          ...r.aggregated.entries.map((e) => Text('${e.key}: ${_formatDouble(e.value.amount)} ${e.value.unit}')),
                                        ],
                                      ),
                                    ),
                                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
                                  ),
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_forever),
                                onPressed: () {
                                  setState(() => records.removeAt(i));
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIngredientCancelDialog() async {
    final List<TextEditingController> nameCtrls = [TextEditingController()];
    final List<TextEditingController> amountCtrls = [TextEditingController(text: '0')];
    final List<TextEditingController> unitCtrls = [TextEditingController(text: 'g')];
    DateTime selectedDate = DateTime.now();
    String? reason;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {
        void addRow() {
          setStateDialog(() {
            nameCtrls.add(TextEditingController());
            amountCtrls.add(TextEditingController(text: '0'));
            unitCtrls.add(TextEditingController(text: 'g'));
          });
        }

        void removeRow(int idx) {
          setStateDialog(() {
            nameCtrls.removeAt(idx);
            amountCtrls.removeAt(idx);
            unitCtrls.removeAt(idx);
          });
        }

        return AlertDialog(
          title: const Text('Hủy nguyên liệu (thủ công)'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Nhập từng nguyên liệu muốn hủy'),
                const SizedBox(height: 8),
                ...List.generate(nameCtrls.length, (i) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextField(controller: nameCtrls[i], decoration: const InputDecoration(labelText: 'Tên nguyên liệu')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(controller: amountCtrls[i], keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Lượng')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(controller: unitCtrls[i], decoration: const InputDecoration(labelText: 'Đơn vị')),
                      ),
                      IconButton(icon: const Icon(Icons.delete), onPressed: nameCtrls.length > 1 ? () => removeRow(i) : null),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(onPressed: addRow, icon: const Icon(Icons.add), label: const Text('Thêm dòng')),
                    const SizedBox(width: 12),
                    Text('Ngày: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                    const Spacer(),
                    TextButton(
                      child: const Text('Chọn ngày'),
                      onPressed: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (dt != null) setStateDialog(() => selectedDate = dt);
                      },
                    )
                  ],
                ),
                const SizedBox(height: 8),
                TextField(onChanged: (v) => reason = v, decoration: const InputDecoration(labelText: 'Lý do (tùy chọn)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final Map<String, AggregatedIngredient> agg = {};
                for (int i = 0; i < nameCtrls.length; i++) {
                  final nm = nameCtrls[i].text.trim();
                  final am = double.tryParse(amountCtrls[i].text.trim()) ?? 0;
                  final un = unitCtrls[i].text.trim();
                  if (nm.isEmpty || am <= 0) continue;
                  final key = nm;
                  final normUnit = _normalizeUnit(un);
                  if (agg.containsKey(key)) {
                    if (agg[key]!.unit == normUnit) {
                      agg[key]!.amount += am;
                    } else {
                      final altKey = '$key ($normUnit)';
                      if (agg.containsKey(altKey)) {
                        agg[altKey]!.amount += am;
                      } else {
                        agg[altKey] = AggregatedIngredient(amount: am, unit: normUnit);
                      }
                    }
                  } else {
                    agg[key] = AggregatedIngredient(amount: am, unit: normUnit);
                  }
                }
                if (agg.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa nhập nguyên liệu hợp lệ')));
                  return;
                }
                final rec = WasteRecord(
                  date: selectedDate,
                  menuName: 'Nguyên liệu (thủ công)',
                  menuQty: 0,
                  menuUnit: '',
                  aggregated: agg,
                  reason: reason,
                );
                setState(() => records.insert(0, rec));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu hủy nguyên liệu')));
                Navigator.pop(context);
              },
              child: const Text('Xác nhận'),
            )
          ],
        );
      }),
    );
  }

  /* ----------------------------
   Menu cancel dialog (simplified: keep original behavior)
  ---------------------------- */
  void _showCancelDialog(MenuItem menu) async {
    final qtyController = TextEditingController(text: '1');
    DateTime selectedDate = DateTime.now();
    String? reason;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Hủy: ${menu.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      try {
                        setStateDialog(() {});
                      } catch (_) {}
                    },
                    decoration: InputDecoration(labelText: 'Số lượng hủy (${menu.unit})'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => reason = v,
                    decoration: const InputDecoration(labelText: 'Lý do (tuỳ chọn)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Ngày: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                      const Spacer(),
                      TextButton(
                        child: const Text('Chọn ngày'),
                        onPressed: () async {
                          final dt = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (dt != null) {
                            setStateDialog(() => selectedDate = dt);
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final qty = double.tryParse(qtyController.text) ?? 0;
                    if (qty <= 0) return const SizedBox.shrink();
                    Map<String, AggregatedIngredient> map;
                    try {
                      map = expandRecipe(menu: menu, menuQty: qty, batches: batches);
                    } catch (e) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.yellow.shade100,
                        child: Text('Lỗi khi mở rộng công thức: $e'),
                      );
                    }
                    if (map.isEmpty) return const SizedBox.shrink();
                    final rows = map.entries.map((e) => '${e.key}: ${_formatDouble(e.value.amount)} ${e.value.unit}').join('\n');
                    return Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey.shade100,
                      child: Text('Dự kiến hao:\n$rows'),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(onPressed: () {
                  Navigator.pop(context);
                }, child: const Text('Huỷ')),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text) ?? 0;
                    if (qty <= 0) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập số lượng hợp lệ')));
                      return;
                    }
                    final agg = expandRecipe(menu: menu, menuQty: qty, batches: batches);
                    final rec = WasteRecord(
                      date: selectedDate,
                      menuName: menu.name,
                      menuQty: qty,
                      menuUnit: menu.unit,
                      aggregated: agg,
                      reason: reason,
                    );
                    setState(() => records.insert(0, rec));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu hủy món')));
                    Navigator.pop(context);
                  },
                  child: const Text('Xác nhận hủy'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Hủy Hàng — Demo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Row 1: search full width
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Tìm món',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2: buttons (horizontally scrollable so won't hide search)
                  SizedBox(
                    height: 44,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showAddMenuDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm món'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showAddBatchDialog,
                            icon: const Icon(Icons.storage),
                            label: const Text('Thêm batch'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showRecords,
                            icon: const Icon(Icons.list),
                            label: const Text('Bản ghi'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showIngredientCancelDialog,
                            icon: const Icon(Icons.local_grocery_store),
                            label: const Text('Hủy nguyên liệu'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showIngredientsManager,
                            icon: const Icon(Icons.inventory_2),
                            label: const Text('Kho nguyên liệu'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showQuickCancelSearchDialog,
                            icon: const Icon(Icons.search_off),
                            label: const Text('Hủy nhanh (search)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredMenus.length,
        itemBuilder: (context, i) {
          final m = filteredMenus[i];
          return ListTile(
            title: Text(m.name),
            subtitle: Text('Đơn vị: ${m.unit}'),
            trailing: ElevatedButton(onPressed: () => _showCancelDialog(m), child: const Text('Hủy')),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Công thức: ${m.name}'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...m.components.map((c) => Text('${c.name} — ${_formatDouble(c.amount)} ${c.unit}${c.isBatchRef ? ' (batch)' : ''}')),
                        const SizedBox(height: 10),
                        const Text('Batches available:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...batches.map((b) => Text('${b.name} — yield ${_formatDouble(b.yieldAmount)} ${b.yieldUnit}')),
                      ],
                    ),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
                ),
              );
            },
          );
        },
      ),
    );
  }
}