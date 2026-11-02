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
    return MaterialApp(
      title: '토핑 이유식 매니저',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9E7D),
          primary: const Color(0xFFFF7A59),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

/// 1. 끼니 차수 정의 및 색상
enum MealType {
  first('1끼', Color(0xFFFF7A59), Color(0xFFFFEFEB)),
  second('2끼', Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  third('3끼', Color(0xFF5E35B1), Color(0xFFEDE7F6)),
  snack('간식', Color(0xFFF57F17), Color(0xFFFFFDE7));

  final String label;
  final Color primaryColor;
  final Color bgColor;

  const MealType(this.label, this.primaryColor, this.bgColor);

  static MealType fromLabel(String label) {
    return MealType.values.firstWhere(
      (m) => m.label == label,
      orElse: () => MealType.first,
    );
  }
}

/// 2. 카테고리 정의
enum FoodCategory {
  grain('곡류', Color(0xFFFFF3CD), Color(0xFF856404)),
  meat('단백질', Color(0xFFF8D7DA), Color(0xFF721C24)),
  vegetable('채소', Color(0xFFD4EDDA), Color(0xFF155724)),
  fruit('과일', Color(0xFFD1ECF1), Color(0xFF0C5460)),
  etc('기타', Color(0xFFE2E3E5), Color(0xFF383D41));

  final String label;
  final Color bgColor;
  final Color textColor;

  const FoodCategory(this.label, this.bgColor, this.textColor);

  static FoodCategory fromLabel(String label) {
    return FoodCategory.values.firstWhere(
      (c) => c.label == label,
      orElse: () => FoodCategory.etc,
    );
  }
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

  CubeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unitWeight,
    required this.quantity,
    required this.madeDate,
    required this.expireDate,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(expireDate.year, expireDate.month, expireDate.day);
    return expiration.difference(today).inDays;
  }

  String get dDayText {
    final diff = daysRemaining;
    if (diff < 0) return '만료(D+${-diff})';
    if (diff == 0) return 'D-Day';
    return 'D-$diff';
  }

  Color get statusColor {
    final diff = daysRemaining;
    if (diff < 0) return const Color(0xFFE53935);
    if (diff <= 2) return const Color(0xFFFB8C00);
    return const Color(0xFF43A047);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.label,
        'unitWeight': unitWeight,
        'quantity': quantity,
        'madeDate': madeDate.toIso8601String(),
        'expireDate': expireDate.toIso8601String(),
      };

  factory CubeItem.fromJson(Map<String, dynamic> json) => CubeItem(
        id: json['id'],
        name: json['name'],
        category: FoodCategory.fromLabel(json['category']),
        unitWeight: json['unitWeight'],
        quantity: json['quantity'],
        madeDate: DateTime.parse(json['madeDate']),
        expireDate: DateTime.parse(json['expireDate']),
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

  // 아기 기본 정보 (생년월일, 이유식 시작일)
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
          name: '소고기 안심',
          category: FoodCategory.meat,
          unitWeight: 10,
          quantity: 2,
          madeDate: now.subtract(const Duration(days: 4)),
          expireDate: now.add(const Duration(days: 3)),
        ),
        CubeItem(
          id: '2',
          name: '오트밀쌀죽',
          category: FoodCategory.grain,
          unitWeight: 30,
          quantity: 5,
          madeDate: now.subtract(const Duration(days: 2)),
          expireDate: now.add(const Duration(days: 5)),
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
      // 기본 예시 (약 6개월 전)
      _birthDate = DateTime.now().subtract(const Duration(days: 180));
    }

    if (weaningString != null) {
      _weaningStartDate = DateTime.parse(weaningString);
    } else {
      // 기본 예시 (약 20일 전)
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

  // 아기 정보(생일/이유식시작일) 설정 다이얼로그
  void _showSettingsDialog() {
    DateTime tempBirth = _birthDate ?? DateTime.now().subtract(const Duration(days: 180));
    DateTime tempWeaning = _weaningStartDate ?? DateTime.now().subtract(const Duration(days: 15));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('아기 성장 & 이유식 설정', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake_outlined, color: Color(0xFFFF7A59)),
                    title: const Text('아기 출생일', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${tempBirth.year}년 ${tempBirth.month}월 ${tempBirth.day}일',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                    title: const Text('이유식 시작일', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${tempWeaning.year}년 ${tempWeaning.month}월 ${tempWeaning.day}일',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cube.name} 큐브 ${addedQty}개 보충 완료!'),
        backgroundColor: const Color(0xFF43A047),
      ),
    );
  }

  void _addMealRecord({
    required MealType mealType,
    required DateTime recordDate,
    required Map<CubeItem, int> selectedCubes,
    required String reaction,
  }) {
    setState(() {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final recordMidnight = DateTime(recordDate.year, recordDate.month, recordDate.day);
      final isFuturePlan = recordMidnight.isAfter(todayMidnight);

      List<String> ingredientSummaries = [];
      Map<String, int> cubeUsageMap = {};
      int totalWeight = 0;

      selectedCubes.forEach((cube, count) {
        if (count > 0) {
          if (!isFuturePlan) {
            cube.quantity = (cube.quantity - count).clamp(0, 999);
          }
          final weight = cube.unitWeight * count;
          totalWeight += weight;
          ingredientSummaries.add('${cube.name} ${weight}g (${count}개)');
          cubeUsageMap[cube.id] = count;
        }
      });

      _mealLogs.insert(
        0,
        MealLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          mealType: mealType,
          time: recordDate,
          ingredients: ingredientSummaries,
          cubeUsage: cubeUsageMap,
          totalGrams: totalWeight,
          reaction: reaction.isEmpty
              ? (isFuturePlan ? '[예정] 식단 계획' : '특이사항 없음')
              : reaction,
          isPlanned: isFuturePlan,
        ),
      );
    });
    _saveData();

    final timeFormatted = '${recordDate.hour.toString().padLeft(2, '0')}:${recordDate.minute.toString().padLeft(2, '0')}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recordDate.month}월 ${recordDate.day}일 $timeFormatted [${mealType.label}] 저장 완료!'),
        backgroundColor: mealType.primaryColor,
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

  void _deleteMealRecord(MealLog log) {
    setState(() {
      if (!log.isPlanned) {
        log.cubeUsage.forEach((cubeId, count) {
          final matchIndex = _cubes.indexWhere((c) => c.id == cubeId);
          if (matchIndex != -1) {
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
          child: CircularProgressIndicator(color: Color(0xFFFF7A59)),
        ),
      );
    }

    final restockCount = _cubes.where((c) => c.quantity <= 2 || c.daysRemaining < 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('토핑 이유식 매니저', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
          ),
          MealCalendarTab(
            mealLogs: _mealLogs,
            birthDate: _birthDate,
            weaningStartDate: _weaningStartDate,
            onEditMeal: _editMealRecord,
            onDeleteMeal: _deleteMealRecord,
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
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '식단 기록',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          const NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: '보관함',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: restockCount > 0,
              label: Text('$restockCount'),
              child: const Icon(Icons.alarm_on_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: restockCount > 0,
              label: Text('$restockCount'),
              child: const Icon(Icons.alarm_on),
            ),
            label: '제작 필요',
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// D-Day 계산 헬퍼 함수
/// ==========================================
String calculateDdayString(DateTime targetDate, DateTime? birthDate, DateTime? weaningStartDate) {
  final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
  List<String> ddays = [];

  if (birthDate != null) {
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final diff = target.difference(birth).inDays + 1; // 출생 당일 1일차
    if (diff > 0) {
      ddays.add('생후 D+$diff일');
    }
  }

  if (weaningStartDate != null) {
    final weaning = DateTime(weaningStartDate.year, weaningStartDate.month, weaningStartDate.day);
    final diff = target.difference(weaning).inDays + 1; // 시작 당일 1일차
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
/// (1) 식단 기록 화면 (D-Day 배너 탑재)
/// ==========================================
class MealLogTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final DateTime? birthDate;
  final DateTime? weaningStartDate;
  final Function({
    required MealType mealType,
    required DateTime recordDate,
    required Map<CubeItem, int> selectedCubes,
    required String reaction,
  }) onSaveMeal;

  const MealLogTab({
    super.key,
    required this.cubes,
    required this.birthDate,
    required this.weaningStartDate,
    required this.onSaveMeal,
  });

  @override
  State<MealLogTab> createState() => _MealLogTabState();
}

class _MealLogTabState extends State<MealLogTab> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  MealType _selectedMealType = MealType.first;
  final Map<String, int> _selectedQuantities = {};
  final TextEditingController _reactionController = TextEditingController();

  final List<String> _attitudeTags = ['완식', '거의 다 먹음', '절반 남김', '뱉어냄'];
  final List<String> _skinTags = ['피부 정상', '입주변 붉어짐', '두드러기/발진', '눈 비빔/가려움'];
  final List<String> _stoolTags = ['황금변', '된변', '무른변', '설사'];

  final Set<String> _activeTags = {};

  bool get _isFutureDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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

  void _submitMeal() {
    if (_selectedQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식단에 배정할 토핑 큐브를 1개 이상 담아주세요.')),
      );
      return;
    }

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
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
      recordDate: combinedDateTime,
      selectedCubes: cubesToApply,
      reaction: _reactionController.text.trim(),
    );

    setState(() {
      _selectedQuantities.clear();
      _reactionController.clear();
      _activeTags.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentTotalGrams = 0;
    for (var cube in widget.cubes) {
      final count = _getSelectedCount(cube);
      currentTotalGrams += count * cube.unitWeight;
    }

    final isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;

    final hourStr = _selectedTime.hour.toString().padLeft(2, '0');
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');

    final ddaySummary = calculateDdayString(_selectedDate, widget.birthDate, widget.weaningStartDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 날짜, 시간 및 D-day 안내 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isFutureDate ? const Color(0xFFE8F4FD) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFutureDate ? const Color(0xFF90CAF9) : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isFutureDate ? Icons.next_plan_outlined : Icons.calendar_today_outlined,
                      color: _isFutureDate ? Colors.blue.shade700 : const Color(0xFFFF7A59),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday
                                ? '오늘 식단 기록'
                                : (_isFutureDate ? '향후 식단 계획 (미래)' : '이전 날짜 소급 기록 (과거)'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isFutureDate ? Colors.blue.shade800 : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar, size: 14),
                      label: const Text('날짜 변경'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: _isFutureDate ? Colors.blue.shade800 : const Color(0xFFFF7A59),
                        side: BorderSide(
                          color: _isFutureDate ? Colors.blue.shade300 : const Color(0xFFFF9E7D),
                        ),
                      ),
                    ),
                  ],
                ),
                if (ddaySummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A59).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.child_care, size: 16, color: Color(0xFFFF7A59)),
                        const SizedBox(width: 6),
                        Text(
                          ddaySummary,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF7A59),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 18, thickness: 0.5),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blueGrey, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '식사 시간: $hourStr:$minuteStr',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule, size: 14),
                      label: const Text('시간 변경'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.blueGrey.shade800,
                        side: BorderSide(color: Colors.blueGrey.shade300),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 끼니 차수 선택
          const Text('끼니 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: MealType.values.map((m) {
              final isSelected = _selectedMealType == m;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(m.label),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : m.primaryColor,
                  ),
                  selected: isSelected,
                  checkmarkColor: Colors.white,
                  backgroundColor: m.bgColor,
                  selectedColor: m.primaryColor,
                  side: BorderSide(
                    color: isSelected ? m.primaryColor : m.primaryColor.withOpacity(0.3),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedMealType = m);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

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
                    const Text('토핑 큐브 담기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '총합: $currentTotalGrams g',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedMealType.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_isFutureDate)
                  Text(
                    '* 향후 식단에 큐브를 담아두면 [제작 필요] 탭에서 마감일을 자동으로 계산해 줍니다.',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                  ),
                const SizedBox(height: 12),
                widget.cubes.isEmpty
                    ? const Text('보관 중인 큐브가 없습니다.')
                    : Column(
                        children: widget.cubes.map((cube) {
                          final count = _getSelectedCount(cube);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${cube.name} (${cube.unitWeight}g)',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      ),
                                      Text(
                                        '재고: ${cube.quantity}개 · 제조: ${cube.madeDate.month}/${cube.madeDate.day} (${cube.dDayText})',
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. 빠른 반응 체크
          if (!_isFutureDate) ...[
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
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 18, color: Color(0xFFFF7A59)),
                      const SizedBox(width: 6),
                      const Text(
                        '빠른 반응 체크 (터치 시 자동 입력)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTagCategoryRow('식사 태도', _attitudeTags, const Color(0xFF388E3C)),
                  const SizedBox(height: 10),
                  _buildTagCategoryRow('피부/알레르기', _skinTags, const Color(0xFFD32F2F)),
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
              labelText: _isFutureDate ? '식단 계획 메모 (선택)' : '아기 반응 / 추가 메모',
              hintText: _isFutureDate ? '예: 새로운 채소 테스트 예정' : '위 버튼을 터치하거나 직접 작성하세요',
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
              icon: Icon(_isFutureDate ? Icons.event_available : Icons.check),
              label: Text(
                _isFutureDate ? '[${_selectedMealType.label}] 계획 저장하기' : '[${_selectedMealType.label}] 기록 완료 & 큐브 차감',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFutureDate ? const Color(0xFF1976D2) : _selectedMealType.primaryColor,
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
            return FilterChip(
              label: Text(tag),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: accentColor,
              backgroundColor: const Color(0xFFF1F3F5),
              side: BorderSide(
                color: isSelected ? accentColor : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (_) => _toggleTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// ==========================================
/// (2) 캘린더 화면 (성장 D-Day 타이틀 결합)
/// ==========================================
enum CalendarViewMode { week, month }

class MealCalendarTab extends StatefulWidget {
  final List<MealLog> mealLogs;
  final DateTime? birthDate;
  final DateTime? weaningStartDate;
  final Function(MealLog log, MealType newType, DateTime newTime, String newReaction, int newTotalGrams) onEditMeal;
  final Function(MealLog log) onDeleteMeal;

  const MealCalendarTab({
    super.key,
    required this.mealLogs,
    required this.birthDate,
    required this.weaningStartDate,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  @override
  State<MealCalendarTab> createState() => _MealCalendarTabState();
}

class _MealCalendarTabState extends State<MealCalendarTab> {
  CalendarViewMode _viewMode = CalendarViewMode.month;
  late DateTime _focusedDate;
  late DateTime _selectedDate;

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
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
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
              title: const Text('식단 기록 수정', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '식재료: ${log.ingredients.join(" + ")}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    const Text('끼니 차수', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: MealType.values.map((m) {
                        final isSel = currentType == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(m.label),
                            selected: isSel,
                            selectedColor: m.primaryColor,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : m.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setDialogState(() => currentType = m);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('식사 시간: $hourStr:$minuteStr', style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextButton.icon(
                          icon: const Icon(Icons.schedule, size: 16),
                          label: const Text('시간 변경'),
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: gramsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '총 섭취량 (g)'),
                    ),
                    const SizedBox(height: 12),
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
          title: const Text('식단 기록 삭제', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            !log.isPlanned
                ? '이 식단 기록을 삭제하시겠습니까?\n\n* 기록 시 차감되었던 큐브 수량이 보관함에 자동으로 복구됩니다.'
                : '이 식단 계획을 삭제하시겠습니까?',
            style: const TextStyle(fontSize: 14),
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
      backgroundColor: const Color(0xFFF9F9FB),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<CalendarViewMode>(
                segments: const [
                  ButtonSegment<CalendarViewMode>(
                    value: CalendarViewMode.week,
                    label: Text('주간 뷰'),
                    icon: Icon(Icons.view_week_outlined),
                  ),
                  ButtonSegment<CalendarViewMode>(
                    value: CalendarViewMode.month,
                    label: Text('월간 뷰'),
                    icon: Icon(Icons.calendar_view_month),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _viewMode = newSelection.first;
                    _focusedDate = _selectedDate;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFFFF9E7D).withOpacity(0.2),
                  selectedForegroundColor: const Color(0xFFFF7A59),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _movePrevious),
                Text(headerTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _moveNext),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
                final isSunday = day == '일';
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
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
            padding: const EdgeInsets.only(bottom: 12),
            child: _viewMode == CalendarViewMode.week ? _buildWeekView() : _buildMonthView(),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // 선택된 날짜 헤더 & D-day 표시
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note, color: Color(0xFFFF7A59), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedDate.month}월 ${_selectedDate.day}일 식단',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (selectedDdayStr.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A59).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selectedDdayStr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF7A59)),
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
                        Icon(Icons.no_meals_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedDate.month}월 ${_selectedDate.day}일에 등록된 식단이 없습니다.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: selectedDayLogs.length,
                    itemBuilder: (ctx, i) {
                      final log = selectedDayLogs[i];
                      final timeStr =
                          '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: log.isPlanned ? Colors.blue.shade200 : log.mealType.primaryColor.withOpacity(0.3),
                          ),
                        ),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: log.mealType.bgColor,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: log.mealType.primaryColor.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          log.mealType.label,
                                          style: TextStyle(
                                            color: log.mealType.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            timeStr,
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      if (log.isPlanned)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '식단 계획',
                                            style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '총 ${log.totalGrams}g',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
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
                                                Text('삭제', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                log.ingredients.join(' + '),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '메모/반응: ${log.reaction}',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF495057)),
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF0EB) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A59)
                          : (isToday ? const Color(0xFFFFE0D6) : Colors.transparent),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cellDate.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isSunday ? Colors.red.shade400 : Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 6,
                    child: hasRecord
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: logs.map((l) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: l.isPlanned ? Colors.blue.shade400 : l.mealType.primaryColor,
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
              return const Expanded(child: SizedBox(height: 44));
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
                  height: 44,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF7A59)
                              : (isToday ? const Color(0xFFFFE0D6) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (colIndex == 0 ? Colors.red.shade400 : Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 4,
                        child: hasRecord
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: logs.take(3).map((l) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: l.isPlanned ? Colors.blue.shade400 : l.mealType.primaryColor,
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
/// (3) 큐브 보관함 화면 (제조일자 직접 선택 추가)
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
              title: const Text('새 큐브 등록', style: TextStyle(fontWeight: FontWeight.bold)),
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

                    // 제조일자 선택 행
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
              title: Text('${cube.name} 큐브 정보 수정', style: const TextStyle(fontWeight: FontWeight.bold)),
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

                    // 제조일자 수정
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
          title: const Text('큐브 삭제 및 폐기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '\'${cube.name}\' 큐브를 보관함에서 완전히 삭제하시겠습니까?\n\n소비기한 만료로 폐기하거나 오기입한 경우 삭제할 수 있습니다.',
            style: const TextStyle(fontSize: 14),
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
      backgroundColor: const Color(0xFFF9F9FB),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                FilterChip(
                  label: const Text('전체'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...FoodCategory.values.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.label),
                      selected: _selectedCategory == cat,
                      onSelected: (val) => setState(() => _selectedCategory = val ? cat : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cube.name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '개당 ${cube.unitWeight}g · 총 ${cube.unitWeight * cube.quantity}g',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          '제조일: ${cube.madeDate.year}.${cube.madeDate.month}.${cube.madeDate.day}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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

  RestockPlanItem({
    required this.cube,
    required this.urgencyMessage,
    required this.deadlineText,
    required this.badgeColor,
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
        final dlText = nextPlanDate != null
            ? '${nextPlanDate.month}/${nextPlanDate.day} 식단 전까지 제작 필요'
            : '현재 재고 없음 (즉시 제작 권장)';

        results.add(RestockPlanItem(
          cube: cube,
          urgencyMessage: '현재 재고 0개 (완전 소진)',
          deadlineText: dlText,
          badgeColor: const Color(0xFFD32F2F),
        ));
        continue;
      }

      if (cube.daysRemaining < 0) {
        results.add(RestockPlanItem(
          cube: cube,
          urgencyMessage: '소비기한 만료 (${cube.dDayText})',
          deadlineText: '폐기 후 신규 제작 권장',
          badgeColor: const Color(0xFFE65100),
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
        ));
      } else if (cube.quantity <= 2) {
        final expireInDays = cube.daysRemaining;
        final dlMsg = '늦어도 D-$expireInDays (${cube.expireDate.month}/${cube.expireDate.day}) 전까지 보충';

        results.add(RestockPlanItem(
          cube: cube,
          urgencyMessage: '안전 재고 부족 (${cube.quantity}개 남음)',
          deadlineText: dlMsg,
          badgeColor: const Color(0xFFFB8C00),
        ));
      }
    }

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
              title: Text('${cube.name} 큐브 제작 완료', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('새로 제작한 개수와 제조일자를 입력하면 보관함 재고와 기한이 새로 갱신됩니다.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 8),
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
      backgroundColor: const Color(0xFFF9F9FB),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD4C4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFFFF7A59), size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '식단 차질 방지 제작 마감선',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF8C3C00)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '현재 잔여 큐브와 향후 계획된 식단을 대조해 늦어도 만들어야 하는 일정을 분석했습니다.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '제작 필요 토핑 (${restockItems.length}개)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: restockItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade400),
                          const SizedBox(height: 12),
                          const Text('예정된 식단에 필요한 모든 큐브가 충분합니다!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('식단 계획에 차질이 없어요.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: restockItems.length,
                      itemBuilder: (ctx, i) {
                        final item = restockItems[i];
                        final cube = item.cube;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: cube.category.bgColor,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  cube.category.label,
                                                  style: TextStyle(color: cube.category.textColor, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                item.urgencyMessage,
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.badgeColor),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(cube.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          Text('현재 재고: ${cube.quantity}개 · 제조: ${cube.madeDate.month}/${cube.madeDate.day} (${cube.dDayText})',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _showRestockDialog(context, cube),
                                      icon: const Icon(Icons.done_all, size: 16),
                                      label: const Text('제작 완료'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF9E7D),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: item.badgeColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.alarm, size: 18, color: item.badgeColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '제작 마감일: ${item.deadlineText}',
                                          style: TextStyle(
                                            fontSize: 13,
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
