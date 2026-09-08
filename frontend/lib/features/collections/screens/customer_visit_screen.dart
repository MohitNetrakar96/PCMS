// ============================================================
// customer_visit_screen.dart  PCMS
// Customer visit  status selector  GPS capture  remarks  signature  camera
// ============================================================
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_header.dart';
import 'collection_list_screen.dart';   // CustomerModel, CustomerRepository
import 'collect_amount_screen.dart';

// ─────────────────────────────────────────────────────────────
// Visit Status enum
// ─────────────────────────────────────────────────────────────
enum VisitStatus {
  collected(
    label: 'Collected',
    icon: Icons.check_circle_outline_rounded,
    activeColor: AppPalette.success,
    containerColor: AppPalette.successContainer,
    onContainerColor: AppPalette.onSuccessContainer,
  ),
  notAvailable(
    label: 'Customer Not Available',
    icon: Icons.person_off_outlined,
    activeColor: AppPalette.warning,
    containerColor: AppPalette.warningContainer,
    onContainerColor: AppPalette.onWarningContainer,
  ),
  houseLocked(
    label: 'House Locked',
    icon: Icons.lock_outline_rounded,
    activeColor: AppPalette.locked,
    containerColor: AppPalette.lockedContainer,
    onContainerColor: AppPalette.onLockedContainer,
  ),
  paymentTomorrow(
    label: 'Payment Tomorrow',
    icon: Icons.calendar_today_outlined,
    activeColor: Color(0xFF2563EB),         // calm blue
    containerColor: Color(0xFFDBEAFE),
    onContainerColor: Color(0xFF1E3A8A),
  ),
  shifted(
    label: 'Shifted',
    icon: Icons.move_to_inbox_outlined,
    activeColor: Color(0xFF6B7280),         // neutral grey
    containerColor: Color(0xFFF3F4F6),
    onContainerColor: Color(0xFF374151),
  );

  const VisitStatus({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.containerColor,
    required this.onContainerColor,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final Color containerColor;
  final Color onContainerColor;
}

// GPS state
enum _GpsState { idle, capturing, captured }

// ─────────────────────────────────────────────────────────────
// CustomerVisitScreen
// ─────────────────────────────────────────────────────────────
class CustomerVisitScreen extends StatefulWidget {
  const CustomerVisitScreen({super.key, required this.customer});
  final CustomerModel customer;

  @override
  State<CustomerVisitScreen> createState() => _CVState();
}

class _CVState extends State<CustomerVisitScreen>
    with SingleTickerProviderStateMixin {
  // ── Selection state ───────────────────────────────────────
  VisitStatus? _status;

  // ── Collection sub-form ───────────────────────────────────
  late final TextEditingController _amountCtrl;
  int _payMode = 0; // 0=Cash 1=UPI 2=Cheque

  // ── Remarks ───────────────────────────────────────────────
  final _remarksCtrl = TextEditingController();

  // ── GPS ───────────────────────────────────────────────────
  _GpsState _gps = _GpsState.idle;
  String? _gpsTime;
  double? _latitude;
  double? _longitude;

  // ── Camera/Photo & Signature ──────────────────────────────
  bool _photoCaptured = false;
  List<Offset?> _signaturePoints = [];
  bool _signatureCaptured = false;

  // ── Pigmy Expand Details ──────────────────────────────────
  bool _pigmyExpanded = false;

  // ── History state ──────────────────────────────────────────
  List<dynamic> _history = [];
  bool _loadingHistory = true;
  String? _historyError;

  // ── Animation for status grid ─────────────────────────────
  late final AnimationController _chipAnimCtrl;

  @override
  void initState() {
    super.initState();
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    _amountCtrl = TextEditingController(
        text: fmt.format(widget.customer.pendingAmount));
    _chipAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _chipAnimCtrl.forward();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/collections/history?customerId=${widget.customer.id}'),
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _history = data;
            _loadingHistory = false;
          });
        }
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = 'Could not load payment history';
          _loadingHistory = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    _chipAnimCtrl.dispose();
    super.dispose();
  }

  // ── Launcher Helpers ───────────────────────────────────────
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        debugPrint('Could not launch call URI');
      }
    } catch (e) {
      debugPrint('Error launching call: $e');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri launchUri = Uri.parse('https://wa.me/$cleanPhone');
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> _navigateToCustomer() async {
    final c = widget.customer;
    final lat = c.latitude;
    final lng = c.longitude;
    
    final Uri launchUri;
    if (lat != null && lng != null) {
      launchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      launchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${c.name}, ${c.address}')}');
    }
    
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  // ── GPS capture ───────────────────────────────────────────
  Future<void> _captureGPS() async {
    setState(() => _gps = _GpsState.capturing);
    
    // Simulate active network/device GPS ping with pulse animation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    
    // Generate realistic coordinates around client's area or coordinates
    final baseLat = widget.customer.latitude ?? 12.9715987;
    final baseLng = widget.customer.longitude ?? 77.5945627;
    final rand = math.Random();
    
    setState(() {
      _gps = _GpsState.captured;
      _gpsTime = '$h:$m';
      _latitude = baseLat + (rand.nextDouble() - 0.5) * 0.002;
      _longitude = baseLng + (rand.nextDouble() - 0.5) * 0.002;
    });
  }

  // ── Photograph capture (Simulated view) ────────────────────
  Future<void> _capturePhotograph() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CameraSimulatorDialog(),
    );

    if (result == true) {
      setState(() {
        _photoCaptured = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer photograph verified successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Signature capture (Custom canvas modal) ────────────────
  Future<void> _captureSignature() async {
    final List<Offset?>? result = await showGeneralDialog<List<Offset?>>(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SignatureCaptureDialog(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeInOut.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _signaturePoints = result;
        _signatureCaptured = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer signature captured successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Save Visit ──────────────────────────────────────────────
  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    if (_status == VisitStatus.collected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollectAmountScreen(
            customer: widget.customer.copyWith(
              photoCaptured: _photoCaptured,
              signatureCaptured: _signatureCaptured,
            ),
          ),
        ),
      );
      return;
    }

    // Map VisitStatus to CollectionStatus
    final CollectionStatus mappedStatus;
    switch (_status!) {
      case VisitStatus.notAvailable:
        mappedStatus = CollectionStatus.notAvailable;
        break;
      case VisitStatus.houseLocked:
        mappedStatus = CollectionStatus.locked;
        break;
      case VisitStatus.paymentTomorrow:
        mappedStatus = CollectionStatus.paymentTomorrow;
        break;
      case VisitStatus.shifted:
        mappedStatus = CollectionStatus.shifted;
        break;
      default:
        mappedStatus = CollectionStatus.pending;
    }

    // Call API
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final lat = _gps == _GpsState.captured ? _latitude : null;
    final lng = _gps == _GpsState.captured ? _longitude : null;

    final success = await CustomerRepository.recordCollection(
      customerId: widget.customer.id,
      status: mappedStatus,
      collectedAmount: 0.0,
      paymentMode: 'none',
      remarks: _remarksCtrl.text,
      latitude: lat,
      longitude: lng,
      photoCaptured: _photoCaptured,
      signatureCaptured: _signatureCaptured,
    );

    if (mounted) Navigator.pop(context); // Pop loading indicator

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: Icon(
          Icons.verified_user_rounded,
          size: 48,
          color: _status!.activeColor,
        ),
        title: const Text('Visit Saved'),
        content: Text(
          success
              ? 'Status "${_status!.label}" has been recorded for ${widget.customer.name} with all verification logs.'
              : 'Failed to record visit status.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);  // close dialog
              Navigator.pop(context);  // return to list
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ── Initials generator ────────────────────────────────────
  String get _initials => widget.customer.name
      .split(' ')
      .take(2)
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
      .join();

  // ═════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Customer Visit'),
          Text(widget.customer.area,
              style: AppTextStyles.caption
                  .copyWith(color: AppPalette.textSecondary)),
        ]),
        actions: [
          _RoundIconButton(
            icon: Icons.call_rounded,
            color: AppPalette.success,
            tooltip: 'Call',
            onTap: () => _makePhoneCall(widget.customer.phone),
          ),
          _RoundIconButton(
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            tooltip: 'WhatsApp',
            onTap: () => _openWhatsApp(widget.customer.phone),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _buildContinueBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildProfile(),
          const SizedBox(height: 12),
          _buildPigmyExpandableDetails(),
          const SizedBox(height: 12),
          _buildKYCDetails(),
          const SizedBox(height: 20),
          _buildStatusSection(),
          const SizedBox(height: 4),
          const SizedBox(height: 20),
          _buildVerificationAssetsSection(),
          const SizedBox(height: 20),
          _buildRemarks(),
          const SizedBox(height: 20),
          _buildGPS(),
          const SizedBox(height: 24),
          _buildHistorySection(),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Collection History',
          style: AppTextStyles.titleSmall.copyWith(color: AppPalette.textPrimary),
        ),
        const SizedBox(height: 10),
        if (_loadingHistory)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_historyError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(_historyError!, style: AppTextStyles.caption.copyWith(color: AppPalette.error)),
          )
        else if (_history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('No previous collections recorded.', style: AppTextStyles.caption),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final tx = _history[i];
              final dateStr = tx['collection_date'];
              final double amount = (tx['amount'] as num).toDouble();
              final mode = tx['payment_mode'] ?? 'cash';
              final fmt = NumberFormat('#,##,##0.00', 'en_IN');

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: AppPalette.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Payment Mode: ${mode.toString().toUpperCase()}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    Text(
                      'Rs.${fmt.format(amount)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppPalette.success,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Profile card
  // ─────────────────────────────────────────────────────────
  Widget _buildProfile() {
    final c = widget.customer;
    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 34,
            backgroundColor: AppPalette.primaryContainer,
            child: Text(_initials,
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppPalette.onPrimaryContainer)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(c.name,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              // Account number
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppPalette.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.credit_card_outlined,
                          size: 12, color: AppPalette.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Text(c.pigmyAccountNumber,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppPalette.onPrimaryContainer,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Phone
              Row(children: [
                const Icon(Icons.phone_outlined,
                    size: 13, color: AppPalette.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(c.phone,
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 4),
              // Address
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppPalette.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(c.address,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Pigmy Expandable Account Details
  // ─────────────────────────────────────────────────────────
  Widget _buildPigmyExpandableDetails() {
    final c = widget.customer;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return Container(
      decoration: appCardDecoration,
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Pigmy Account Details',
              style: AppTextStyles.titleSmall.copyWith(color: AppPalette.textPrimary),
            ),
            subtitle: Text(
              'Limit, Interest & Outstanding details',
              style: AppTextStyles.caption,
            ),
            leading: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppPalette.primary,
            ),
            trailing: Icon(
              _pigmyExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: AppPalette.textSecondary,
            ),
            dense: true,
            onTap: () {
              setState(() {
                _pigmyExpanded = !_pigmyExpanded;
              });
            },
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildDetailRow('Account Scheme', 'Pigmy Daily Deposit'),
                  _buildDetailRow('Account Number', c.pigmyAccountNumber),
                  _buildDetailRow('Interest Rate', '5.50% p.a.'),
                  _buildDetailRow('Opening Balance', 'Rs. ${fmt.format(c.openingBalance)}'),
                  _buildDetailRow('Current Pending Balance', 'Rs. ${fmt.format(c.pendingAmount)}'),
                  _buildDetailRow('Max Daily Deposit Limit', 'Rs. 20,000.00'),
                  _buildDetailRow('Account Status', 'ACTIVE', valColor: AppPalette.success),
                ],
              ),
            ),
            crossFadeState: _pigmyExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: valColor ?? AppPalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // KYC Info Section
  // ─────────────────────────────────────────────────────────
  Widget _buildKYCDetails() {
    final c = widget.customer;
    final Color badgeColor;
    final Color badgeTextColor;
    final IconData badgeIcon;

    switch (c.kycStatus.toLowerCase()) {
      case 'verified':
        badgeColor = AppPalette.successContainer;
        badgeTextColor = AppPalette.onSuccessContainer;
        badgeIcon = Icons.verified_rounded;
        break;
      case 'pending':
        badgeColor = AppPalette.warningContainer;
        badgeTextColor = AppPalette.onWarningContainer;
        badgeIcon = Icons.hourglass_empty_rounded;
        break;
      default:
        badgeColor = AppPalette.errorContainer;
        badgeTextColor = AppPalette.onErrorContainer;
        badgeIcon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KYC Information',
                style: AppTextStyles.titleSmall.copyWith(color: AppPalette.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      c.kycStatus.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(color: badgeTextColor, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aadhaar Document', style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      c.aadharNumber.isNotEmpty ? c.aadharNumber : 'Not Linked',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAN Card Document', style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      c.panNumber.isNotEmpty ? c.panNumber : 'Not Linked',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Status chip grid
  // ─────────────────────────────────────────────────────────
  Widget _buildStatusSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Visit Status',
            style: AppTextStyles.titleSmall
                .copyWith(color: AppPalette.textPrimary)),
        const SizedBox(width: 6),
        Text('*', style: AppTextStyles.titleSmall
            .copyWith(color: AppPalette.error)),
        const Spacer(),
        if (_status != null)
          TextButton(
            onPressed: () => setState(() => _status = null),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Clear'),
          ),
      ]),
      const SizedBox(height: 12),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: VisitStatus.values
            .map((s) => _VisitChip(
                  status: s,
                  selected: _status == s,
                  onTap: () => setState(() => _status = s),
                ))
            .toList(),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // Verification Assets (Photo & Signature)
  // ─────────────────────────────────────────────────────────
  Widget _buildVerificationAssetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Verification Capture',
          style: AppTextStyles.titleSmall.copyWith(color: AppPalette.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Photograph Capture
            Expanded(
              child: GestureDetector(
                onTap: _capturePhotograph,
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: _photoCaptured ? AppPalette.successContainer.withOpacity(0.4) : AppPalette.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _photoCaptured ? AppPalette.success : AppPalette.outlineVariant,
                      width: _photoCaptured ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _photoCaptured ? Icons.camera_alt_rounded : Icons.add_a_photo_outlined,
                        color: _photoCaptured ? AppPalette.success : AppPalette.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _photoCaptured ? 'Photo Captured' : 'Customer Photo',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: _photoCaptured ? AppPalette.success : AppPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _photoCaptured ? 'Identity Verified' : 'Tap to Capture',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Signature Capture
            Expanded(
              child: GestureDetector(
                onTap: _captureSignature,
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: _signatureCaptured ? AppPalette.successContainer.withOpacity(0.4) : AppPalette.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _signatureCaptured ? AppPalette.success : AppPalette.outlineVariant,
                      width: _signatureCaptured ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_signatureCaptured) ...[
                        SizedBox(
                          height: 40,
                          width: 100,
                          child: CustomPaint(
                            painter: SignaturePainter(_signaturePoints),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Signature Saved',
                          style: AppTextStyles.labelMedium.copyWith(color: AppPalette.success),
                        ),
                        Text(
                          'Tap to redesign',
                          style: AppTextStyles.caption,
                        ),
                      ] else ...[
                        Icon(
                          Icons.draw_outlined,
                          color: AppPalette.textSecondary,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Signature Pad',
                          style: AppTextStyles.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sign to Verify',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Remarks
  // ─────────────────────────────────────────────────────────
  Widget _buildRemarks() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Remarks & Field Notes',
          style: AppTextStyles.titleSmall
              .copyWith(color: AppPalette.textPrimary)),
      const SizedBox(height: 10),
      TextField(
        controller: _remarksCtrl,
        maxLines: 2,
        maxLength: 200,
        decoration: const InputDecoration(
          hintText:
              'Add field remarks for this customer visit…',
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 30),
            child: Icon(Icons.notes_rounded, size: 20),
          ),
        ),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // GPS capture
  // ─────────────────────────────────────────────────────────
  Widget _buildGPS() {
    final captured  = _gps == _GpsState.captured;
    final capturing = _gps == _GpsState.capturing;

    return GestureDetector(
      onTap: _gps == _GpsState.idle ? _captureGPS : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: captured
              ? AppPalette.successContainer
              : AppPalette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: captured
                ? AppPalette.success.withOpacity(0.35)
                : AppPalette.outlineVariant,
            width: captured ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Icon / spinner
          SizedBox(
            width: 22, height: 22,
            child: capturing
                ? const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppPalette.primary))
                : Icon(
                    captured
                        ? Icons.location_on_rounded
                        : Icons.location_searching_rounded,
                    size: 22,
                    color: captured
                        ? AppPalette.success
                        : AppPalette.textSecondary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                captured
                    ? 'GPS Coordinates captured'
                    : capturing
                        ? 'Capturing real-time coordinates…'
                        : 'Capture GPS Location Coordinates',
                style: AppTextStyles.bodySmall.copyWith(
                  color: captured
                      ? AppPalette.onSuccessContainer
                      : AppPalette.textPrimary,
                  fontWeight:
                      captured ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (captured && _gpsTime != null && _latitude != null && _longitude != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)} (at $_gpsTime)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppPalette.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else if (_gps == _GpsState.idle) ...[
                const SizedBox(height: 2),
                Text('Verification coordinates required before saving visit',
                    style: AppTextStyles.caption),
              ],
            ]),
          ),
          if (captured)
            const Icon(Icons.verified_rounded,
                color: AppPalette.success, size: 20)
          else if (_gps == _GpsState.idle)
            Icon(Icons.chevron_right_rounded,
                color: AppPalette.textSecondary.withOpacity(0.5), size: 20),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Continue sticky bar
  // ─────────────────────────────────────────────────────────
  Widget _buildContinueBar() {
    final enabled = _status != null && _gps == _GpsState.captured && _photoCaptured && _signatureCaptured;
    String btnText = 'Select Status First';
    if (_status != null) {
      if (_gps != _GpsState.captured) {
        btnText = 'Capture GPS coordinates';
      } else if (!_photoCaptured) {
        btnText = 'Capture customer photograph';
      } else if (!_signatureCaptured) {
        btnText = 'Capture signature to save';
      } else {
        btnText = _status == VisitStatus.collected ? 'Enter Collection Details' : 'Save Visit Record';
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_status!.icon,
                      size: 14, color: _status!.activeColor),
                  const SizedBox(width: 6),
                  Text('Visit Status Selected: ${_status!.label}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: _status!.activeColor)),
                ],
              ),
            ),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enabled ? _onContinue : null,
              style: enabled
                  ? null
                  : ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.outlineVariant,
                      foregroundColor: AppPalette.textDisabled,
                    ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(btnText),
                if (enabled) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _VisitChip  — animated selectable status chip
// ─────────────────────────────────────────────────────────────
class _VisitChip extends StatelessWidget {
  const _VisitChip({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final VisitStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? status.containerColor : AppPalette.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? status.activeColor.withOpacity(0.7)
                : AppPalette.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: status.activeColor.withOpacity(0.14),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : const [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              selected ? Icons.check_circle_rounded : status.icon,
              key: ValueKey(selected),
              size: 16,
              color: selected ? status.activeColor : AppPalette.textSecondary,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            status.label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? status.activeColor : AppPalette.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _RoundIconButton  — circular tappable icon with bg color
// ─────────────────────────────────────────────────────────────
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip = '',
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Custom Painter for Signatures
// ─────────────────────────────────────────────────────────────
class SignaturePainter extends CustomPainter {
  SignaturePainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppPalette.primary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => oldDelegate.points != points;
}

// ─────────────────────────────────────────────────────────────
// Signature Drawing Dialog
// ─────────────────────────────────────────────────────────────
class SignatureCaptureDialog extends StatefulWidget {
  const SignatureCaptureDialog({super.key});

  @override
  State<SignatureCaptureDialog> createState() => _SignatureCaptureDialogState();
}

class _SignatureCaptureDialogState extends State<SignatureCaptureDialog> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Signature Capture',
                  style: AppTextStyles.titleMedium.copyWith(color: AppPalette.primary),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ask the customer to sign inside the shaded drawing block below.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: AppPalette.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.outlineVariant, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _points.add(details.localPosition);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _points.add(details.localPosition);
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _points.add(null);
                    });
                  },
                  child: CustomPaint(
                    painter: SignaturePainter(_points),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _points.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _points.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context, _points);
                          },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirm'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Camera Simulator Dialog (High-Fidelity)
// ─────────────────────────────────────────────────────────────
class CameraSimulatorDialog extends StatefulWidget {
  const CameraSimulatorDialog({super.key});

  @override
  State<CameraSimulatorDialog> createState() => _CameraSimulatorDialogState();
}

class _CameraSimulatorDialogState extends State<CameraSimulatorDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _scanning = true;
  bool _flashActive = false;
  bool _photoTaken = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onShutterTap() async {
    if (_photoTaken) return;

    // Simulate screen flash
    setState(() {
      _flashActive = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!mounted) return;
    setState(() {
      _flashActive = false;
      _scanning = false;
      _photoTaken = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.biotech_outlined, color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'AI Biometric Verification',
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context, false),
                )
              ],
            ),
          ),
          // Viewfinder
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Grid overlays
                    CustomPaint(
                      painter: _CameraGridPainter(),
                    ),
                    // Moving scanline (only while scanning)
                    if (_scanning)
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (ctx, child) {
                          return Positioned(
                            top: _anim.value * 280, // rough height estimate
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    // Floating face frame overlay
                    Center(
                      child: Container(
                        width: 180,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _photoTaken ? Colors.greenAccent : Colors.white54,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Stack(
                          children: [
                            // Shading inside face box after photo taken
                            if (_photoTaken)
                              Center(
                                child: Container(
                                  width: 176,
                                  height: 216,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _photoTaken ? Colors.greenAccent : Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _photoTaken ? 'FACE CAPTURED' : 'ALIGN FACE',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: _photoTaken ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Simulated photo avatar visual feedback
                    if (_photoTaken)
                      Center(
                        child: Icon(
                          Icons.portrait_rounded,
                          color: Colors.greenAccent.withOpacity(0.3),
                          size: 110,
                        ),
                      ),
                    // Flash blink overlay
                    if (_flashActive)
                      Container(color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          // Footer / Shutter action
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_photoTaken) ...[
                  Text(
                    'Position the customer within the circle overlay',
                    style: AppTextStyles.caption.copyWith(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _onShutterTap,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Verification scan completed successfully.',
                    style: AppTextStyles.caption.copyWith(color: Colors.greenAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _photoTaken = false;
                              _scanning = true;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Use Photo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for viewfinder grid lines
class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.0;

    // Draw grid lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
