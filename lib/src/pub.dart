import 'dart:convert';

import 'package:http/http.dart' as http;

class Pub {
  http.Client? _httpClient;

  http.Client get httpClient => _httpClient ??= http.Client();

  Future<bool> hasPublishedVersion(String name, String version) async {
    var response =
        await httpClient.get(Uri.parse('https://pub.dev/packages/$name.json'));
    if (response.statusCode != 200) {
      return false;
    }

    var json = jsonDecode(response.body) as Map;
    var versions = (json['versions'] as List).cast<String>();
    return versions.contains(version);
  }

  // todo: call this
  void close() {
    _httpClient?.close();
  }
}
