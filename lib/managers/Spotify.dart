// Spotify
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

var authenticationToken;

Future<void> getSpotifyAuth() async {
  String clientId = DotEnv().env['CLIENT_ID'];
  String redirectUrl = DotEnv().env['REDIRECT_URL'];
  print("Initializing Spotify for client $clientId and URI $redirectUrl");

  authenticationToken = await SpotifySdk.getAuthenticationToken(
      clientId: clientId,
      redirectUrl: redirectUrl,
      scope:
          "app-remote-control,user-modify-playback-state, user-read-recently-played, user-top-read, user-read-currently-playing, user-read-playback-state");
  print("Auth token retrieved: $authenticationToken");
  return authenticationToken;
}

class CurrentTrack {
  final String artist;
  final String track;
  final String url;
  final String href;

  CurrentTrack({this.artist, this.track, this.url, this.href});

  factory CurrentTrack.fromJson(Map<String, dynamic> json) {
    return CurrentTrack(
        artist: json['item']['album']['artists'][0]['name'],
        track: json['item']['name'],
        url: json['item']['external_urls']['spotify'],
        href: json['item']['href']);
  }
}

Future<CurrentTrack> fetchTrack() async {
  final response = await http.get(
      'https://api.spotify.com/v1/me/player/currently-playing',
      headers: {'Authorization': 'Bearer ' + authenticationToken});

  if (response.statusCode == 200) {
    var currentTrack = CurrentTrack.fromJson(jsonDecode(response.body));
    print("artist: ${currentTrack.artist}");
    print("track: ${currentTrack.track}");
    print("url: ${currentTrack.url}");
    print("href: ${currentTrack.href}");
    return currentTrack;
  } else {
    throw Exception('Failed to fetch track');
  }
}

// Future<void> getPlayerState() async {
//   print("getting current track...");
//   var playerConnection = await SpotifySdk.subscribeConnectionStatus();
//   var currentPlayerState = await SpotifySdk.subscribePlayerState();
//   print("Connection: $playerConnection");
//   print("PlayerState: $currentPlayerState");

//   //await SpotifySdk.pause();
// }
