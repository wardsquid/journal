import 'package:flutter/material.dart';
import '../views/Calendar.dart';
import '../views/DiaryEntryView.dart';
import '../views/UserProfile.dart';
import '../views/TFLite.dart';

class MainView extends StatefulWidget {
  @override
  _MainViewState createState() => _MainViewState();

  static _MainViewState of(BuildContext context) =>
      context.findAncestorStateOfType<_MainViewState>();
}

class _MainViewState extends State<MainView> {
  static PageController _pageController;
  DateTime activeDate = DateTime.now();
  String documentId = "";
  set date(DateTime value) => setState(() => activeDate = value);
  set documentIdReference(String value) => setState(() => documentId = value);

  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
        controller: _pageController,
        onPageChanged: (index) {
          print(activeDate);
          print(documentId);
        },
        children: [
          // NOT ACTUAL ERRORS
          Calendar(
              title: "Diary Calendar",
              tabController: _pageController,
              activeDate: activeDate,
              documentId: documentId), //index 0
          // NOT ACTUAL ERRORS
          DiaryEntryView(activeDate: activeDate, documentId: documentId),
          UserProfile(),
          //TFLite() TF ML functions may not need
          //Container(color: Colors.red), //index 2
        ]);
  }
}

typedef void DateTimeCallback(DateTime val);
typedef void StringCallback(String val);
