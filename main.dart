import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Mouse ve Touch desteği için gerekli
import 'package:intl/intl.dart';

void main() => runApp(const FocusFlowApp());


class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch, // Mobil parmak kontrolü
        PointerDeviceKind.mouse, // Masaüstü/Web mouse sürükleme kontrolü
        PointerDeviceKind.trackpad, // Touchpad kontrolü
      };
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // BURASI KRİTİK: Sisteme sürükleme desteğini burada enjekte ediyoruz.
      scrollBehavior: MyCustomScrollBehavior(), 
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const MainNavigationScreen(),
    );
  }
}


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const ProfessionalNoteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Görevlerim'),
          NavigationDestination(icon: Icon(Icons.note_alt_rounded), label: 'Notlarım'),
        ],
      ),
    );
  }
}

// --- DASHBOARD (Senin Kodun) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  
  final Map<String, String> _specialDays = {
    "01-01": "Yılbaşı 🎊", "02-14": "Sevgililer Günü ❤️", "04-23": "23 Nisan 🇹🇷",
    "05-01": "İşçi Bayramı 🛠️", "05-19": "19 Mayıs 🇹🇷", "08-30": "Zafer Bayramı 🇹🇷", "10-29": "Cumhuriyet 🇹🇷",
  };

  late List<Map<String, dynamic>> _todoList;
  final List<Map<String, dynamic>> _notes = [
    {"content": "Takvimde kırmızı günler tatildir!", "color": Colors.orange.shade100},
    {"content": "Notlarım sekmesinden kalıcı notlar alabilirsin.", "color": Colors.blue.shade100},
  ];

  @override
  void initState() {
    super.initState();
    _todoList = [
      {"title": "FocusFlow Test Et", "isDone": false, "date": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)},
    ];
  }

  double _calculateProgress() {
    final daily = _todoList.where((t) => t['date'].day == _selectedDate.day && t['date'].month == _selectedDate.month).toList();
    if (daily.isEmpty) return 0.0;
    return daily.where((t) => t['isDone'] == true).length / daily.length;
  }

  Future<void> _selectFullDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    String? holidayName = _specialDays[DateFormat('MM-dd').format(_selectedDate)];
    final dailyTasks = _todoList.where((t) => t['date'].day == _selectedDate.day && t['date'].month == _selectedDate.month).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("FocusFlow", style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(Icons.calendar_month_rounded, size: 28), onPressed: () => _selectFullDate(context)),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressCard(holidayName),
                  const SizedBox(height: 25),
                  _sectionHeader("Haftalık Takvim", Icons.date_range_rounded),
                  _buildHorizontalCalendar(),
                  const SizedBox(height: 25),
                  _sectionHeader("Hızlı Notlar", Icons.lightbulb_outline),
                  _buildNotesList(),
                  const SizedBox(height: 25),
                  _sectionHeader(holidayName != null ? "Görevler ($holidayName)" : "Günün Görevleri", Icons.task_alt),
                ],
              ),
            ),
          ),
          dailyTasks.isEmpty 
          ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("Bu gün için plan yok.", style: TextStyle(color: Colors.grey)))))
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildTodoItem(dailyTasks[i]),
                childCount: dailyTasks.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(),
        label: const Text("Yeni Görev"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProgressCard(String? holidayName) {
    double progress = _calculateProgress();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: holidayName != null ? [Colors.red.shade400, Colors.red.shade700] : [Colors.indigo.shade400, Colors.indigo.shade700]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(holidayName ?? "Günlük Özet", style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text("%${(progress * 100).toInt()} Tamamlandı", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
          const Icon(Icons.auto_awesome, color: Colors.white, size: 35),
        ]),
        const SizedBox(height: 15),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white24, color: Colors.white, minHeight: 10)),
      ]),
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(height: 95, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 30, itemBuilder: (context, index) {
      DateTime date = DateTime.now().add(Duration(days: index - 3));
      bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
      bool isSpecial = _specialDays[DateFormat('MM-dd').format(date)] != null;
      return GestureDetector(
        onTap: () => setState(() => _selectedDate = date),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250), width: 65, margin: const EdgeInsets.only(right: 12), 
          decoration: BoxDecoration(color: isSelected ? Colors.indigo : (isSpecial ? Colors.red.withOpacity(0.1) : Theme.of(context).cardColor), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? Colors.indigo : Colors.grey.withOpacity(0.2))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('E').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 11)), 
            Text(date.day.toString(), style: TextStyle(color: isSelected ? Colors.white : (isSpecial ? Colors.red : null), fontSize: 18, fontWeight: FontWeight.bold)),
            if(isSpecial) const Icon(Icons.star, size: 10, color: Colors.orange)
          ])));
    }));
  }

  Widget _buildNotesList() {
    return SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _notes.length, itemBuilder: (ctx, i) => Container(width: 220, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _notes[i]['color'], borderRadius: BorderRadius.circular(20)), child: Text(_notes[i]['content'], maxLines: 3))));
  }

  Widget _buildTodoItem(Map<String, dynamic> todo) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Card(child: ListTile(onTap: () => setState(() => todo['isDone'] = !todo['isDone']), leading: Icon(todo['isDone'] ? Icons.check_circle_rounded : Icons.radio_button_off_rounded, color: todo['isDone'] ? Colors.green : Colors.indigo), title: Text(todo['title'], style: TextStyle(decoration: todo['isDone'] ? TextDecoration.lineThrough : null)))));
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, color: Colors.indigo, size: 22), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]));

  void _showAddTaskSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Container(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("${DateFormat('d MMMM').format(_selectedDate)} Tarihine Ekle", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 15), TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: "Görev detayı...", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))), const SizedBox(height: 20), ElevatedButton(onPressed: () { if(ctrl.text.isNotEmpty) setState(() => _todoList.add({"title": ctrl.text, "isDone": false, "date": DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)})); Navigator.pop(ctx); }, child: const Text("Kaydet")), const SizedBox(height: 20)])));
  }
}

// --- 2. SAYFA: PROFESYONEL NOTLAR (Senin Kodun) ---
class ProfessionalNoteScreen extends StatefulWidget {
  const ProfessionalNoteScreen({super.key});
  @override
  State<ProfessionalNoteScreen> createState() => _ProfessionalNoteScreenState();
}

class _ProfessionalNoteScreenState extends State<ProfessionalNoteScreen> {
  final List<Map<String, String>> _myNotes = [];
  final TextEditingController _noteController = TextEditingController();

  void _saveNote() {
    if (_noteController.text.trim().isNotEmpty) {
      setState(() {
        _myNotes.insert(0, {"content": _noteController.text, "time": DateFormat('HH:mm | d MMM').format(DateTime.now())});
        _noteController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Not Defterim")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                TextField(controller: _noteController, maxLines: 4, decoration: const InputDecoration(hintText: "Buraya not al...", border: InputBorder.none, contentPadding: EdgeInsets.all(12))),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  ElevatedButton(onPressed: _saveNote, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white), child: const Text("Kaydet"))
                ])
              ])
            )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              const Icon(Icons.history_rounded, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("Kayıtlı Notlar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            ])
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _myNotes.length,
              itemBuilder: (ctx, i) => Card(
                color: Colors.amber.shade50,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(_myNotes[i]['content']!),
                  subtitle: Text(_myNotes[i]['time']!, style: const TextStyle(fontSize: 10)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => setState(() => _myNotes.removeAt(i))),
                )
              )
            )
          )
        ],
      ),
    );
  }
}
