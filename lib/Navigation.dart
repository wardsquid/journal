import 'package:flutter/material.dart';
import 'calendar.dart';

class Navigation extends StatefulWidget {
  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swipe Navigation'),
      ),
      body: PageView(
        children: [
          Calendar(),
          Container(color: Colors.red),
        ],
      ),
    );
  }
}
