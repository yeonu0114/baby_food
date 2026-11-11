import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const BabyFoodApp());

class BabyFoodApp extends StatelessWidget {
  const BabyFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '토핑 이유식 매니저',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3EB489),
          primary: const Color(0xFF3EB489),
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

  static MealType fromLabel(String l) =>
      MealType.values.firstWhere((m) => m.label == l, orElse: () => MealType.first);
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
  if (n.contains('쌀') || n.contains('오트밀') || n.contains('현미')) return '🌾';
  if (n.contains('소고기') || n.contains('안심')) return '🥩';
  if (n.contains('닭')) return '🍗';
  if (n.contains('단호박') || n.contains('호박')) return '🎃';
  if (n.contains('브로콜리')) return '🥦';
  if (n.contains('당근')) return '🥕';
  if (n.contains('애호박') || n.contains('오이')) return '🥒';
  if (n.contains('감자')) return '🥔';
  if (n.contains('고구마')) return '🍠';
  if (n.contains('사과')) return '🍎';
  if (n.contains('바나나')) return '🍌';
  if (n.contains('계란') || n.contains('노른자')) return '🥚';
  if (n.contains('두부') || n.contains('완두콩')) return '🫘';
  return '🥄';
}

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
    return DateTime(expireDate.year, expireDate.month, expireDate.day).difference(today).inDays;
  }

  String get dDayText {
    if (isPlannedOnly) return '미보유';
    final d = daysRemaining;
    if (d < 0) return '만료(D+${-d})';
    if (d == 0) return 'D-Day';
    return 'D-$d';
  }

  Color get statusColor {
    if (isPlannedOnly) return const Color(0xFF9C27B0);
    final d = daysRemaining;
    if (d < 0) return const Color(0xFFE53935);
    if (d <= 2) return const Color(0xFFFB8C00);
    return const Color(0xFF3EB489);
  }

  Color get statusBgColor {
    if (isPlannedOnly) return const Color(0xFFF3E5F5);
    final d = daysRemaining;
    if (d < 0) return const Color(0xFFFFEBEE);
    if (d <= 2) return const Color(0xFFFFF3E0);
    return const Color(0xFFE8F8F2);
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

  factory CubeItem.fromJson(Map<String, dynamic> j) => CubeItem(
        id: j['id'],
        name: j['name'],
        category: FoodCategory.fromLabel(j['category']),
        unitWeight: j['unitWeight'],
        quantity: j['quantity'],
        madeDate: DateTime.parse(j['madeDate']),
        expireDate: DateTime.parse(j['expireDate']),
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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0; // 0: 캘린더 기본
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
    final cs = prefs.getString('cubes_data');
    final ms = prefs.getString('meals_data');
    final bs = prefs.getString('baby_birth_date');
    final ws = prefs.getString('weaning_start_date');

    if (cs != null) {
      _cubes = (jsonDecode(cs) as List).map((i) => CubeItem.fromJson(i)).toList();
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
          expireDate: now.add(const Duration(days: 12)),
        ),
        CubeItem(
          id: '2',
          name: '소고기 안심',
          category: FoodCategory.meat,
          unitWeight: 10,
          quantity: 3,
          madeDate: now.subtract(const Duration(days: 3)),
          expireDate: now.add(const Duration(days: 11)),
        ),
      ];
    }

    if (ms != null) {
      _mealLogs = (jsonDecode(ms) as List).map((i) => MealLog.fromJson(i)).toList();
    }

    _birthDate = bs != null ? DateTime.parse(bs) : DateTime.now().subtract(const Duration(days: 180));
    _weaningStartDate = ws != null ? DateTime.parse(ws) : DateTime.now().subtract(const Duration(days: 20));

    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cubes_data', jsonEncode(_cubes.map((c) => c.toJson()).toList()));
    await prefs.setString('meals_data', jsonEncode(_mealLogs.map((m) => m.toJson()).toList()));
    if (_birthDate != null) await prefs.setString('baby_birth_date', _birthDate!.toIso8601String());
    if (_weaningStartDate != null) await prefs.setString('weaning_start_date', _weaningStartDate!.toIso8601String());
  }

  void _showSettings() {
    DateTime b = _birthDate ?? DateTime.now();
    DateTime w = _weaningStartDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text('아기 성장 & 이유식 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined, color: Color(0xFF3EB489)),
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
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  _birthDate = b;
                  _weaningStartDate = w;
                });
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
      List<String> ingSummaries = [];
      Map<String, int> cubeUsageMap = {};
      int totalWeight = 0;

      selectedCubes.forEach((cube, count) {
        if (count > 0) {
          final w = cube.unitWeight * count;
          totalWeight += w;
          ingSummaries.add('${cube.name} ${w}g (${count}개)');
          cubeUsageMap[cube.id] = count;
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
            ? (repeatDays > 1 ? '[${i + 1}/$repeatDays일차 계획]' : (isFuture ? '[예정] 식단 계획' : '특이사항 없음'))
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('[${mealType.label}] 식단이 성공적으로 저장되었습니다.'), backgroundColor: const Color(0xFF3EB489)),
    );
  }

  void _completePlannedMeal(MealLog log) {
    setState(() {
      log.cubeUsage.forEach((cubeId, count) {
        final idx = _cubes.indexWhere((c) => c.id == cubeId);
        if (idx != -1) _cubes[idx].quantity = (_cubes[idx].quantity - count).clamp(0, 999);
      });
      log.isPlanned = false;
      if (log.reaction.startsWith('[예정]') || log.reaction.contains('계획')) log.reaction = '완식 (식사 완료)';
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('[${log.mealType.label}] 식사 완료! 큐브가 차감되었습니다.'), backgroundColor: const Color(0xFF3EB489)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF3EB489))));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: Color(0xFF3EB489), size: 22),
            SizedBox(width: 6),
            Text('토핑 이유식 매니저', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF234E42))),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Color(0xFF234E42)), onPressed: _showSettings),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // 0번: 캘린더
          MealCalendarTab(
            mealLogs: _mealLogs,
            cubes: _cubes,
            birthDate: _birthDate,
            weaningStartDate: _weaningStartDate,
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
              setState(() => l.reaction = r);
              _saveData();
            },
          ),
          // 1번: 식단 기록
          MealLogTab(
            cubes: _cubes,
            birthDate: _birthDate,
            weaningStartDate: _weaningStartDate,
            onSaveMeal: _addMealRecord,
            onAddPlannedCube: (c) {
              setState(() => _cubes.insert(0, c));
              _saveData();
            },
          ),
          // 2번: 보관함
          CubeStockTab(
            cubes: _cubes,
            mealLogs: _mealLogs,
            onUpdateQty: (c, d) {
              setState(() => c.quantity = (c.quantity + d).clamp(0, 999));
              _saveData();
            },
            onAddCube: (c) {
              setState(() => _cubes.insert(0, c));
              _saveData();
            },
            onEditCube: (c, n, cat, w, q, md, sl) {
              setState(() {
                c.name = n;
                c.category = cat;
                c.unitWeight = w;
                c.quantity = q;
                c.madeDate = md;
                c.expireDate = md.add(Duration(days: sl));
                c.isPlannedOnly = false;
              });
              _saveData();
            },
            onDeleteCube: (c) {
              setState(() => _cubes.removeWhere((item) => item.id == c.id));
              _saveData();
            },
          ),
          // 3번: 제작 필요
          RestockPlanTab(
            cubes: _cubes,
            mealLogs: _mealLogs,
            onRestock: (c, w, q, md, sl) {
              setState(() {
                c.unitWeight = w;
                c.quantity += q;
                c.madeDate = md;
                c.expireDate = md.add(Duration(days: sl));
                c.isPlannedOnly = false;
              });
              _saveData();
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        indicatorColor: const Color(0xFFE8F8F2),
        backgroundColor: Colors.white,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF3EB489)), label: '캘린더'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note, color: Color(0xFF3EB489)), label: '식단 기록'),
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen, color: Color(0xFF3EB489)), label: '보관함'),
          NavigationDestination(icon: Icon(Icons.alarm_on_outlined), selectedIcon: Icon(Icons.alarm_on, color: Color(0xFF3EB489)), label: '제작 필요'),
        ],
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
// 1. 식단 기록 화면
// ==========================================
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

  const MealLogTab({super.key, required this.cubes, required this.birthDate, required this.weaningStartDate, required this.onSaveMeal, required this.onAddPlannedCube});

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
  final List<String> _stoolTags = ['황금변', '된변', '무른변', '설사', '대변 X'];
  final Set<String> _activeTags = {};

  int get _repeatDays => DateTime(_endDate.year, _endDate.month, _endDate.day).difference(DateTime(_startDate.year, _startDate.month, _startDate.day)).inDays + 1;
  bool get _isFutureDate => DateTime(_startDate.year, _startDate.month, _startDate.day).isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

  void _showAddUnregisteredDialog() {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '10');
    FoodCategory cat = FoodCategory.vegetable;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text('새 식재료 직접 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '식재료명 (예: 비트, 닭안심)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<FoodCategory>(
                value: cat,
                decoration: const InputDecoration(labelText: '카테고리'),
                items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                onChanged: (v) => setDState(() => cat = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '1회 권장량 (g)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
              onPressed: () {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                final newCube = CubeItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: n,
                  category: cat,
                  unitWeight: int.tryParse(weightCtrl.text) ?? 10,
                  quantity: 0,
                  madeDate: DateTime.now(),
                  expireDate: DateTime.now().add(const Duration(days: 14)),
                  isPlannedOnly: true,
                );
                widget.onAddPlannedCube(newCube);
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
    int totalG = 0;
    for (var c in widget.cubes) {
      totalG += (_selectedQuantities[c.id] ?? 0) * c.unitWeight;
    }
    final ddayStr = calculateDdayString(_startDate, widget.birthDate, widget.weaningStartDate);

    final sortedCubes = List<CubeItem>.from(widget.cubes)
      ..sort((a, b) {
        final cmp = a.category.sortOrder.compareTo(b.category.sortOrder);
        return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isFutureDate ? const Color(0xFFF0FDF8) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isFutureDate ? const Color(0xFFA7E9D1) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_repeatDays > 1 ? Icons.date_range : Icons.calendar_today_outlined, color: const Color(0xFF3EB489), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _repeatDays > 1 ? '$_repeatDays일 연속 동일 식단' : '식단 날짜',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3EB489)),
                          ),
                          Text(
                            _repeatDays > 1 ? '${_startDate.month}/${_startDate.day} ~ ${_endDate.month}/${_endDate.day}' : '${_startDate.year}년 ${_startDate.month}월 ${_startDate.day}일',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF234E42)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final r = await showDateRangePicker(
                          context: context,
                          initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (r != null) setState(() { _startDate = r.start; _endDate = r.end; });
                      },
                      icon: const Icon(Icons.calendar_month, size: 14),
                      label: const Text('기간 달력', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8F8F2), foregroundColor: const Color(0xFF234E42), elevation: 0),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('빠른 설정: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _endDate = _startDate),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _repeatDays == 1 ? const Color(0xFF3EB489) : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _repeatDays == 1 ? const Color(0xFF3EB489) : Colors.grey.shade300),
                        ),
                        child: Text('하루만', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _repeatDays == 1 ? Colors.white : Colors.black87)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _endDate = _startDate.add(const Duration(days: 2))),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _repeatDays == 3 ? const Color(0xFF3EB489) : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _repeatDays == 3 ? const Color(0xFF3EB489) : Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, size: 14, color: _repeatDays == 3 ? Colors.white : Colors.amber.shade800),
                            const SizedBox(width: 2),
                            Text('3일 테스트', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _repeatDays == 3 ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (ddayStr.isNotEmpty && _repeatDays == 1) ...[
                  const SizedBox(height: 10),
                  Text(ddayStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3EB489))),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('시간: ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton.icon(
                      icon: const Icon(Icons.schedule, size: 14),
                      label: const Text('시간 변경', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: _selectedTime);
                        if (t != null) setState(() => _selectedTime = t);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 끼니 선택
          const Text('끼니 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF234E42))),
          const SizedBox(height: 8),
          Row(
            children: MealType.values.map((m) {
              final isSel = _selectedMealType == m;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedMealType = m),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? m.primaryColor : m.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? m.primaryColor : m.primaryColor.withOpacity(0.4)),
                    ),
                    child: Text(m.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSel ? Colors.white : m.primaryColor)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 3. 토핑 큐브 선택
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('토핑 큐브 담기 (1끼 기준)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF234E42))),
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 17, color: Color(0xFF3EB489)),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('식재료 정렬 안내', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              content: const Text('[ 곡류 ➔ 단백질 ➔ 채소 ➔ 과일 ➔ 기타 ]\n순서로 자동 정렬되어 표시됩니다.', style: TextStyle(fontSize: 13, height: 1.5)),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text('총 $totalG g', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3EB489))),
                  ],
                ),
                const SizedBox(height: 8),
                sortedCubes.isEmpty
                    ? const Text('등록된 큐브가 없습니다.')
                    : Column(
                        children: sortedCubes.map((cube) {
                          final count = _selectedQuantities[cube.id] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: cube.category.bgColor, borderRadius: BorderRadius.circular(6)),
                                  child: Text(cube.category.label, style: TextStyle(color: cube.category.textColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(getFoodEmoji(cube.name)),
                                          const SizedBox(width: 4),
                                          Text('${cube.name} (${cube.unitWeight}g)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          if (cube.isPlannedOnly) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFCE93D8))),
                                              child: const Text('신규 제작필요', style: TextStyle(fontSize: 10, color: Color(0xFF9C27B0), fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (!cube.isPlannedOnly)
                                        Text('재고 ${cube.quantity}개 · 사용기한 ${cube.dDayText}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: count > 0 ? () => setState(() => _selectedQuantities[cube.id] = count - 1) : null),
                                Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => setState(() => _selectedQuantities[cube.id] = count + 1)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                const Divider(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showAddUnregisteredDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6A1B9A),
                      side: const BorderSide(color: Color(0xFFCE93D8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('미등록 재료 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. 빠른 반응 체크
          if (!_isFutureDate && _repeatDays == 1) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('빠른 반응 체크', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF234E42))),
                  const SizedBox(height: 10),
                  _buildTagGroup('피부/알레르기', _skinTags, const Color(0xFFE53935)),
                  const SizedBox(height: 8),
                  _buildTagGroup('배변 상태', _stoolTags, const Color(0xFFF57C00)),
                  const SizedBox(height: 8),
                  _buildTagGroup('식사 태도', _attitudeTags, const Color(0xFF3EB489)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _reactionController,
            decoration: InputDecoration(
              labelText: _repeatDays > 1 ? '연속 식단 공통 메모' : '식단 계획 / 아기 반응 메모',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                if (_selectedQuantities.isEmpty) return;
                final dt = DateTime(_startDate.year, _startDate.month, _startDate.day, _selectedTime.hour, _selectedTime.minute);
                Map<CubeItem, int> selected = {};
                for (var c in widget.cubes) {
                  if (_selectedQuantities.containsKey(c.id)) selected[c] = _selectedQuantities[c.id]!;
                }
                widget.onSaveMeal(mealType: _selectedMealType, startDate: dt, repeatDays: _repeatDays, selectedCubes: selected, reaction: _reactionController.text.trim());
                setState(() {
                  _selectedQuantities.clear();
                  _reactionController.clear();
                  _endDate = _startDate;
                });
              },
              child: Text(_repeatDays > 1 ? '$_repeatDays일 연속 식단 저장하기' : '식단 저장하기', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagGroup(String title, List<String> tags, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: tags.map((t) {
            final isSel = _activeTags.contains(t);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSel) _activeTags.remove(t); else _activeTags.add(t);
                  _reactionController.text = _activeTags.join(', ');
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isSel ? color : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isSel ? color : Colors.grey.shade300),
                ),
                child: Text(t, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ==========================================
// 2. 캘린더 화면 (식단 수정 시 토핑 큐브 직접 추가/제거 가능)
// ==========================================
class MealCalendarTab extends StatefulWidget {
  final List<MealLog> mealLogs;
  final List<CubeItem> cubes;
  final DateTime? birthDate;
  final DateTime? weaningStartDate;
  final Function(MealLog, MealType, DateTime, String, int, Map<String, int>, List<String>) onEditMealFull;
  final Function(MealLog) onDeleteMeal;
  final Function(MealLog) onCompleteMeal;
  final Function(MealLog, String) onUpdateReaction;

  const MealCalendarTab({super.key, required this.mealLogs, required this.cubes, required this.birthDate, required this.weaningStartDate, required this.onEditMealFull, required this.onDeleteMeal, required this.onCompleteMeal, required this.onUpdateReaction});

  @override
  State<MealCalendarTab> createState() => _MealCalendarTabState();
}

class _MealCalendarTabState extends State<MealCalendarTab> {
  bool _isWeekView = false;
  late DateTime _focusedDate;
  late DateTime _selectedDate;

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
    final past = widget.mealLogs.where((l) => DateTime(l.time.year, l.time.month, l.time.day).isBefore(curDay)).toList();
    Set<String> pastIds = {};
    for (var pl in past) { pastIds.addAll(pl.cubeUsage.keys); }

    log.cubeUsage.forEach((id, count) {
      if (!pastIds.contains(id)) {
        final match = widget.cubes.firstWhere((c) => c.id == id, orElse: () => CubeItem(id: '', name: '', category: FoodCategory.etc, unitWeight: 0, quantity: 0, madeDate: DateTime.now(), expireDate: DateTime.now()));
        if (match.name.isNotEmpty) news.add(match.name);
      }
    });
    return news;
  }

  // 식단 수정 팝업: 토핑 큐브 증감 및 직접 추가/제거 지원
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
                        Text('총 $computedGrams g', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3EB489))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 현재 보관함 큐브 목록을 띄워 바로 추가/감소 가능
                    ...widget.cubes.map((c) {
                      final count = editUsage[c.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(getFoodEmoji(c.name)),
                            const SizedBox(width: 6),
                            Expanded(child: Text('${c.name} (${c.unitWeight}g)', style: TextStyle(fontSize: 12, fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal))),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
                onPressed: () {
                  final newDt = DateTime(log.time.year, log.time.month, log.time.day, currentTime.hour, currentTime.minute);
                  List<String> newIngs = [];
                  editUsage.forEach((id, cnt) {
                    if (cnt > 0) {
                      final c = widget.cubes.firstWhere((item) => item.id == id, orElse: () => CubeItem(id: '', name: '', category: FoodCategory.etc, unitWeight: 10, quantity: 0, madeDate: DateTime.now(), expireDate: DateTime.now()));
                      newIngs.add('${c.name} ${c.unitWeight * cnt}g ($cnt개)');
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

  @override
  Widget build(BuildContext context) {
    final logs = _getLogsForDate(_selectedDate);
    final dday = calculateDdayString(_selectedDate, widget.birthDate, widget.weaningStartDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isWeekView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(color: _isWeekView ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: Text('주간', style: TextStyle(fontSize: 12, fontWeight: _isWeekView ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF234E42))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isWeekView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(color: !_isWeekView ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: Text('월간', style: TextStyle(fontSize: 12, fontWeight: !_isWeekView ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF234E42))),
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
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1))),
                Text('${_focusedDate.year}년 ${_focusedDate.month}월', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF234E42))),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1))),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: _isWeekView ? _buildWeekView() : _buildMonthView(),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selectedDate.month}월 ${_selectedDate.day}일 식단', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF234E42))),
                if (dday.isNotEmpty) Text(dday, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3EB489))),
              ],
            ),
          ),
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('등록된 식단이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    itemCount: logs.length,
                    itemBuilder: (ctx, i) {
                      final l = logs[i];
                      final news = _getNewIngredients(l);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: l.isPlanned
                                ? const Color(0xFF3EB489)
                                : (news.isNotEmpty ? const Color(0xFFFFB74D) : Colors.grey.shade200),
                            width: l.isPlanned ? 1.5 : 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
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
                                        decoration: BoxDecoration(color: l.mealType.bgColor, borderRadius: BorderRadius.circular(4)),
                                        child: Text(l.mealType.label, style: TextStyle(color: l.mealType.primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text('${l.time.hour.toString().padLeft(2, '0')}:${l.time.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      if (l.isPlanned) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFE8F8F2), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('식단 계획', style: TextStyle(fontSize: 10, color: Color(0xFF3EB489), fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text('${l.totalGrams}g', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
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
                              if (news.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('⚠️ NEW 첫 시도: ${news.map((e) => "${getFoodEmoji(e)} $e").join(", ")}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                              ],
                              const SizedBox(height: 4),
                              Text(l.ingredients.join(' + '), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              if (l.reaction.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(l.reaction, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                                      onPressed: () => _showReactionDialog(l),
                                      child: const Text('반응/알레르기 기록', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                  if (l.isPlanned) ...[
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                                        onPressed: () => widget.onCompleteMeal(l),
                                        child: const Text('식사 완료 (차감)', style: TextStyle(fontSize: 11)),
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

  void _showReactionDialog(MealLog log) {
    final ctrl = TextEditingController(text: log.reaction);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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

  Widget _buildWeekView() {
    final offset = _focusedDate.weekday % 7;
    final start = _focusedDate.subtract(Duration(days: offset));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final now = DateTime.now();

    return Row(
      children: days.map((d) {
        final isSel = _isSameDay(d, _selectedDate);
        final isToday = _isSameDay(d, now);

        return Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedDate = d),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF3EB489) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: (!isSel && isToday) ? Border.all(color: const Color(0xFF3EB489), width: 1.5) : null,
              ),
              child: Column(
                children: [
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: (isSel || isToday) ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.white : (isToday ? const Color(0xFF3EB489) : Colors.black87),
                    ),
                  ),
                  if (_getLogsForDate(d).isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : const Color(0xFF3EB489),
                        shape: BoxShape.circle,
                      ),
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
    final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday % 7;
    final totalDays = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final rows = ((firstDay + totalDays) / 7).ceil();
    final now = DateTime.now();

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(7, (c) {
            final idx = r * 7 + c;
            final day = idx - firstDay + 1;
            if (day < 1 || day > totalDays) return const Expanded(child: SizedBox(height: 34));
            final d = DateTime(_focusedDate.year, _focusedDate.month, day);
            final isSel = _isSameDay(d, _selectedDate);
            final isToday = _isSameDay(d, now);

            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedDate = d),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF3EB489) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: (!isSel && isToday) ? Border.all(color: const Color(0xFF3EB489), width: 1.5) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (isSel || isToday) ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? Colors.white : (isToday ? const Color(0xFF3EB489) : Colors.black87),
                        ),
                      ),
                      if (_getLogsForDate(d).isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : const Color(0xFF3EB489),
                            shape: BoxShape.circle,
                          ),
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

// ==========================================
// 3. 큐브 보관함 화면
// ==========================================
class CubeStockTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final List<MealLog> mealLogs;
  final Function(CubeItem, int) onUpdateQty;
  final Function(CubeItem) onAddCube;
  final Function(CubeItem, String, FoodCategory, int, int, DateTime, int) onEditCube;
  final Function(CubeItem) onDeleteCube;

  const CubeStockTab({super.key, required this.cubes, required this.mealLogs, required this.onUpdateQty, required this.onAddCube, required this.onEditCube, required this.onDeleteCube});

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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text('새 큐브 등록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nCtrl, decoration: const InputDecoration(labelText: '식재료명 (예: 감자, 닭고기)')),
                const SizedBox(height: 10),
                DropdownButtonFormField<FoodCategory>(
                  value: cat,
                  decoration: const InputDecoration(labelText: '카테고리'),
                  items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setDState(() => cat = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '1개 용량 (g)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '제작 개수'))),
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
                      label: const Text('날짜 선택'),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
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
                ));
                Navigator.pop(ctx);
              },
              child: const Text('저장'),
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
    if (![3, 7, 14].contains(shelfDays)) shelfDays = 14;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: Text('${c.name} 큐브 정보 수정', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nCtrl, decoration: const InputDecoration(labelText: '식재료명')),
                const SizedBox(height: 10),
                DropdownButtonFormField<FoodCategory>(
                  value: cat,
                  decoration: const InputDecoration(labelText: '카테고리'),
                  items: FoodCategory.values.map((catItem) => DropdownMenuItem(value: catItem, child: Text(catItem.label))).toList(),
                  onChanged: (v) => setDState(() => cat = v!),
                ),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
              onPressed: () {
                if (nCtrl.text.trim().isEmpty) return;
                widget.onEditCube(c, nCtrl.text.trim(), cat, int.tryParse(weightCtrl.text) ?? c.unitWeight, int.tryParse(qtyCtrl.text) ?? c.quantity, mDate, shelfDays);
                Navigator.pop(ctx);
              },
              child: const Text('수정 완료'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final futureLogs = widget.mealLogs.where((l) {
      final d = DateTime(l.time.year, l.time.month, l.time.day);
      return d.isAfter(today) || d.isAtSameMomentAs(today);
    }).toList()..sort((a, b) => a.time.compareTo(b.time));

    DateTime getFirstNeedDate(CubeItem cube) {
      for (var l in futureLogs) {
        if (l.cubeUsage.containsKey(cube.id) || l.ingredients.any((ing) => ing.contains(cube.name))) {
          return l.time;
        }
      }
      return DateTime(2099, 12, 31);
    }

    final filtered = _selCat == null ? List<CubeItem>.from(widget.cubes) : widget.cubes.where((c) => c.category == _selCat).toList();

    filtered.sort((a, b) {
      if (!a.isPlannedOnly && b.isPlannedOnly) return -1;
      if (a.isPlannedOnly && !b.isPlannedOnly) return 1;

      if (!a.isPlannedOnly && !b.isPlannedOnly) {
        return a.madeDate.compareTo(b.madeDate);
      } else {
        final dateA = getFirstNeedDate(a);
        final dateB = getFirstNeedDate(b);
        final cmp = dateA.compareTo(dateB);
        return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  InkWell(
                    onTap: () => setState(() => _selCat = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: _selCat == null ? const Color(0xFFE8F8F2) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                      child: Text('전체', style: TextStyle(fontSize: 12, fontWeight: _selCat == null ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ...FoodCategory.values.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selCat = _selCat == cat ? null : cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: _selCat == cat ? const Color(0xFFE8F8F2) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                        child: Text(cat.label, style: TextStyle(fontSize: 12, fontWeight: _selCat == cat ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('새 큐브 등록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3EB489),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final c = filtered[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: c.isPlannedOnly ? const Color(0xFFCE93D8) : Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: c.category.bgColor, borderRadius: BorderRadius.circular(4)),
                                  child: Text(c.category.label, style: TextStyle(color: c.category.textColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: c.statusBgColor, borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    c.dDayText,
                                    style: TextStyle(color: c.statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showEditDialog(c);
                                } else if (val == 'delete') {
                                  widget.onDeleteCube(c);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(fontSize: 13))),
                                const PopupMenuItem(value: 'delete', child: Text('삭제/폐기', style: TextStyle(fontSize: 13, color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(getFoodEmoji(c.name), style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  if (!c.isPlannedOnly)
                                    Text('개당 ${c.unitWeight}g · ${c.quantity}개 남음 (제조: ${c.madeDate.month}.${c.madeDate.day})', style: const TextStyle(fontSize: 11, color: Colors.grey))
                                  else
                                    Text('1회 권장량 ${c.unitWeight}g', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: c.quantity > 0 ? () => widget.onUpdateQty(c, -1) : null),
                            Text('${c.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => widget.onUpdateQty(c, 1)),
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
}

// ==========================================
// 4. 제작 필요 화면 (실제 계획 소진 시점 스마트 반영)
// ==========================================
enum RestockFilter { all, owned, unowned }

class RestockPlanTab extends StatefulWidget {
  final List<CubeItem> cubes;
  final List<MealLog> mealLogs;
  final Function(CubeItem, int, int, DateTime, int) onRestock;

  const RestockPlanTab({super.key, required this.cubes, required this.mealLogs, required this.onRestock});

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
          title: Text('${c.name} 제작 완료 등록', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3EB489), foregroundColor: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 미래/당일 식단 로그
    final futureLogs = widget.mealLogs.where((l) {
      final logDay = DateTime(l.time.year, l.time.month, l.time.day);
      return logDay.isAfter(today) || logDay.isAtSameMomentAs(today);
    }).toList()..sort((a, b) => a.time.compareTo(b.time));

    List<_PlanDisplayItem> items = [];

    for (var cube in widget.cubes) {
      // 해당 큐브가 쓰이는 미래 식단 목록 (ID 또는 재료명으로 안전하게 탐색)
      List<MealLog> matchedLogs = [];
      for (var l in futureLogs) {
        final usesById = l.cubeUsage.containsKey(cube.id);
        final usesByName = l.ingredients.any((ing) => ing.contains(cube.name));
        if (usesById || usesByName) {
          matchedLogs.add(l);
        }
      }

      // 1. 미보유 신규 큐브 (식단에 배정되어 있으므로 무조건 제작 필요)
      if (cube.isPlannedOnly) {
        final targetDate = matchedLogs.isNotEmpty ? matchedLogs.first.time : null;
        final dl = targetDate != null ? '${targetDate.month}월 ${targetDate.day}일' : '식단 전';
        items.add(_PlanDisplayItem(
          cube: cube,
          urgency: null,
          deadline: dl,
          color: const Color(0xFF8E24AA),
          score: targetDate != null ? targetDate.difference(today).inDays : 999,
          isUnowned: true,
        ));
        continue;
      }

      final curQty = cube.quantity;
      final isExpired = cube.daysRemaining < 0;

      // 2. 현재 재고 0개
      if (curQty == 0) {
        final nextUse = matchedLogs.isNotEmpty ? matchedLogs.first.time : null;
        final dl = nextUse != null ? '${nextUse.month}월 ${nextUse.day}일' : '즉시 제작 권장';
        items.add(_PlanDisplayItem(
          cube: cube,
          urgency: '현재 재고 0개',
          deadline: dl,
          color: const Color(0xFFE53935),
          score: nextUse != null ? nextUse.difference(today).inDays : 900,
          isUnowned: false,
        ));
        continue;
      }

      // 3. 소비기한 만료
      if (isExpired) {
        final nextUse = matchedLogs.isNotEmpty ? matchedLogs.first.time : null;
        final dl = nextUse != null ? '${nextUse.month}월 ${nextUse.day}일 (식단 전)' : '폐기 후 신규 제작';
        items.add(_PlanDisplayItem(
          cube: cube,
          urgency: '소비기한 만료',
          deadline: dl,
          color: const Color(0xFFE65100),
          score: nextUse != null ? nextUse.difference(today).inDays : 100,
          isUnowned: false,
        ));
        continue;
      }

      // 4. 재고 1~3개인 보유 큐브:
      // ★ 실제 향후 식단 계획에서 기존 재고가 바닥나는 시점(outOfStockDate)이 생길 때만 리스트에 올림!
      if (curQty <= 3) {
        int simulatedQty = curQty;
        DateTime? outOfStockDate;

        for (var l in matchedLogs) {
          int count = l.cubeUsage[cube.id] ?? 1;
          simulatedQty -= count;
          if (simulatedQty < 1) {
            outOfStockDate = l.time;
            break;
          }
        }

        // 기존 재고로 예정된 식단을 다 커버하고도 남거나, 향후 식단 계획이 아예 없다면 굳이 목록에 띄우지 않음!
        if (outOfStockDate != null) {
          items.add(_PlanDisplayItem(
            cube: cube,
            urgency: '소진 임박',
            deadline: '${outOfStockDate.month}월 ${outOfStockDate.day}일',
            color: const Color(0xFFE53935),
            score: outOfStockDate.difference(today).inDays,
            isUnowned: false,
          ));
        }
      }
    }

    // 마감일이 당장 가까운 순으로 자동 정렬
    items.sort((a, b) => a.score.compareTo(b.score));

    final filteredItems = items.where((i) {
      if (_filter == RestockFilter.owned) return !i.isUnowned;
      if (_filter == RestockFilter.unowned) return i.isUnowned;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildFilterButton('전체', RestockFilter.all),
                const SizedBox(width: 8),
                _buildFilterButton('보유', RestockFilter.owned),
                const SizedBox(width: 8),
                _buildFilterButton('미보유', RestockFilter.unowned),
              ],
            ),
            const SizedBox(height: 14),
            Text('제작 필요 토핑 (${filteredItems.length}개)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF234E42))),
            const SizedBox(height: 10),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text('해당하는 큐브가 없습니다! 🎉', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (ctx, i) {
                        final item = filteredItems[i];
                        final c = item.cube;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: item.color.withOpacity(0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Text(getFoodEmoji(c.name), style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          if (item.urgency != null) ...[
                                            const SizedBox(width: 6),
                                            Text(item.urgency!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.color)),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      if (c.isPlannedOnly)
                                        Text('1회 권장량 ${c.unitWeight}g', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))
                                      else
                                        Text('현재 재고 ${c.quantity}개 (개당 ${c.unitWeight}g)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      const SizedBox(height: 2),
                                      Text('제작 마감일: ${item.deadline}', style: TextStyle(fontSize: 11, color: item.color, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.isPlannedOnly ? const Color(0xFF8E24AA) : const Color(0xFF3EB489),
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _showRestockDialog(c),
                                  child: const Text('제작 완료', style: TextStyle(fontSize: 11)),
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

  Widget _buildFilterButton(String label, RestockFilter filter) {
    final isSel = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF3EB489) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? const Color(0xFF3EB489) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? Colors.white : const Color(0xFF234E42),
          ),
        ),
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

  _PlanDisplayItem({
    required this.cube,
    this.urgency,
    required this.deadline,
    required this.color,
    required this.score,
    required this.isUnowned,
  });
}
