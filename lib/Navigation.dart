import 'package:flutter/material.dart';
import 'Calendar.dart';
import 'DiaryEntryView.dart';
import 'views/UserProfile.dart';

class Navigation extends StatefulWidget {
  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );
  void onAddButtonTapped(int index) {
    // use this to animate to the page
    pageController.animateToPage(index);
    // or this to jump to it without animating
    pageController.jumpToPage(index);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swipe Navigation'),
      ),
      body: PageView(
        controller: pageController,
        children: [
          Calendar(),
          DiaryEntryView(),
          UserProfile(),
          Container(color: Colors.red),
        ],
      ),
    );
  }
}
/////
