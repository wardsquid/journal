import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../managers/EntryRetriever.dart';
import '../../managers/DateToHuman.dart';
import '../../managers/Spotify.dart';

class TimeLineView extends StatefulWidget {
  TimeLineView({Key key}) : super(key: key);
  @override
  _TimeLineView createState() => _TimeLineView();
}

class _TimeLineView extends State<TimeLineView> {
//  final DateTime origin = DateTime.parse("2020-10-23");
  var _storedTrack;
  //var _spotifyToken;
  String _spotifyUrl = "";

  DateTime today = DateTime.now();
  List<Map<String, dynamic>> display = [
    {
      "title": "### Load More ###",
      "timestamp": Timestamp.fromDate(DateTime.parse("1900-01-01 13:27:00")),
      "content": {
        "image": false,
        'text': "filler",
        "spotify": null,
        "artist": null,
        "track": null,
        "albumImage": null,
        "url": null // to open in spotify
      },
    }
  ];

  void pushToList(Map<String, dynamic> entry) async {
    if (entry["content"]["spotify"] != null) {
      var _url = entry["content"]["spotify"];
      await getTrackByUrl(_url);
      setState(() {
        _storedTrack = fetchStoredTrack();
      });
      entry["content"]["track"] = _storedTrack.track;
      entry["content"]["artist"] = _storedTrack.artist;
      entry["content"]["albumImage"] = _storedTrack.imageUrl;
      entry["content"]["url"] = _storedTrack.url;
    }
    print("pushing ${entry.toString()}");
    setState(() {
      display.add(entry);
      display.sort((b, a) => a["timestamp"].compareTo(b["timestamp"]));
    });
  }

  void parseQuery(DateTime date) {
    if (date == null) date = today;
    fireStoreQuery(date).then((value) => {
          value.docs.forEach((element) {
            Map<String, dynamic> entry = element.data();
            if (entry["content"]["spotify"] != null) {
              _spotifyUrl = entry['content']['spotify'];
              print("URL TO GET: $_spotifyUrl");
            }
            if (entry["content"]["image"] == true) {
              downloadURLImage(element.id).then((value) => {
                    entry["imageUrl"] = value,
                    pushToList(entry),
                  });
            } else {
              pushToList(entry);
            }
          })
        });
  }

  void initState() {
    super.initState();
    parseQuery(today);
  }

  @override
  void dispose() {
    super.dispose();
    //_spotifyToken = fetchSpotifyToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: createListView(context, display),
    );
  }

  Widget createListView(
      BuildContext context, List<Map<String, dynamic>> entries) {
    return ListView.builder(
      itemCount: entries.length == null ? 0 : entries.length,
      itemBuilder: (BuildContext context, int index) {
        return new Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
            child: timeLineCard(context, entries[index]),
          ),
        );
      },
    );
  }

  Widget timeLineCard(BuildContext context, Map<String, dynamic> entry) {
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
            height: 10,
          ),
          FloatingActionButton.extended(
              onPressed: () {
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
              subtitle: Text(entry['timestamp'].runtimeType == Timestamp
                  ? dateToHumanReadable((entry['timestamp'].toDate()))
                  : dateToHumanReadable(entry['timestamp'])),
            ),
            // Spotify
            if (entry["content"]["spotify"] != null)
              ListTile(
                leading: Image.network(entry["content"]["albumImage"],
                    width: 70, height: 70),
                title: Text('${entry["content"]["track"]}'),
                subtitle: Text('${entry["content"]["artist"]}'),
                trailing: IconButton(
                    icon:
                        Icon(Icons.audiotrack, color: Colors.green, size: 50.0),
                    onPressed: () {
                      // open in spotify
                      return launch(entry["content"]["url"]);
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
