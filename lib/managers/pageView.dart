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
  int page = 0;
  static LiquidController _liquidController;

  UpdateType _updateType;
  //set variable
  DateTime activeDate = DateTime.now();
  String documentId = "";
  set date(DateTime value) => setState(() => activeDate = value);
  set documentIdReference(String value) => setState(() => documentId = value);
  List<Container> pages;

  void initState() {
    super.initState();
    _liquidController = LiquidController();
  }

  // @override
  void dispose() {
    //   _liquidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidSwipe(
      initialPage: 2,
      fullTransitionValue: 200,
      // onPageChangeCallback: () => print("here"),
      enableLoop: false,
      waveType: WaveType.liquidReveal,
      liquidController: _liquidController,
      // ignoreUserGestureWhileAnimating: true,
      onPageChangeCallback: (index) => {
        if (index != 2) {
          FocusScope.of(context).unfocus()
          },
          print(inkling.userProfile.toString()),
          print(activeDate),
          print(documentId),
      },
      pages: [
        Container(
          child: UserProfile(),
        ),
        Container(
          child: Calendar(
              title: "Diary Calendar",
              liquidController: _liquidController,
              activeDate: activeDate,
              documentId: documentId), //index 0
        ),
        Container(
          child: TimeLineView(),
        ),
        Container(
          child: DiaryEntryView(activeDate: activeDate, documentId: documentId),
        ),
        Container(
          color: Colors.red,
        ),
      ],
    );
    // @override
    // Widget build(BuildContext context) {
    //   return SafeArea(
    //       child: Scaffold(
    //     body: LiquidSwipe(
    //       pages: pages,
    //       enableLoop: false,
    //       fullTransitionValue: 300,
    //       //if (pages[i] = pages[pages.length -1]) return false else true;
    //       enableSlideIcon: true,
    //       waveType: WaveType.liquidReveal,
    //       positionSlideIcon: .5,
    //     ),
    //   ));
    // }

    // @override
    // Widget build(BuildContext context) {
    //   return PageView(
    //       controller: _pageController,
    //       onPageChanged: (index) {
    //         if (index != 2) {
    //           FocusScope.of(context).unfocus();
    //         }
    //         print(inkling.userProfile.toString());
    //         print(activeDate);
    //         print(documentId);
    //       },
    //       children: [
    //         TimeLineView(),
    //         Calendar(
    //             title: "Diary Calendar",
    //             tabController: _pageController,
    //             activeDate: activeDate,
    //             documentId: documentId), //index 0
    //         DiaryEntryView(activeDate: activeDate, documentId: documentId),
    //         UserProfile(),
    //         Container(
    //           color: Colors.red,
    //         ), //index 2
    //         //TFLite() TF ML functions may not need
    //       ]);
    // }
  }
}

typedef void DateTimeCallback(DateTime val);
typedef void StringCallback(String val);
//declare here as well
