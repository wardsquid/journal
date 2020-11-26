import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//import 'Choose_Login.dart';

class DiaryEntryView extends StatefulWidget {
  @override
  _DiaryEntryViewState createState() => _DiaryEntryViewState();
}


class _EntryTextState extends State<EntryText> {
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    textController.addListener(_printLatestValue);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.
    textController.dispose();
    super.dispose();
  }

  _printLatestValue() {
    print("Text field: ${textController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
              controller: textController,
              onChanged: (text) {
                print("Text field onchange: $text");
              },
    );
  }
}

class EntryText extends StatefulWidget {
  @override
  _EntryTextState createState() => _EntryTextState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  final int _numPages = 3;
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  // String textContent = "Write an entry...";
  // bool _isEditingText = false;
  // TextEditingController _textEditingController;

  // @override
  // void initState() {
  //   super.initState();
  //   _textEditingController = TextEditingController(text: textContent);
  // }

  // @override
  // void dispose() {
  //   _textEditingController.dispose();
  //   super.dispose();
  // }

  /*
  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _numPages; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

*/
  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      height: 5.0,
      width: isActive ? 24.0 : 16.0,
      decoration: BoxDecoration(
        color: /*isActive ? Color(0xFFFB8986) :*/ Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;

    var _textH1 = TextStyle(
        fontFamily: "Sofia",
        fontWeight: FontWeight.w600,
        fontSize: 23.0,
        backgroundColor: Colors.blueGrey,
        color: Colors.white); // h1 text color

    var _textH2 = TextStyle(
        fontFamily: "Sofia",
        fontWeight: FontWeight.w200,
        fontSize: 16.0,
        color: Colors.white); // h2 text color

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey, // background color
          ),
          child: Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height,
                child: PageView(
                  physics: ClampingScrollPhysics(),
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Image(
                          image: AssetImage(
                              'assets/select_image.png'),
                          height: 400.0,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          //color: Colors.blueGrey,
                          margin:
                              EdgeInsets.only(top: 0.0, bottom: _height / 2.25),

                          /*
                          // uncomment to fade bottom part of picture
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: FractionalOffset(0.0, 0.0),
                              end: FractionalOffset(0.0, 1.0),
                              // stops: [0.0, 1.0],
                              colors: <Color>[
                                Color(0xFF1E2026).withOpacity(0.1),
                                Color(0xFF1E2026).withOpacity(0.3),
                                Color(0xFF1E2026),
                                Color(0xFF1E2026),
                              ],
                            ),
                          ),
                          */
                        ),
                        Align(
                          alignment: FractionalOffset.center,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 25.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              
                              children: <Widget>[
                                Text(
                                  'Date State will live here!',
                                  style: _textH1,
                                  ),
                                SizedBox(height: 25.0),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0, right: 15.0),
                                  child: EntryText(),
                                  // TextField(
                                  //   onChanged: (text) {
                                  //     print("First text field: $text");
                                  //     setState(() {
                                  //       textContent = text;
                                  //     });
                                  //   },
                                  //   // decoration: InputDecoration(
                                  //   //   border: InputBorder.none,
                                  //   //   hintText: 'Write your entry',
                                  //   //   // 'Entry State will live here, make this editable',
                                  //   //   // textAlign: TextAlign.center,
                                  //   //   // style: _textH2,
                                  //   // ),
                                  // ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Align(
                alignment: FractionalOffset.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 270.0),
                  //child: Row(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  //children: _buildPageIndicator(),
                  //),
                ),
              ),
              _currentPage != _numPages - 1
                  ? Align(
                      alignment: FractionalOffset.bottomRight,
                      //child: FlatButton(
                          // onPressed: () {
                          //   setState(() {
                          //     if(_isEditingText) {
                          //       _isEditingText = false;
                          //       print("saved text: " + _textEditingController.text);
                          //     } else {
                          //       _isEditingText = true;
                          //     }
                          //   });
                          //},
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Container(
                              height: 50.0,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                  color: Colors
                                      .transparent, // background button color
                                  border: Border.all(
                                      color: Color(
                                          0xFFFB8986)) // all border colors
                                  ),
                              child: Center(
                                  child: Text(
                                "Edit/Save (make this smaller)",
                                style: TextStyle(
                                    color: Color(0xFFFB8986),
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "Poppins",
                                    letterSpacing: 1.5),
                              )),
                            ),
                          ),
                    )
                  : Text(''),
              //*/
            ],
          ),
        ),
      ),
    );
  }
}