import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class CenterService {
  static const String _googleApiKey = "AIzaSyB715cm57Fb-nuhUYxW-YSTwi31mGKSGso";

  static Future<Set<Marker>> fetchMarkers(LatLng location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
      'location=${location.latitude},${location.longitude}&'
      'radius=50000&keyword=recycling%20center&key=$_googleApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load data');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    final results = (data['results'] as List<dynamic>?) ?? [];

    return results.take(10).map<Marker>((place) {
      final location = place['geometry']['location'];
      final lat = location['lat'] as double;
      final lng = location['lng'] as double;
      final name = place['name'] ?? 'Unknown';
      final address = place['vicinity'] ?? 'No address';

      return Marker(
        markerId: MarkerId(place['place_id']),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: name, snippet: address),
      );
    }).toSet();
  }
}
