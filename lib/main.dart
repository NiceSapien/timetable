import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(TimetableApp());
}

class TimetableApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timetable Pro',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Color(0xFFF2F6FF),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TimetableScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TimetableScreen extends StatefulWidget {
  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<String> days = [];
  List<List<String>> timetable = [];

  int? currentPackedDayIndex;
  int? targetPackingDayIndex;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    final String jsonString =
        await rootBundle.loadString('assets/timetable.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);

    setState(() {
      days = List<String>.from(data['days']);
      timetable = (data['timetable'] as List<dynamic>)
          .map((row) => List<String>.from(row))
          .toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading Timetable")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('My School Timetable'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.backpack_rounded),
            tooltip: 'Pack Bag',
            onPressed: () => showPackBagSheet(),
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(12),
          child: Table(
            border: TableBorder.all(color: Colors.indigo.shade100),
            defaultColumnWidth: FixedColumnWidth(isMobile ? 100 : 120),
            children: [
              _buildHeaderRow(),
              for (int day = 0; day < days.length; day++) _buildDayRow(day),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      children: [
        _headerCell('Day / Period'),
        for (int i = 1; i <= 8; i++) _headerCell('P$i'),
      ],
    );
  }

  TableRow _buildDayRow(int day) {
    return TableRow(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.all(10),
          child: Text(
            days[day],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        for (int period = 0; period < 8; period++) _periodCell(day, period),
      ],
    );
  }

  Widget _headerCell(String label) {
    return Container(
      padding: EdgeInsets.all(10),
      color: Colors.indigo.shade100,
      child: Center(
        child: Text(label,
            style:
                TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
    );
  }

  Widget _periodCell(int day, int period) {
    final subject = timetable[period][day];
    Color? bgColor;

    if (currentPackedDayIndex != null && targetPackingDayIndex != null) {
      final currentSubjects = Set<String>.from(
        timetable.map((row) => row[currentPackedDayIndex!]),
      );
      final targetSubjects = Set<String>.from(
        timetable.map((row) => row[targetPackingDayIndex!]),
      );

      if (day == currentPackedDayIndex && !targetSubjects.contains(subject)) {
        bgColor = Colors.red[100]; // To remove
      } else if (day == targetPackingDayIndex &&
          !currentSubjects.contains(subject)) {
        bgColor = Colors.green[100]; // To add
      }
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      margin: EdgeInsets.all(4),
      padding: EdgeInsets.all(8),
      child: Center(
        child: Text(subject, textAlign: TextAlign.center),
      ),
    );
  }

  void showPackBagSheet() {
    int? selectedCurrent;
    int? selectedTarget;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pack Bag',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration:
                        InputDecoration(labelText: "Currently Packed For"),
                    value: selectedCurrent,
                    items: List.generate(days.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(days[index]),
                      );
                    }),
                    onChanged: (val) =>
                        setSheetState(() => selectedCurrent = val),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: "Packing For"),
                    value: selectedTarget,
                    items: List.generate(days.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(days[index]),
                      );
                    }),
                    onChanged: (val) =>
                        setSheetState(() => selectedTarget = val),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (selectedCurrent != null && selectedTarget != null) {
                        setState(() {
                          currentPackedDayIndex = selectedCurrent;
                          targetPackingDayIndex = selectedTarget;
                        });
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(Icons.compare),
                    label: Text('Compare & Highlight'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
