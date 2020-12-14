// import 'dart:developer';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:table_calendar/table_calendar.dart';

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
  int previousPage = 2;
  int page = 0;
  static LiquidController _liquidController;

  UpdateType _updateType;
  //set variable
  DateTime activeDate = DateTime.now();
  String documentId = "";
  bool editController = false;
  set isEditing(bool value) => setState(() => editController = value);
  set date(DateTime value) => setState(() => activeDate = value);
  set documentIdReference(String value) => setState(() => documentId = value);
  List<Container> pages;

  void initState() {
    super.initState();
    _liquidController = LiquidController();
  }

  // @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidSwipe(
      initialPage: 2,
      fullTransitionValue: 200,
      enableLoop: false,
      waveType: WaveType.liquidReveal,
      liquidController: _liquidController,
      onPageChangeCallback: (index) => {
        if (index != 3) {FocusScope.of(context).unfocus()},
        if (previousPage == 3 && index == 2) editController = false, //
        previousPage = index,
      },
      pages: [
        Container(
          child: UserProfile(
            liquidController: _liquidController,
          ),
        ),
        Container(
          child: Calendar(
            title: "Diary Calendar",
            liquidController: _liquidController,
            activeDate: activeDate,
            documentId: documentId,
            editController: editController,
          ), //index 0
        ),
        Container(
          child: TimeLineView(
            liquidController: _liquidController,
            editController: editController,
          ),
        ),
        Container(
          child: DiaryEntryView(
            activeDate: activeDate,
            documentId: documentId,
            liquidController: _liquidController,
            editController: editController,
          ),
        ),
      ],
    );
  }
}

typedef void DateTimeCallback(DateTime val);
typedef void StringCallback(String val);
typedef void BoolCallback(bool val);
//declare here as well
