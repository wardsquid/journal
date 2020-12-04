// Spotify
import 'package:async/async.dart';
import 'package:spotify_sdk/models/connection_status.dart';
import 'package:spotify_sdk/models/crossfade_state.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/models/player_context.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'dart:convert';

var _authenticationToken;
//CurrentTrack _currentTrack;
var _currentTrack;

Future<void> getSpotifyAuth() async {
  String clientId = DotEnv().env['CLIENT_ID'];
  String redirectUrl = DotEnv().env['REDIRECT_URL'];
  print("Initializing Spotify for client $clientId and URI $redirectUrl");

  _authenticationToken = await SpotifySdk.getAuthenticationToken(
      clientId: clientId,
      redirectUrl: redirectUrl,
      scope:
          "app-remote-control,user-modify-playback-state, user-read-recently-played, user-top-read, user-read-currently-playing, user-read-playback-state");
  print("Auth token retrieved: $_authenticationToken");
  await loadRecentSpotifyTrack();
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

  void getImage() async {
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
    loadRecentSpotifyTrack();
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
  print("just fetched track: ${_currentTrack.artist}");
  return _currentTrack;
}

// Future<void> getPlayerState() async {
//   print("getting current track...");
//   var playerConnection = await SpotifySdk.subscribeConnectionStatus();
//   var currentPlayerState = await SpotifySdk.subscribePlayerState();
//   print("Connection: $playerConnection");
//   print("PlayerState: $currentPlayerState");

//   //await SpotifySdk.pause();
// }
