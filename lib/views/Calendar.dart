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
  String documentId;
  Calendar(
      {Key key,
      this.documentId,
      this.title,
      this.tabController,
      this.activeDate})
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

  CollectionReference entries = getFireStoreEntriesDB();

  Future<void> getEntries(dateWithMonth) async {
    Map<DateTime, List> entryParser = {};
    _entryInfos = [];
    _entries = {};
    await entries
        .where('user_id', isEqualTo: _user.uid)
        .where('timestamp',
            isGreaterThan: DateTime(dateWithMonth.year, dateWithMonth.month))
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
                if (entryParser.containsKey(formatDate)) {
                  entryParser[formatDate].add(entryInfo["title"]);
                } else {
                  entryParser[formatDate] = [entryInfo["title"]];
                }
                //print(_entries);
              })
            });
    setState(() {
      _selectedDay = DateTime.now();
      _entries = entryParser;
      _selectedEntries = _entryInfos
          .where((entry) =>
              (entry["timestamp"].toDate().year == _selectedDay.year &&
                  entry["timestamp"].toDate().month == _selectedDay.month &&
                  entry["timestamp"].toDate().day == _selectedDay.day))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEntries = [];
    getEntries(_selectedDay);
    print(_entries);
    //     .where((entry) =>
    //         (entry["timestamp"].toDate().year == _selectedDay.year &&
    //             entry["timestamp"].toDate().month == _selectedDay.month &&
    //             entry["timestamp"].toDate().day == _selectedDay.day))
    //     .toList();
    _calendarController = CalendarController();
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
    //print(events);
    List validEntries = _entryInfos
        .where((entry) => (entry["timestamp"].toDate().year == day.year &&
            entry["timestamp"].toDate().month == day.month &&
            entry["timestamp"].toDate().day == day.day))
        .toList();
    MainView.of(context).date =
        day; // update all date states to the selected one
    setState(() {
      _selectedDay = day;
      _selectedEntries = validEntries;
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

  void _onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
    print(first.toString());
    getEntries(first);
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
      onVisibleDaysChanged: _onVisibleDaysChanged,
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
                  title: Text(event["title"].toString()),
                  onTap: () => {
                    MainView.of(context).date = _selectedDay,
                    MainView.of(context).documentIdReference = event['doc_id'],
                    widget.tabController.animateToPage(1,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn),
                    // print('$event tapped!, $_selectedDay'),
                    // print(widget.documentId),
                    // print(widget.activeDate.toString()),
                  },
                ),
              ))
          .toList(),
    );
  }
}

// typedef void OnVisibleDaysChanged(
//     DateTime first, DateTime last, CalendarFormat format);
