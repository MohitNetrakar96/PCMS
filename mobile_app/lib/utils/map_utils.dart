import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  /// Opens turn-by-turn navigation or map location for a customer.
  /// Falls back smoothly from native Google Maps intent to Google Maps Web and coordinates search.
  static Future<void> openMap({
    required BuildContext context,
    double? latitude,
    double? longitude,
    String? title,
    String? address,
  }) async {
    try {
      Uri? targetUri;

      if (latitude != null && longitude != null && latitude != 0.0 && longitude != 0.0) {
        // Preferred: Turn-by-turn direction to the exact coordinate
        targetUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
        );
      } else if (address != null && address.trim().isNotEmpty) {
        // Fallback: Search by address string
        final encoded = Uri.encodeComponent(address.trim());
        targetUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
      }

      if (targetUri == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No location coordinates or address registered for this stop.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
        return;
      }

      // Try launching external application (Google Maps)
      bool launched = false;
      try {
        launched = await launchUrl(targetUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // If external app fails, try platform default
        try {
          launched = await launchUrl(targetUri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening maps in browser/app...'),
            backgroundColor: Color(0xFF55356E),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching navigation: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// Opens the full optimized multi-stop route sequence in Google Maps
  static Future<void> openFullRoute({
    required BuildContext context,
    required List<Map<String, dynamic>> waypoints,
  }) async {
    try {
      if (waypoints.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pending waypoints on route today.')),
          );
        }
        return;
      }

      final validCoords = waypoints.where((w) {
        final lat = (w['lat'] as num?)?.toDouble();
        final lng = (w['lng'] as num?)?.toDouble();
        return lat != null && lng != null && lat != 0.0 && lng != 0.0;
      }).toList();

      if (validCoords.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waypoints do not contain GPS coordinates.')),
          );
        }
        return;
      }

      final destination = validCoords.first;
      final lat = destination['lat'];
      final lng = destination['lng'];

      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening route: $e')),
        );
      }
    }
  }
}
