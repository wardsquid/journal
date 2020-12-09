import 'package:flutter/material.dart';
import '../managers/pageView.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../managers/Firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../managers/DateToHuman.dart';

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
  CalendarController _calendarController;
  DateTime _selectedDay;
  final User _user = checkUserLoginStatus();
  int _selectedIndex = 0;

  CollectionReference entries = getFireStoreEntriesDB();

  Future<void> getCalendarEntries(dateWithMonth) async {
    if (!mounted) return;

    Map<DateTime, List> entryParser = {};
    _entryInfos = [];
    _entries = {};
    /////////////////////////////////////////////////////////////////////////////////////
    /// RETRIEVE USER POSTS
    /////////////////////////////////////////////////////////////////////////////////////
    await entries
        .where('user_id', isEqualTo: _user.uid)
        .where('timestamp',
            isGreaterThanOrEqualTo:
                DateTime(dateWithMonth.year, dateWithMonth.month))
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) {
                Map<String, dynamic> entryInfo = {
                  "doc_id": doc.id,
                  "title": doc["title"],
                  "timestamp": doc["timestamp"],
                  "shared": false,
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
    /////////////////////////////////////////////////////////////////////////////////////
    /// RETRIEVE POSTS SHARED WITH USER
    /////////////////////////////////////////////////////////////////////////////////////
    await entries
        .where('shared_with', arrayContains: _user.email)
        .where('timestamp',
            isGreaterThanOrEqualTo:
                DateTime(dateWithMonth.year, dateWithMonth.month))
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) {
                Map<String, dynamic> entryInfo = {
                  "doc_id": doc.id,
                  "title": doc["title"],
                  "timestamp": doc["timestamp"],
                  "shared": true,
                };
                _entryInfos.add(entryInfo);
                DateTime date = entryInfo["timestamp"].toDate();
                DateTime formatDate = DateTime(date.year, date.month, date.day);
                if (entryParser.containsKey(formatDate)) {
                  entryParser[formatDate].add(entryInfo["title"]);
                } else {
                  entryParser[formatDate] = [entryInfo["title"]];
                }
              })
            });
    if (mounted)
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

  Future<void> _deleteEntry(docId) {
    return entries.doc(docId).delete().then((value) {
      getCalendarEntries(_selectedDay);
      Navigator.of(context).pop();
    });
  }

  @override
  void initState() {
    super.initState();
    if (_selectedDay == null) _selectedDay = DateTime.now();
    _selectedEntries = [];
    getCalendarEntries(_selectedDay);
    _calendarController = CalendarController();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  void _makeEntry() {
    // print(_selectedDay);
  }

  void _onDaySelected(DateTime day, List events, List holidays) {
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          child: Icon(Icons.edit),
          onTap: () {
            widget.liquidController.animateToPage(page: 3, duration: 400);
          },
        ),
        title: Text("Calendar"),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                widget.liquidController.animateToPage(page: 3, duration: 400);
              }),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            _buildTableCalendar(),
            Expanded(child: _buildEntryList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text("New Entry"),
        onPressed: () => {
          MainView.of(context).date = _selectedDay,
          MainView.of(context).documentIdReference = "",
          widget.tabController.animateToPage(2,
              duration: Duration(milliseconds: 300), curve: Curves.easeIn),
        },
        // _makeEntry,
        tooltip: 'New Entry',
        icon: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // BottomNavigationBar(
      //   items: const <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.business),
      //       label: 'Business',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.school),
      //       label: 'School',
      //     ),
      //   ],
      //   currentIndex: _selectedIndex,
      //   selectedItemColor: Colors.amber[800],
      //   onTap: _onItemTapped,
      // ),
    );
  }

///////////////////////////////////////////////////////////////////////
  /// When the calendar active month is changed (swipe)
///////////////////////////////////////////////////////////////////////
  void _onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
    print(first.toString());
    getCalendarEntries(first);
  }

///////////////////////////////////////////////////////////////////////
  /// Builds the calendar table
///////////////////////////////////////////////////////////////////////
  Widget _buildTableCalendar() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: TableCalendar(
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
      ),
    );
  }

///////////////////////////////////////////////////////////////////////
  /// Builds bottom tiles if there are entries on the selected day
///////////////////////////////////////////////////////////////////////
  Widget _buildEntryList() {
    List<Widget> entryList = _selectedEntries
        .map(
          (event) => Container(
            child: Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0)),
                child: Column(
                  children: <Widget>[
                    ListTile(
                        trailing: event['shared']
                            ? null
                            : IconButton(
                                icon: Icon(Icons.restore_from_trash),
                                color: Colors.red,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return _buildDeleteEntryForm(
                                        event['doc_id'],
                                        event['title'],
                                      );
                                    },
                                    barrierDismissible: false,
                                  );
                                },
                              ),
                        title: Text(event['title'].toString()),
                        subtitle: Text(
                            (event['timestamp'].runtimeType == Timestamp
                                    ? dateToHumanReadable(
                                        (event['timestamp'].toDate()))
                                    : dateToHumanReadable(event['timestamp'])) +
                                (event['shared'] ? " - shared entry" : '')),
                        onTap: () => {
                              MainView.of(context).date = _selectedDay,
                              MainView.of(context).documentIdReference =
                                  event['doc_id'],
                              widget.tabController.animateToPage(2,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeIn),
                            }),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
    entryList.add(
      Container(
        child: SizedBox(
          height: 80,
        ),
      ),
    );
    return ListView(children: entryList);
  }

  Widget _buildDeleteEntryForm(String docId, String entryTitle) {
    return AlertDialog(
      title: Text("Are you sure to delete $entryTitle ?"),
      contentPadding: EdgeInsets.all(0.0),
      actions: <Widget>[
        FlatButton(
          child: Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            _deleteEntry(docId);
          },
        ),
        FlatButton(
          child: Text(
            'Cancel',
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
