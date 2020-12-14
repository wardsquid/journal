import 'package:flutter/material.dart';
import '../managers/pageView.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../managers/Firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../managers/DateToHuman.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import '../managers/userInfo.dart' as inkling;

class Calendar extends StatefulWidget {
  final String title;
  LiquidController liquidController;
  DateTime activeDate;
  String documentId;
  bool editController;
  Calendar(
      {Key key,
      this.documentId,
      this.title,
      this.liquidController,
      this.activeDate,
      this.editController})
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
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        Map<String, dynamic> entryInfo;
        if (doc.data().containsKey("user_name")) {
          entryInfo = {
            "doc_id": doc.id,
            "title": doc["title"],
            "timestamp": doc["timestamp"],
            "shared": true,
            "user_name": doc["user_name"],
          };
        } else {
          entryInfo = {
            "doc_id": doc.id,
            "title": doc["title"],
            "timestamp": doc["timestamp"],
            "shared": true,
          };
        }
        _entryInfos.add(entryInfo);
        DateTime date = entryInfo["timestamp"].toDate();
        DateTime formatDate = DateTime(date.year, date.month, date.day);
        if (entryParser.containsKey(formatDate)) {
          entryParser[formatDate].add(entryInfo["title"]);
        } else {
          entryParser[formatDate] = [entryInfo["title"]];
        }
      });
    });
    if (mounted)
      setState(() {
        if (dateWithMonth.year == DateTime.now().year &&
            dateWithMonth.month == DateTime.now().month) {
          _selectedDay = DateTime.now();
        } else {
          _selectedDay = dateWithMonth;
        }
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
    // deletes from local storage
    final int deleteIndex = inkling.orderedListIDMap[widget.documentId];
    inkling.orderedList.removeAt(deleteIndex);
    // deletes picture from cloud storage
    if (inkling.activeEntry['content']['image']) {
      deletePhoto(widget.documentId);
    }
    if (docId == widget.documentId) {
      MainView.of(context).documentIdReference = '';
    }

    // delete entry from firestore and sets the state
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
      backgroundColor: Color(0xFF2C4096),
      appBar: AppBar(
        backgroundColor: Color(0xFFFA6164),
        leading: IconButton(
          icon: Icon(Icons.home),
          splashColor: Colors.orange[300],
          highlightColor: Colors.orange[300],
          hoverColor: Colors.orange[300],
          onPressed: () {
            widget.liquidController.animateToPage(page: 2, duration: 750);
          },
        ),
        title: Text("Calendar"),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(Icons.edit),
              splashColor: Colors.orange[300],
              highlightColor: Colors.orange[300],
              hoverColor: Colors.orange[300],
              onPressed: () {
                widget.liquidController.animateToPage(page: 3, duration: 750);
              }),
        ],
      ),
      body: Center(
          child: Stack(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              _buildTableCalendar(),
              Expanded(child: _buildEntryList()),
            ],
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'calendarNewEntry',
        backgroundColor: Color(0xFFFA6164),
        label: Text("New Entry"),
        splashColor: Colors.orange[300],
        hoverColor: Colors.orange[300],
        focusColor: Colors.orange[300],
        onPressed: () => {
          MainView.of(context).date = _selectedDay,
          MainView.of(context).documentIdReference = "",
          MainView.of(context).editController = true,
          widget.liquidController.jumpToPage(page: 3),
        },
        tooltip: 'New Entry',
        icon: Icon(Icons.add),
        elevation: 10,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

///////////////////////////////////////////////////////////////////////
  /// When the calendar active month is changed (swipe)
///////////////////////////////////////////////////////////////////////
  void _onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
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
        availableGestures: AvailableGestures.verticalSwipe,
        startingDayOfWeek: StartingDayOfWeek.monday,
        initialCalendarFormat: CalendarFormat.twoWeeks,
        calendarStyle: CalendarStyle(
          selectedColor: Color(0xFFFA6164),
          todayColor: Colors.deepOrange[200],
          markersColor: Color(0xFF2C4096),
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
                                color: Color(0xFFC73967),
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
                              (event['shared']
                                  ? (event['user_name'] == null)
                                      ? " - shared entry"
                                      : " - shared by ${event['user_name'].split(" ")[0]}"
                                  : ''),
                        ),
                        onTap: () => {
                              MainView.of(context).date = _selectedDay,
                              MainView.of(context).documentIdReference =
                                  event['doc_id'],
                              widget.liquidController.jumpToPage(page: 3)
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
      title: Text("Are you sure you want to delete $entryTitle ?"),
      contentPadding: EdgeInsets.all(0.0),
      actions: <Widget>[
        FlatButton(
          child: Text(
            'Delete',
            style: TextStyle(color: Color(0xFFf2296a)),
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
