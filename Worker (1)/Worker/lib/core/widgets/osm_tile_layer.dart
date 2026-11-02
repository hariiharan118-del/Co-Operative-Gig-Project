import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// OSM raster tiles with an identifying User-Agent (required by OSM tile usage).
TileLayer osmTileLayer({required String userAgent}) {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: userAgent,
    tileProvider: NetworkTileProvider(
      headers: {'User-Agent': userAgent},
    ),
  );
}

Widget osmAttribution() {
  return const SimpleAttributionWidget(
    source: Text('OpenStreetMap contributors'),
  );
}
