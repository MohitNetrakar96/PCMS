import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class BankerAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;
  final bool showBadge;
  final IconData badgeIcon;
  final Color badgeColor;

  const BankerAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 46,
    this.onTap,
    this.showBadge = false,
    this.badgeIcon = Icons.camera_alt,
    this.badgeColor = const Color(0xFF76A787),
  });

  ImageProvider? _getImageProvider(String url) {
    try {
      if (url.startsWith('data:image')) {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final Uint8List bytes = base64Decode(base64Str);
        return MemoryImage(bytes);
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        return NetworkImage(url);
      } else if (url.startsWith('/') || (url.length > 2 && url[1] == ':')) {
        return FileImage(File(url));
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = photoUrl != null && photoUrl!.trim().isNotEmpty
        ? _getImageProvider(photoUrl!.trim())
        : null;

    final avatarContent = CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD6F5FF),
      child: CircleAvatar(
        radius: radius - 3,
        backgroundColor: const Color(0xFF55356E),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Text(
                (name.isNotEmpty ? name[0] : 'B').toUpperCase(),
                style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD6F5FF),
                ),
              )
            : null,
      ),
    );

    if (!showBadge && onTap == null) {
      return avatarContent;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatarContent,
          if (showBadge)
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(badgeIcon, size: radius * 0.35, color: const Color(0xFF191308)),
            ),
        ],
      ),
    );
  }
}
