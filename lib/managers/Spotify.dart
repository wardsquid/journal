import 'package:url_launcher/url_launcher.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

var _authenticationToken;
var _currentTrack;
var _storedTrack;
List<dynamic> _todaysTracks = [];

Future<void> getSpotifyAuth() async {
  String clientId = DotEnv().env['CLIENT_ID'];
  String redirectUrl = DotEnv().env['REDIRECT_URL'];

  try {
    _authenticationToken = await SpotifySdk.getAuthenticationToken(
        clientId: clientId,
        redirectUrl: redirectUrl,
        scope:
            "app-remote-control,user-modify-playback-state, user-read-recently-played, user-top-read, user-read-currently-playing, user-read-playback-state");
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
    _currentTrack = CurrentTrack.fromJson(jsonDecode(response.body));
  } else {
    print('No current track playing');
  }
}

Future<void> loadRecentSpotifyTrack() async {
  final response = await http.get(
      'https://api.spotify.com/v1/me/player/recently-played',
      headers: {'Authorization': 'Bearer ' + _authenticationToken});

  if (response.statusCode == 200) {
    _currentTrack = RecentTrack.fromJson(jsonDecode(response.body));
    await _currentTrack.getImage();
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
  final response = await http
      .get(_url, headers: {'Authorization': 'Bearer ' + _authenticationToken});

  if (response.statusCode == 200) {
    _storedTrack = StoredTrack.fromJson(jsonDecode(response.body));
    return (_storedTrack);
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
      json = jsonDecode(response.body);
      this.imageUrl = json['album']['images'][0]['url'];
    } else {
      print('Track ID not found');
    }
  }
}

Future<void> loadTodaysTracks() async {
  Map<String, String> _queryParams = {
    'limit': '5',
  };

  var endpoint = "https://api.spotify.com/v1/me/player/recently-played";
  String queryString = Uri(queryParameters: _queryParams).query;
  var uri = endpoint + '?' + queryString;

  final response = await http.get(uri, headers: {
    'Authorization': 'Bearer ' + _authenticationToken,
    'contentTypeHeader': 'application/json'
  });

  if (response.statusCode == 200) {
    num length = jsonDecode(response.body)["items"].length;

    for (var i = 0; i < length; i++) {
      _todaysTracks.add(TodayTrack.fromJson(jsonDecode(response.body), i));
      await _todaysTracks[i].getImage();
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
