class MapboxConfig {
  static String publicAccessToken = '';

  // Style Keys
  static const String styleStreets = 'streets';
  static const String styleSatellite = 'satellite';
  static const String styleDark = 'dark';
  static const String styleOutdoors = 'outdoors';
  static const String styleLight = 'light';

  // Tile URL Provider (100% Watermark-Free & Zero API Key Required)
  static String getTileUrl({String style = styleStreets, String? token}) {
    final activeToken = token ?? publicAccessToken;
    
    // If a valid Mapbox token is provided, use Mapbox endpoints
    if (activeToken.isNotEmpty && activeToken.startsWith('pk.')) {
      String mapboxStyle = 'streets-v12';
      if (style == styleSatellite) mapboxStyle = 'satellite-streets-v12';
      if (style == styleDark) mapboxStyle = 'dark-v11';
      if (style == styleOutdoors) mapboxStyle = 'outdoors-v12';
      if (style == styleLight) mapboxStyle = 'light-v11';
      return 'https://api.mapbox.com/styles/v1/mapbox//tiles/256/{z}/{x}/{y}@2x?access_token=';
    }

    // 100% Watermark-Free High-Definition Providers (No API Keys, No Watermarks!)
    switch (style) {
      case styleSatellite:
        // Esri HD Satellite Imagery (Crisp aerial view, Zero watermark)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case styleDark:
        // Esri World Dark Gray Canvas (Sleek Tactical Dark Mode, Zero watermark)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
      case styleOutdoors:
        // OpenTopoMap (Topographic terrain & rivers, Zero watermark)
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case styleLight:
        // Esri World Light Canvas (Minimal light style, Zero watermark)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}';
      case styleStreets:
      default:
        // OpenStreetMap Standard HD (Full street names, landmarks, shops, Zero watermark)
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }
}
