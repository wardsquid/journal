import 'package:flutter/material.dart';
import 'calendar.dart';
import 'DiaryEntryView.dart';
import 'views/UserProfile.dart';

class Navigation extends StatefulWidget {
  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  //uses the index of PageView's children.
  PageController pageController = PageController(initialPage: 0);
  //for debugging purposes. Will be used to console.log the page transitions.
  int currentPage = 1;

  //_scrollController = ScrollController(initialScrollOffset: 50.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Inkling'),
        //these appbar buttons are for [TEST] purposes! the function
        //is meant as a template for the calendar date => main view function
        actions: [
          //this button template is to show that you can have a button go straight to a designated index
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              pageController.animateToPage(1,
                  duration: Duration(milliseconds: 400),
                  curve: Curves.bounceInOut);
            },
          ),
          //this button template shows that you can navigate to a page by altering the currentPage variable
          IconButton(
            icon: Icon(Icons.arrow_forward_ios),
            onPressed: () {
              pageController.animateToPage(++currentPage,
                  duration: Duration(milliseconds: 400),
                  curve: Curves.bounceInOut);
            },
          )
        ],
      ),
      body: PageView(
        pageSnapping:
            true, //this setting controlls the swipey-ness of the transitions
        controller:
            pageController, //gives pagecontroller access to PageView's children
        onPageChanged: (index) {
          //setState because we are changing the UI
          setState(() {
            currentPage = index;
          });
          //console.log
          print(currentPage);
        },
        children: [
          Calendar(), //index 0
          DiaryEntryView(), //index 1 bc its the middle view
          UserProfile(),
          Container(color: Colors.red), //index 2
        ],
      ),
    );
  }
}
/////

void switchView(DateTime selectedDay) {
  print('click received');
  _NavigationState().pageController.animateToPage(1,
      duration: Duration(milliseconds: 400), curve: Curves.bounceInOut);
}
