import 'dart:convert';

import 'package:http/http.dart' as http;

class Pub {
  Future<bool> hasPublishedVersion(String name, String version) async {
    var response =
        await http.get(Uri.parse('https://pub.dev/packages/$name.json'));
    if (response.statusCode != 200) {
      return false;
    }

    var json = jsonDecode(response.body);
    var versions = (json['versions'] as List).cast<String>();
    return versions.contains(version);
  }
}
