// Spotify
import 'package:spotify_sdk/models/connection_status.dart';
import 'package:spotify_sdk/models/crossfade_state.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/models/player_context.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initializeSpotify() async {
  String clientId = DotEnv().env['CLIENT_ID'];
  String redirectUrl = DotEnv().env['REDIRECT_URL'];
  print("Initializing Spotify for client $clientId and URI $redirectUrl");
  // bool connected = await SpotifySdk.connectToSpotifyRemote(
  //     clientId: DotEnv().env['CLIENT_ID'],
  //     redirectUrl: DotEnv().env['REDIRECT_URL']);
  // print("Spotify connection status: $connected!");
  var authenticationToken = await SpotifySdk.getAuthenticationToken(
      clientId: clientId,
      redirectUrl: redirectUrl,
      scope:
          "app-remote-control,user-modify-playback-state, user-read-recently-played, user-top-read");
  print("Auth token retrieved: $authenticationToken");
}
