import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'Navigation.dart';
class Calendar extends StatefulWidget {
  Calendar({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  Map<DateTime, List> _entries;
  List _selectedEntries;
  AnimationController _animationController;
  CalendarController _calendarController;
  DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();

    _entries = {
      DateTime.parse("2020-11-25 20:18:04Z"): ['Roppongi'],
      DateTime.parse("2020-11-20 20:18:04Z"): ['Shinjuku', 'Asakusa'],
      DateTime.parse("2020-11-16 20:18:04Z"): ['Disney Land'],
    };

    _selectedEntries = _entries[_selectedDay] ?? [];

    _calendarController = CalendarController();
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  void _makeEntry() {
    print(_selectedDay);
  }

  void _onDaySelected(DateTime day, List events, List holidays) {
    setState(() {
      _selectedDay = day;
      _selectedEntries = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   centerTitle: true,
      //   title: Text(
      //     "Inkling",
      //   ),
      // ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            _buildTableCalendar(),
            Expanded(child: _buildEntryList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _makeEntry,
        tooltip: 'New Entry',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
      calendarController: _calendarController,
      events: _entries,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        selectedColor: Colors.deepOrange[400],
        todayColor: Colors.deepOrange[200],
        markersColor: Colors.brown[700],
        outsideDaysVisible: false,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        centerHeaderTitle: true,
      ),
      onDaySelected: _onDaySelected,
    );
  }

  Widget _buildEntryList() {
    return ListView(
      children: _selectedEntries
          .map((event) => Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 0.8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                    title: Text(event.toString()),
                    onTap: () => {
                          print('$event tapped!, $_selectedDay'),
                        } // replace this with switch page view
                    ),
              ))
          .toList(),
    );
  }
}
