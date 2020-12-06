// import 'dart:developer';
import 'userInfo.dart' as inkling;
import 'package:flutter/material.dart';
import '../views/Calendar.dart';
import '../views/DiaryEntryView.dart';
import '../views/UserProfile.dart';
import '../views/timeline/TimeLineView.dart';

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
    _pageController = PageController(initialPage: 2);
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
          if (index != 2) {
            FocusScope.of(context).unfocus();
          }
          print(inkling.userProfile.toString());
          print(activeDate);
          print(documentId);
        },
        children: [
          TimeLineView(),
          Calendar(
              title: "Diary Calendar",
              tabController: _pageController,
              activeDate: activeDate,
              documentId: documentId), //index 0
          DiaryEntryView(activeDate: activeDate, documentId: documentId),
          UserProfile(),
          //TFLite() TF ML functions may not need
        ]);
  }
}

typedef void DateTimeCallback(DateTime val);
typedef void StringCallback(String val);
