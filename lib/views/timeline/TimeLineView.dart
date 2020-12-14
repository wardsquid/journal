import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../managers/EntryRetriever.dart';
import '../../managers/DateToHuman.dart';
import '../../managers/Spotify.dart';
import '../../managers/pageView.dart';
import '../../managers/Firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import '../../managers/userInfo.dart' as inkling;

class TimeLineView extends StatefulWidget {
  LiquidController liquidController;
  bool editController;
  TimeLineView({Key key, this.liquidController, this.editController})
      : super(key: key);

  @override
  _TimeLineView createState() => _TimeLineView();
}

class _TimeLineView extends State<TimeLineView> {
//  final DateTime origin = DateTime.parse("2020-10-23");

  final User _user = checkUserLoginStatus();
  var _storedTrack;
  var _spotifyToken;
  Future<QuerySnapshot> userRetrievalQuery;
  Future<QuerySnapshot> sharedRetrievalQuery;
  DateTime today = DateTime.now();
  List<Map<String, dynamic>> display = [
    {
      "id": '0',
      "title": "### Load More ###",
      "timestamp": Timestamp.fromDate(DateTime.parse("1900-01-01 13:27:00")),
      "content": {
        "image": false,
        'text': "filler",
        "spotify": null,
        "artist": null,
        "track": null,
        "albumImage": null,
        "url": null, // to open spotify
        "uri": null, // to play in background
      },
      "shared_with": [],
      "user_name": "",
    }
  ];

  void pushToList(Map<String, dynamic> entry) async {
    if (!mounted) return;
    if (entry["content"]["spotify"] != null && _spotifyToken != null) {
      var _url = entry["content"]["spotify"];
      print("error is thrown here ${entry.toString}");
      await getTrackByUrl(_url).then((val) => {
            if (mounted)
              setState(() {
                _storedTrack = fetchStoredTrack();
              }),
            entry["content"]["track"] = _storedTrack.track,
            entry["content"]["artist"] = _storedTrack.artist,
            entry["content"]["albumImage"] = _storedTrack.imageUrl,
            entry["content"]["url"] = _storedTrack.url,
            entry["content"]["uri"] = _storedTrack.uri
          });
    }
    if (mounted)
      setState(() {
        display.add(entry);
        display.sort((b, a) => a["timestamp"].compareTo(b["timestamp"]));
        inkling.orderedList = display;
        inkling.orderedList.forEach((element) =>
            inkling.orderedListIDMap[element['id']] =
                inkling.orderedList.indexOf(element));
        print(inkling.orderedList.toString());
      });
  }

  void parseQuery(DateTime date) {
    if (date == null) date = today;
    userRetrievalQuery = fireStoreUserQuery(date);
    userRetrievalQuery.then((value) => {
          value.docs.forEach((element) {
            Map<String, dynamic> entry = element.data();
            if (entry["content"]["image"] == true && mounted) {
              downloadURLImage(entry["user_id"], element.id).then((value) => {
                    entry["imageUrl"] = value,
                    entry["id"] = element.id,
                    pushToList(entry),
                  });
            } else {
              entry["id"] = element.id;
              pushToList(entry);
            }
          })
        });
    sharedRetrievalQuery = fireStoreSharedQuery(date);
    sharedRetrievalQuery.then((value) => {
          value.docs.forEach((element) {
            // print(element.data());
            Map<String, dynamic> entry = element.data();
            // if (entry['timestamp'].runtimeType == Timestamp)
            //   entry['timestamp'] = entry['timestamp'].toDate();
            // inkling.addToLocalStorage(element.id, entry);

            if (entry["content"]["image"] == true && mounted) {
              downloadURLImage(entry["user_id"], element.id).then((value) => {
                    entry["imageUrl"] = value,
                    entry["id"] = element.id,
                    pushToList(entry),
                  });
            } else {
              entry["id"] = element.id;
              pushToList(entry);
            }
          }),
          if (mounted)
            {
              inkling.lastTimelineFetch = DateTime.now(),
            }
        });
  }
  // }
  // }

  void initState() {
    super.initState();
    print("init");

    _spotifyToken = fetchSpotifyToken();
    if (inkling.lastTimelineFetch != null &&
        DateTime.now().difference(inkling.lastTimelineFetch).inMinutes < 5) {
      display = inkling.orderedList;
      print(DateTime.now().difference(inkling.lastTimelineFetch));
    } else {
      print('fetching from DB');
      parseQuery(today);
    }
  }

  @override
  void dispose() {
    print("dispose");
    sharedRetrievalQuery = null;
    userRetrievalQuery = null;
    super.dispose();
    //_spotifyToken = fetchSpotifyToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C4096),
      appBar: AppBar(
        backgroundColor: Colors.orange[300],
        leading: IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: () {
            widget.liquidController.animateToPage(page: 1, duration: 750);
          },
        ),
        title: Text("Memory Lane"),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                widget.liquidController.animateToPage(page: 0, duration: 750);
              }),
        ],
      ),
      body: Center(
          child: Stack(
        children: <Widget>[
          createListView(context, display),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => {
          MainView.of(context).documentIdReference = '',
          MainView.of(context).editController = true,
          MainView.of(context).date = DateTime.now(),
          widget.liquidController.animateToPage(page: 3, duration: 750)
        },
        child: Icon(Icons.add),
      ),
    );
  }

  _playSpotifyTrack(_url, _uri) async {
    if (_uri != null) {
      await playSpotifyTrack(_url, _uri);
    }
  }

  Widget createListView(
      BuildContext context, List<Map<String, dynamic>> entries) {
    if (!mounted) return null;
    return ListView.builder(
      itemCount: entries.length == null ? 0 : entries.length,
      itemBuilder: (BuildContext context, int index) {
        return new Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
            child: timeLineCard(context, entries[index], index),
          ),
        );
      },
    );
  }

  Widget timeLineCard(
      BuildContext context, Map<String, dynamic> entry, int index) {
    if (!mounted) return null;
    if (entry['imageUrl'] == '') {
      downloadURLImage(entry["user_id"], entry["doc_id"]).then((value) => {
            setState(() {
              entry["imageUrl"] = value;
            })
          });
    }
    Widget imageFadeIn;
    if (entry['imageUrl'] != null)
      imageFadeIn = new Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Container(
          alignment: Alignment.center,
          child: FadeInImage(
              image: NetworkImage(entry['imageUrl']),
              placeholder: AssetImage("assets/placeholder.gif"),
              fit: BoxFit.cover),
        ),
      );
    if (entry['title'] == "### Load More ###") {
      return Container(
        child: Column(children: <Widget>[
          SizedBox(
            height: 30,
          ),
          FloatingActionButton.extended(
              heroTag: null,
              onPressed: () {
                if (mounted)
                  setState(() {
                    today = DateTime(today.year, today.month - 1);
                    parseQuery(today);
                  });
                // Add your onPressed code here!
              },
              label: Text("read more..."),
              icon: Icon(Icons.menu_book),
              backgroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0))),
              elevation: 5),
          SizedBox(
            height: 10,
          )
        ]),
      );
    } else {
      return Card(
        elevation: 5,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Column(
          children: <Widget>[
            imageFadeIn != null ? imageFadeIn : SizedBox(height: 0),
            ListTile(
              leading: Icon(Icons.menu_book_rounded),
              title: Text(entry['title'].toString()),
              subtitle: Text(
                (entry['timestamp'].runtimeType == Timestamp
                        ? dateToHumanReadable((entry['timestamp'].toDate()))
                        : dateToHumanReadable(entry['timestamp'])) +
                    (entry['user_id'] != _user.uid &&
                            entry['shared_with'].length > 0
                        ? (entry['user_name'] == null)
                            ? " - shared entry"
                            : " - shared by ${entry['user_name'].split(" ")[0]}"
                        : ''),
              ),
            ),
            // Spotify
            if (entry["content"]["spotify"] != null && _spotifyToken != null)
              ListTile(
                leading: Image.network(entry["content"]["albumImage"],
                    width: 70, height: 70),
                title: Text('${entry["content"]["track"]}'),
                subtitle: Text('${entry["content"]["artist"]}'),
                trailing: IconButton(
                    icon: Icon(Icons.play_circle_fill,
                        color: Colors.green, size: 50.0),
                    onPressed: () {
                      // play in spotify
                      _playSpotifyTrack(
                          entry["content"]["url"], entry["content"]["uri"]);
                      //return launch(entry["content"]["url"]);
                    }),
                isThreeLine: true,
              ),
            // Spotify
            Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 25.0, right: 25.0),
              child: Text(
                entry['content']['text'],
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                ),
              ),
            ),
            SizedBox(
              height: 25,
            )
          ],
        ),
      );
    }
  }
}
