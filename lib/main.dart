import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BabyGender {
  boy('남아', '👦', Color(0xFF4DABF7), Color(0xFFE7F5FF), Color(0xFFF8FAFC), Color(0xFF1864AB)),
  girl('여아', '👧', Color(0xFFFAA2C1), Color(0xFFFFF0F6), Color(0xFFFFF5F7), Color(0xFFA61E4D)),
  none('기본', '🌱', Color(0xFF20C997), Color(0xFFE6FCF5), Color(0xFFF4FDF9), Color(0xFF087F5B));

  final String label;
  final String emoji;
  final Color primary;
  final Color lightAccent;
  final Color background;
  final Color textColor;

  const BabyGender(this.label, this.emoji, this.primary, this.lightAccent, this.background, this.textColor);

  static BabyGender fromCode(String? code) {
    if (code == 'boy') return BabyGender.boy;
    if (code == 'girl') return BabyGender.girl;
    return BabyGender.none;
  }

  String get code {
    if (this == BabyGender.boy) return 'boy';
    if (this == BabyGender.girl) return 'girl';
    return 'none';
  }
}

class AppThemeController extends ChangeNotifier {
  static final AppThemeController instance = AppThemeController._();
  AppThemeController._();

  BabyGender _gender = BabyGender.none;
  BabyGender get gender => _gender;

  Color get primaryColor => _gender.primary;
  Color get lightAccentColor => _gender.lightAccent;
  Color get backgroundColor => _gender.background;
  Color get appbarTextColor => _gender.textColor;

  void setGender(BabyGender g) {
    if (_gender != g) {
      _gender = g;
      notifyListeners();
    }
  }
}

Color get appPrimaryColor => AppThemeController.instance.primaryColor;
Color get appLightAccentColor => AppThemeController.instance.lightAccentColor;
Color get appBgColor => AppThemeController.instance.backgroundColor;
Color get appTextColor => AppThemeController.instance.appbarTextColor;

void main() => runApp(const BabyFoodApp());

class BabyFoodApp extends StatelessWidget {
  const BabyFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        final ctrl = AppThemeController.instance;
        return MaterialApp(
          title: '또핑',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: ctrl.primaryColor,
              primary: ctrl.primaryColor,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: ctrl.appbarTextColor,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

enum MealType {
  first('1끼', 1, Color(0xFFFF7A59), Color(0xFFFFEFEB)),
  second('2끼', 2, Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  third('3끼', 3, Color(0xFF5E35B1), Color(0xFFEDE7F6)),
  snack('간식', 4, Color(0xFFF57F17), Color(0xFFFFFDE7));

  final String label;
  final int order;
  final Color primaryColor;
  final Color bgColor;
  const MealType(this.label, this.order, this.primaryColor, this.bgColor);

  static MealType fromLabel(String l) {
    if (l == '1차 식사' || l == '1끼') return MealType.first;
    if (l == '2차 식사' || l == '2끼') return MealType.second;
    if (l == '3차 식사' || l == '3끼') return MealType.third;
    if (l == '간식') return MealType.snack;
    return MealType.values.firstWhere((m) => m.label == l, orElse: () => MealType.first);
  }
}

enum FoodCategory {
  grain('곡류', 1, Color(0xFFFFF3CD), Color(0xFF856404)),
  meat('단백질', 2, Color(0xFFF8D7DA), Color(0xFF721C24)),
  vegetable('채소', 3, Color(0xFFD4EDDA), Color(0xFF155724)),
  fruit('과일', 4, Color(0xFFD1ECF1), Color(0xFF0C5460)),
  etc('기타', 5, Color(0xFFE2E3E5), Color(0xFF383D41));

  final String label;
  final int sortOrder;
  final Color bgColor;
  final Color textColor;
  const FoodCategory(this.label, this.sortOrder, this.bgColor, this.textColor);

  static FoodCategory fromLabel(String l) =>
      FoodCategory.values.firstWhere((c) => c.label == l, orElse: () => FoodCategory.etc);
}

String getFoodEmoji(String name) {
  final n = name.trim().toLowerCase();
  if (n.contains('쌀죽') || n.contains('쌀')) return '🍚';
  if (n.contains('오트밀')) return '🥣';
  if (n.contains('현미')) return '🌾';
  if (n.contains('소고기') || n.contains('우둔살') || n.contains('홍두깨') || n.contains('설도') || (n.contains('안심') && !n.contains('닭'))) return '🥩';
  if (n.contains('닭')) return '🍗';
  if (n.contains('단호박') || n.contains('호박')) return '🎃';
  if (n.contains('브로콜리')) return '🥦';
  if (n.contains('당근')) return '🥕';
  if (n.contains('애호박') || n.contains('오이')) return '🥒';
  if (n.contains('감자')) return '🥔';
  if (n.contains('고구마')) return '🍠';
  if (n.contains('사과')) return '🍎';
  if (n.contains('바나나')) return '🍌';
  if (n.contains('배')) return '🍐';
  if (n.contains('계란') || n.contains('노른자')) return '🥚';
  if (n.contains('두부') || n.contains('완두콩')) return '🫘';
  if (n.contains('청경채') || n.contains('양배추') || n.contains('배추') || n.contains('시금치')) return '🥬';
  return '🥄';
}

FoodCategory guessCategoryByName(String name) {
  final n = name.trim();
  if (n.contains('쌀') || n.contains('오트밀') || n.contains('현미') || n.contains('보리')) return FoodCategory.grain;
  if (n.contains('소고기') || n.contains('안심') || n.contains('닭') || n.contains('계란') || n.contains('노른자') || n.contains('두부')) return FoodCategory.meat;
  if (n.contains('사과') || n.contains('배') || n.contains('바나나') || n.contains('블루베리')) return FoodCategory.fruit;
  return FoodCategory.vegetable;
}

const List<String> kGrainPorridgeOptions = [
  '20배죽',
  '16배죽',
  '10배죽(권장)',
  '8배죽',
  '5배죽',
  '진밥',
  '오트밀포리지',
  '기타',
];

const List<String> kMeatCutOptions = [
  '소고기 안심(추천)',
  '우둔살',
  '홍두깨살',
  '설도',
  '닭안심',
  '닭가슴살',
  '기타',
];

/// 식재료명에서 배죽, 부위, 괄호 표기 등을 제거하고 근본 식재료(쌀, 소고기, 오트밀 등)를 추출
String getCanonicalBaseIngredient(String rawName) {
  // 1. 괄호 내용 제거: '쌀죽(10배죽)' -> '쌀죽', '소고기(안심)' -> '소고기'
  String s = rawName.replaceAll(RegExp(r'\(.*?\)'), '').trim();
  // 2. 이모지 제거
  s = s.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim();
  // 3. g(그램), 개수 표기 제거: '10g (1개)'
  s = s.replaceAll(RegExp(r'\s*\d+g.*$'), '').trim();

  // 4. 이유식 대표 식재료 표준 그룹핑
  if (s.contains('쌀') || s.contains('배죽') || s == '진밥' || s.contains('미음')) return '쌀';
  if (s.contains('소고기') || s.contains('쇠고기') || s.contains('우둔') || s.contains('홍두깨') || s.contains('설도') || (s.contains('안심') && !s.contains('닭'))) return '소고기';
  if (s.contains('오트밀') || s.contains('오트')) return '오트밀';
  if (s.contains('닭') || s.contains('치킨')) return '닭고기';
  if (s.contains('단호박') || (s.contains('호박') && !s.contains('애호박'))) return '단호박';
  if (s.contains('애호박')) return '애호박';
  if (s.contains('청경채')) return '청경채';
  if (s.contains('양배추')) return '양배추';
  if (s.contains('브로콜리')) return '브로콜리';
  if (s.contains('사과')) return '사과';
  if (s.contains('바나나')) return '바나나';
  if (s.contains('배') && !s.contains('배죽')) return '배';
  if (s.contains('당근')) return '당근';
  if (s.contains('비트')) return '비트';
  if (s.contains('오이')) return '오이';
  if (s.contains('감자')) return '감자';
  if (s.contains('고구마')) return '고구마';
  if (s.contains('계란') || s.contains('달걀') || s.contains('노른자')) return '계란';
  if (s.contains('두부')) return '두부';

  final firstWord = s.split(RegExp(r'\s+')).first;
  return firstWord.isNotEmpty ? firstWord : s;
}

class TriedIngredient {
  String name;
  FoodCategory category;
  int lastUnitWeight;
  String lastReactionNote;
  bool hasAlertReaction;

  TriedIngredient({
    required this.name,
    required this.category,
    required this.lastUnitWeight,
    this.lastReactionNote = '특이사항 없음',
    this.hasAlertReaction = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category.label,
        'lastUnitWeight': lastUnitWeight,
        'lastReactionNote': lastReactionNote,
        'hasAlertReaction': hasAlertReaction,
      };

  factory TriedIngredient.fromJson(Map<String, dynamic> j) => TriedIngredient(
        name: j['name'],
        category: FoodCategory.fromLabel(j['category']),
        lastUnitWeight: j['lastUnitWeight'] ?? 10,
        lastReactionNote: j['lastReactionNote'] ?? '특이사항 없음',
        hasAlertReaction: j['hasAlertReaction'] ?? false,
      );
}

class CubeItem {
  final String id;
  String name;
  FoodCategory category;
  int unitWeight;
  int quantity;
  DateTime madeDate;
  DateTime expireDate;
  String subOption;
  bool isPlannedOnly;
  int createdAt;

  CubeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unitWeight,
    required this.quantity,
    required this.madeDate,
    required this.expireDate,
    this.subOption = '',
    this.isPlannedOnly = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  String get displayName => subOption.isNotEmpty ? '$name ($subOption)' : name;

  int get daysRemaining {
    if (isPlannedOnly) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(expireDate.year, expireDate.month, expireDate.day).difference(today).inDays;
  }

  String get dDayText {
    if (isPlannedOnly || quantity == 0) return '미보유';
    final d = daysRemaining;
    if (d < 0) return '만료(D+${-d})';
    if (d == 0) return 'D-Day';
    return 'D-$d';
  }

  Color get statusColor {
    if (isPlannedOnly || quantity == 0) return const Color(0xFF9C27B0);
    final d = daysRemaining;
    if (d < 0) return const Color(0xFFE53935);
    if (d <= 2) return const Color(0xFFE53935);
    return appPrimaryColor;
  }

  Color get statusBgColor {
    if (isPlannedOnly || quantity == 0) return const Color(0xFFF3E5F5);
    final d = daysRemaining;
    if (d < 0) return const Color(0xFFFFEBEE);
    if (d <= 2) return const Color(0xFFFFEBEE);
    return appLightAccentColor;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.label,
        'unitWeight': unitWeight,
        'quantity': quantity,
        'madeDate': madeDate.toIso8601String(),
        'expireDate': expireDate.toIso8601String(),
        'subOption': subOption,
        'isPlannedOnly': isPlannedOnly,
        'createdAt': createdAt,
      };

  factory CubeItem.fromJson(Map<String, dynamic> j) => CubeItem(
        id: j['id'],
        name: j['name'],
        category: FoodCategory.fromLabel(j['category']),
        unitWeight: j['unitWeight'],
        quantity: j['quantity'],
        madeDate: DateTime.parse(j['madeDate']),
        expireDate: DateTime.parse(j['expireDate']),
        subOption: j['subOption'] ?? '',
        isPlannedOnly: j['isPlannedOnly'] ?? false,
        createdAt: j['createdAt'],
      );
}

class MealLog {
  final String id;
  MealType mealType;
  DateTime time;
  List<String> ingredients;
  Map<String, int> cubeUsage;
  int totalGrams;
  String reaction;
  bool isPlanned;

  MealLog({
    required this.id,
    required this.mealType,
    required this.time,
    required this.ingredients,
    required this.cubeUsage,
    required this.totalGrams,
    required this.reaction,
    required this.isPlanned,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mealType': mealType.label,
        'time': time.toIso8601String(),
        'ingredients': ingredients,
        'cubeUsage': cubeUsage,
        'totalGrams': totalGrams,
        'reaction': reaction,
        'isPlanned': isPlanned,
      };

  factory MealLog.fromJson(Map<String, dynamic> j) => MealLog(
        id: j['id'],
        mealType: MealType.fromLabel(j['mealType']),
        time: DateTime.parse(j['time']),
        ingredients: List<String>.from(j['ingredients']),
        cubeUsage: Map<String, int>.from(j['cubeUsage'] ?? {}),
        totalGrams: j['totalGrams'],
        reaction: j['reaction'],
        isPlanned: j['isPlanned'] ?? false,
      );
}

/// 아기가 이전에 경험해본 식재료인지 판별 (배죽/부위 옵션 무관하게 판별)
bool checkIsTriedIngredient({
  required String name,
  required List<TriedIngredient> triedIngredients,
  List<MealLog> mealLogs = const [],
  List<CubeItem> cubes = const [],
}) {
  final targetBase = getCanonicalBaseIngredient(name);

  // 1. 이미 등록된 먹어본 재료 목록 확인
  for (var t in triedIngredients) {
    if (getCanonicalBaseIngredient(t.name) == targetBase || t.name == name || t.name.contains(targetBase) || targetBase.contains(t.name)) {
      return true;
    }
  }

  // 2. 과거 완료된 식단 기록(isPlanned == false) 확인
  for (var m in mealLogs) {
    if (!m.isPlanned) {
      for (var ing in m.ingredients) {
        if (getCanonicalBaseIngredient(ing) == targetBase) return true;
      }
    }
  }

  // 3. 큐브 보관함에 실물로 제작되었던 큐브(!isPlannedOnly) 확인
  for (var c in cubes) {
    if (!c.isPlannedOnly) {
      if (getCanonicalBaseIngredient(c.name) == targetBase) return true;
    }
  }

  return false;
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;
  bool _isLoading = true;

  String _babyName = '또핑';
  List<CubeItem> _cubes = [];
  List<MealLog> _mealLogs = [];
  List<TriedIngredient> _triedIngredients = [];
  DateTime? _birthDate;
  DateTime? _weaningStartDate;
  BabyGender _gender = BabyGender.none;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _babyName = prefs.getString('baby_name') ?? '또핑';
    final cs = prefs.getString('cubes_data');
    final ms = prefs.getString('meals_data');
    final ts = prefs.getString('tried_ingredients_data');
    final bs = prefs.getString('baby_birth_date');
    final ws = prefs.getString('weaning_start_date');
    final gs = prefs.getString('baby_gender');

    if (cs != null) {
      _cubes = (jsonDecode(cs) as List).map((i) => CubeItem.fromJson(i)).toList();
    } else {
      final now = DateTime.now();
      _cubes = [
        CubeItem(
          id: '1',
          name: '쌀죽',
          category: FoodCategory.grain,
          unitWeight: 50,
          quantity: 4,
          subOption: '10배죽',
          madeDate: now.subtract(const Duration(days: 4)),
          expireDate: now.add(const Duration(days: 10)),
        ),
        CubeItem(
          id: '2',
          name: '소고기',
          category: FoodCategory.meat,
          unitWeight: 10,
          quantity: 3,
          subOption: '안심',
          madeDate: now.subtract(const Duration(days: 6)),
          expireDate: now.add(const Duration(days: 8)),
        ),
        CubeItem(
          id: '3',
          name: '청경채',
          category: FoodCategory.vegetable,
          unitWeight: 10,
          quantity: 2,
          madeDate: now.subtract(const Duration(days: 12)),
          expireDate: now.add(const Duration(days: 2)), // D-2 임박 큐브!
        ),
        CubeItem(
          id: '4',
          name: '단호박',
          category: FoodCategory.vegetable,
          unitWeight: 10,
          quantity: 5,
          madeDate: now.subtract(const Duration(days: 7)),
          expireDate: now.add(const Duration(days: 7)),
        ),
        CubeItem(
          id: '5',
          name: '사과',
          category: FoodCategory.fruit,
          unitWeight: 20,
          quantity: 2,
          madeDate: now.subtract(const Duration(days: 9)),
          expireDate: now.add(const Duration(days: 5)),
        ),
      ];
    }

    if (ms != null) {
      _mealLogs = (jsonDecode(ms) as List).map((i) => MealLog.fromJson(i)).toList();
    } else {
      final now = DateTime.now();
      _mealLogs = [
        MealLog(
          id: 'sample_meal_1',
          mealType: MealType.first,
          time: DateTime(now.year, now.month, now.day, 9, 30),
          ingredients: ['쌀죽(10배죽) 50g', '소고기(안심) 10g', '단호박 10g'],
          cubeUsage: {'1': 1, '2': 1, '4': 1},
          totalGrams: 70,
          reaction: '반응 관찰 준비 완료',
          isPlanned: true,
        ),
        MealLog(
          id: 'sample_meal_2',
          mealType: MealType.second,
          time: DateTime(now.year, now.month, now.day, 14, 0),
          ingredients: ['오트밀포리지 30g', '사과 20g'],
          cubeUsage: {'5': 1},
          totalGrams: 50,
          reaction: '완식',
          isPlanned: false,
        ),
      ];
    }

    if (ts != null) {
      _triedIngredients = (jsonDecode(ts) as List).map((i) => TriedIngredient.fromJson(i)).toList();
    }

    _syncTriedIngredients();

    _birthDate = bs != null ? DateTime.parse(bs) : DateTime.now().subtract(const Duration(days: 182));
    _weaningStartDate = ws != null ? DateTime.parse(ws) : DateTime.now().subtract(const Duration(days: 32));
    _gender = BabyGender.fromCode(gs);
    AppThemeController.instance.setGender(_gender);

    setState(() => _isLoading = false);
  }

  bool _isAlertReaction(String text) {
    return text.contains('붉어짐') || text.contains('두드러기') || text.contains('발진') || text.contains('가려움') || text.contains('설사') || text.contains('뱉어냄');
  }

  void _recordTriedIngredient(String name, FoodCategory category, int unitWeight, {String? reaction}) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final baseName = getCanonicalBaseIngredient(cleanName);
    final targetNames = {cleanName, baseName};

    for (var n in targetNames) {
      if (n.isEmpty) continue;
      final idx = _triedIngredients.indexWhere((t) => t.name == n || getCanonicalBaseIngredient(t.name) == baseName);
      final hasAlert = reaction != null && _isAlertReaction(reaction);

      if (idx != -1) {
        _triedIngredients[idx].category = category;
        _triedIngredients[idx].lastUnitWeight = unitWeight;
        if (reaction != null && reaction.isNotEmpty && !reaction.contains('계획') && !reaction.contains('예정')) {
          _triedIngredients[idx].lastReactionNote = reaction;
          if (hasAlert) _triedIngredients[idx].hasAlertReaction = true;
        }
      } else {
        _triedIngredients.add(TriedIngredient(
          name: n,
          category: category,
          lastUnitWeight: unitWeight,
          lastReactionNote: (reaction != null && reaction.isNotEmpty && !reaction.contains('계획')) ? reaction : '특이사항 없음',
          hasAlertReaction: hasAlert,
        ));
      }
    }
  }

  void _syncTriedIngredients() {
    for (var c in _cubes) {
      if (!c.isPlannedOnly) {
        _recordTriedIngredient(c.name, c.category, c.unitWeight);
      }
    }
    for (var m in _mealLogs) {
      for (var ingStr in m.ingredients) {
        final match = RegExp(r'^(.+?)\s+(\d+)g').firstMatch(ingStr.trim());
        if (match != null) {
          final parsedName = match.group(1)!.trim();
          final parsedGrams = int.tryParse(match.group(2)!) ?? 10;
          final cntMatch = RegExp(r'\((\d+)개\)').firstMatch(ingStr);
          final cnt = cntMatch != null ? (int.tryParse(cntMatch.group(1)!) ?? 1) : 1;
          final unitW = cnt > 0 ? (parsedGrams ~/ cnt) : parsedGrams;

          final existingCube = _cubes.firstWhere(
            (c) => c.name == parsedName || getCanonicalBaseIngredient(c.name) == getCanonicalBaseIngredient(parsedName),
            orElse: () => CubeItem(id: '', name: parsedName, category: guessCategoryByName(parsedName), unitWeight: unitW, quantity: 0, madeDate: DateTime.now(), expireDate: DateTime.now()),
          );

          _recordTriedIngredient(
            parsedName,
            existingCube.category,
            unitW,
            reaction: m.isPlanned ? null : m.reaction,
          );
        }
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baby_name', _babyName);
    await prefs.setString('cubes_data', jsonEncode(_cubes.map((c) => c.toJson()).toList()));
    await prefs.setString('meals_data', jsonEncode(_mealLogs.map((m) => m.toJson()).toList()));
    await prefs.setString('tried_ingredients_data', jsonEncode(_triedIngredients.map((t) => t.toJson()).toList()));
    if (_birthDate != null) await prefs.setString('baby_birth_date', _birthDate!.toIso8601String());
    if (_weaningStartDate != null) await prefs.setString('weaning_start_date', _weaningStartDate!.toIso8601String());
    await prefs.setString('baby_gender', _gender.code);
  }

  void _handleDiscardOrDeleteCube(CubeItem targetCube, {required bool isDiscardOnly}) {
    final prevQty = targetCube.quantity;
    final deletedIndex = _cubes.indexWhere((c) => c.id == targetCube.id);
    if (deletedIndex == -1) return;

    setState(() {
      if (!targetCube.isPlannedOnly) {
        _recordTriedIngredient(targetCube.name, targetCube.category, targetCube.unitWeight);
      }

      if (isDiscardOnly) {
        targetCube.quantity = 0;
      } else {
        _cubes.removeAt(deletedIndex);
      }
    });
    _saveData();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isDiscardOnly
            ? "'${targetCube.name}' 남은 큐브를 폐기(재고 0개) 처리했습니다."
            : "'${targetCube.name}' 큐브가 삭제되었습니다."),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '실행 취소',
          textColor: const Color(0xFF80CBC4),
          onPressed: () {
            setState(() {
              if (isDiscardOnly) {
                targetCube.quantity = prevQty;
              } else {
                final insertIdx = deletedIndex.clamp(0, _cubes.length);
                _cubes.insert(insertIdx, targetCube);
              }
            });
            _saveData();
          },
        ),
      ),
    );
  }

  void _editPlannedTopping(CubeItem cube, String newName, FoodCategory newCategory, int newUnitWeight, String newSubOption) {
    setState(() {
      final oldName = cube.name;

      // 1. _cubes 목록에서 대상 찾아서 수정 또는 추가
      final idx = _cubes.indexWhere((c) => c.id == cube.id || c.name == oldName);
      if (idx != -1) {
        _cubes[idx].name = newName;
        _cubes[idx].category = newCategory;
        _cubes[idx].unitWeight = newUnitWeight;
        _cubes[idx].subOption = newSubOption;
      } else {
        _cubes.add(CubeItem(
          id: cube.id.startsWith('virtual_') ? DateTime.now().millisecondsSinceEpoch.toString() : cube.id,
          name: newName,
          category: newCategory,
          unitWeight: newUnitWeight,
          quantity: 0,
          madeDate: DateTime.now(),
          expireDate: DateTime.now().add(const Duration(days: 14)),
          subOption: newSubOption,
          isPlannedOnly: true,
        ));
      }

      // 2. 예정된 식단 목록(upcoming mealLogs)에서 해당 재료명 일괄 변경
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final newDisplayName = newSubOption.isNotEmpty ? '$newName($newSubOption)' : newName;

      for (var l in _mealLogs) {
        final logDay = DateTime(l.time.year, l.time.month, l.time.day);
        final isUpcoming = logDay.isAfter(today) || (logDay.isAtSameMomentAs(today) && l.isPlanned);
        if (isUpcoming) {
          for (int i = 0; i < l.ingredients.length; i++) {
            final ing = l.ingredients[i];
            if (ing.contains(oldName)) {
              final match = RegExp(r'\s+(\d+g.*)$').firstMatch(ing);
              final suffix = match != null ? ' ${match.group(1)}' : ' ${newUnitWeight}g';
              l.ingredients[i] = '$newDisplayName$suffix';
            }
          }
        }
      }

      _recordTriedIngredient(newName, newCategory, newUnitWeight);
    });
    _saveData();
  }

  void _deletePlannedTopping(CubeItem cube) {
    setState(() {
      final targetName = cube.name;

      // 1. _cubes에서 삭제
      _cubes.removeWhere((c) => c.id == cube.id || c.name == targetName);

      // 2. 예정된 식단(upcoming mealLogs)에서도 해당 재료 및 큐브 사용 삭제
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (var l in _mealLogs) {
        final logDay = DateTime(l.time.year, l.time.month, l.time.day);
        final isUpcoming = logDay.isAfter(today) || (logDay.isAtSameMomentAs(today) && l.isPlanned);
        if (isUpcoming) {
          l.cubeUsage.remove(cube.id);
          l.ingredients.removeWhere((ing) => ing.contains(targetName));

          // totalGrams 재계산
          int newTotal = 0;
          for (var ing in l.ingredients) {
            final m = RegExp(r'(\d+)g').firstMatch(ing);
            if (m != null) newTotal += int.tryParse(m.group(1)!) ?? 0;
          }
          l.totalGrams = newTotal;
        }
      }
    });
    _saveData();
  }

  String _buildBabySubtitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysFromBirth = 182;
    if (_birthDate != null) {
      daysFromBirth = today.difference(DateTime(_birthDate!.year, _birthDate!.month, _birthDate!.day)).inDays + 1;
    }
    String stage;
    if (daysFromBirth < 150) {
      stage = '초기 1단계';
    } else if (daysFromBirth < 210) {
      stage = '초기 2단계';
    } else if (daysFromBirth < 270) {
      stage = '중기';
    } else if (daysFromBirth < 360) {
      stage = '후기';
    } else {
      stage = '완료기';
    }

    int weaningDays = 32;
    if (_weaningStartDate != null) {
      weaningDays = today.difference(DateTime(_weaningStartDate!.year, _weaningStartDate!.month, _weaningStartDate!.day)).inDays + 1;
    }
    return '생후 ${daysFromBirth}일 · $stage (D+$weaningDays)';
  }

  void _showSettings() {
    DateTime b = _birthDate ?? DateTime.now();
    DateTime w = _weaningStartDate ?? DateTime.now();
    BabyGender g = _gender;
    final nameCtrl = TextEditingController(text: _babyName);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('아기 성장 & 테마 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👶 아기 이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: '아기 이름을 입력해 주세요 (예: 또핑, 로아, 하준)',
                    prefixIcon: const Icon(Icons.face_outlined, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('🌸 테마 색상 선택 (즉시 적용)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDState(() => g = BabyGender.none);
                          AppThemeController.instance.setGender(BabyGender.none);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: g == BabyGender.none ? BabyGender.none.lightAccent : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: g == BabyGender.none ? BabyGender.none.primary : Colors.grey.shade300,
                              width: g == BabyGender.none ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('🌱', style: TextStyle(fontSize: 20)),
                              const SizedBox(height: 2),
                              Text('밝은 민트', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BabyGender.none.textColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDState(() => g = BabyGender.boy);
                          AppThemeController.instance.setGender(BabyGender.boy);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: g == BabyGender.boy ? BabyGender.boy.lightAccent : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: g == BabyGender.boy ? BabyGender.boy.primary : Colors.grey.shade300,
                              width: g == BabyGender.boy ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('☁️', style: TextStyle(fontSize: 20)),
                              const SizedBox(height: 2),
                              Text('하늘색 (남아)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BabyGender.boy.textColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDState(() => g = BabyGender.girl);
                          AppThemeController.instance.setGender(BabyGender.girl);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: g == BabyGender.girl ? BabyGender.girl.lightAccent : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: g == BabyGender.girl ? BabyGender.girl.primary : Colors.grey.shade300,
                              width: g == BabyGender.girl ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('🎀', style: TextStyle(fontSize: 20)),
                              const SizedBox(height: 2),
                              Text('베이비핑크 (여아)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: BabyGender.girl.textColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cake_outlined, color: g.primary),
                  title: const Text('아기 출생일', style: TextStyle(fontSize: 13)),
                  subtitle: Text('${b.year}.${b.month}.${b.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: OutlinedButton(
                    child: const Text('변경'),
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: b, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (p != null) setDState(() => b = p);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restaurant_outlined, color: Color(0xFF2E7D32)),
                  title: const Text('이유식 시작일', style: TextStyle(fontSize: 13)),
                  subtitle: Text('${w.year}.${w.month}.${w.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: OutlinedButton(
                    child: const Text('변경'),
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: w, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 30)));
                      if (p != null) setDState(() => w = p);
                    },
                  ),
                ),
                const Divider(),
                const SizedBox(height: 4),
                const Text('데이터 백업 & 복원', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 15),
                        label: const Text('웹앱 데이터 가져오기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: appPrimaryColor,
                          side: BorderSide(color: appPrimaryColor),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showImportDataDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('백업 복사', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      ),
                      onPressed: _exportDataToClipboard,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppThemeController.instance.setGender(_gender);
                Navigator.pop(ctx);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: g.primary, foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  _babyName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : '또핑';
                  _birthDate = b;
                  _weaningStartDate = w;
                  _gender = g;
                });
                AppThemeController.instance.setGender(g);
                _saveData();
                Navigator.pop(ctx);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDataDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync_alt, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Text('웹앱 데이터 가져오기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '기존 웹앱에서 복사한 백업 데이터를 아래 입력칸에 붙여넣고 [데이터 복원]을 누르세요.\n'
                '(모든 식단 기록, 큐브 재고, 아기 날짜 설정이 즉시 복원됩니다.)',
                style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 7,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '여기에 복사한 JSON 데이터를 붙여넣으세요...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              final raw = textCtrl.text.trim();
              if (raw.isEmpty) return;
              try {
                final dynamic decoded = jsonDecode(raw);
                if (decoded is! Map<String, dynamic>) {
                  throw 'JSON 객체 형식이 아닙니다.';
                }
                final Map<String, dynamic> data = decoded;
                final prefs = await SharedPreferences.getInstance();

                if (data.containsKey('cubes_data') && data['cubes_data'] != null) {
                  final cs = data['cubes_data'] is String ? data['cubes_data'] as String : jsonEncode(data['cubes_data']);
                  await prefs.setString('cubes_data', cs);
                  _cubes = (jsonDecode(cs) as List).map((i) => CubeItem.fromJson(i)).toList();
                }
                if (data.containsKey('meals_data') && data['meals_data'] != null) {
                  final ms = data['meals_data'] is String ? data['meals_data'] as String : jsonEncode(data['meals_data']);
                  await prefs.setString('meals_data', ms);
                  _mealLogs = (jsonDecode(ms) as List).map((i) => MealLog.fromJson(i)).toList();
                }
                if (data.containsKey('tried_ingredients_data') && data['tried_ingredients_data'] != null) {
                  final ts = data['tried_ingredients_data'] is String ? data['tried_ingredients_data'] as String : jsonEncode(data['tried_ingredients_data']);
                  await prefs.setString('tried_ingredients_data', ts);
                  _triedIngredients = (jsonDecode(ts) as List).map((i) => TriedIngredient.fromJson(i)).toList();
                }
                if (data.containsKey('baby_birth_date') && data['baby_birth_date'] != null) {
                  final bs = data['baby_birth_date'].toString();
                  await prefs.setString('baby_birth_date', bs);
                  _birthDate = DateTime.tryParse(bs);
                }
                if (data.containsKey('weaning_start_date') && data['weaning_start_date'] != null) {
                  final ws = data['weaning_start_date'].toString();
                  await prefs.setString('weaning_start_date', ws);
                  _weaningStartDate = DateTime.tryParse(ws);
                }
                if (data.containsKey('baby_name') && data['baby_name'] != null) {
                  _babyName = data['baby_name'].toString();
                  await prefs.setString('baby_name', _babyName);
                }
                if (data.containsKey('baby_gender') && data['baby_gender'] != null) {
                  final gs = data['baby_gender'].toString();
                  _gender = BabyGender.fromCode(gs);
                  await prefs.setString('baby_gender', _gender.code);
                  AppThemeController.instance.setGender(_gender);
                }
                _syncTriedIngredients();
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 데이터 복원 완료! (식단 ${_mealLogs.length}개, 큐브 ${_cubes.length}개)'),
                    backgroundColor: appPrimaryColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('데이터 복원 실패: 올바른 백업 데이터가 아닙니다 ($e)'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('데이터 복원하기'),
          ),
        ],
      ),
    );
  }

  void _exportDataToClipboard() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'baby_name': _babyName,
      'cubes_data': prefs.getString('cubes_data'),
      'meals_data': prefs.getString('meals_data'),
      'tried_ingredients_data': prefs.getString('tried_ingredients_data'),
      'baby_birth_date': prefs.getString('baby_birth_date'),
      'weaning_start_date': prefs.getString('weaning_start_date'),
      'baby_gender': _gender.code,
    };
    await Clipboard.setData(ClipboardData(text: jsonEncode(data)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('📋 현재 데이터가 클립보드에 복사되었습니다!'), backgroundColor: appPrimaryColor),
      );
    }
  }

  void _addMealRecord({
    required MealType mealType,
    required DateTime startDate,
    required int repeatDays,
    required Map<CubeItem, int> selectedCubes,
    required String reaction,
  }) {
    List<String> shortageWarnings = [];

    setState(() {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      List<String> ingSummaries = [];
      Map<String, int> cubeUsageMap = {};
      int totalWeight = 0;

      selectedCubes.forEach((cube, count) {
        if (count > 0) {
          final w = cube.unitWeight * count;
          totalWeight += w;
          ingSummaries.add('${cube.displayName} ${w}g (${count}개)');
          cubeUsageMap[cube.id] = count;

          _recordTriedIngredient(cube.name, cube.category, cube.unitWeight, reaction: reaction);

          final totalNeeded = count * repeatDays;
          final isFuture = DateTime(startDate.year, startDate.month, startDate.day).isAfter(todayMidnight);
          if ((isFuture || repeatDays > 1) && cube.quantity < totalNeeded) {
            final lack = totalNeeded - cube.quantity;
            shortageWarnings.add('${cube.name} (${lack}개 부족)');
          }
        }
      });

      for (int i = 0; i < repeatDays; i++) {
        final curDate = startDate.add(Duration(days: i));
        final isFuture = DateTime(curDate.year, curDate.month, curDate.day).isAfter(todayMidnight);

        if (!isFuture && repeatDays == 1) {
          selectedCubes.forEach((cube, count) {
            if (!cube.isPlannedOnly && count > 0) {
              cube.quantity = (cube.quantity - count).clamp(0, 999);
            }
          });
        }

        final memo = reaction.isEmpty
            ? (repeatDays > 1 ? '[${i + 1}/$repeatDays일차 계획]' : (isFuture ? '[예정] 식단 계획' : '반응 관찰 준비 완료'))
            : (repeatDays > 1 ? '[$repeatDays일 연속] $reaction' : reaction);

        _mealLogs.insert(
          0,
          MealLog(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            mealType: mealType,
            time: curDate,
            ingredients: List.from(ingSummaries),
            cubeUsage: Map.from(cubeUsageMap),
            totalGrams: totalWeight,
            reaction: memo,
            isPlanned: isFuture || repeatDays > 1,
          ),
        );
      }
    });
    _saveData();

    if (shortageWarnings.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 완료! 부족 재료(${shortageWarnings.join(", ")})가 [제작 필요] 탭에 자동 연동되었습니다.'),
          backgroundColor: const Color(0xFFE53935),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('[${mealType.label}] 식단이 성공적으로 저장되었습니다.'), backgroundColor: appPrimaryColor),
      );
    }
  }

  void _completePlannedMeal(MealLog log) {
    setState(() {
      log.cubeUsage.forEach((cubeId, count) {
        final idx = _cubes.indexWhere((c) => c.id == cubeId);
        if (idx != -1) {
          _cubes[idx].quantity = (_cubes[idx].quantity - count).clamp(0, 999);
          _recordTriedIngredient(_cubes[idx].name, _cubes[idx].category, _cubes[idx].unitWeight, reaction: log.reaction);
        }
      });
      log.isPlanned = false;
      if (log.reaction.startsWith('[예정]') || log.reaction.contains('계획')) log.reaction = '완식 (식사 완료)';
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('[${log.mealType.label}] 식사 완료! 큐브가 차감되었습니다.'), backgroundColor: appPrimaryColor),
    );
  }

  void _addQuickRescueMeal(DateTime date, MealType mealType, CubeItem cube) {
    setState(() {
      final todayMidnight = DateTime(date.year, date.month, date.day);
      final idx = _mealLogs.indexWhere(
        (m) => m.mealType == mealType && m.time.year == date.year && m.time.month == date.month && m.time.day == date.day,
      );

      final addedWeight = cube.unitWeight > 0 ? cube.unitWeight : 10;

      if (idx != -1) {
        final meal = _mealLogs[idx];
        meal.cubeUsage[cube.id] = (meal.cubeUsage[cube.id] ?? 0) + 1;
        meal.totalGrams += addedWeight;
        final currentCount = meal.cubeUsage[cube.id]!;
        final ingIdx = meal.ingredients.indexWhere((ing) => ing.startsWith(cube.name));
        if (ingIdx != -1) {
          meal.ingredients[ingIdx] = '${cube.displayName} ${currentCount * addedWeight}g (${currentCount}개)';
        } else {
          meal.ingredients.add('${cube.displayName} ${addedWeight}g (1개)');
        }
        if (!meal.isPlanned) {
          cube.quantity = (cube.quantity - 1).clamp(0, 999);
        }
        _recordTriedIngredient(cube.name, cube.category, addedWeight, reaction: meal.reaction);
      } else {
        final now = DateTime.now();
        final isFuture = todayMidnight.isAfter(DateTime(now.year, now.month, now.day));
        final newLog = MealLog(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          mealType: mealType,
          time: DateTime(date.year, date.month, date.day, 9, 30),
          ingredients: ['${cube.displayName} ${addedWeight}g (1개)'],
          cubeUsage: {cube.id: 1},
          totalGrams: addedWeight,
          reaction: isFuture ? '[예정] 식단 계획' : '반응 관찰 준비 완료',
          isPlanned: isFuture,
        );
        if (!isFuture) {
          cube.quantity = (cube.quantity - 1).clamp(0, 999);
        }
        _mealLogs.insert(0, newLog);
        _recordTriedIngredient(cube.name, cube.category, addedWeight);
      }
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cube.name} 10g이 [${mealType.label}] 식단에 쏙 추가되었어요! ✨'),
        backgroundColor: appPrimaryColor,
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 22,
              color: isSelected ? appPrimaryColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? appTextColor : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: appPrimaryColor)));
    }

    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        // Modern Premium Header matching ui_redesign_preview.html
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              _babyName.isNotEmpty ? _babyName : '또핑',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: appLightAccentColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: appPrimaryColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                '토핑 매니저',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: appTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _buildBabySubtitle(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _showSettings,
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            MealCalendarTab(
              mealLogs: _mealLogs,
              cubes: _cubes,
              triedIngredients: _triedIngredients,
              birthDate: _birthDate,
              weaningStartDate: _weaningStartDate,
              onSwitchTab: (idx) => setState(() => _currentTabIndex = idx),
              onAddQuickRescueMeal: _addQuickRescueMeal,
              onEditMealFull: (l, t, tm, r, g, usages, ings) {
                setState(() {
                  l.mealType = t;
                  l.time = tm;
                  l.reaction = r;
                  l.totalGrams = g;
                  l.cubeUsage = usages;
                  l.ingredients = ings;
                });
                _saveData();
              },
              onDeleteMeal: (l) {
                setState(() {
                  if (!l.isPlanned) {
                    l.cubeUsage.forEach((id, cnt) {
                      final i = _cubes.indexWhere((c) => c.id == id);
                      if (i != -1) _cubes[i].quantity += cnt;
                    });
                  }
                  _mealLogs.removeWhere((item) => item.id == l.id);
                });
                _saveData();
              },
              onCompleteMeal: _completePlannedMeal,
              onUpdateReaction: (l, r) {
                setState(() {
                  l.reaction = r;
                  l.cubeUsage.forEach((cubeId, count) {
                    final cIdx = _cubes.indexWhere((c) => c.id == cubeId);
                    if (cIdx != -1) {
                      _recordTriedIngredient(_cubes[cIdx].name, _cubes[cIdx].category, _cubes[cIdx].unitWeight, reaction: r);
                    }
                  });
                });
                _saveData();
              },
            ),
            CubeStorageHubTab(
              cubes: _cubes,
              mealLogs: _mealLogs,
              triedIngredients: _triedIngredients,
              onUpdateQty: (c, d) {
                setState(() => c.quantity = (c.quantity + d).clamp(0, 999));
                _saveData();
              },
              onAddCube: (c) {
                setState(() {
                  _cubes.insert(0, c);
                  _recordTriedIngredient(c.name, c.category, c.unitWeight);
                });
                _saveData();
              },
              onEditCube: (c, n, cat, w, q, md, sl, subOpt) {
                setState(() {
                  c.name = n;
                  c.category = cat;
                  c.unitWeight = w;
                  c.quantity = q;
                  c.madeDate = md;
                  c.expireDate = md.add(Duration(days: sl));
                  c.subOption = subOpt;
                  c.isPlannedOnly = false;
                  _recordTriedIngredient(n, cat, w);
                });
                _saveData();
              },
              onDiscardCube: (c) => _handleDiscardOrDeleteCube(c, isDiscardOnly: true),
              onDeleteCube: (c) => _handleDiscardOrDeleteCube(c, isDiscardOnly: false),
              onRestock: (c, w, q, md, sl) {
                setState(() {
                  final existingIdx = _cubes.indexWhere((item) => item.id == c.id || item.name == c.name);
                  if (existingIdx != -1) {
                    _cubes[existingIdx].unitWeight = w;
                    _cubes[existingIdx].quantity += q;
                    _cubes[existingIdx].madeDate = md;
                    _cubes[existingIdx].expireDate = md.add(Duration(days: sl));
                    _cubes[existingIdx].isPlannedOnly = false;
                  } else {
                    _cubes.insert(
                      0,
                      CubeItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: c.name,
                        category: c.category,
                        unitWeight: w,
                        quantity: q,
                        madeDate: md,
                        expireDate: md.add(Duration(days: sl)),
                        subOption: c.subOption,
                        isPlannedOnly: false,
                      ),
                    );
                  }
                  _recordTriedIngredient(c.name, c.category, w);
                });
                _saveData();
              },
              onEditPlannedTopping: _editPlannedTopping,
              onDeletePlannedTopping: _deletePlannedTopping,
            ),
            MealLogTab(
              cubes: _cubes,
              mealLogs: _mealLogs,
              triedIngredients: _triedIngredients,
              birthDate: _birthDate,
              weaningStartDate: _weaningStartDate,
              onSaveMeal: _addMealRecord,
              onAddCubeToStock: (c) {
                setState(() {
                  _cubes.insert(0, c);
                  if (!c.isPlannedOnly) {
                    _recordTriedIngredient(c.name, c.category, c.unitWeight);
                  }
                });
                _saveData();
              },
            ),
          ],
        ),
        // Modern Custom Bottom Navigation Bar
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(0, Icons.calendar_today_outlined, Icons.calendar_month, '캘린더'),
                  _buildBottomNavItem(1, Icons.grid_view_outlined, Icons.grid_view_rounded, '큐브보관함'),
                  _buildBottomNavItem(2, Icons.edit_note_outlined, Icons.edit_note, '식단기록'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String calculateDdayString(DateTime targetDate, DateTime? birthDate, DateTime? weaningStartDate) {
  final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
  List<String> ddays = [];
  if (birthDate != null) {
    final diff = target.difference(DateTime(birthDate.year, birthDate.month, birthDate.day)).inDays + 1;
    if (diff > 0) ddays.add('생후 D+$diff일');
  }
  if (weaningStartDate != null) {
    final diff = target.difference(DateTime(weaningStartDate.year, weaningStartDate.month, weaningStartDate.day)).inDays + 1;
    if (diff > 0) {
      ddays.add('이유식 $diff일차');
    } else if (diff == 0) {
      ddays.add('이유식 D-Day');
    } else {
      ddays.add('이유식 D${diff - 1}');
    }
  }
  return ddays.join(' · ');
}

// ==========================================
// 1. 식단 기록 화면 (MealLogTab)
// ==========================================
class MealLogTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final List<MealLog> mealLogs;
  final List<TriedIngredient> triedIngredients;
  final DateTime? birthDate;
  final DateTime? weaningStartDate;
  final Function({
    required MealType mealType,
    required DateTime startDate,
    required int repeatDays,
    required Map<CubeItem, int> selectedCubes,
    required String reaction,
  }) onSaveMeal;
  final Function(CubeItem) onAddCubeToStock;

  const MealLogTab({
    super.key,
    required this.cubes,
    required this.mealLogs,
    required this.triedIngredients,
    required this.birthDate,
    required this.weaningStartDate,
    required this.onSaveMeal,
    required this.onAddCubeToStock,
  });

  @override
  State<MealLogTab> createState() => _MealLogTabState();
}

class _MealLogTabState extends State<MealLogTab> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  MealType _selectedMealType = MealType.first;
  final Map<String, int> _selectedQuantities = {};
  final TextEditingController _reactionController = TextEditingController();


  int get _repeatDays => DateTime(_endDate.year, _endDate.month, _endDate.day).difference(DateTime(_startDate.year, _startDate.month, _startDate.day)).inDays + 1;

  void _showTriedHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final sortedTried = List<TriedIngredient>.from(widget.triedIngredients)
          ..sort((a, b) => a.category.sortOrder.compareTo(b.category.sortOrder));

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('먹어본 재료 다시 담기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: sortedTried.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('아직 먹어본 식재료 이력이 없습니다.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: sortedTried.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, idx) {
                      final item = sortedTried[idx];
                      final existingCubeIdx = widget.cubes.indexWhere((c) => c.name == item.name);
                      final hasStock = existingCubeIdx != -1 && widget.cubes[existingCubeIdx].quantity > 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: Text(getFoodEmoji(item.name), style: const TextStyle(fontSize: 22)),
                        title: Row(
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: item.category.bgColor, borderRadius: BorderRadius.circular(6)),
                              child: Text(item.category.label, style: TextStyle(fontSize: 9.5, color: item.category.textColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '기존 용량 ${item.lastUnitWeight}g · ${hasStock ? "보관함 잔여 (${widget.cubes[existingCubeIdx].quantity}개)" : "현재 재고 없음"}',
                              style: TextStyle(fontSize: 11, color: hasStock ? appPrimaryColor : const Color(0xFFE53935), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              item.hasAlertReaction ? '⚠️ 주의 이력: ${item.lastReactionNote}' : '✅ 과거 반응: ${item.lastReactionNote}',
                              style: TextStyle(fontSize: 11, color: item.hasAlertReaction ? Colors.red.shade700 : Colors.grey.shade600),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appPrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            if (existingCubeIdx != -1) {
                              final c = widget.cubes[existingCubeIdx];
                              setState(() => _selectedQuantities[c.id] = (_selectedQuantities[c.id] ?? 0) + 1);
                            } else {
                              final restoredCube = CubeItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: item.name,
                                category: item.category,
                                unitWeight: item.lastUnitWeight,
                                quantity: 0,
                                madeDate: DateTime.now(),
                                expireDate: DateTime.now().add(const Duration(days: 14)),
                                isPlannedOnly: false,
                              );
                              widget.onAddCubeToStock(restoredCube);
                              setState(() => _selectedQuantities[restoredCube.id] = 1);
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text('담기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
          ],
        );
      },
    );
  }

  void _showAddUnregisteredDialog() {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '10');
    FoodCategory cat = FoodCategory.vegetable;
    String selectedSubOption = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('새 식재료 직접 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '식재료명 (예: 단호박, 비트)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<FoodCategory>(
                  value: cat,
                  decoration: const InputDecoration(labelText: '카테고리'),
                  items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setDState(() {
                    cat = v!;
                    selectedSubOption = '';
                  }),
                ),
                if (cat == FoodCategory.grain) ...[
                  const SizedBox(height: 10),
                  Text('배죽 옵션 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kGrainPorridgeOptions.map((opt) {
                      final isSel = selectedSubOption == opt;
                      return ChoiceChip(
                        label: Text(opt, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: appPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onSelected: (val) => setDState(() => selectedSubOption = val ? opt : ''),
                      );
                    }).toList(),
                  ),
                ] else if (cat == FoodCategory.meat) ...[
                  const SizedBox(height: 10),
                  Text('부위 옵션 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kMeatCutOptions.map((opt) {
                      final isSel = selectedSubOption == opt;
                      return ChoiceChip(
                        label: Text(opt, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: appPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onSelected: (val) => setDState(() => selectedSubOption = val ? opt : ''),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '1회 권장량 (g)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
              onPressed: () {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                final alreadyTried = widget.triedIngredients.any((t) => t.name == n);

                final newCube = CubeItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: n,
                  category: cat,
                  unitWeight: int.tryParse(weightCtrl.text) ?? 10,
                  quantity: 0,
                  madeDate: DateTime.now(),
                  expireDate: DateTime.now().add(const Duration(days: 14)),
                  subOption: selectedSubOption,
                  isPlannedOnly: !alreadyTried,
                );
                widget.onAddCubeToStock(newCube);
                setState(() => _selectedQuantities[newCube.id] = 1);
                Navigator.pop(ctx);
              },
              child: const Text('식단에 담기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int grainG = 0;
    int proteinG = 0;
    int veggieG = 0;
    int fruitG = 0;
    int etcG = 0;

    for (var c in widget.cubes) {
      final cnt = _selectedQuantities[c.id] ?? 0;
      if (cnt > 0) {
        final w = cnt * c.unitWeight;
        switch (c.category) {
          case FoodCategory.grain: grainG += w; break;
          case FoodCategory.meat: proteinG += w; break;
          case FoodCategory.vegetable: veggieG += w; break;
          case FoodCategory.fruit: fruitG += w; break;
          case FoodCategory.etc: etcG += w; break;
        }
      }
    }
    final totalG = grainG + proteinG + veggieG + fruitG + etcG;
    final ddayStr = calculateDdayString(_startDate, widget.birthDate, widget.weaningStartDate);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? getEarliestNeedDate(CubeItem c) {
      DateTime? earliest;
      for (var l in widget.mealLogs) {
        final logDay = DateTime(l.time.year, l.time.month, l.time.day);
        final isUpcoming = logDay.isAfter(today) || (logDay.isAtSameMomentAs(today) && l.isPlanned);
        if (isUpcoming) {
          final usesCube = l.cubeUsage.containsKey(c.id) || l.ingredients.any((ing) => ing.contains(c.name));
          if (usesCube) {
            if (earliest == null || l.time.isBefore(earliest)) {
              earliest = l.time;
            }
          }
        }
      }
      return earliest;
    }

    // 3. 토핑 큐브 선택 정렬: 현재 보유한 것 우선, 미보유 후순위
    // 보유 큐브: 곡류-단백질(육류)-채소-과일-기타 순
    // 미보유 큐브: 빨리 필요해지는 일정의 큐브부터 정렬
    final sortedCubes = List<CubeItem>.from(widget.cubes)
      ..sort((a, b) {
        final aOwned = !a.isPlannedOnly && a.quantity > 0;
        final bOwned = !b.isPlannedOnly && b.quantity > 0;

        // 보유한 큐브 우선, 미보유는 뒤로
        if (aOwned && !bOwned) return -1;
        if (!aOwned && bOwned) return 1;

        if (aOwned && bOwned) {
          // 보유 큐브: 곡류 -> 단백질(육류) -> 채소 -> 과일 -> 기타 순
          final catCmp = a.category.sortOrder.compareTo(b.category.sortOrder);
          if (catCmp != 0) return catCmp;
          return a.daysRemaining.compareTo(b.daysRemaining);
        } else {
          // 미보유 큐브: 빨리 필요해지는 일정의 큐브부터 정렬
          final needA = getEarliestNeedDate(a);
          final needB = getEarliestNeedDate(b);
          if (needA != null && needB != null) {
            final dateCmp = needA.compareTo(needB);
            if (dateCmp != 0) return dateCmp;
          } else if (needA != null && needB == null) {
            return -1;
          } else if (needA == null && needB != null) {
            return 1;
          }
          final catCmp = a.category.sortOrder.compareTo(b.category.sortOrder);
          if (catCmp != 0) return catCmp;
          return a.name.compareTo(b.name);
        }
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 날짜 및 기간 설정 카드 (웹앱 방식 달력 선택 + 빠른 설정)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: appLightAccentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text('📅', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _repeatDays > 1 ? '$_repeatDays일 연속 동일 식단' : '식단 날짜',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appTextColor),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _repeatDays > 1 ? '${_startDate.month}/${_startDate.day} ~ ${_endDate.month}/${_endDate.day}' : '${_startDate.year}년 ${_startDate.month}월 ${_startDate.day}일',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            _endDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: appLightAccentColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: appPrimaryColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text('달력 선택', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: appTextColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('빠른 설정: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() => _endDate = _startDate),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _repeatDays == 1 ? appPrimaryColor : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _repeatDays == 1 ? appPrimaryColor : const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                '하루만',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _repeatDays == 1 ? Colors.white : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() => _endDate = _startDate.add(const Duration(days: 2))),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _repeatDays == 3 ? appPrimaryColor : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _repeatDays == 3 ? appPrimaryColor : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on, size: 12, color: _repeatDays == 3 ? Colors.white : Colors.amber.shade800),
                                  const SizedBox(width: 2),
                                  Text(
                                    '3일 테스트',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _repeatDays == 3 ? Colors.white : const Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ddayStr.isNotEmpty && _repeatDays == 1)
                        Text(ddayStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appTextColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. 끼니 선택 (1끼 / 2끼 / 3끼 / 간식)
          const Text('끼니 선택', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          Row(
            children: MealType.values.map((m) {
              final isSel = _selectedMealType == m;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMealType = m),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? appPrimaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? appPrimaryColor : const Color(0xFFE2E8F0)),
                        boxShadow: isSel ? [BoxShadow(color: appPrimaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))] : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        m.label,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSel ? Colors.white : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 3. 실시간 이유식 볼 채우기 게이지
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('🥣', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text('이유식 볼 채우기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                    Text(
                      '${totalG}g / 권장 80g',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: appTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 9,
                    color: const Color(0xFFF1F5F9),
                    child: Row(
                      children: [
                        if (grainG > 0) Expanded(flex: grainG, child: Container(color: const Color(0xFFF59F00))),
                        if (proteinG > 0) Expanded(flex: proteinG, child: Container(color: const Color(0xFFEF4444))),
                        if (veggieG > 0) Expanded(flex: veggieG, child: Container(color: const Color(0xFF10B981))),
                        if (fruitG > 0) Expanded(flex: fruitG, child: Container(color: const Color(0xFF06B6D4))),
                        if (etcG > 0) Expanded(flex: etcG, child: Container(color: const Color(0xFF868E96))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('곡류 ${grainG}g', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    Text('단백질 ${proteinG}g', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    Text('채소 ${veggieG}g', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    if (fruitG > 0) Text('과일 ${fruitG}g', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. 토핑 큐브 선택 리스트
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('토핑 큐브 선택 (${_selectedMealType.label} 기준)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const Text('보관함 실시간 연동', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 10),
                ...sortedCubes.map((cube) {
                  final count = _selectedQuantities[cube.id] ?? 0;
                  final emoji = getFoodEmoji(cube.name);
                  final isOwned = !cube.isPlannedOnly && cube.quantity > 0;
                  final needDate = getEarliestNeedDate(cube);

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(cube.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                    if (cube.subOption.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(color: appLightAccentColor, borderRadius: BorderRadius.circular(4)),
                                        child: Text(cube.subOption, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: appTextColor)),
                                      ),
                                    ],
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                      child: Text('${cube.unitWeight}g', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                                    ),
                                    if (!isOwned) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7ED),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFFFED7AA)),
                                        ),
                                        child: const Text('미보유', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  isOwned
                                      ? '보관함 잔여: ${cube.quantity}개 (${cube.quantity * cube.unitWeight}g)'
                                      : (needDate != null
                                          ? '미보유 · ${needDate.month}/${needDate.day} 식단 예정'
                                          : '미보유 · 제작 필요'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isOwned ? FontWeight.normal : FontWeight.w600,
                                    color: isOwned ? const Color(0xFF94A3B8) : const Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: count > 0 ? () => setState(() => _selectedQuantities[cube.id] = count - 1) : null,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text('-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: count > 0 ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                              ),
                            ),
                            Container(
                              width: 26,
                              alignment: Alignment.center,
                              child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                            InkWell(
                              onTap: () => setState(() => _selectedQuantities[cube.id] = count + 1),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: appLightAccentColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appTextColor)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _showTriedHistoryDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text('먹어본 재료 추가', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _showAddUnregisteredDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text('+ 새 식재료', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. 메모 입력
          TextField(
            controller: _reactionController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: '식단 계획 / 아기 상태 메모 입력',
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: appPrimaryColor, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),

          // 6. 저장 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: appPrimaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                if (_selectedQuantities.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('최소 1개 이상의 큐브를 선택해 주세요.')),
                  );
                  return;
                }
                final dt = DateTime(_startDate.year, _startDate.month, _startDate.day, _selectedTime.hour, _selectedTime.minute);
                Map<CubeItem, int> selected = {};
                for (var c in widget.cubes) {
                  if (_selectedQuantities.containsKey(c.id)) selected[c] = _selectedQuantities[c.id]!;
                }
                widget.onSaveMeal(
                  mealType: _selectedMealType,
                  startDate: dt,
                  repeatDays: _repeatDays,
                  selectedCubes: selected,
                  reaction: _reactionController.text.trim(),
                );
                setState(() {
                  _selectedQuantities.clear();
                  _reactionController.clear();
                  _endDate = _startDate;
                });
              },
              child: Text(
                _repeatDays > 1
                    ? '$_repeatDays일 연속 식단 저장하기 ($totalG g)'
                    : '${_startDate.month}월 ${_startDate.day}일 ${_selectedMealType.label} 식단 계획 저장하기 ($totalG g)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ==========================================
// 2. 캘린더 화면 (MealCalendarTab)
// ==========================================
class MealCalendarTab extends StatefulWidget {
  final List<MealLog> mealLogs;
  final List<CubeItem> cubes;
  final List<TriedIngredient> triedIngredients;
  final DateTime? birthDate;
  final DateTime? weaningStartDate;
  final Function(int) onSwitchTab;
  final Function(DateTime, MealType, CubeItem) onAddQuickRescueMeal;
  final Function(MealLog, MealType, DateTime, String, int, Map<String, int>, List<String>) onEditMealFull;
  final Function(MealLog) onDeleteMeal;
  final Function(MealLog) onCompleteMeal;
  final Function(MealLog, String) onUpdateReaction;

  const MealCalendarTab({
    super.key,
    required this.mealLogs,
    required this.cubes,
    required this.triedIngredients,
    required this.birthDate,
    required this.weaningStartDate,
    required this.onSwitchTab,
    required this.onAddQuickRescueMeal,
    required this.onEditMealFull,
    required this.onDeleteMeal,
    required this.onCompleteMeal,
    required this.onUpdateReaction,
  });

  @override
  State<MealCalendarTab> createState() => _MealCalendarTabState();
}

class _MealCalendarTabState extends State<MealCalendarTab> {
  late DateTime _focusedDate;
  late DateTime _selectedDate;
  bool _isRescueDismissed = false;

  final List<String> _skinTags = ['피부 정상', '입주변 붉어짐', '두드러기/발진', '눈 비빔/가려움'];
  final List<String> _stoolTags = ['황금변', '된변', '무른변', '설사', '대변 X'];
  final List<String> _attitudeTags = ['완식', '거의 다 먹음', '절반 남김', '뱉어냄'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDate = DateTime(now.year, now.month, now.day);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _getKoreanWeekday(DateTime d) => ['월', '화', '수', '목', '금', '토', '일'][d.weekday - 1];

  List<MealLog> _getLogsForDate(DateTime d) {
    final list = widget.mealLogs.where((l) => _isSameDay(l.time, d)).toList();
    list.sort((a, b) {
      final o = a.mealType.order.compareTo(b.mealType.order);
      return o != 0 ? o : a.time.compareTo(b.time);
    });
    return list;
  }

  List<String> _getNewIngredients(MealLog log) {
    List<String> news = [];
    final curDay = DateTime(log.time.year, log.time.month, log.time.day);

    // 1) 이 식단 이전에 진행된 모든 식단의 재료 수집
    final past = widget.mealLogs.where((l) {
      final logDay = DateTime(l.time.year, l.time.month, l.time.day);
      if (logDay.isBefore(curDay)) return true;
      if (logDay.isAtSameMomentAs(curDay)) {
        return l.mealType.index < log.mealType.index;
      }
      return false;
    }).toList();

    Set<String> pastBases = {};
    for (var pl in past) {
      for (var ing in pl.ingredients) {
        final b = getCanonicalBaseIngredient(ing);
        if (b.isNotEmpty) pastBases.add(b);
      }
    }

    Set<String> curMealIngredients = {};
    for (var ing in log.ingredients) {
      final name = ing.split(' ').first.replaceAll(RegExp(r'\(.*\)'), '').trim();
      if (name.isNotEmpty) curMealIngredients.add(name);
    }
    log.cubeUsage.forEach((id, count) {
      final match = widget.cubes.firstWhere(
        (c) => c.id == id,
        orElse: () => CubeItem(id: '', name: '', category: FoodCategory.etc, unitWeight: 0, quantity: 0, madeDate: DateTime.now(), expireDate: DateTime.now()),
      );
      if (match.name.isNotEmpty) {
        curMealIngredients.add(match.name);
      }
    });

    for (var name in curMealIngredients) {
      final base = getCanonicalBaseIngredient(name);
      if (!pastBases.contains(base) && !news.contains(name)) {
        news.add(name);
      }
    }
    return news;
  }

  void _showFirstTryGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFF59F00), size: 20),
            SizedBox(width: 8),
            Text('첫 시도 알레르기 관찰 가이드', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '처음 먹는 식재료는 오전 1끼에 급여하고, 식후 2~3시간 동안 아기의 반응을 주의 깊게 살펴주세요.\n\n'
          '• 입 주변 붉어짐이나 피부 발진\n'
          '• 눈 비빔 또는 가려움 증상\n'
          '• 갑작스러운 설사나 구토\n\n'
          '특이 반응 발생 시 즉시 [반응 기록]에 남겨두시면 다음 식단 계획 시 안전하게 참고할 수 있습니다.',
          style: TextStyle(fontSize: 12.5, height: 1.55),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
        ],
      ),
    );
  }

  void _showEditMealDialog(MealLog log) {
    MealType currentType = log.mealType;
    TimeOfDay currentTime = TimeOfDay(hour: log.time.hour, minute: log.time.minute);
    final reactionController = TextEditingController(text: log.reaction);
    final Map<String, int> editUsage = Map<String, int>.from(log.cubeUsage);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) {
          int computedGrams = 0;
          editUsage.forEach((cubeId, count) {
            final c = widget.cubes.firstWhere((item) => item.id == cubeId, orElse: () => CubeItem(id: '', name: '', category: FoodCategory.etc, unitWeight: 10, quantity: 0, madeDate: DateTime.now(), expireDate: DateTime.now()));
            computedGrams += count * c.unitWeight;
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('식단 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('토핑 큐브 조정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('총 $computedGrams g', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: appPrimaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.cubes.map((c) {
                      final count = editUsage[c.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(getFoodEmoji(c.name)),
                            const SizedBox(width: 6),
                            Expanded(child: Text('${c.displayName} (${c.unitWeight}g)', style: TextStyle(fontSize: 12, fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal))),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                              onPressed: count > 0
                                  ? () => setDState(() {
                                        if (count == 1) editUsage.remove(c.id); else editUsage[c.id] = count - 1;
                                      })
                                  : null,
                            ),
                            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              onPressed: () => setDState(() => editUsage[c.id] = count + 1),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 18),
                    const Text('끼니 차수', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: MealType.values.map((m) {
                        final isSel = currentType == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setDState(() => currentType = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? m.primaryColor : m.bgColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSel ? m.primaryColor : m.primaryColor.withOpacity(0.4)),
                              ),
                              child: Text(m.label, style: TextStyle(color: isSel ? Colors.white : m.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('시간: ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.schedule, size: 14),
                          label: const Text('시간 변경', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: currentTime);
                            if (picked != null) setDState(() => currentTime = picked);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: reactionController, decoration: const InputDecoration(labelText: '메모 / 아기 반응')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
                onPressed: () {
                  final newDt = DateTime(log.time.year, log.time.month, log.time.day, currentTime.hour, currentTime.minute);
                  List<String> newIngs = [];
                  editUsage.forEach((id, cnt) {
                    if (cnt > 0) {
                      final c = widget.cubes.firstWhere((item) => item.id == id, orElse: () => CubeItem(id: '', name: '', category: FoodCategory.etc, unitWeight: 10, quantity: 0, madeDate: DateTime.now(), expireDate: DateTime.now()));
                      newIngs.add('${c.displayName} ${c.unitWeight * cnt}g ($cnt개)');
                    }
                  });

                  widget.onEditMealFull(log, currentType, newDt, reactionController.text.trim(), computedGrams, editUsage, newIngs);
                  Navigator.pop(ctx);
                },
                child: const Text('수정 완료'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReactionDialog(MealLog log) {
    final ctrl = TextEditingController(text: log.reaction);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('반응 및 알레르기 기록', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 4,
              children: [..._skinTags, ..._stoolTags, ..._attitudeTags].map((t) => ActionChip(
                label: Text(t, style: const TextStyle(fontSize: 11)),
                onPressed: () => ctrl.text = ctrl.text.isEmpty ? t : '${ctrl.text}, $t',
              )).toList(),
            ),
            const SizedBox(height: 8),
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: '메모')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
            onPressed: () {
              widget.onUpdateReaction(log, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 큐브 추가 제안 배너 (노란/앰버 계열 그라데이션 + 친근한 어투 + D-3 정확한 디데이 산정)
  Widget _buildRescueBanner(List<MealLog> logs) {
    if (_isRescueDismissed) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    // 과거 날짜는 이미 지난 식단이므로 추가 제안을 표시하지 않음
    if (selectedDay.isBefore(today)) return const SizedBox.shrink();

    // 1. 현재 실보유 중이며, '오늘' 기준으로도 만료되지 않은 유효 큐브 선별 (폐기된 것은 제안 안 함)
    final validCubes = widget.cubes.where((c) => !c.isPlannedOnly && c.quantity > 0 && c.daysRemaining >= 0).toList();
    if (validCubes.isEmpty) return const SizedBox.shrink();

    // 2. 선택된 날짜(selectedDay) 기준으로 보관기한 D-3 ~ D-0(만료일) 사이인 큐브만 제안 (만료 지난 것 diffDays < 0 과감히 폐기 제외)
    final expiringOnSelectedDay = validCubes.where((c) {
      final expireDay = DateTime(c.expireDate.year, c.expireDate.month, c.expireDate.day);
      final diffDays = expireDay.difference(selectedDay).inDays;
      return diffDays >= 0 && diffDays <= 3; // D-3, D-2, D-1, 오늘/이날 만료
    }).toList();

    if (expiringOnSelectedDay.isEmpty) return const SizedBox.shrink();

    // 3. 해당 날짜 식단(logs)에 아직 포함되지 않은 큐브 필터링
    final candidates = expiringOnSelectedDay.where((c) {
      return !logs.any((l) => l.cubeUsage.containsKey(c.id) || l.ingredients.any((ing) => ing.contains(c.name)));
    }).toList();

    if (candidates.isEmpty) return const SizedBox.shrink();

    // 선택 날짜 기준 가장 만료 임박한 큐브 우선 선택
    candidates.sort((a, b) {
      final diffA = DateTime(a.expireDate.year, a.expireDate.month, a.expireDate.day).difference(selectedDay).inDays;
      final diffB = DateTime(b.expireDate.year, b.expireDate.month, b.expireDate.day).difference(selectedDay).inDays;
      return diffA.compareTo(diffB);
    });

    final cube = candidates.first;
    final expireDay = DateTime(cube.expireDate.year, cube.expireDate.month, cube.expireDate.day);
    final diffDays = expireDay.difference(selectedDay).inDays;

    final isToday = selectedDay.isAtSameMomentAs(today);
    final dText = diffDays == 0 ? (isToday ? '오늘 만료' : '이날 만료') : '만료 ${diffDays}일 전';

    final hasMeatInLogs = logs.any((l) => l.ingredients.any((ing) => ing.contains('소고기') || ing.contains('안심') || ing.contains('우둔살') || ing.contains('닭') || ing.contains('고기')));
    String synergyHint;
    if (hasMeatInLogs && (cube.category == FoodCategory.vegetable || cube.category == FoodCategory.fruit)) {
      synergyHint = '비타민 C가 소고기의 철분 흡수를 쑥쑥 도와줘요 🌱';
    } else if (cube.category == FoodCategory.meat) {
      synergyHint = '철분과 단백질이 균형을 이뤄 흡수율이 높아져요 💪';
    } else {
      synergyHint = '영양 밸런스가 딱 맞아 아기 성장을 도와줘요 ✨';
    }

    final targetDateLabel = isToday ? '오늘' : '${_selectedDate.month}월 ${_selectedDate.day}일';
    final buttonDateLabel = isToday ? '오늘' : '${_selectedDate.day}일';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🥗', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('큐브 추가 제안', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF78350F))),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('영양 찰떡궁합 ✨', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${cube.displayName}($dText)가 아직 식단에 없어요! $targetDateLabel 1끼 식단에 10g 쏙 넣어보세요. $synergyHint',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.35),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isRescueDismissed = true),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.only(left: 4, top: 2),
                  child: Text('✕', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => widget.onAddQuickRescueMeal(_selectedDate, MealType.first, cube),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('+ $buttonDateLabel 1끼 식단에 10g 추가', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 주간 스트립 캘린더 카드 (ui_redesign_preview.html 스타일 100% 구현)
  Widget _buildWeeklyStripCalendar() {
    final monday = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day).subtract(Duration(days: _focusedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final weekNumber = ((_focusedDate.day + firstDayOfMonth.weekday - 2) ~/ 7) + 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _focusedDate = _focusedDate.subtract(const Duration(days: 7))),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_left, size: 20, color: Color(0xFF64748B)),
                    ),
                  ),
                  Text(
                    '${_focusedDate.year}년 ${_focusedDate.month}월 ${weekNumber}주차',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                  InkWell(
                    onTap: () => setState(() => _focusedDate = _focusedDate.add(const Duration(days: 7))),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right, size: 20, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _focusedDate = today;
                    _selectedDate = today;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: appLightAccentColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appPrimaryColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    '오늘',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appTextColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) {
              final isSelected = _isSameDay(d, _selectedDate);
              final isToday = _isSameDay(d, today);
              final dayLogs = widget.mealLogs.where((l) => _isSameDay(l.time, d)).toList();
              final hasMeal = dayLogs.isNotEmpty;
              final hasFirstTry = dayLogs.any((l) => _getNewIngredients(l).isNotEmpty);
              final weekdayName = _getKoreanWeekday(d);

              Color dayTextColor;
              if (isSelected) {
                dayTextColor = Colors.white;
              } else if (d.weekday == 7) {
                dayTextColor = const Color(0xFFEF4444);
              } else if (d.weekday == 6) {
                dayTextColor = const Color(0xFF3B82F6);
              } else {
                dayTextColor = const Color(0xFF475569);
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? appPrimaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected
                          ? [BoxShadow(color: appPrimaryColor.withOpacity(0.35), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekdayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : (isToday ? FontWeight.bold : FontWeight.w600),
                            color: dayTextColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 4.5,
                          height: 4.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : (hasFirstTry ? const Color(0xFFF59F00) : (hasMeal ? appPrimaryColor : Colors.transparent)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 개별 식단 카드 (상단 첫 시도 뱃지, 그램 수, 끼니 점, 필 태그 랩핑, 하단 액션)
  Widget _buildMealCard(MealLog l, List<String> news) {
    final hasNew = news.isNotEmpty;
    final timeStr = '${l.time.hour.toString().padLeft(2, '0')}:${l.time.minute.toString().padLeft(2, '0')}';

    final alertIngredients = widget.triedIngredients.where((t) {
      if (!t.hasAlertReaction) return false;
      final tBase = getCanonicalBaseIngredient(t.name);
      return l.ingredients.any((ing) => getCanonicalBaseIngredient(ing) == tBase);
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasNew
              ? const Color(0xFFF59E0B)
              : (alertIngredients.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)),
          width: (hasNew || alertIngredients.isNotEmpty) ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 처음 시도 알레르기 관찰 Warning 배너
          if (hasNew) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9DB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE066)),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'NEW 첫 시도: ${news.map((e) => "${getFoodEmoji(e)} $e").join(", ")}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _showFirstTryGuideDialog,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Color(0xFFF59F00)),
                          SizedBox(width: 2),
                          Text('가이드', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (alertIngredients.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '알레르기 주의 이력: ${alertIngredients.map((a) => a.name).join(", ")} (${alertIngredients.first.lastReactionNote})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 2. 끼니 정보 및 상단 태그
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasNew ? const Color(0xFFF59E0B) : l.mealType.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.mealType.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '· $timeStr',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  if (hasNew) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('첫 시도', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: appLightAccentColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: appPrimaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${l.totalGrams}g',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appTextColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.isPlanned ? '식단 예정' : '식사 완료',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: l.isPlanned ? const Color(0xFF94A3B8) : appTextColor),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditMealDialog(l);
                      } else if (val == 'delete') {
                        widget.onDeleteMeal(l);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(fontSize: 13))),
                      const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(fontSize: 13, color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 필 태그 랩핑 (식재료명, 용량)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: l.ingredients.map((ing) {
              final cleanName = ing.split(' ').first.replaceAll(RegExp(r'\(.*\)'), '').trim();
              final isNew = news.contains(cleanName);
              final emoji = getFoodEmoji(cleanName);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isNew ? appLightAccentColor : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isNew ? appPrimaryColor.withOpacity(0.4) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '$emoji $ing',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isNew ? FontWeight.bold : FontWeight.w500,
                    color: isNew ? appTextColor : const Color(0xFF334155),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l.reaction.isEmpty
                        ? (hasNew && l.isPlanned ? '반응 관찰 준비 완료' : '특이사항 없음')
                        : l.reaction,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: (hasNew && l.isPlanned && l.reaction.isEmpty) ? const Color(0xFFB45309) : const Color(0xFF94A3B8),
                      fontWeight: (hasNew && l.isPlanned && l.reaction.isEmpty) ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _showReactionDialog(l),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('반응 기록', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ),
                    ),
                    if (l.isPlanned) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => widget.onCompleteMeal(l),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: appPrimaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('식사 완료 기록', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 미등록 식단 슬롯 플레이스홀더 카드 (점선/연한 테두리)
  Widget _buildEmptyMealCard(MealType mealType) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                mealType.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 6),
              const Text(
                '· (미등록)',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          InkWell(
            onTap: () => widget.onSwitchTab(2),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '+ ${mealType.label} 계획 작성',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _getLogsForDate(_selectedDate);
    final dday = calculateDdayString(_selectedDate, widget.birthDate, widget.weaningStartDate);

    // Check which meal types are registered for this day
    final registeredTypes = logs.map((l) => l.mealType).toSet();
    final missingTypes = [MealType.first, MealType.second, MealType.snack].where((m) => !registeredTypes.contains(m)).toList();

    return Column(
      children: [
        const SizedBox(height: 4),
        // 1. 큐브 추가 제안 배너 (기한 임박 큐브 발생 시 부드러운 앰버로 안내)
        _buildRescueBanner(logs),

        // 2. 주간 스트립 캘린더
        _buildWeeklyStripCalendar(),

        // 3. 식단 목록 헤더 (날짜 + 식단 계획 추가 버튼)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedDate.month}월 ${_selectedDate.day}일 (${_getKoreanWeekday(_selectedDate)}) 식단',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  if (dday.isNotEmpty)
                    Text(
                      dday,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: appTextColor),
                    ),
                ],
              ),
              InkWell(
                onTap: () => widget.onSwitchTab(2),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: appPrimaryColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: appPrimaryColor.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 13, color: Colors.white),
                      SizedBox(width: 3),
                      Text('식단 계획 추가', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. 식단 카드 리스트
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            children: [
              ...logs.map((l) => _buildMealCard(l, _getNewIngredients(l))),
              if (missingTypes.isNotEmpty && logs.isNotEmpty) ...[
                const SizedBox(height: 2),
                _buildEmptyMealCard(missingTypes.first),
              ],
              if (logs.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Text('🥣', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      const Text('등록된 식단이 없습니다.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      const Text('아기를 위한 새로운 토핑 식단을 계획해 보세요.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appPrimaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => widget.onSwitchTab(2),
                        child: const Text('식단 계획 작성하기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 3. 큐브 보관함 & 제작 필요 허브 (스마트 보관함)
// ==========================================
class CubeStorageHubTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final List<MealLog> mealLogs;
  final List<TriedIngredient> triedIngredients;
  final Function(CubeItem, int) onUpdateQty;
  final Function(CubeItem) onAddCube;
  final Function(CubeItem, String, FoodCategory, int, int, DateTime, int, String) onEditCube;
  final Function(CubeItem) onDiscardCube;
  final Function(CubeItem) onDeleteCube;
  final Function(CubeItem, int, int, DateTime, int) onRestock;
  final Function(CubeItem, String, FoodCategory, int, String)? onEditPlannedTopping;
  final Function(CubeItem)? onDeletePlannedTopping;

  const CubeStorageHubTab({
    super.key,
    required this.cubes,
    required this.mealLogs,
    required this.triedIngredients,
    required this.onUpdateQty,
    required this.onAddCube,
    required this.onEditCube,
    required this.onDiscardCube,
    required this.onDeleteCube,
    required this.onRestock,
    this.onEditPlannedTopping,
    this.onDeletePlannedTopping,
  });

  @override
  State<CubeStorageHubTab> createState() => _CubeStorageHubTabState();
}

class _CubeStorageHubTabState extends State<CubeStorageHubTab> {
  int _subTabIndex = 0;

  int _computeNeededCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingLogs = widget.mealLogs.where((l) {
      final logDay = DateTime(l.time.year, l.time.month, l.time.day);
      return logDay.isAfter(today) || (logDay.isAtSameMomentAs(today) && l.isPlanned);
    }).toList();

    int count = 0;
    Set<String> counted = {};

    for (var cube in widget.cubes) {
      if (cube.isPlannedOnly) {
        if (!counted.contains(cube.name)) {
          counted.add(cube.name);
          count++;
        }
        continue;
      }
      // 재고 소진(0개) 또는 소비기한 만료
      if (cube.quantity == 0 || cube.daysRemaining < 0) {
        if (!counted.contains(cube.name)) {
          counted.add(cube.name);
          count++;
        }
        continue;
      }
      // 3개 이하 남은 큐브: 제작 필요 알림에 즉시 포함
      if (cube.quantity <= 3) {
        if (!counted.contains(cube.name)) {
          counted.add(cube.name);
          count++;
        }
        continue;
      }
      // 잔여 4개 이상이어도 예정된 식단에서 모두 소진되는 경우
      int simulatedQty = cube.quantity;
      for (var l in upcomingLogs) {
        if (l.cubeUsage.containsKey(cube.id) || l.ingredients.any((ing) => ing.contains(cube.name))) {
          simulatedQty -= (l.cubeUsage[cube.id] ?? 1);
          if (simulatedQty < 1) {
            if (!counted.contains(cube.name)) {
              counted.add(cube.name);
              count++;
            }
            break;
          }
        }
      }
    }

    for (var l in upcomingLogs) {
      for (var ing in l.ingredients) {
        final match = RegExp(r'^(.+?)\s+(\d+)g').firstMatch(ing.trim());
        if (match != null) {
          final pName = match.group(1)!.trim();
          if (!counted.contains(pName)) {
            counted.add(pName);
            count++;
          }
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final neededCount = _computeNeededCount();
    final ownedCount = widget.cubes.where((c) => !c.isPlannedOnly && c.quantity > 0).length;

    return Column(
      children: [
        // Clean Sub-Tab Segmented Control (보관함 / 제작 필요 - ui_redesign_preview.html)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _subTabIndex = 0),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _subTabIndex == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _subTabIndex == 0 ? [const BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('보관함', style: TextStyle(fontSize: 12, fontWeight: _subTabIndex == 0 ? FontWeight.bold : FontWeight.w600, color: _subTabIndex == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B))),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                          child: Text('$ownedCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _subTabIndex = 1),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _subTabIndex == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _subTabIndex == 1 ? [const BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('제작 필요', style: TextStyle(fontSize: 12, fontWeight: _subTabIndex == 1 ? FontWeight.bold : FontWeight.w600, color: _subTabIndex == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B))),
                        if (neededCount > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: appPrimaryColor, borderRadius: BorderRadius.circular(10)),
                            child: Text('$neededCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _subTabIndex,
            children: [
              CubeStockTab(
                cubes: widget.cubes,
                mealLogs: widget.mealLogs,
                neededCount: neededCount,
                onGoToNeeded: () => setState(() => _subTabIndex = 1),
                onUpdateQty: widget.onUpdateQty,
                onAddCube: widget.onAddCube,
                onEditCube: widget.onEditCube,
                onDiscardCube: widget.onDiscardCube,
                onDeleteCube: widget.onDeleteCube,
              ),
              RestockPlanTab(
                cubes: widget.cubes,
                mealLogs: widget.mealLogs,
                triedIngredients: widget.triedIngredients,
                onRestock: widget.onRestock,
                onEditPlannedTopping: widget.onEditPlannedTopping,
                onDeletePlannedTopping: widget.onDeletePlannedTopping,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 2열 트레이 그리드 보관함 뷰 (CubeStockTab)
class CubeStockTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final List<MealLog> mealLogs;
  final int neededCount;
  final VoidCallback onGoToNeeded;
  final Function(CubeItem, int) onUpdateQty;
  final Function(CubeItem) onAddCube;
  final Function(CubeItem, String, FoodCategory, int, int, DateTime, int, String) onEditCube;
  final Function(CubeItem) onDiscardCube;
  final Function(CubeItem) onDeleteCube;

  const CubeStockTab({
    super.key,
    required this.cubes,
    required this.mealLogs,
    required this.neededCount,
    required this.onGoToNeeded,
    required this.onUpdateQty,
    required this.onAddCube,
    required this.onEditCube,
    required this.onDiscardCube,
    required this.onDeleteCube,
  });

  @override
  State<CubeStockTab> createState() => _CubeStockTabState();
}

class _CubeStockTabState extends State<CubeStockTab> {
  FoodCategory? _selCat;

  void _showAddDialog() {
    final nCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '10');
    final qtyCtrl = TextEditingController(text: '6');
    FoodCategory cat = FoodCategory.vegetable;
    DateTime mDate = DateTime.now();
    int shelfDays = 14;
    String selectedSubOption = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('새 큐브 등록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nCtrl, decoration: const InputDecoration(labelText: '식재료명 (예: 감자, 닭고기)')),
                const SizedBox(height: 10),
                DropdownButtonFormField<FoodCategory>(
                  value: cat,
                  decoration: const InputDecoration(labelText: '카테고리'),
                  items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setDState(() {
                    cat = v!;
                    selectedSubOption = '';
                  }),
                ),
                if (cat == FoodCategory.grain) ...[
                  const SizedBox(height: 10),
                  Text('배죽 옵션 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kGrainPorridgeOptions.map((opt) {
                      final isSel = selectedSubOption == opt;
                      return ChoiceChip(
                        label: Text(opt, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: appPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onSelected: (val) => setDState(() => selectedSubOption = val ? opt : ''),
                      );
                    }).toList(),
                  ),
                ] else if (cat == FoodCategory.meat) ...[
                  const SizedBox(height: 10),
                  Text('부위 옵션 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kMeatCutOptions.map((opt) {
                      final isSel = selectedSubOption == opt;
                      return ChoiceChip(
                        label: Text(opt, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: appPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onSelected: (val) => setDState(() => selectedSubOption = val ? opt : ''),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '1개 용량 (g)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '만든 개수'))),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: shelfDays,
                  decoration: const InputDecoration(labelText: '보관 기한'),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3일 (냉장)')),
                    DropdownMenuItem(value: 7, child: Text('7일 (1주일 권장)')),
                    DropdownMenuItem(value: 14, child: Text('14일 (2주)')),
                  ],
                  onChanged: (v) => setDState(() => shelfDays = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('제조일: ${mDate.month}.${mDate.day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: const Text('날짜 변경'),
                      onPressed: () async {
                        final p = await showDatePicker(context: context, initialDate: mDate, firstDate: DateTime.now().subtract(const Duration(days: 60)), lastDate: DateTime.now());
                        if (p != null) setDState(() => mDate = p);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
              onPressed: () {
                if (nCtrl.text.trim().isEmpty) return;
                widget.onAddCube(CubeItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nCtrl.text.trim(),
                  category: cat,
                  unitWeight: int.tryParse(weightCtrl.text) ?? 10,
                  quantity: int.tryParse(qtyCtrl.text) ?? 6,
                  madeDate: mDate,
                  expireDate: mDate.add(Duration(days: shelfDays)),
                  subOption: selectedSubOption,
                  isPlannedOnly: false,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(CubeItem c) {
    final nCtrl = TextEditingController(text: c.name);
    final weightCtrl = TextEditingController(text: '${c.unitWeight}');
    final qtyCtrl = TextEditingController(text: '${c.quantity}');
    FoodCategory cat = c.category;
    DateTime mDate = c.madeDate;
    int shelfDays = c.expireDate.difference(c.madeDate).inDays;
    if (shelfDays < 3) shelfDays = 3;
    if (shelfDays != 3 && shelfDays != 7 && shelfDays != 14) shelfDays = 14;
    String selectedSubOption = c.subOption;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${c.name} 큐브 수정', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nCtrl, decoration: const InputDecoration(labelText: '식재료명')),
                const SizedBox(height: 10),
                DropdownButtonFormField<FoodCategory>(
                  value: cat,
                  decoration: const InputDecoration(labelText: '카테고리'),
                  items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setDState(() {
                    cat = v!;
                    selectedSubOption = '';
                  }),
                ),
                if (cat == FoodCategory.grain) ...[
                  const SizedBox(height: 10),
                  Text('배죽 옵션 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kGrainPorridgeOptions.map((opt) {
                      final isSel = selectedSubOption == opt;
                      return ChoiceChip(
                        label: Text(opt, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: appPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onSelected: (val) => setDState(() => selectedSubOption = val ? opt : ''),
                      );
                    }).toList(),
                  ),
                ] else if (cat == FoodCategory.meat) ...[
                  const SizedBox(height: 10),
                  Text('부위 옵션 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kMeatCutOptions.map((opt) {
                      final isSel = selectedSubOption == opt;
                      return ChoiceChip(
                        label: Text(opt, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: appPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onSelected: (val) => setDState(() => selectedSubOption = val ? opt : ''),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '1개 용량 (g)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '현재 잔여 수량'))),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: shelfDays,
                  decoration: const InputDecoration(labelText: '보관 기한'),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3일 (냉장)')),
                    DropdownMenuItem(value: 7, child: Text('7일 (1주일 권장)')),
                    DropdownMenuItem(value: 14, child: Text('14일 (2주)')),
                  ],
                  onChanged: (v) => setDState(() => shelfDays = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('제조일: ${mDate.month}.${mDate.day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: const Text('날짜 변경'),
                      onPressed: () async {
                        final p = await showDatePicker(context: context, initialDate: mDate, firstDate: DateTime.now().subtract(const Duration(days: 60)), lastDate: DateTime.now());
                        if (p != null) setDState(() => mDate = p);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
              onPressed: () {
                if (nCtrl.text.trim().isEmpty) return;
                widget.onEditCube(c, nCtrl.text.trim(), cat, int.tryParse(weightCtrl.text) ?? c.unitWeight, int.tryParse(qtyCtrl.text) ?? c.quantity, mDate, shelfDays, selectedSubOption);
                Navigator.pop(ctx);
              },
              child: const Text('수정 완료'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCubeOptionDialog(CubeItem c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(getFoodEmoji(c.name), style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('${c.displayName} 관리', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF475569)),
                title: const Text('정보 수정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('수량, 용량, 배죽/부위 옵션 수정', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(c);
                },
              ),
              if (c.quantity > 0 && !c.isPlannedOnly)
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFE53935)),
                  title: const Text('기한만료 폐기 (재고 0개 처리)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
                  subtitle: const Text('재고를 0으로 만들고 [제작 필요]로 자동 연동', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onDiscardCube(c);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('보관함에서 완전히 삭제', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onDeleteCube(c);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2열 트레이 그리드 카드 빌더 (ui_redesign_preview.html)
  Widget _buildCubeGridCard(CubeItem c) {
    final isUnownedOrDiscarded = c.isPlannedOnly || c.quantity == 0;
    final isExpiring = !isUnownedOrDiscarded && c.daysRemaining >= 0 && c.daysRemaining <= 3;
    final isLowStock = !isUnownedOrDiscarded && c.quantity <= 3;
    final emoji = getFoodEmoji(c.name);

    final totalDots = (c.quantity > 6) ? c.quantity : 6;
    final filledDots = c.quantity.clamp(0, totalDots);

    return InkWell(
      onTap: () => _showCubeOptionDialog(c),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isExpiring ? const Color(0xFFFFF5F5) : (isLowStock ? const Color(0xFFFFFBEB) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpiring
                ? const Color(0xFFFCA5A5)
                : (isLowStock ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
            width: (isExpiring || isLowStock) ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isExpiring ? const Color(0xFF7F1D1D) : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpiring)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          '● ${c.dDayText} 임박',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                        ),
                      )
                    else if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          '⚠️ 잔여 ${c.quantity}개',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                      )
                    else if (c.subOption.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: appLightAccentColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: appPrimaryColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          c.subOption,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: appTextColor),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.category.label,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.unitWeight}g · ${c.dDayText}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isExpiring ? const Color(0xFFDC2626).withOpacity(0.85) : const Color(0xFF94A3B8),
                    fontWeight: isExpiring ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),

            // 트레이 시각화 도트 (사각 큐브 트레이 형태)
            Row(
              children: List.generate(totalDots > 8 ? 8 : totalDots, (idx) {
                final isFilled = idx < filledDots;
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? (isExpiring ? const Color(0xFFEF4444) : appPrimaryColor)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                );
              }),
            ),

            // 하단: 수량 표시 및 증감 스텝퍼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${c.quantity}개 (${c.quantity * c.unitWeight}g)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isExpiring ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
                  ),
                ),
                if (isExpiring)
                  InkWell(
                    onTap: () => _showCubeOptionDialog(c),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('식단 추가', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                else if (isUnownedOrDiscarded)
                  InkWell(
                    onTap: () => _showEditDialog(c),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('관리', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => widget.onUpdateQty(c, -1),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text('-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => widget.onUpdateQty(c, 1),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text('+', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // + 새 큐브 추가 카드 (점선 그리드 아이템)
  Widget _buildAddCubeGridCard() {
    return InkWell(
      onTap: _showAddDialog,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+ 새 큐브', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            SizedBox(height: 2),
            Text('배죽/부위 옵션', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildCatFilterChip(FoodCategory? cat, String label) {
    final isSel = _selCat == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selCat = cat),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? appPrimaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSel ? appPrimaryColor : const Color(0xFFE2E8F0)),
            boxShadow: isSel ? [BoxShadow(color: appPrimaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              color: isSel ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 4. 보관함 페이지에서는 현재 제작되어 실제 보유 중인 큐브(!isPlannedOnly && quantity > 0)만 노출
    // (식단계획에 있는 미제작 식재료는 보여주지 않고, 제작 완료 버튼이 눌리면 그 때 나타남)
    final ownedCubes = widget.cubes.where((c) => !c.isPlannedOnly && c.quantity > 0).toList();
    final filtered = _selCat == null ? ownedCubes : ownedCubes.where((c) => c.category == _selCat).toList();

    filtered.sort((a, b) {
      return a.daysRemaining.compareTo(b.daysRemaining);
    });

    final totalOwned = ownedCubes.length;

    return Column(
      children: [
        // 1. 제작 필요 큐브 존재 시 알림 배너
        if (widget.neededCount > 0)
          InkWell(
            onTap: widget.onGoToNeeded,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: appLightAccentColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: appPrimaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.neededCount}가지 큐브 제작 필요',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appTextColor),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '내일/모레 식단을 위해 미리 만들어두세요.',
                          style: TextStyle(fontSize: 10, color: appTextColor.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: appPrimaryColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '목록 보기 →',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appTextColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 2. 카테고리 필터 칩 (이모지 없이 미니멀한 텍스트 칩 - ui_redesign_preview.html)
        Container(
          height: 34,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCatFilterChip(null, '전체 ($totalOwned)'),
              _buildCatFilterChip(FoodCategory.grain, '곡류'),
              _buildCatFilterChip(FoodCategory.meat, '육류'),
              _buildCatFilterChip(FoodCategory.vegetable, '채소'),
              _buildCatFilterChip(FoodCategory.fruit, '과일'),
              _buildCatFilterChip(FoodCategory.etc, '기타'),
            ],
          ),
        ),

        // 3. 2열 트레이 그리드 뷰 (2-Column Storage Grid)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.90,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filtered.length + 1,
            itemBuilder: (ctx, i) {
              if (i == filtered.length) {
                return _buildAddCubeGridCard();
              }
              final c = filtered[i];
              return _buildCubeGridCard(c);
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 4. 제작 필요 화면 (RestockPlanTab)
// ==========================================
enum RestockFilter { all, owned, unowned }

class RestockPlanTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final List<MealLog> mealLogs;
  final List<TriedIngredient> triedIngredients;
  final Function(CubeItem, int, int, DateTime, int) onRestock;
  final Function(CubeItem, String, FoodCategory, int, String)? onEditPlannedTopping;
  final Function(CubeItem)? onDeletePlannedTopping;

  const RestockPlanTab({
    super.key,
    required this.cubes,
    required this.mealLogs,
    required this.triedIngredients,
    required this.onRestock,
    this.onEditPlannedTopping,
    this.onDeletePlannedTopping,
  });

  @override
  State<RestockPlanTab> createState() => _RestockPlanTabState();
}

class _RestockPlanTabState extends State<RestockPlanTab> {
  RestockFilter _filter = RestockFilter.all;

  void _showRestockDialog(CubeItem c) {
    final weightCtrl = TextEditingController(text: '${c.unitWeight}');
    final qtyCtrl = TextEditingController(text: '6');
    DateTime mDate = DateTime.now();
    int shelfDays = 14;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${c.displayName} 제작 완료 등록', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.isPlannedOnly ? '식단 계획을 위해 등록했던 재료입니다. 제작 정보를 입력하면 보관함의 실물 큐브로 등록됩니다.' : '새로 제작한 정보를 입력하면 보관함 재고와 소비기한이 갱신됩니다.', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '1개 용량 (g)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '만든 개수'))),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: shelfDays,
                  decoration: const InputDecoration(labelText: '보관 기한'),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3일 (냉장)')),
                    DropdownMenuItem(value: 7, child: Text('7일 (1주일 권장)')),
                    DropdownMenuItem(value: 14, child: Text('14일 (2주)')),
                  ],
                  onChanged: (v) => setDState(() => shelfDays = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('제조일: ${mDate.month}.${mDate.day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: const Text('날짜 변경'),
                      onPressed: () async {
                        final p = await showDatePicker(context: context, initialDate: mDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now());
                        if (p != null) setDState(() => mDate = p);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
              onPressed: () {
                final w = int.tryParse(weightCtrl.text) ?? c.unitWeight;
                final q = int.tryParse(qtyCtrl.text) ?? 6;
                widget.onRestock(c, w, q, mDate, shelfDays);
                Navigator.pop(ctx);
              },
              child: const Text('보관함에 반영'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlannedDialog(CubeItem c) {
    final nCtrl = TextEditingController(text: c.name);
    final weightCtrl = TextEditingController(text: '${c.unitWeight}');
    FoodCategory cat = c.category;
    String selectedSubOption = c.subOption;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${c.displayName} 수정', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nCtrl, decoration: const InputDecoration(labelText: '식재료명')),
                const SizedBox(height: 10),
                DropdownButtonFormField<FoodCategory>(
                  value: cat,
                  decoration: const InputDecoration(labelText: '카테고리'),
                  items: FoodCategory.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(),
                  onChanged: (v) => setDState(() {
                    cat = v!;
                    selectedSubOption = '';
                  }),
                ),
                if (cat == FoodCategory.grain) ...[
                  const SizedBox(height: 10),
                  Text('배죽 옵션 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kGrainPorridgeOptions.map((opt) {
                      final isSel = selectedSubOption == opt;
                      return ChoiceChip(
                        label: Text(opt, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: appPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onSelected: (val) => setDState(() => selectedSubOption = val ? opt : ''),
                      );
                    }).toList(),
                  ),
                ] else if (cat == FoodCategory.meat) ...[
                  const SizedBox(height: 10),
                  Text('부위 옵션 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kMeatCutOptions.map((opt) {
                      final isSel = selectedSubOption == opt;
                      return ChoiceChip(
                        label: Text(opt, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: appPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onSelected: (val) => setDState(() => selectedSubOption = val ? opt : ''),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '1개 용량 (g)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
              onPressed: () {
                final newName = nCtrl.text.trim();
                if (newName.isEmpty) return;
                final newWeight = int.tryParse(weightCtrl.text) ?? c.unitWeight;
                widget.onEditPlannedTopping?.call(c, newName, cat, newWeight, selectedSubOption);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✨ $newName 정보가 수정되었습니다.'), backgroundColor: appPrimaryColor),
                );
              },
              child: const Text('수정 저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePlanned(CubeItem c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('토핑 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          '\'${c.displayName}\' 토핑을 삭제하시겠습니까?\n\n제작 필요 목록에서 제거되며, 예정된 식단 계획에서도 이 식재료가 함께 제외됩니다.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              widget.onDeletePlannedTopping?.call(c);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ ${c.displayName} 토핑이 삭제되었습니다.'), backgroundColor: const Color(0xFFEF4444)),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _simulateBatchRestock(List<_PlanDisplayItem> items) {
    for (var item in items) {
      widget.onRestock(item.cube, item.cube.unitWeight, 6, DateTime.now(), 14);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 총 ${items.length}가지 큐브가 보관함에 6개씩 일괄 등록되었습니다!'),
        backgroundColor: appPrimaryColor,
      ),
    );
  }

  Widget _buildFilterButton(String label, RestockFilter filter) {
    final isSel = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? appPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? appPrimaryColor : const Color(0xFFE2E8F0)),
          boxShadow: isSel ? [BoxShadow(color: appPrimaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingLogs = widget.mealLogs.where((l) {
      final logDay = DateTime(l.time.year, l.time.month, l.time.day);
      final isFutureDay = logDay.isAfter(today);
      final isTodayUncompleted = logDay.isAtSameMomentAs(today) && l.isPlanned;
      return isFutureDay || isTodayUncompleted;
    }).toList()..sort((a, b) => a.time.compareTo(b.time));

    List<_PlanDisplayItem> items = [];
    Set<String> processedNames = {};

    for (var cube in widget.cubes) {
      processedNames.add(cube.name);

      List<MealLog> matchedLogs = [];
      for (var l in upcomingLogs) {
        final usesById = l.cubeUsage.containsKey(cube.id);
        final usesByName = l.ingredients.any((ing) => ing.contains(cube.name));
        if (usesById || usesByName) {
          matchedLogs.add(l);
        }
      }

      final isFirst = !checkIsTriedIngredient(
        name: cube.name,
        triedIngredients: widget.triedIngredients,
        mealLogs: widget.mealLogs,
        cubes: widget.cubes,
      );

      if (cube.isPlannedOnly) {
        final targetDate = matchedLogs.isNotEmpty ? matchedLogs.first.time : null;
        final dl = targetDate != null ? '${targetDate.month}월 ${targetDate.day}일' : '식단 전';
        items.add(_PlanDisplayItem(
          cube: cube,
          urgency: '신규 필요',
          deadline: dl,
          color: appPrimaryColor,
          score: targetDate != null ? targetDate.difference(today).inDays : 999,
          isUnowned: true,
          isFirstTry: isFirst,
        ));
        continue;
      }

      final curQty = cube.quantity;
      final isExpired = cube.daysRemaining < 0;

      if (curQty == 0) {
        final nextUse = matchedLogs.isNotEmpty ? matchedLogs.first.time : null;
        final dl = nextUse != null ? '${nextUse.month}월 ${nextUse.day}일' : '식단 예정 없음';
        items.add(_PlanDisplayItem(
          cube: cube,
          urgency: '재고 소진',
          deadline: dl,
          color: const Color(0xFFE53935),
          score: nextUse != null ? nextUse.difference(today).inDays : 900,
          isUnowned: true,
          isFirstTry: isFirst,
        ));
        continue;
      }

      if (isExpired) {
        final nextUse = matchedLogs.isNotEmpty ? matchedLogs.first.time : null;
        final dl = nextUse != null ? '${nextUse.month}월 ${nextUse.day}일' : '소비기한 만료';
        items.add(_PlanDisplayItem(
          cube: cube,
          urgency: '소비기한 만료',
          deadline: dl,
          color: const Color(0xFFE65100),
          score: nextUse != null ? nextUse.difference(today).inDays : 100,
          isUnowned: false,
          isFirstTry: isFirst,
        ));
        continue;
      }

      // 3개 이하 남은 큐브: 예정된 식단 유무와 상관없이 무조건 제작 필요 목록에 포함!
      if (curQty <= 3) {
        int simulatedQty = curQty;
        DateTime? outOfStockDate;
        DateTime? nextUseDate = matchedLogs.isNotEmpty ? matchedLogs.first.time : null;

        for (var l in upcomingLogs) {
          if (l.cubeUsage.containsKey(cube.id) || l.ingredients.any((ing) => ing.contains(cube.name))) {
            int count = l.cubeUsage[cube.id] ?? 1;
            simulatedQty -= count;
            if (simulatedQty < 1) {
              outOfStockDate = l.time;
              break;
            }
          }
        }

        final deadlineStr = outOfStockDate != null
            ? '${outOfStockDate.month}월 ${outOfStockDate.day}일 소진 예정 (잔여 ${curQty}개)'
            : (nextUseDate != null
                ? '${nextUseDate.month}월 ${nextUseDate.day}일 식단 예정 (잔여 ${curQty}개)'
                : '보관함 잔여 ${curQty}개 (미리 제작 권장)');

        items.add(_PlanDisplayItem(
          cube: cube,
          urgency: outOfStockDate != null ? '소진 임박' : '수량 부족 (잔여 ${curQty}개)',
          deadline: deadlineStr,
          color: outOfStockDate != null ? const Color(0xFFE53935) : const Color(0xFFF59F00),
          score: outOfStockDate != null
              ? outOfStockDate.difference(today).inDays
              : (nextUseDate != null ? nextUseDate.difference(today).inDays : 50),
          isUnowned: false,
          isFirstTry: isFirst,
        ));
        continue;
      }

      // 잔여 4개 이상이어도 예정된 식단에서 소진되는 경우
      int simulatedQty = curQty;
      DateTime? outOfStockDate;
      for (var l in upcomingLogs) {
        if (l.cubeUsage.containsKey(cube.id) || l.ingredients.any((ing) => ing.contains(cube.name))) {
          int count = l.cubeUsage[cube.id] ?? 1;
          simulatedQty -= count;
          if (simulatedQty < 1) {
            outOfStockDate = l.time;
            break;
          }
        }
      }
      if (outOfStockDate != null) {
        items.add(_PlanDisplayItem(
          cube: cube,
          urgency: '소진 예정',
          deadline: '${outOfStockDate.month}월 ${outOfStockDate.day}일 소진 예정 (잔여 ${curQty}개)',
          color: const Color(0xFFE53935),
          score: outOfStockDate.difference(today).inDays,
          isUnowned: false,
          isFirstTry: isFirst,
        ));
      }
    }

    for (var l in upcomingLogs) {
      for (var ingStr in l.ingredients) {
        final match = RegExp(r'^(.+?)\s+(\d+)g').firstMatch(ingStr.trim());
        if (match != null) {
          final parsedName = match.group(1)!.trim();
          if (!processedNames.contains(parsedName)) {
            processedNames.add(parsedName);

            final parsedGrams = int.tryParse(match.group(2)!) ?? 10;
            final cntMatch = RegExp(r'\((\d+)개\)').firstMatch(ingStr);
            final cnt = cntMatch != null ? (int.tryParse(cntMatch.group(1)!) ?? 1) : 1;
            final unitW = cnt > 0 ? (parsedGrams ~/ cnt) : parsedGrams;

            final triedInfo = widget.triedIngredients.firstWhere(
              (t) => t.name == parsedName,
              orElse: () => TriedIngredient(name: parsedName, category: guessCategoryByName(parsedName), lastUnitWeight: unitW),
            );

            final virtualCube = CubeItem(
              id: 'virtual_${parsedName}_${l.time.millisecondsSinceEpoch}',
              name: parsedName,
              category: triedInfo.category,
              unitWeight: unitW,
              quantity: 0,
              madeDate: DateTime.now(),
              expireDate: DateTime.now().add(const Duration(days: 14)),
              isPlannedOnly: true,
            );

            final isFirstVirtual = !checkIsTriedIngredient(
              name: parsedName,
              triedIngredients: widget.triedIngredients,
              mealLogs: widget.mealLogs,
              cubes: widget.cubes,
            );

            items.add(_PlanDisplayItem(
              cube: virtualCube,
              urgency: '식단 예정',
              deadline: '${l.time.month}월 ${l.time.day}일',
              color: appPrimaryColor,
              score: l.time.difference(today).inDays,
              isUnowned: true,
              isFirstTry: isFirstVirtual,
            ));
          }
        }
      }
    }

    items.sort((a, b) => a.score.compareTo(b.score));

    final filteredItems = items.where((i) {
      if (_filter == RestockFilter.owned) return !i.isUnowned;
      if (_filter == RestockFilter.unowned) return i.isUnowned;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter pills
          Row(
            children: [
              _buildFilterButton('전체', RestockFilter.all),
              const SizedBox(width: 6),
              _buildFilterButton('보유', RestockFilter.owned),
              const SizedBox(width: 6),
              _buildFilterButton('미보유', RestockFilter.unowned),
            ],
          ),
          const SizedBox(height: 10),

          // Header Box with Total Count & Batch Restock Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('총 ${filteredItems.length}가지 큐브 제작 필요', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A))),
                    const SizedBox(height: 1),
                    const Text('예정된 식단 일정순 자동 정렬', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
                if (filteredItems.isNotEmpty)
                  InkWell(
                    onTap: () => _simulateBatchRestock(filteredItems),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('전체 일괄 등록', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // List of Restock Items (ui_redesign_preview.html)
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text('해당하는 큐브가 없습니다! 🎉', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (ctx, i) {
                      final item = filteredItems[i];
                      final c = item.cube;
                      final emoji = getFoodEmoji(c.name);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.isUnowned ? appPrimaryColor.withOpacity(0.5) : const Color(0xFFE2E8F0),
                            width: item.isUnowned ? 1.5 : 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                c.displayName,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: item.isFirstTry ? appPrimaryColor : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.isFirstTry ? '첫 시도' : '기존 식재료',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: item.isFirstTry ? Colors.white : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.deadline} 식단 (${c.unitWeight}g 필요)',
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: item.isUnowned ? appTextColor : const Color(0xFF64748B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _showRestockDialog(c),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: item.isUnowned ? appPrimaryColor : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: item.isUnowned ? null : Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: item.isUnowned
                                          ? [BoxShadow(color: appPrimaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))]
                                          : null,
                                    ),
                                    child: Text(
                                      '제작 완료',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: item.isUnowned ? Colors.white : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF94A3B8)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showEditPlannedDialog(c);
                                    } else if (val == 'delete') {
                                      _confirmDeletePlanned(c);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0F172A)),
                                          SizedBox(width: 8),
                                          Text('토핑 수정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                                          SizedBox(width: 8),
                                          Text('토핑 삭제', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanDisplayItem {
  final CubeItem cube;
  final String? urgency;
  final String deadline;
  final Color color;
  final int score;
  final bool isUnowned;
  final bool isFirstTry;

  _PlanDisplayItem({
    required this.cube,
    this.urgency,
    required this.deadline,
    required this.color,
    required this.score,
    required this.isUnowned,
    required this.isFirstTry,
  });
}
