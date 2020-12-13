// Spotify
// import 'package:async/async.dart';
// import 'package:spotify_sdk/models/connection_status.dart';
// import 'package:spotify_sdk/models/crossfade_state.dart';
// import 'package:spotify_sdk/models/image_uri.dart';
// import 'package:spotify_sdk/models/player_context.dart';
// import 'package:spotify_sdk/models/player_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
//import 'dart:io';
import 'dart:async';
import 'dart:convert';

var _authenticationToken;
var _currentTrack;
var _storedTrack;
List<dynamic> _todaysTracks = [];

Future<void> getSpotifyAuth() async {
  String clientId = DotEnv().env['CLIENT_ID'];
  String redirectUrl = DotEnv().env['REDIRECT_URL'];
  print("Initializing Spotify for client $clientId and URI $redirectUrl");

  try {
    _authenticationToken = await SpotifySdk.getAuthenticationToken(
        clientId: clientId,
        redirectUrl: redirectUrl,
        scope:
            "app-remote-control,user-modify-playback-state, user-read-recently-played, user-top-read, user-read-currently-playing, user-read-playback-state");
    print("Auth token retrieved: $_authenticationToken");
  } catch (error) {
    print("Spotify access denied by user; auth token: $_authenticationToken");
  }
}

fetchSpotifyToken() {
  return _authenticationToken;
}

class StoredTrack {
  final String artist;
  final String track;
  final String url;
  final String href;
  final String uri;
  final String imageUrl;

  StoredTrack(
      {this.artist, this.track, this.url, this.href, this.uri, this.imageUrl});

  factory StoredTrack.fromJson(Map<String, dynamic> json) {
    return StoredTrack(
        artist: json['album']['artists'][0]['name'],
        track: json['name'],
        url: json['external_urls']['spotify'],
        href: json['href'],
        uri: json['uri'],
        imageUrl: json['album']['images'][0]['url']);
  }
}

class CurrentTrack {
  final String artist;
  final String track;
  final String url;
  final String href;
  final String imageUrl;

  CurrentTrack({this.artist, this.track, this.url, this.href, this.imageUrl});

  factory CurrentTrack.fromJson(Map<String, dynamic> json) {
    return CurrentTrack(
        artist: json['item']['album']['artists'][0]['name'],
        track: json['item']['name'],
        url: json['item']['external_urls']['spotify'],
        href: json['item']['href'],
        imageUrl: json['item']['album']['images'][0]['url']);
  }
}

class RecentTrack {
  final String artist;
  final String track;
  final String url;
  final String href;
  String imageUrl;

  RecentTrack({this.artist, this.track, this.url, this.href, this.imageUrl});

  factory RecentTrack.fromJson(Map<String, dynamic> json) {
    return RecentTrack(
        artist: json['items'][0]['track']['artists'][0]['name'],
        track: json['items'][0]['track']['name'],
        url: json['items'][0]['track']['external_urls']['spotify'],
        href: json['items'][0]['track']['href']);
  }

  Future<void> getImage() async {
    Map<String, dynamic> json;

    final response = await http.get(this.href,
        headers: {'Authorization': 'Bearer ' + _authenticationToken});

    if (response.statusCode == 200) {
      print("Track ID found");
      json = jsonDecode(response.body);
      this.imageUrl = json['album']['images'][0]['url'];
    } else {
      print('Track ID not found');
    }
  }
}

Future<void> loadSpotifyTrack() async {
  _todaysTracks = [];

  final response = await http.get(
      'https://api.spotify.com/v1/me/player/currently-playing',
      headers: {'Authorization': 'Bearer ' + _authenticationToken});

  if (response.statusCode == 200) {
    print("Current track found");
    _currentTrack = CurrentTrack.fromJson(jsonDecode(response.body));
    print("artist: ${_currentTrack.artist}");
    print("track: ${_currentTrack.track}");
    print("url: ${_currentTrack.url}");
    print("href: ${_currentTrack.href}");
    print("imageUrl: ${_currentTrack.imageUrl}");
  } else {
    print('No current track playing');
    //await loadRecentSpotifyTrack();
  }
}

Future<void> loadRecentSpotifyTrack() async {
  final response = await http.get(
      'https://api.spotify.com/v1/me/player/recently-played',
      headers: {'Authorization': 'Bearer ' + _authenticationToken});

  if (response.statusCode == 200) {
    print("Most recent track found");
    _currentTrack = RecentTrack.fromJson(jsonDecode(response.body));
    await _currentTrack.getImage();

    print("artist: ${_currentTrack.artist}");
    print("track: ${_currentTrack.track}");
    print("url: ${_currentTrack.url}");
    print("href: ${_currentTrack.href}");
    print("imageUrl: ${_currentTrack.imageUrl}");
  } else {
    print('Failed to fetch recent track');
  }
}

fetchSpotifyTrack() {
  return _currentTrack;
}

fetchStoredTrack() {
  return _storedTrack;
}

fetchTodaysTracks() {
  return _todaysTracks;
}

Future<void> getTrackByUrl(String _url) async {
  print("Getting track by url: $_url auth token $_authenticationToken");
  final response = await http
      .get(_url, headers: {'Authorization': 'Bearer ' + _authenticationToken});

  if (response.statusCode == 200) {
    print("Track ID found");
    _storedTrack = StoredTrack.fromJson(jsonDecode(response.body));

    print("artist: ${_storedTrack.artist}");
    print("track: ${_storedTrack.track}");
    // print("url: ${_storedTrack.url}");
    // print("href: ${_storedTrack.href}");
    print("uri: ${_storedTrack.uri}");
    // print("imageUrl: ${_storedTrack.imageUrl}");
  } else {
    print('Stored track ID not found');
  }
}

class TodayTrack {
  final String artist;
  final String track;
  final String url;
  final String href;
  final String uri;
  String imageUrl;
  String next;

  TodayTrack(
      {this.artist,
      this.track,
      this.url,
      this.href,
      this.imageUrl,
      this.uri,
      this.next});

  factory TodayTrack.fromJson(Map<String, dynamic> json, num n) {
    print("LIMIT ${json['limit']}, NEXT: ${json['next']}");
    return TodayTrack(
        artist: json['items'][n]['track']['artists'][0]['name'],
        track: json['items'][n]['track']['name'],
        url: json['items'][n]['track']['external_urls']['spotify'],
        href: json['items'][n]['track']['href'],
        uri: json['items'][n]['track']['uri'],
        next: json['next']);
  }

  Future<void> getImage() async {
    Map<String, dynamic> json;

    final response = await http.get(this.href,
        headers: {'Authorization': 'Bearer ' + _authenticationToken});

    if (response.statusCode == 200) {
      print("Track ID found");
      json = jsonDecode(response.body);
      this.imageUrl = json['album']['images'][0]['url'];
    } else {
      print('Track ID not found');
    }
  }
}

Future<void> loadTodaysTracks() async {
  print("Getting today's tracks for $_authenticationToken");
  // _todaysTracks.length = 50;
  Map<String, String> _queryParams = {
    'limit': '5',
  };

  var endpoint = "https://api.spotify.com/v1/me/player/recently-played";
  String queryString = Uri(queryParameters: _queryParams).query;
  var uri = endpoint +
      '?' +
      queryString; // result - https://www.myurl.com/api/v1/user?param1=1&param2=2
  // Uri.decodeComponent(uri); // To encode url
//https://api.spotify.com/v1/me/player/recently-played?before=1607364438313&limit=10

  final response = await http.get(uri, headers: {
    'Authorization': 'Bearer ' + _authenticationToken,
    'contentTypeHeader': 'application/json'
  });

  if (response.statusCode == 200) {
    print("Recently played tracks found");
    num length = jsonDecode(response.body).length;
    print("length: $length");

    for (var i = 0; i < length; i++) {
      _todaysTracks.add(TodayTrack.fromJson(jsonDecode(response.body), i));
      await _todaysTracks[i].getImage();
      print("TODAY'S track: ${_todaysTracks[i].track}");
      print("artist: ${_todaysTracks[i].artist}");
      // print("url: ${_todaysTracks[i].url}");
      // print("href: ${_todaysTracks[i].href}");
      print("uri: ${_todaysTracks[i].uri}");
      // print("image: ${_todaysTracks[i].imageUrl}");
    }
  } else {
    print('Stored track ID not found');
  }

  // adds currently playing track too as it's in progress
  if (_currentTrack != null) {
    _todaysTracks.add(_currentTrack);
  }
}

playSpotifyTrack(String _uri, String _url) async {
  print("sending $_uri to spotify...");

  final response = await http.put('https://api.spotify.com/v1/me/player/play',
      headers: {
        'Authorization': 'Bearer ' + _authenticationToken,
        'contentTypeHeader': 'application/json'
      },
      body: jsonEncode({
        "uris": [
          _uri,
        ]
      }));

  if (response.statusCode == 200) {
    print("opening $_uri in spotify");
  } else if (response.statusCode == 204) {
    print("playing $_uri in background");
  } else if (response.statusCode == 404) {
    return launch(_url);
  } else {
    print("Error playing track: ${response.statusCode}");
  }
}

// FETCHING MORE THAN 5 tracks - need to use next???
// final response2 = await http.get(
//     "https://api.spotify.com/v1/me/player/recently-played?before=1607392056792&limit=5",
//     headers: {
//       'Authorization': 'Bearer ' + _authenticationToken,
//       'contentTypeHeader': 'application/json'
//     });
// if (response2.statusCode == 200) {
//   print("Recently played tracks found");
//   num length = jsonDecode(response.body).length;
//   print("length: $length");

//   for (var i = 0; i < length; i++) {
//     _todaysTracks.add(TodayTrack.fromJson(jsonDecode(response2.body), i));
//     await _todaysTracks[i].getImage();
//     print("todaystracks LAST: ${_todaysTracks[9].track}");

// print("TODAY'S track: ${_todaysTracks[i].track}");
// print("artist: ${_todaysTracks[i].artist}");
// print("url: ${_todaysTracks[i].url}");
// print("href: ${_todaysTracks[i].href}");
// print("image: ${_todaysTracks[i].imageUrl}");

// Future<void> getPlayerState() async {
//   print("getting current track...");
//   var playerConnection = await SpotifySdk.subscribeConnectionStatus();
//   var currentPlayerState = await SpotifySdk.subscribePlayerState();
//   print("Connection: $playerConnection");
//   print("PlayerState: $currentPlayerState");

//   //await SpotifySdk.pause();
// }
