import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BabyFoodApp());
}

class BabyFoodApp extends StatelessWidget {
  const BabyFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    const mintPrimary = Color(0xFF3EB489);

    return MaterialApp(
      title: '토핑 이유식 매니저',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: mintPrimary,
          primary: mintPrimary,
          secondary: const Color(0xFF5BC0BE),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F9F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF234E42),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

/// 1. 끼니 차수 정의 및 순서
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

  static MealType fromLabel(String label) {
    return MealType.values.firstWhere(
      (m) => m.label == label,
      orElse: () => MealType.first,
    );
  }
}

/// 2. 카테고리 정의
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

  static FoodCategory fromLabel(String label) {
    return FoodCategory.values.firstWhere(
      (c) => c.label == label,
      orElse: () => FoodCategory.etc,
    );
  }
}

/// 식재료명 기반 이모지 매퍼 함수
String getFoodEmoji(String name) {
  final cleanName = name.trim().toLowerCase();
  if (cleanName.contains('쌀') || cleanName.contains('오트밀') || cleanName.contains('보리') || cleanName.contains('퀴노아') || cleanName.contains('현미')) return '🌾';
  if (cleanName.contains('소고기') || cleanName.contains('안심') || cleanName.contains('우둔')) return '🥩';
  if (cleanName.contains('닭') || cleanName.contains('닭가슴살') || cleanName.contains('닭안심')) return '🍗';
  if (cleanName.contains('돼지')) return '🥓';
  if (cleanName.contains('생선') || cleanName.contains('대구') || cleanName.contains('연어')) return '🐟';
  if (cleanName.contains('단호박') || cleanName.contains('호박')) return '🎃';
  if (cleanName.contains('브로콜리')) return '🥦';
  if (cleanName.contains('당근')) return '🥕';
  if (cleanName.contains('애호박') || cleanName.contains('오이')) return '🥒';
  if (cleanName.contains('감자')) return '🥔';
  if (cleanName.contains('고구마')) return '🍠';
  if (cleanName.contains('양배추') || cleanName.contains('배추') || cleanName.contains('청경채')) return '🥬';
  if (cleanName.contains('사과')) return '🍎';
  if (cleanName.contains('배')) return '🍐';
  if (cleanName.contains('바나나')) return '🍌';
  if (cleanName.contains('아보카도')) return '🥑';
  if (cleanName.contains('치즈')) return '🧀';
  if (cleanName.contains('계란') || cleanName.contains('달걀') || cleanName.contains('노른자')) return '🥚';
  if (cleanName.contains('두부') || cleanName.contains('콩') || cleanName.contains('완두콩')) return '🫘';
  if (cleanName.contains('버섯')) return '🍄';
  if (cleanName.contains('토마토')) return '🍅';
  if (cleanName.contains('비트')) return '🫐';
  return '🥄';
}

/// 3. 큐브 데이터 모델
class CubeItem {
  final String id;
  String name;
  FoodCategory category;
  int unitWeight;
  int quantity;
  DateTime madeDate;
  DateTime expireDate;
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
    this.isPlannedOnly = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  int get daysRemaining {
    if (isPlannedOnly) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(expireDate.year, expireDate.month, expireDate.day);
    return expiration.difference(today).inDays;
  }

  String get dDayText {
    if (isPlannedOnly) return '미보유(제작필요)';
    final diff = daysRemaining;
    if (diff < 0) return '만료(D+${-diff})';
    if (diff == 0) return 'D-Day';
    return 'D-$diff';
  }

  Color get statusColor {
    if (isPlannedOnly) return const Color(0xFF9C27B0);
    final diff = daysRemaining;
    if (diff < 0) return const Color(0xFFE53935);
    if (diff <= 2) return const Color(0xFFFB8C00);
    return const Color(0xFF3EB489);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.label,
        'unitWeight': unitWeight,
        'quantity': quantity,
        'madeDate': madeDate.toIso8601String(),
        'expireDate': expireDate.toIso8601String(),
        'isPlannedOnly': isPlannedOnly,
        'createdAt': createdAt,
      };

  factory CubeItem.fromJson(Map<String, dynamic> json) => CubeItem(
        id: json['id'],
        name: json['name'],
        category: FoodCategory.fromLabel(json['category']),
        unitWeight: json['unitWeight'],
        quantity: json['quantity'],
        madeDate: DateTime.parse(json['madeDate']),
        expireDate: DateTime.parse(json['expireDate']),
        isPlannedOnly: json['isPlannedOnly'] ?? false,
        createdAt: json['createdAt'],
      );
}

/// 4. 식단 기록 모델
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

  factory MealLog.fromJson(Map<String, dynamic> json) => MealLog(
        id: json['id'],
        mealType: MealType.fromLabel(json['mealType']),
        time: DateTime.parse(json['time']),
        ingredients: List<String>.from(json['ingredients']),
        cubeUsage: Map<String, int>.from(json['cubeUsage'] ?? {}),
        totalGrams: json['totalGrams'],
        reaction: json['reaction'],
        isPlanned: json['isPlanned'] ?? false,
      );
}

/// 5. 메인 네비게이션 컨테이너
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;
  bool _isLoading = true;

  List<CubeItem> _cubes = [];
  List<MealLog> _mealLogs = [];

  DateTime? _birthDate;
  DateTime? _weaningStartDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final cubesString = prefs.getString('cubes_data');
    final mealsString = prefs.getString('meals_data');
    final birthString = prefs.getString('baby_birth_date');
    final weaningString = prefs.getString('weaning_start_date');

    if (cubesString != null) {
      final List decoded = jsonDecode(cubesString);
      _cubes = decoded.map((item) => CubeItem.fromJson(item)).toList();
    } else {
      final now = DateTime.now();
      _cubes = [
        CubeItem(
          id: '1',
          name: '오트밀쌀죽',
          category: FoodCategory.grain,
          unitWeight: 30,
          quantity: 6,
          madeDate: now.subtract(const Duration(days: 2)),
          expireDate: now.add(const Duration(days: 5)),
          createdAt: 1000,
        ),
        CubeItem(
          id: '2',
          name: '소고기 안심',
          category: FoodCategory.meat,
          unitWeight: 10,
          quantity: 3,
          madeDate: now.subtract(const Duration(days: 3)),
          expireDate: now.add(const Duration(days: 4)),
          createdAt: 2000,
        ),
      ];
    }

    if (mealsString != null) {
      final List decoded = jsonDecode(mealsString);
      _mealLogs = decoded.map((item) => MealLog.fromJson(item)).toList();
    } else {
      _mealLogs = [];
    }

    if (birthString != null) {
      _birthDate = DateTime.parse(birthString);
    } else {
      _birthDate = DateTime.now().subtract(const Duration(days: 180));
    }

    if (weaningString != null) {
      _weaningStartDate = DateTime.parse(weaningString);
    } else {
      _weaningStartDate = DateTime.now().subtract(const Duration(days: 20));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final cubesJson = jsonEncode(_cubes.map((c) => c.toJson()).toList());
    final mealsJson = jsonEncode(_mealLogs.map((m) => m.toJson()).toList());

    await prefs.setString('cubes_data', cubesJson);
    await prefs.setString('meals_data', mealsJson);
    if (_birthDate != null) {
      await prefs.setString('baby_birth_date', _birthDate!.toIso8601String());
    }
    if (_weaningStartDate != null) {
      await prefs.setString('weaning_start_date', _weaningStartDate!.toIso8601String());
    }
  }

  void _showSettingsDialog() {
    DateTime tempBirth = _birthDate ?? DateTime.now().subtract(const Duration(days: 180));
    DateTime tempWeaning = _weaningStartDate ?? DateTime.now().subtract(const Duration(days: 15));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('아기 성장 & 이유식 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake_outlined, color: Color(0xFF3EB489)),
                    title: const Text('아기 출생일', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${tempBirth.year}년 ${tempBirth.month}월 ${tempBirth.day}일',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    trailing: OutlinedButton(
                      child: const Text('변경'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempBirth,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempBirth = picked);
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restaurant_outlined, color: Color(0xFF2E7D32)),
                    title: const Text('이유식 시작일', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${tempWeaning.year}년 ${tempWeaning.month}월 ${tempWeaning.day}일',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    trailing: OutlinedButton(
                      child: const Text('변경'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempWeaning,
                          firstDate: tempBirth,
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setDialogState(() => tempWeaning = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
                  onPressed: () {
                    setState(() {
                      _birthDate = tempBirth;
                      _weaningStartDate = tempWeaning;
                    });
                    _saveData();
                    Navigator.pop(ctx);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateQuantity(CubeItem cube, int delta) {
    setState(() {
      final newQty = cube.quantity + delta;
      if (newQty >= 0) cube.quantity = newQty;
    });
    _saveData();
  }

  void _addNewCube(CubeItem cube) {
    setState(() {
      _cubes.insert(0, cube);
    });
    _saveData();
  }

  void _editCube(CubeItem targetCube, String newName, FoodCategory newCategory, int newUnitWeight, int newQuantity, DateTime newMadeDate, int newShelfLifeDays) {
    setState(() {
      targetCube.name = newName;
      targetCube.category = newCategory;
      targetCube.unitWeight = newUnitWeight;
      targetCube.quantity = newQuantity;
      targetCube.madeDate = newMadeDate;
      targetCube.expireDate = newMadeDate.add(Duration(days: newShelfLifeDays));
      targetCube.isPlannedOnly = false;
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${targetCube.name} 큐브 정보가 수정되었습니다.')),
    );
  }

  void _deleteCube(CubeItem targetCube) {
    setState(() {
      _cubes.removeWhere((c) => c.id == targetCube.id);
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${targetCube.name} 큐브가 삭제되었습니다.')),
    );
  }

  void _restockCube(CubeItem cube, int addedQty, DateTime madeDate, int newShelfLifeDays) {
    setState(() {
      cube.quantity += addedQty;
      cube.madeDate = madeDate;
      cube.expireDate = madeDate.add(Duration(days: newShelfLifeDays));
      cube.isPlannedOnly = false;
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cube.name} 큐브 ${addedQty}개 보충 완료!'),
        backgroundColor: const Color(0xFF3EB489),
      ),
    );
  }

  void _addMealRecord({
    required MealType mealType,
    required DateTime startDate,
    required int repeatDays,
    required Map<CubeItem, int> selectedCubes,
    required String reaction,
  }) {
    setState(() {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      List<String> ingredientSummaries = [];
      Map<String, int> cubeUsageMap = {};
      int totalWeight = 0;

      selectedCubes.forEach((cube, count) {
        if (count > 0) {
          final weight = cube.unitWeight * count;
          totalWeight += weight;
          ingredientSummaries.add('${cube.name} ${weight}g (${count}개)');
          cubeUsageMap[cube.id] = count;
        }
      });

      for (int i = 0; i < repeatDays; i++) {
        final currentDate = startDate.add(Duration(days: i));
        final recordMidnight = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final isFuturePlan = recordMidnight.isAfter(todayMidnight);

        if (!isFuturePlan && repeatDays == 1) {
          selectedCubes.forEach((cube, count) {
            if (!cube.isPlannedOnly && count > 0) {
              cube.quantity = (cube.quantity - count).clamp(0, 999);
            }
          });
        }

        final memoText = reaction.isEmpty
            ? (repeatDays > 1 ? '[${i + 1}/$repeatDays일차 계획]' : (isFuturePlan ? '[예정] 식단 계획' : '특이사항 없음'))
            : (repeatDays > 1 ? '[$repeatDays일 연속] $reaction' : reaction);

        _mealLogs.insert(
          0,
          MealLog(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            mealType: mealType,
            time: currentDate,
            ingredients: List.from(ingredientSummaries),
            cubeUsage: Map.from(cubeUsageMap),
            totalGrams: totalWeight,
            reaction: memoText,
            isPlanned: isFuturePlan || repeatDays > 1,
          ),
        );
      }
    });
    _saveData();

    final endDay = startDate.add(Duration(days: repeatDays - 1));
    final msg = repeatDays > 1
        ? '${startDate.month}/${startDate.day} ~ ${endDay.month}/${endDay.day} ($repeatDays일간) [${mealType.label}] 계획 등록 완료!'
        : '${startDate.month}/${startDate.day} [${mealType.label}] 저장 완료!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF3EB489),
      ),
    );
  }

  void _completePlannedMeal(MealLog log) {
    setState(() {
      log.cubeUsage.forEach((cubeId, count) {
        final matchIndex = _cubes.indexWhere((c) => c.id == cubeId);
        if (matchIndex != -1) {
          final cube = _cubes[matchIndex];
          cube.quantity = (cube.quantity - count).clamp(0, 999);
        }
      });

      log.isPlanned = false;
      if (log.reaction.startsWith('[예정]') || log.reaction.contains('계획')) {
        log.reaction = '완식 (식사 완료)';
      }
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('[${log.mealType.label}] 식사 완료! 큐브가 차감되었습니다.'),
        backgroundColor: const Color(0xFF3EB489),
      ),
    );
  }

  void _editMealRecord(MealLog log, MealType newType, DateTime newTime, String newReaction, int newTotalGrams) {
    setState(() {
      log.mealType = newType;
      log.time = newTime;
      log.reaction = newReaction;
      log.totalGrams = newTotalGrams;
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('식단 기록이 수정되어 저장되었습니다.')),
    );
  }

  void _updateMealReaction(MealLog log, String updatedReaction) {
    setState(() {
      log.reaction = updatedReaction;
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('아기 반응 및 상태가 저장되었습니다.'),
        backgroundColor: Color(0xFF3EB489),
      ),
    );
  }

  void _deleteMealRecord(MealLog log) {
    setState(() {
      if (!log.isPlanned) {
        log.cubeUsage.forEach((cubeId, count) {
          final matchIndex = _cubes.indexWhere((c) => c.id == cubeId);
          if (matchIndex != -1 && !_cubes[matchIndex].isPlannedOnly) {
            _cubes[matchIndex].quantity += count;
          }
        });
      }
      _mealLogs.removeWhere((l) => l.id == log.id);
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!log.isPlanned
            ? '기록이 삭제되고 큐브 재고가 복원되었습니다.'
            : '식단 계획이 삭제되었습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3EB489)),
        ),
      );
    }

    final restockCount = _cubes.where((c) => c.isPlannedOnly || c.quantity <= 2 || c.daysRemaining < 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.eco_rounded, color: Color(0xFF3EB489), size: 22),
            SizedBox(width: 6),
            Text('토핑 이유식 매니저', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF234E42))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF234E42)),
            tooltip: '아기 정보 & D-day 설정',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          MealLogTab(
            cubes: _cubes,
            birthDate: _birthDate,
            weaningStartDate: _weaningStartDate,
            onSaveMeal: _addMealRecord,
            onAddPlannedCube: _addNewCube,
          ),
          MealCalendarTab(
            mealLogs: _mealLogs,
            cubes: _cubes,
            birthDate: _birthDate,
            weaningStartDate: _weaningStartDate,
            onEditMeal: _editMealRecord,
            onDeleteMeal: _deleteMealRecord,
            onCompleteMeal: _completePlannedMeal,
            onUpdateReaction: _updateMealReaction,
          ),
          CubeStockTab(
            cubes: _cubes,
            onUpdateQty: _updateQuantity,
            onAddCube: _addNewCube,
            onEditCube: _editCube,
            onDeleteCube: _deleteCube,
          ),
          RestockPlanTab(
            cubes: _cubes,
            mealLogs: _mealLogs,
            onRestock: _restockCube,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        indicatorColor: const Color(0xFFE8F8F2),
        backgroundColor: Colors.white,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note, color: Color(0xFF3EB489)),
            label: '식단 기록',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF3EB489)),
            label: '캘린더',
          ),
          const NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen, color: Color(0xFF3EB489)),
            label: '보관함',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: restockCount > 0,
              label: Text('$restockCount'),
              backgroundColor: const Color(0xFF3EB489),
              child: const Icon(Icons.alarm_on_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: restockCount > 0,
              label: Text('$restockCount'),
              backgroundColor: const Color(0xFF3EB489),
              child: const Icon(Icons.alarm_on, color: Color(0xFF3EB489)),
            ),
            label: '제작 필요',
          ),
        ],
      ),
    );
  }
}

/// D-Day 계산 헬퍼 함수
String calculateDdayString(DateTime targetDate, DateTime? birthDate, DateTime? weaningStartDate) {
  final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
  List<String> ddays = [];

  if (birthDate != null) {
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final diff = target.difference(birth).inDays + 1;
    if (diff > 0) ddays.add('생후 D+$diff일');
  }

  if (weaningStartDate != null) {
    final weaning = DateTime(weaningStartDate.year, weaningStartDate.month, weaningStartDate.day);
    final diff = target.difference(weaning).inDays + 1;
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

/// ==========================================
/// (1) 식단 기록 화면 (커스텀 버튼으로 글자 잘림 완벽 해결)
/// ==========================================
class MealLogTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final DateTime? birthDate;
  final DateTime? weaningStartDate;
  final Function({
    required MealType mealType,
    required DateTime startDate,
    required int repeatDays,
    required Map<CubeItem, int> selectedCubes,
    required String reaction,
  }) onSaveMeal;
  final Function(CubeItem) onAddPlannedCube;

  const MealLogTab({
    super.key,
    required this.cubes,
    required this.birthDate,
    required this.weaningStartDate,
    required this.onSaveMeal,
    required this.onAddPlannedCube,
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

  final List<String> _attitudeTags = ['완식', '거의 다 먹음', '절반 남김', '뱉어냄'];
  final List<String> _skinTags = ['피부 정상', '입주변 붉어짐', '두드러기/발진', '눈 비빔/가려움'];
  final List<String> _stoolTags = ['황금변', '된변', '무른변', '설사'];

  final Set<String> _activeTags = {};

  int get _repeatDays {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    return end.difference(start).inDays + 1;
  }

  bool get _isFutureDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_startDate.year, _startDate.month, _startDate.day);
    return target.isAfter(today);
  }

  int _getSelectedCount(CubeItem cube) => _selectedQuantities[cube.id] ?? 0;

  void _modifyCubeSelection(CubeItem cube, int delta) {
    setState(() {
      final current = _getSelectedCount(cube);
      final next = current + delta;
      if (next <= 0) {
        _selectedQuantities.remove(cube.id);
      } else {
        _selectedQuantities[cube.id] = next;
      }
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_activeTags.contains(tag)) {
        _activeTags.remove(tag);
      } else {
        _activeTags.add(tag);
      }
      _reactionController.text = _activeTags.join(', ');
    });
  }

  Future<void> _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3EB489),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF234E42),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
    }
  }

  void _setThreeDaysRange() {
    setState(() {
      _endDate = _startDate.add(const Duration(days: 2));
    });
  }

  void _setSingleDay() {
    setState(() {
      _endDate = _startDate;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showAddUnregisteredCubeDialog() {
    final nameController = TextEditingController();
    final weightController = TextEditingController(text: '10');
    FoodCategory selectedCat = FoodCategory.vegetable;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('새 식재료 직접 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '미보유 식재료를 식단 계획에 배정합니다. 등록 시 [제작 필요] 탭에 자동 알림이 생성됩니다.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '식재료명 (예: 비트, 닭안심, 파프리카)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<FoodCategory>(
                    value: selectedCat,
                    decoration: const InputDecoration(labelText: '카테고리'),
                    items: FoodCategory.values.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '1회 권장량 (g)'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final newCube = CubeItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      category: selectedCat,
                      unitWeight: int.tryParse(weightController.text) ?? 10,
                      quantity: 0,
                      madeDate: DateTime.now(),
                      expireDate: DateTime.now().add(const Duration(days: 7)),
                      isPlannedOnly: true,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    );

                    widget.onAddPlannedCube(newCube);

                    setState(() {
                      _selectedQuantities[newCube.id] = 1;
                    });

                    Navigator.pop(ctx);
                  },
                  child: const Text('식단에 담기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitMeal() {
    if (_selectedQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식단에 배정할 토핑 큐브를 1개 이상 담아주세요.')),
      );
      return;
    }

    final combinedDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Map<CubeItem, int> cubesToApply = {};
    for (var cube in widget.cubes) {
      if (_selectedQuantities.containsKey(cube.id)) {
        cubesToApply[cube] = _selectedQuantities[cube.id]!;
      }
    }

    widget.onSaveMeal(
      mealType: _selectedMealType,
      startDate: combinedDateTime,
      repeatDays: _repeatDays,
      selectedCubes: cubesToApply,
      reaction: _reactionController.text.trim(),
    );

    setState(() {
      _selectedQuantities.clear();
      _reactionController.clear();
      _activeTags.clear();
      _endDate = _startDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentTotalGrams = 0;
    for (var cube in widget.cubes) {
      final count = _getSelectedCount(cube);
      currentTotalGrams += count * cube.unitWeight;
    }

    final isToday = DateTime.now().year == _startDate.year &&
        DateTime.now().month == _startDate.month &&
        DateTime.now().day == _startDate.day;

    final hourStr = _selectedTime.hour.toString().padLeft(2, '0');
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');

    final ddaySummary = calculateDdayString(_startDate, widget.birthDate, widget.weaningStartDate);

    final sortedCubes = List<CubeItem>.from(widget.cubes)
      ..sort((a, b) {
        final catCompare = a.category.sortOrder.compareTo(b.category.sortOrder);
        if (catCompare != 0) return catCompare;
        return a.createdAt.compareTo(b.createdAt);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 날짜 범위 선택 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isFutureDate ? const Color(0xFFF0FDF8) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFutureDate ? const Color(0xFFA7E9D1) : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _repeatDays > 1 ? Icons.date_range : (_isFutureDate ? Icons.next_plan_outlined : Icons.calendar_today_outlined),
                      color: const Color(0xFF3EB489),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _repeatDays > 1
                                ? '$_repeatDays일 연속 동일 식단 플랜'
                                : (isToday ? '오늘 식단 기록' : (_isFutureDate ? '향후 식단 계획 (미래)' : '이전 날짜 소급 기록 (과거)')),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _repeatDays > 1 ? const Color(0xFF3EB489) : (_isFutureDate ? const Color(0xFF267D5E) : Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _repeatDays > 1
                                ? '${_startDate.month}/${_startDate.day} ~ ${_endDate.month}/${_endDate.day} ($_repeatDays일간)'
                                : '${_startDate.year}년 ${_startDate.month}월 ${_startDate.day}일',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF234E42)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.calendar_month, size: 15),
                      label: const Text('기간 달력', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F8F2),
                        foregroundColor: const Color(0xFF234E42),
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // (1) 빠른 설정 버튼: Chip 제거 및 커스텀 컨테이너로 글자 잘림 완벽 해결
                Row(
                  children: [
                    Text('빠른 설정: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    const SizedBox(width: 8),
                    // '하루만' 버튼
                    InkWell(
                      onTap: _setSingleDay,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _repeatDays == 1 ? const Color(0xFF3EB489) : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _repeatDays == 1 ? const Color(0xFF3EB489) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '하루만',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _repeatDays == 1 ? FontWeight.bold : FontWeight.w500,
                            color: _repeatDays == 1 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // '3일 테스트' 버튼
                    InkWell(
                      onTap: _setThreeDaysRange,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _repeatDays == 3 ? const Color(0xFF3EB489) : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _repeatDays == 3 ? const Color(0xFF3EB489) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, size: 14, color: _repeatDays == 3 ? Colors.white : Colors.amber.shade800),
                            const SizedBox(width: 4),
                            Text(
                              '3일 테스트',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _repeatDays == 3 ? FontWeight.bold : FontWeight.w500,
                                color: _repeatDays == 3 ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (ddaySummary.isNotEmpty && _repeatDays == 1) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.child_care, size: 16, color: Color(0xFF3EB489)),
                        const SizedBox(width: 6),
                        Text(
                          ddaySummary,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF234E42),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 24, thickness: 0.5),

                // 식사 시간
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blueGrey, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '매 끼니 시간: $hourStr:$minuteStr',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule, size: 14),
                      label: const Text('시간 변경'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.blueGrey.shade700,
                        side: BorderSide(color: Colors.blueGrey.shade200),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // (2) 끼니 선택: 1끼, 2끼, 3끼, 간식 글자 잘림 완벽 해결 (커스텀 박스)
          const Text('끼니 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF234E42))),
          const SizedBox(height: 8),
          Row(
            children: MealType.values.map((m) {
              final isSelected = _selectedMealType == m;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedMealType = m),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? m.primaryColor : m.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? m.primaryColor : m.primaryColor.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      m.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? Colors.white : m.primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // 3. 토핑 큐브 선택 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('토핑 큐브 담기 (1끼 기준)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF234E42))),
                    Text(
                      '1회 총합: $currentTotalGrams g',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3EB489)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _repeatDays > 1
                      ? '* 선택한 식단이 시작일로부터 $_repeatDays일 동안 매일 자동으로 캘린더에 배정됩니다.'
                      : '* 곡류 ➔ 단백질 ➔ 채소 ➔ 과일 순으로 정렬되어 있습니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _repeatDays > 1 ? const Color(0xFF3EB489) : Colors.grey.shade600,
                    fontWeight: _repeatDays > 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 12),
                sortedCubes.isEmpty
                    ? const Text('등록된 큐브가 없습니다.')
                    : Column(
                        children: sortedCubes.map((cube) {
                          final count = _getSelectedCount(cube);
                          final emoji = getFoodEmoji(cube.name);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cube.category.bgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    cube.category.label,
                                    style: TextStyle(color: cube.category.textColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(emoji, style: const TextStyle(fontSize: 15)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${cube.name} (${cube.unitWeight}g)',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          if (cube.isPlannedOnly) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.purple.shade200),
                                              ),
                                              child: Text(
                                                '신규 제작필요',
                                                style: TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        cube.isPlannedOnly
                                            ? '아직 미보유 (식단 계획용 가상 큐브)'
                                            : '재고: ${cube.quantity}개 · 제조: ${cube.madeDate.month}/${cube.madeDate.day} (${cube.dDayText})',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: count > 0 ? () => _modifyCubeSelection(cube, -1) : null,
                                ),
                                Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () => _modifyCubeSelection(cube, 1),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                const Divider(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showAddUnregisteredCubeDialog,
                    icon: const Icon(Icons.playlist_add, size: 18),
                    label: const Text('+ 미등록 재료 직접 추가 (식단 계획용)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6A1B9A),
                      side: const BorderSide(color: Color(0xFFCE93D8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!_isFutureDate && _repeatDays == 1) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.touch_app_outlined, size: 18, color: Color(0xFF3EB489)),
                      SizedBox(width: 6),
                      Text(
                        '빠른 반응 체크 (터치 시 자동 입력)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF234E42)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTagCategoryRow('식사 태도', _attitudeTags, const Color(0xFF3EB489)),
                  const SizedBox(height: 10),
                  _buildTagCategoryRow('피부/알레르기', _skinTags, const Color(0xFFE53935)),
                  const SizedBox(height: 10),
                  _buildTagCategoryRow('배변 상태', _stoolTags, const Color(0xFFF57C00)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _reactionController,
            decoration: InputDecoration(
              labelText: _repeatDays > 1 ? '연속 식단 공통 메모 (예: 3일간 비트 알레르기 테스트)' : '아기 반응 / 식단 계획 메모',
              hintText: _repeatDays > 1 ? '예: 3일 연속 새로운 재료 반응 관찰' : '위 버튼을 터치하거나 직접 작성하세요',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              suffixIcon: _reactionController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _reactionController.clear();
                          _activeTags.clear();
                        });
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitMeal,
              icon: Icon(_repeatDays > 1 || _isFutureDate ? Icons.event_repeat : Icons.check),
              label: Text(
                _repeatDays > 1
                    ? '$_repeatDays일 연속 [${_selectedMealType.label}] 일괄 저장하기'
                    : (_isFutureDate ? '[${_selectedMealType.label}] 계획 저장하기' : '[${_selectedMealType.label}] 기록 완료 & 큐브 차감'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3EB489),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCategoryRow(String title, List<String> tags, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.map((tag) {
            final isSelected = _activeTags.contains(tag);
            return InkWell(
              onTap: () => _toggleTag(tag),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isSelected ? accentColor : Colors.grey.shade300),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// ==========================================
/// (2) 캘린더 화면 (주간/월간 커스텀 토글 및 중앙 정렬)
/// ==========================================
enum CalendarViewMode { week, month }

class MealCalendarTab extends StatefulWidget {
  final List<MealLog> mealLogs;
  final List<CubeItem> cubes;
  final DateTime? birthDate;
  final DateTime? weaningStartDate;
  final Function(MealLog log, MealType newType, DateTime newTime, String newReaction, int newTotalGrams) onEditMeal;
  final Function(MealLog log) onDeleteMeal;
  final Function(MealLog log) onCompleteMeal;
  final Function(MealLog log, String updatedReaction) onUpdateReaction;

  const MealCalendarTab({
    super.key,
    required this.mealLogs,
    required this.cubes,
    required this.birthDate,
    required this.weaningStartDate,
    required this.onEditMeal,
    required this.onDeleteMeal,
    required this.onCompleteMeal,
    required this.onUpdateReaction,
  });

  @override
  State<MealCalendarTab> createState() => _MealCalendarTabState();
}

class _MealCalendarTabState extends State<MealCalendarTab> {
  CalendarViewMode _viewMode = CalendarViewMode.month;
  late DateTime _focusedDate;
  late DateTime _selectedDate;

  final List<String> _attitudeTags = ['완식', '거의 다 먹음', '절반 남김', '뱉어냄'];
  final List<String> _skinTags = ['피부 정상', '입주변 붉어짐', '두드러기/발진', '눈 비빔/가려움'];
  final List<String> _stoolTags = ['황금변', '된변', '무른변', '설사'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDate = DateTime(now.year, now.month, now.day);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<MealLog> _getLogsForDate(DateTime date) {
    final list = widget.mealLogs.where((log) => _isSameDay(log.time, date)).toList();
    list.sort((a, b) {
      final orderCompare = a.mealType.order.compareTo(b.mealType.order);
      if (orderCompare != 0) return orderCompare;
      return a.time.compareTo(b.time);
    });
    return list;
  }

  List<String> _getNewIngredientsForLog(MealLog log) {
    List<String> newItems = [];
    final currentDay = DateTime(log.time.year, log.time.month, log.time.day);

    final pastLogs = widget.mealLogs.where((l) {
      final lDay = DateTime(l.time.year, l.time.month, l.time.day);
      return lDay.isBefore(currentDay);
    }).toList();

    Set<String> pastUsedCubeIds = {};
    for (var pl in pastLogs) {
      pastUsedCubeIds.addAll(pl.cubeUsage.keys);
    }

    log.cubeUsage.forEach((cubeId, count) {
      if (!pastUsedCubeIds.contains(cubeId)) {
        final match = widget.cubes.firstWhere(
          (c) => c.id == cubeId,
          orElse: () => CubeItem(id: '', name: '', category: FoodCategory.etc, unitWeight: 0, quantity: 0, madeDate: DateTime.now(), expireDate: DateTime.now()),
        );
        if (match.name.isNotEmpty) {
          newItems.add(match.name);
        }
      }
    });

    return newItems;
  }

  void _movePrevious() {
    setState(() {
      if (_viewMode == CalendarViewMode.week) {
        _focusedDate = _focusedDate.subtract(const Duration(days: 7));
      } else {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
      }
    });
  }

  void _moveNext() {
    setState(() {
      if (_viewMode == CalendarViewMode.week) {
        _focusedDate = _focusedDate.add(const Duration(days: 7));
      } else {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
      }
    });
  }

  List<DateTime> _getCurrentWeekDays(DateTime anchor) {
    final sundayOffset = anchor.weekday % 7;
    final startOfWeek = DateTime(anchor.year, anchor.month, anchor.day).subtract(Duration(days: sundayOffset));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  void _showReactionUpdateDialog(MealLog log) {
    final reactionController = TextEditingController(text: log.reaction);
    final Set<String> activeTags = {};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void toggleDialogTag(String tag) {
              setDialogState(() {
                if (activeTags.contains(tag)) {
                  activeTags.remove(tag);
                } else {
                  activeTags.add(tag);
                }
                final tagStr = activeTags.join(', ');
                if (reactionController.text.isEmpty || reactionController.text.contains('식사 완료') || reactionController.text.contains('특이사항 없음')) {
                  reactionController.text = tagStr;
                } else {
                  reactionController.text = '${reactionController.text.replaceAll(RegExp(r',\s*$'), '')}, $tag';
                }
              });
            }

            Widget buildTagChips(String title, List<String> tags, Color accentColor) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((t) {
                      final isSel = activeTags.contains(t) || reactionController.text.contains(t);
                      return InkWell(
                        onTap: () => toggleDialogTag(t),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? accentColor : const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isSel ? accentColor : Colors.grey.shade300),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.healing_outlined, color: Color(0xFF3EB489), size: 20),
                  const SizedBox(width: 6),
                  Text('[${log.mealType.label}] 아기 반응·알레르기 기록', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('식사 후 지연된 알레르기 반응이나 배변 상태를 기록해 두세요.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 12),
                    buildTagChips('피부/알레르기 반응', _skinTags, const Color(0xFFE53935)),
                    const SizedBox(height: 8),
                    buildTagChips('배변 상태', _stoolTags, const Color(0xFFF57C00)),
                    const SizedBox(height: 8),
                    buildTagChips('식사 태도', _attitudeTags, const Color(0xFF3EB489)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reactionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '상태 메모 / 상세 관찰 내용',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        hintText: '예: 식사 2시간 후 턱 밑 붉은 발진 관찰됨 등',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
                  onPressed: () {
                    widget.onUpdateReaction(log, reactionController.text.trim());
                    Navigator.pop(ctx);
                  },
                  child: const Text('상태 저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMealDialog(MealLog log) {
    MealType currentType = log.mealType;
    TimeOfDay currentTime = TimeOfDay(hour: log.time.hour, minute: log.time.minute);
    final reactionController = TextEditingController(text: log.reaction);
    final gramsController = TextEditingController(text: '${log.totalGrams}');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hourStr = currentTime.hour.toString().padLeft(2, '0');
            final minuteStr = currentTime.minute.toString().padLeft(2, '0');

            return AlertDialog(
              title: const Text('식단 기록 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '식재료: ${log.ingredients.join(" + ")}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    const Text('끼니 차수', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: MealType.values.map((m) {
                        final isSel = currentType == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setDialogState(() => currentType = m),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? m.primaryColor : m.bgColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSel ? m.primaryColor : m.primaryColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                m.label,
                                style: TextStyle(
                                  color: isSel ? Colors.white : m.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('식사 시간: $hourStr:$minuteStr', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.schedule, size: 14),
                          label: const Text('시간 변경', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: currentTime,
                            );
                            if (picked != null) {
                              setDialogState(() => currentTime = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: gramsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '총 섭취량 (g)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reactionController,
                      decoration: const InputDecoration(labelText: '아기 반응 / 메모'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
                  onPressed: () {
                    final newDateTime = DateTime(
                      log.time.year,
                      log.time.month,
                      log.time.day,
                      currentTime.hour,
                      currentTime.minute,
                    );
                    final grams = int.tryParse(gramsController.text) ?? log.totalGrams;

                    widget.onEditMeal(
                      log,
                      currentType,
                      newDateTime,
                      reactionController.text.trim(),
                      grams,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('수정 완료'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteMeal(MealLog log) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('식단 기록 삭제', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
          content: Text(
            !log.isPlanned
                ? '이 식단 기록을 삭제하시겠습니까?\n\n* 기록 시 차감되었던 큐브 수량이 보관함에 자동으로 복구됩니다.'
                : '이 식단 계획을 삭제하시겠습니까?',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                widget.onDeleteMeal(log);
                Navigator.pop(ctx);
              },
              child: const Text('삭제하기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayLogs = _getLogsForDate(_selectedDate);

    String headerTitle;
    if (_viewMode == CalendarViewMode.week) {
      final weekDays = _getCurrentWeekDays(_focusedDate);
      final start = weekDays.first;
      final end = weekDays.last;
      headerTitle = start.month == end.month
          ? '${start.year}년 ${start.month}월 (${start.day}일~${end.day}일)'
          : '${start.month}월 ${start.day}일 ~ ${end.month}월 ${end.day}일';
    } else {
      headerTitle = '${_focusedDate.year}년 ${_focusedDate.month}월';
    }

    final selectedDdayStr = calculateDdayString(_selectedDate, widget.birthDate, widget.weaningStartDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      body: Column(
        children: [
          // (2) 캘린더 화면 보기 방식: 중앙 정렬 & 커스텀 토글 버튼으로 글자 짤림 방지
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            alignment: Alignment.center,
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _viewMode = CalendarViewMode.week;
                          _focusedDate = _selectedDate;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _viewMode == CalendarViewMode.week ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _viewMode == CalendarViewMode.week
                              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.view_week_outlined, size: 15, color: _viewMode == CalendarViewMode.week ? const Color(0xFF3EB489) : Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '주간',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _viewMode == CalendarViewMode.week ? FontWeight.bold : FontWeight.w500,
                                color: _viewMode == CalendarViewMode.week ? const Color(0xFF234E42) : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _viewMode = CalendarViewMode.month;
                          _focusedDate = _selectedDate;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _viewMode == CalendarViewMode.month ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _viewMode == CalendarViewMode.month
                              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_view_month, size: 15, color: _viewMode == CalendarViewMode.month ? const Color(0xFF3EB489) : Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '월간',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _viewMode == CalendarViewMode.month ? FontWeight.bold : FontWeight.w500,
                                color: _viewMode == CalendarViewMode.month ? const Color(0xFF234E42) : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFF234E42)), onPressed: _movePrevious),
                Text(headerTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF234E42))),
                IconButton(icon: const Icon(Icons.chevron_right, color: Color(0xFF234E42)), onPressed: _moveNext),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
                final isSunday = day == '일';
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSunday ? Colors.red.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: _viewMode == CalendarViewMode.week ? _buildWeekView() : _buildMonthView(),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant, color: Color(0xFF3EB489), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedDate.month}월 ${_selectedDate.day}일 식단 (끼니순)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF234E42)),
                    ),
                  ],
                ),
                if (selectedDdayStr.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selectedDdayStr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF267D5E)),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: selectedDayLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_meals_outlined, size: 32, color: Colors.grey.shade400),
                        const SizedBox(height: 6),
                        Text(
                          '${_selectedDate.month}월 ${_selectedDate.day}일에 등록된 식단이 없습니다.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    itemCount: selectedDayLogs.length,
                    itemBuilder: (ctx, i) {
                      final log = selectedDayLogs[i];
                      final timeStr =
                          '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}';
                      final newItems = _getNewIngredientsForLog(log);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: newItems.isNotEmpty
                                ? const Color(0xFFFFB74D)
                                : (log.isPlanned ? const Color(0xFFA7E9D1) : Colors.grey.shade200),
                            width: newItems.isNotEmpty ? 1.5 : 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: log.mealType.bgColor,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: log.mealType.primaryColor.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          log.mealType.label,
                                          style: TextStyle(
                                            color: log.mealType.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        timeStr,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 6),
                                      if (log.isPlanned)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F8F2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            '식단 계획',
                                            style: TextStyle(fontSize: 10, color: Color(0xFF267D5E), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${log.totalGrams}g',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF234E42)),
                                      ),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showEditMealDialog(log);
                                            } else if (val == 'delete') {
                                              _confirmDeleteMeal(log);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              height: 36,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 16),
                                                  SizedBox(width: 6),
                                                  Text('수정', style: TextStyle(fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              height: 36,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                  SizedBox(width: 6),
                                                  Text('삭제', style: TextStyle(color: Colors.red, fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              if (newItems.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFFCC80)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('⚠️ NEW 첫 시도: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                                      ...newItems.map((name) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Text(
                                            '${getFoodEmoji(name)} $name',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 5),
                              Text(
                                log.ingredients.join(' + '),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),

                              if (log.reaction.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAF9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.rate_review_outlined, size: 13, color: Color(0xFF3EB489)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          log.reaction,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF444444)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 32,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showReactionUpdateDialog(log),
                                        icon: const Icon(Icons.edit_note, size: 15),
                                        label: Text(
                                          log.reaction.isEmpty || log.reaction.contains('식사 완료') ? '+ 상태/반응 기록' : '상태/알러지 수정',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF267D5E),
                                          side: const BorderSide(color: Color(0xFFA7E9D1)),
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (log.isPlanned) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 32,
                                        child: ElevatedButton.icon(
                                          onPressed: () => widget.onCompleteMeal(log),
                                          icon: const Icon(Icons.check_circle_outline, size: 14),
                                          label: const Text('식사 완료 (차감)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF3EB489),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final weekDays = _getCurrentWeekDays(_focusedDate);

    return Row(
      children: weekDays.map((cellDate) {
        final isSelected = _isSameDay(cellDate, _selectedDate);
        final isToday = _isSameDay(cellDate, DateTime.now());
        final logs = _getLogsForDate(cellDate);
        final hasRecord = logs.isNotEmpty;
        final isSunday = cellDate.weekday == DateTime.sunday;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _selectedDate = cellDate;
                _focusedDate = cellDate;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F8F2) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3EB489)
                          : (isToday ? const Color(0xFFC8EEDF) : Colors.transparent),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cellDate.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isSunday ? Colors.red.shade400 : const Color(0xFF234E42)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 5,
                    child: hasRecord
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: logs.map((l) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: l.isPlanned ? const Color(0xFF3EB489) : l.mealType.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthView() {
    final firstDayWeekday = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday % 7;
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final totalCells = firstDayWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            final dayNum = cellIndex - firstDayWeekday + 1;

            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 38));
            }

            final cellDate = DateTime(_focusedDate.year, _focusedDate.month, dayNum);
            final isSelected = _isSameDay(cellDate, _selectedDate);
            final isToday = _isSameDay(cellDate, DateTime.now());
            final logs = _getLogsForDate(cellDate);
            final hasRecord = logs.isNotEmpty;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedDate = cellDate;
                    _focusedDate = cellDate;
                  });
                },
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3EB489)
                              : (isToday ? const Color(0xFFC8EEDF) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (colIndex == 0 ? Colors.red.shade400 : const Color(0xFF234E42)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 3,
                        child: hasRecord
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: logs.take(3).map((l) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: l.isPlanned ? const Color(0xFF3EB489) : l.mealType.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

/// ==========================================
/// (3) 큐브 보관함 화면 (카테고리 칩 글자 잘림 완벽 해결)
/// ==========================================
class CubeStockTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final Function(CubeItem, int) onUpdateQty;
  final Function(CubeItem) onAddCube;
  final Function(CubeItem, String, FoodCategory, int, int, DateTime, int) onEditCube;
  final Function(CubeItem) onDeleteCube;

  const CubeStockTab({
    super.key,
    required this.cubes,
    required this.onUpdateQty,
    required this.onAddCube,
    required this.onEditCube,
    required this.onDeleteCube,
  });

  @override
  State<CubeStockTab> createState() => _CubeStockTabState();
}

class _CubeStockTabState extends State<CubeStockTab> {
  FoodCategory? _selectedCategory;

  void _showAddDialog() {
    final nameController = TextEditingController();
    final weightController = TextEditingController(text: '10');
    final qtyController = TextEditingController(text: '6');
    FoodCategory selectedCat = FoodCategory.vegetable;
    DateTime selectedMadeDate = DateTime.now();
    int shelfLifeDays = 7;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('새 큐브 등록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '식재료명 (예: 감자, 닭고기)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FoodCategory>(
                      value: selectedCat,
                      decoration: const InputDecoration(labelText: '카테고리'),
                      items: FoodCategory.values.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCat = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '1개 용량 (g)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '제작 개수'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '제조일: ${selectedMadeDate.year}.${selectedMadeDate.month}.${selectedMadeDate.day}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: const Text('날짜 선택'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedMadeDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedMadeDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: shelfLifeDays,
                      decoration: const InputDecoration(labelText: '보관 기한 (제조일 기준)'),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5일')),
                        DropdownMenuItem(value: 7, child: Text('7일 (1주일 권장)')),
                        DropdownMenuItem(value: 10, child: Text('10일')),
                        DropdownMenuItem(value: 14, child: Text('14일')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => shelfLifeDays = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    widget.onAddCube(
                      CubeItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        category: selectedCat,
                        unitWeight: int.tryParse(weightController.text) ?? 10,
                        quantity: int.tryParse(qtyController.text) ?? 1,
                        madeDate: selectedMadeDate,
                        expireDate: selectedMadeDate.add(Duration(days: shelfLifeDays)),
                        isPlannedOnly: false,
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(CubeItem cube) {
    final nameController = TextEditingController(text: cube.name);
    final weightController = TextEditingController(text: '${cube.unitWeight}');
    final qtyController = TextEditingController(text: '${cube.quantity}');
    FoodCategory selectedCat = cube.category;
    DateTime selectedMadeDate = cube.madeDate;

    int shelfLifeDays = cube.expireDate.difference(cube.madeDate).inDays;
    if (![5, 7, 10, 14].contains(shelfLifeDays)) {
      shelfLifeDays = 7;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${cube.name} 큐브 정보 수정', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '식재료명'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FoodCategory>(
                      value: selectedCat,
                      decoration: const InputDecoration(labelText: '카테고리'),
                      items: FoodCategory.values.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCat = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '1개 용량 (g)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '남은 수량'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '제조일: ${selectedMadeDate.year}.${selectedMadeDate.month}.${selectedMadeDate.day}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: const Text('날짜 변경'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedMadeDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 60)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedMadeDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: shelfLifeDays,
                      decoration: const InputDecoration(labelText: '보관 기한 (제조일 기준)'),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5일')),
                        DropdownMenuItem(value: 7, child: Text('7일 (권장)')),
                        DropdownMenuItem(value: 10, child: Text('10일')),
                        DropdownMenuItem(value: 14, child: Text('14일')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => shelfLifeDays = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    widget.onEditCube(
                      cube,
                      nameController.text.trim(),
                      selectedCat,
                      int.tryParse(weightController.text) ?? cube.unitWeight,
                      int.tryParse(qtyController.text) ?? cube.quantity,
                      selectedMadeDate,
                      shelfLifeDays,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('수정 완료'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(CubeItem cube) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('큐브 삭제 및 폐기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
          content: Text(
            '\'${cube.name}\' 큐브를 보관함에서 완전히 삭제하시겠습니까?\n\n소비기한 만료로 폐기하거나 오기입한 경우 삭제할 수 있습니다.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                widget.onDeleteCube(cube);
                Navigator.pop(ctx);
              },
              child: const Text('삭제하기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == null
        ? widget.cubes
        : widget.cubes.where((c) => c.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      body: Column(
        children: [
          // (3) 보관함 카테고리: Chip 제거 및 커스텀 컨테이너로 글자 짤림 방지
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // '전체' 버튼
                  InkWell(
                    onTap: () => setState(() => _selectedCategory = null),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategory == null ? const Color(0xFFE8F8F2) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedCategory == null ? const Color(0xFF3EB489) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '전체',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                          color: _selectedCategory == null ? const Color(0xFF234E42) : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 각 카테고리별 버튼
                  ...FoodCategory.values.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = (_selectedCategory == cat ? null : cat)),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedCategory == cat ? const Color(0xFFE8F8F2) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedCategory == cat ? const Color(0xFF3EB489) : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                              color: _selectedCategory == cat ? const Color(0xFF234E42) : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('보관 중인 큐브가 없습니다.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final cube = filtered[i];
                      final emoji = getFoodEmoji(cube.name);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: cube.isPlannedOnly ? Colors.purple.shade200 : Colors.grey.shade200,
                          ),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cube.category.bgColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          cube.category.label,
                                          style: TextStyle(
                                            color: cube.category.textColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cube.statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          cube.dDayText,
                                          style: TextStyle(
                                            color: cube.statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditDialog(cube);
                                      } else if (value == 'delete') {
                                        _confirmDelete(cube);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('수정'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('삭제/폐기', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cube.name,
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '개당 ${cube.unitWeight}g · 총 ${cube.unitWeight * cube.quantity}g',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          cube.isPlannedOnly
                                              ? '식단 계획에 의해 등록된 미보유 재료'
                                              : '제조일: ${cube.madeDate.year}.${cube.madeDate.month}.${cube.madeDate.day}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: cube.isPlannedOnly ? Colors.purple.shade700 : Colors.grey.shade500,
                                            fontWeight: cube.isPlannedOnly ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F3F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 18),
                                          onPressed: cube.quantity > 0 ? () => widget.onUpdateQty(cube, -1) : null,
                                        ),
                                        Text(
                                          '${cube.quantity}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: cube.quantity == 0 ? Colors.red : Colors.black87,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          onPressed: () => widget.onUpdateQty(cube, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3EB489),
        foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('큐브 추가'),
      ),
    );
  }
}

/// ==========================================
/// (4) 제작 필요 및 마감일(Deadline) 화면
/// ==========================================
class RestockPlanItem {
  final CubeItem cube;
  final String urgencyMessage;
  final String deadlineText;
  final Color badgeColor;
  final int urgencyScore;

  RestockPlanItem({
    required this.cube,
    required this.urgencyMessage,
    required this.deadlineText,
    required this.badgeColor,
    required this.urgencyScore,
  });
}

class RestockPlanTab extends StatelessWidget {
  final List<CubeItem> cubes;
  final List<MealLog> mealLogs;
  final Function(CubeItem cube, int addedQty, DateTime madeDate, int newShelfLifeDays) onRestock;

  const RestockPlanTab({
    super.key,
    required this.cubes,
    required this.mealLogs,
    required this.onRestock,
  });

  List<RestockPlanItem> _calculateRestockPlans() {
    List<RestockPlanItem> results = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final futureLogs = mealLogs.where((l) {
      final logDay = DateTime(l.time.year, l.time.month, l.time.day);
      return logDay.isAfter(today) || logDay.isAtSameMomentAs(today);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    for (var cube in cubes) {
      if (cube.isPlannedOnly) {
        DateTime? firstPlanDate;
        for (var log in futureLogs) {
          if (log.cubeUsage.containsKey(cube.id)) {
            firstPlanDate = log.time;
            break;
          }
        }
        final daysDiff = firstPlanDate != null ? firstPlanDate.difference(today).inDays : 99;
        final dlText = firstPlanDate != null
            ? '${firstPlanDate.month}/${firstPlanDate.day} (${daysDiff == 0 ? '오늘' : '$daysDiff일 후'}) 식단 전까지 제작 필요'
            : '식단 계획에 포함된 신규 재료 (제작 권장)';

        results.add(RestockPlanItem(
          cube: cube,
          urgencyMessage: '식단 계획 신규 식재료 (미보유)',
          deadlineText: dlText,
          badgeColor: const Color(0xFF6A1B9A),
          urgencyScore: daysDiff <= 1 ? -100 + daysDiff : 10 + daysDiff,
        ));
        continue;
      }

      int remainingQty = cube.quantity;
      DateTime? runOutDate;

      if (remainingQty == 0) {
        DateTime? nextPlanDate;
        for (var log in futureLogs) {
          if (log.cubeUsage.containsKey(cube.id)) {
            nextPlanDate = log.time;
            break;
          }
        }
        final daysDiff = nextPlanDate != null ? nextPlanDate.difference(today).inDays : 999;
        final dlText = nextPlanDate != null
            ? '${nextPlanDate.month}/${nextPlanDate.day} 식단 전까지 제작 필요'
            : '현재 재고 없음 (즉시 제작 권장)';

        results.add(RestockPlanItem(
          cube: cube,
          urgencyMessage: '현재 재고 0개 (완전 소진)',
          deadlineText: dlText,
          badgeColor: const Color(0xFFD32F2F),
          urgencyScore: -50 + (daysDiff < 10 ? daysDiff : 10),
        ));
        continue;
      }

      if (cube.daysRemaining < 0) {
        results.add(RestockPlanItem(
          cube: cube,
          urgencyMessage: '소비기한 만료 (${cube.dDayText})',
          deadlineText: '폐기 후 신규 제작 권장',
          badgeColor: const Color(0xFFE65100),
          urgencyScore: -30 + cube.daysRemaining,
        ));
        continue;
      }

      for (var log in futureLogs) {
        if (log.cubeUsage.containsKey(cube.id)) {
          final plannedUse = log.cubeUsage[cube.id]!;
          if (remainingQty < plannedUse) {
            runOutDate = log.time;
            break;
          }
          remainingQty -= plannedUse;
        }
      }

      if (runOutDate != null) {
        final daysDiff = runOutDate.difference(today).inDays;
        final dlMsg = daysDiff <= 1
            ? '내일(${runOutDate.month}/${runOutDate.day}) 식단 차질! 오늘 중 제작 필수'
            : '늦어도 ${runOutDate.month}월 ${runOutDate.day}일 이전까지 제작 필수';

        results.add(RestockPlanItem(
          cube: cube,
          urgencyMessage: '식단 계획에 의해 수량 부족 예정 (잔여 $remainingQty개)',
          deadlineText: dlMsg,
          badgeColor: const Color(0xFFC2185B),
          urgencyScore: -80 + daysDiff,
        ));
      } else if (cube.quantity <= 2) {
        final expireInDays = cube.daysRemaining;
        final dlMsg = '늦어도 D-$expireInDays (${cube.expireDate.month}/${cube.expireDate.day}) 전까지 보충';

        results.add(RestockPlanItem(
          cube: cube,
          urgencyMessage: '안전 재고 부족 (${cube.quantity}개 남음)',
          deadlineText: dlMsg,
          badgeColor: const Color(0xFFFB8C00),
          urgencyScore: 100 + expireInDays,
        ));
      }
    }

    results.sort((a, b) => a.urgencyScore.compareTo(b.urgencyScore));
    return results;
  }

  void _showRestockDialog(BuildContext context, CubeItem cube) {
    final qtyController = TextEditingController(text: '6');
    DateTime madeDate = DateTime.now();
    int shelfLifeDays = 7;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${cube.name} 큐브 제작 완료', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cube.isPlannedOnly
                        ? '식단 계획을 위해 등록했던 재료입니다. 새로 만든 개수를 입력하면 보관함의 실물 큐브로 등록됩니다.'
                        : '새로 제작한 개수와 제조일자를 입력하면 보관함 재고와 기한이 새로 갱신됩니다.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '새로 만든 개수'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '제조일: ${madeDate.year}.${madeDate.month}.${madeDate.day}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: const Text('날짜 변경'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: madeDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 14)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => madeDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: shelfLifeDays,
                    decoration: const InputDecoration(labelText: '보관 기한 설정'),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5일')),
                      DropdownMenuItem(value: 7, child: Text('7일 (1주일 권장)')),
                      DropdownMenuItem(value: 10, child: Text('10일')),
                      DropdownMenuItem(value: 14, child: Text('14일 (최대)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => shelfLifeDays = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text) ?? 6;
                    onRestock(cube, qty, madeDate, shelfLifeDays);
                    Navigator.pop(ctx);
                  },
                  child: const Text('보관함에 반영'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final restockItems = _calculateRestockPlans();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7E9D1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFF3EB489), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '식단 차질 방지 제작 마감선 (시급순)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF234E42)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '예정된 식단에 당장 필요한 재료부터 시급성 순으로 배치했습니다.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '제작 필요 토핑 (${restockItems.length}개)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF234E42)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: restockItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 44, color: Colors.green.shade400),
                          const SizedBox(height: 10),
                          const Text('예정된 식단에 필요한 모든 큐브가 충분합니다!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('식단 계획에 차질이 없어요.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: restockItems.length,
                      itemBuilder: (ctx, i) {
                        final item = restockItems[i];
                        final cube = item.cube;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: cube.isPlannedOnly ? Colors.purple.shade200 : Colors.grey.shade200,
                            ),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: cube.category.bgColor,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  cube.category.label,
                                                  style: TextStyle(color: cube.category.textColor, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                item.urgencyMessage,
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.badgeColor),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(cube.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          Text(
                                            cube.isPlannedOnly
                                                ? '현재 상태: 미보유 (식단 계획용)'
                                                : '현재 재고: ${cube.quantity}개 · 제조: ${cube.madeDate.month}/${cube.madeDate.day} (${cube.dDayText})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cube.isPlannedOnly ? Colors.purple.shade700 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _showRestockDialog(context, cube),
                                      icon: const Icon(Icons.done_all, size: 14),
                                      label: const Text('제작 완료', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cube.isPlannedOnly ? const Color(0xFF8E24AA) : const Color(0xFF3EB489),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: item.badgeColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.alarm, size: 16, color: item.badgeColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '제작 마감일: ${item.deadlineText}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: item.badgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
