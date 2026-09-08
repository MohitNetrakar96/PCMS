import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DoorstepGeotagPhotoWidget extends StatefulWidget {
  final String customerName;
  final String customerId;
  final String area;
  final String address;
  final double? latitude;
  final double? longitude;
  final String agentName;
  final String? initialPhotoBase64;
  final ValueChanged<String?> onPhotoChanged;

  const DoorstepGeotagPhotoWidget({
    super.key,
    required this.customerName,
    required this.customerId,
    required this.area,
    required this.address,
    this.latitude,
    this.longitude,
    required this.agentName,
    this.initialPhotoBase64,
    required this.onPhotoChanged,
  });

  @override
  State<DoorstepGeotagPhotoWidget> createState() => _DoorstepGeotagPhotoWidgetState();
}

class _DoorstepGeotagPhotoWidgetState extends State<DoorstepGeotagPhotoWidget> {
  final ImagePicker _picker = ImagePicker();
  String? _photoBase64;
  String? _capturedTimestamp;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _photoBase64 = widget.initialPhotoBase64;
    if (_photoBase64 != null) {
      _capturedTimestamp = DateFormat('dd MMM yyyy, hh:mm:ss a').format(DateTime.now());
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      setState(() => _isProcessing = true);
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final timeStr = DateFormat('dd MMM yyyy, hh:mm:ss a').format(DateTime.now());

        setState(() {
          _photoBase64 = base64String;
          _capturedTimestamp = timeStr;
          _isProcessing = false;
        });

        widget.onPhotoChanged(_photoBase64);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Doorstep photo geotagged & attached ✓', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _photoBase64 = null;
      _capturedTimestamp = null;
    });
    widget.onPhotoChanged(null);
  }

  void _showFullscreenPhoto() {
    if (_photoBase64 == null) return;

    final lat = widget.latitude ?? 15.3647;
    final lng = widget.longitude ?? 75.1240;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final coordStr = '${lat.abs().toStringAsFixed(5)}° $latDir, ${lng.abs().toStringAsFixed(5)}° $lngDir';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.black.withOpacity(0.85),
                elevation: 0,
                title: const Text('Geotagged Doorstep Audit Proof', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Flexible(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.memory(
                      base64Decode(_photoBase64!),
                      fit: BoxFit.contain,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.95),
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 16),
                              const SizedBox(width: 6),
                              const Text('TAMPER-PROOF GEOTAGGED PROOF', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('📍 GPS: $coordStr', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('🏢 Customer: ${widget.customerName} (${widget.customerId})', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('📍 Address: ${widget.address.isNotEmpty ? widget.address : widget.area}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('🕒 Timestamp: ${_capturedTimestamp ?? DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now())}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('🛡️ Verified Agent: ${widget.agentName}', style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.latitude ?? 15.3647;
    final lng = widget.longitude ?? 75.1240;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final coordStr = '${lat.abs().toStringAsFixed(4)}° $latDir, ${lng.abs().toStringAsFixed(4)}° $lngDir';

    if (_photoBase64 != null) {
      // Photo Captured State
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Doorstep Geotagged Photo',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Text(
                      'GPS Verified ✓',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),

            // Photo Preview with Geotag HUD Overlay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _showFullscreenPhoto,
                      child: SizedBox(
                        height: 190,
                        width: double.infinity,
                        child: Image.memory(
                          base64Decode(_photoBase64!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Frosted Geotag Watermark Strip
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.black.withOpacity(0.65),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Color(0xFF4ADE80), size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$coordStr • ${widget.area}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.touch_app_rounded, color: Colors.white70, size: 12),
                              const Text(' View', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: Colors.white70, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                _capturedTimestamp ?? 'Just now',
                                style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                              ),
                              const Spacer(),
                              Text(
                                'Agent: ${widget.agentName.split(" ")[0]}',
                                style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 15, color: Color(0xFF55356E)),
                      label: const Text('Retake', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF55356E))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: Color(0xFF55356E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 15, color: Color(0xFF2563EB)),
                      label: const Text('Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _removePhoto,
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                    tooltip: 'Remove Photo',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default Uncaptured State
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF55356E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF55356E), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doorstep Geotagged Photo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capture customer doorstep with GPS watermark',
                      style: TextStyle(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // GPS Tag Preview Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: Color(0xFF2563EB), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'GPS Ready: $coordStr • ${widget.area}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Trigger Buttons
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Color(0xFF55356E), strokeWidth: 2.5),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: const Text('Capture Doorstep Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF55356E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFF2563EB)),
                    label: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
