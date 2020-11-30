import 'package:flutter/material.dart';
import '../managers/pageView.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../managers/Firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Calendar extends StatefulWidget {
  final String title;
  final PageController tabController;
  DateTime activeDate;
  Calendar({Key key, this.title, this.tabController, this.activeDate})
      : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  Map<DateTime, List> _entries = {};
  List _entryInfos = [];
  List _selectedEntries;
  AnimationController _animationController;
  CalendarController _calendarController;
  DateTime _selectedDay;
  final User _user = checkUserLoginStatus();

  CollectionReference entries = getFireStore();

  Future<void> getEntries() {
    return entries
        .where('user_id', isEqualTo: _user.uid)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) {
                Map<String, dynamic> entryInfo = {
                  "doc_id": doc.id,
                  "title": doc["title"],
                  "timestamp": doc["timestamp"],
                };
                _entryInfos.add(entryInfo);
                DateTime date = entryInfo["timestamp"].toDate();
                DateTime formatDate = DateTime(date.year, date.month, date.day);
                if (_entries.containsKey(formatDate)) {
                  _entries[formatDate].add(entryInfo["title"]);
                } else {
                  _entries[formatDate] = [entryInfo["title"]];
                }
                print(_entryInfos);
              })
            });
  }

  @override
  void initState() {
    super.initState();
    getEntries();
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
    MainView.of(context).date =
        day; // update all date states to the selected one
    setState(() {
      _selectedDay = day;
      _selectedEntries = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    widget.activeDate = _selectedDay,
                    widget.tabController.animateToPage(1,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn),
                    MainView.of(context).date = _selectedDay,
                    print('$event tapped!, $_selectedDay'),
                    print(widget.activeDate.toString()),
                  },
                ),
              ))
          .toList(),
    );
  }
}
