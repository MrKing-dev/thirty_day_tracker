import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RollingTrackerApp());
}

class RollingTrackerApp extends StatelessWidget {
  const RollingTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: RollingTrackerPage(),
    );
  }
}

class RollingTrackerPage extends StatefulWidget {
  @override
  _RollingTrackerPageState createState() => _RollingTrackerPageState();
}

class _RollingTrackerPageState extends State<RollingTrackerPage> {
  List<Map<String, dynamic>> _days = [];
  bool _isDataLoaded = false;

  Future<void> _saveDays() async {
    final prefs = await SharedPreferences.getInstance();
    final daysJson = jsonEncode(_days);
    await prefs.setString('days', daysJson);
  }

  Future<void> _loadDays() async {
    final prefs = await SharedPreferences.getInstance();
    final daysJson = prefs.getString('days');
    if (daysJson != null) {
      setState(() {
        _days = List<Map<String, dynamic>>.from(jsonDecode(daysJson));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeDays();
  }

  Future<void> _initializeDays() async {
    await _loadDays();
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currentDateString = dateFormat.format(now);

    bool needsRestart = true;

    while (needsRestart) {
      needsRestart = false;

      // Ensure the last day is the current date
      if (_days.isEmpty || _days.last['date'] != currentDateString) {
        _days.add({
          'date': currentDateString,
          'isOn': false,
        });
        needsRestart = true;
        continue;
      }

      // Iterate backward to ensure each day is the previous day to the last one checked
      for (int i = _days.length - 1; i > 0; i--) {
        DateTime currentDay = dateFormat.parse(_days[i]['date']);
        DateTime previousDay = currentDay.subtract(Duration(days: 1));
        String previousDayString = dateFormat.format(previousDay);

        if (_days[i - 1]['date'] != previousDayString) {
          _days.insert(i, {
            'date': previousDayString,
            'isOn': false,
          });
          needsRestart = true;
          break;
        }
      }
    }

    // Add missing days if the list is shorter than 30 days
    while (_days.length < 30) {
      DateTime lastDay = dateFormat.parse(_days.first['date']);
      DateTime newDay = lastDay.subtract(Duration(days: 1));
      _days.insert(0, {
        'date': dateFormat.format(newDay),
        'isOn': false,
      });
    }

    // Ensure the list does not exceed 30 days
    while (_days.length > 30) {
      _days.removeAt(0);
    }

    setState(() {
      _isDataLoaded = true;
    });
    _saveDays();
  }

  void _toggleDay(int index) {
    setState(() {
      _days[index]['isOn'] = !_days[index]['isOn'];
    });
    _saveDays();
  }

  int _countOnDays() {
    return _days.where((day) => day['isOn']).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rolling 30-Day Tracker (${_countOnDays()})'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeDays,
          ),
        ],
      ),
      body: _isDataLoaded
          ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 5 columns
                childAspectRatio: 1, // 1:1 aspect ratio for squares
              ),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                return GestureDetector(
                  onTap: () {
                    _toggleDay(index);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: day['isOn'] ? Colors.purple : Colors.grey[700],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          day['date'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
