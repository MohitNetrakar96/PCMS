// ============================================================
// collect_amount_screen.dart  PCMS
// POS-style collection confirmation screen
// Amount input  payment mode  mode-specific details  receipt
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import 'collection_list_screen.dart'; // CustomerModel

// ─────────────────────────────────────────────────────────────
// Payment Mode
// ─────────────────────────────────────────────────────────────
enum PaymentMode { cash, upi, cheque, neft }

extension _PMX on PaymentMode {
  String get label => switch (this) {
        PaymentMode.cash   => 'Cash',
        PaymentMode.upi    => 'UPI',
        PaymentMode.cheque => 'Cheque',
        PaymentMode.neft   => 'NEFT',
      };
  String get fullLabel => switch (this) {
        PaymentMode.cash   => 'Cash',
        PaymentMode.upi    => 'UPI',
        PaymentMode.cheque => 'Cheque',
        PaymentMode.neft   => 'NEFT / RTGS',
      };
  IconData get icon => switch (this) {
        PaymentMode.cash   => Icons.payments_outlined,
        PaymentMode.upi    => Icons.qr_code_scanner_rounded,
        PaymentMode.cheque => Icons.receipt_long_outlined,
        PaymentMode.neft   => Icons.account_balance_outlined,
      };
}

// ─────────────────────────────────────────────────────────────
// Custom amount formatter
// ─────────────────────────────────────────────────────────────
class _AmountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final t = next.text;
    if (t.isEmpty) return next;
    // Only one decimal point
    if ('.'.allMatches(t).length > 1) return old;
    // No more than 2 decimal places
    final parts = t.split('.');
    if (parts.length == 2 && parts[1].length > 2) return old;
    // No leading zeros (except 0.xx)
    if (t.length > 1 && t.startsWith('0') && !t.startsWith('0.')) return old;
    return next;
  }
}

// ─────────────────────────────────────────────────────────────
// CollectAmountScreen
// ─────────────────────────────────────────────────────────────
class CollectAmountScreen extends StatefulWidget {
  const CollectAmountScreen({
    super.key,
    required this.customer,
    this.overdueDays = 0,
  });
  final CustomerModel customer;
  final int overdueDays;

  @override
  State<CollectAmountScreen> createState() => _CAState();
}

class _CAState extends State<CollectAmountScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _chequeCtrl = TextEditingController();
  final _bankCtrl   = TextEditingController();
  final _dateCtrl   = TextEditingController();
  final _utrCtrl    = TextEditingController();
  final _upiCtrl    = TextEditingController();

  PaymentMode _mode       = PaymentMode.cash;
  bool        _confirming = false;

  // Derived
  double get _entered =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;

  String get _displayAmount {
    final n = _entered;
    if (n <= 0) return '0.00';
    return NumberFormat('#,##,##0.00', 'en_IN').format(n);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _chequeCtrl.dispose();
    _bankCtrl.dispose();
    _dateCtrl.dispose();
    _utrCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  // ── Quick-fill ────────────────────────────────────────────
  void _setAmount(double v) {
    _amountCtrl.text = v.toStringAsFixed(2);
    _amountCtrl.selection = TextSelection.collapsed(
        offset: _amountCtrl.text.length);
    setState(() {});
  }

  // ── Date picker ───────────────────────────────────────────
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (d != null) {
      _dateCtrl.text = DateFormat('dd/MM/yyyy').format(d);
    }
  }

  // ── Confirm ───────────────────────────────────────────────
  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _confirming = true);
    
    // Call database record api
    final success = await CustomerRepository.recordCollection(
      customerId: widget.customer.id,
      status: CollectionStatus.collected,
      collectedAmount: _entered,
      paymentMode: _mode.name,
      remarks: 'Recorded via amount confirmation screen',
      latitude: widget.customer.latitude,
      longitude: widget.customer.longitude,
      photoCaptured: widget.customer.photoCaptured,
      signatureCaptured: widget.customer.signatureCaptured,
    );

    if (!mounted) return;
    setState(() => _confirming = false);

    if (success) {
      _showReceiptSheet();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record collection.')),
      );
    }
  }

  void _showReceiptSheet() {
    final fmt  = NumberFormat('#,##,##0.00', 'en_IN');
    final time = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final ref  = 'PCM${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiptSheet(
        customerName: widget.customer.name,
        accountNo: widget.customer.pigmyAccountNumber,
        amount: _entered,
        mode: _mode,
        referenceNo: ref,
        timestamp: time,
        onDone: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // pop CollectAmountScreen
          Navigator.pop(context); // pop CustomerVisitScreen -> back to CollectionListScreen!
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Collect Amount'),
          Text(widget.customer.name,
              style: AppTextStyles.caption
                  .copyWith(color: AppPalette.textSecondary)),
        ]),
      ),
      bottomNavigationBar: _buildConfirmBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 20),
              _buildAmountSection(),
              const SizedBox(height: 20),
              _buildPaymentSelector(),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => SizeTransition(
                    sizeFactor: anim, axisAlignment: -1, child: child),
                child: switch (_mode) {
                  PaymentMode.upi    => _buildUpiPanel(),
                  PaymentMode.cheque => _buildChequePanel(),
                  PaymentMode.neft   => _buildNeftPanel(),
                  _                  => const SizedBox.shrink(),
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Balance card (navy, top of screen)
  // ─────────────────────────────────────────────────────────
  Widget _buildBalanceCard() {
    final c   = widget.customer;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final initials = c.name.split(' ').take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.primary, Color(0xFF153A68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(color: Color(0x300B2545), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Customer row
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Text(initials,
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name,
                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(c.pigmyAccountNumber,
                  style: AppTextStyles.caption.copyWith(color: Colors.white60,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
          // Overdue badge
          if (widget.overdueDays > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppPalette.warning.withOpacity(0.6)),
              ),
              child: Text('${widget.overdueDays}d overdue',
                  style: AppTextStyles.caption.copyWith(color: AppPalette.warning)),
            ),
        ]),
        const SizedBox(height: 20),
        // Due amount
        Text('Total Due',
            style: AppTextStyles.caption.copyWith(color: Colors.white54)),
        const SizedBox(height: 4),
        Text('Rs.${fmt.format(c.pendingAmount)}',
            style: AppTextStyles.amountLarge.copyWith(
                color: Colors.white,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 16),
        // Stats row
        Row(children: [
          _StatPill(label: 'EMI', value: 'Rs.${fmt.format(c.pendingAmount)}'),
          const SizedBox(width: 12),
          _StatPill(label: 'Area', value: c.area),
          const SizedBox(width: 12),
          _StatPill(label: 'Route', value: c.route),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Amount input section
  // ─────────────────────────────────────────────────────────
  Widget _buildAmountSection() {
    final due = widget.customer.pendingAmount;
    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enter Amount',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppPalette.textSecondary)),
          const SizedBox(height: 12),
          // ── Large amount input ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // ₹ symbol — large, baseline-aligned
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Rs.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.primary,
                      fontFamily: AppTextStyles.bodyMedium.fontFamily,
                    )),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: _amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    _AmountFormatter(),
                  ],
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    color: _entered > 0
                        ? AppPalette.textPrimary
                        : AppPalette.textDisabled,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontFamily: AppTextStyles.amountLarge.fontFamily,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.5,
                      color: AppPalette.textDisabled,
                      fontFamily: AppTextStyles.amountLarge.fontFamily,
                    ),
                    errorStyle: const TextStyle(fontSize: 12),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '') ?? '') ?? 0;
                    if (n <= 0) return 'Please enter a valid amount';
                    if (n > due * 1.01) {
                      return 'Amount exceeds due (Rs.${NumberFormat('#,##,##0.00','en_IN').format(due)})';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // ── Quick amount chips ─────────────────────────────
          Text('Quick fill',
              style: AppTextStyles.caption
                  .copyWith(color: AppPalette.textSecondary)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _QuickChip(
                label: 'Full Due',
                sub: 'Rs.${NumberFormat('#,##,##0', 'en_IN').format(due)}',
                selected: _entered == due,
                onTap: () => _setAmount(due)),
            _QuickChip(
                label: '50%',
                sub: 'Rs.${NumberFormat('#,##,##0', 'en_IN').format(due / 2)}',
                selected: _entered == due / 2,
                onTap: () => _setAmount(due / 2)),
            for (final v in [500.0, 1000.0, 2000.0, 5000.0])
              if (v < due)
                _QuickChip(
                    label: 'Rs.${NumberFormat('#,##,##0', 'en_IN').format(v)}',
                    selected: _entered == v,
                    onTap: () => _setAmount(v)),
          ]),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Payment mode selector
  // ─────────────────────────────────────────────────────────
  Widget _buildPaymentSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Payment Mode',
          style: AppTextStyles.titleSmall
              .copyWith(color: AppPalette.textPrimary)),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<PaymentMode>(
          showSelectedIcon: false,
          segments: PaymentMode.values
              .map((m) => ButtonSegment<PaymentMode>(
                    value: m,
                    label: Text(m.label),
                    icon: Icon(m.icon, size: 16),
                  ))
              .toList(),
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: AppPalette.surfaceVariant,
            foregroundColor: AppPalette.textSecondary,
            selectedBackgroundColor: AppPalette.primaryContainer,
            selectedForegroundColor: AppPalette.onPrimaryContainer,
            textStyle: AppTextStyles.labelSmall,
            side: const BorderSide(color: AppPalette.outlineVariant),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        ),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // UPI Panel
  // ─────────────────────────────────────────────────────────
  Widget _buildUpiPanel() {
    return Padding(
      key: const ValueKey('upi'),
      padding: const EdgeInsets.only(top: 16),
      child: DecoratedBox(
        decoration: appCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // QR placeholder
            Center(child: _QrPlaceholder(amount: _entered)),
            const SizedBox(height: 16),
            Text('Ask customer to scan this QR code',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppPalette.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // UPI ID (optional)
            TextFormField(
              controller: _upiCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'UPI ID (optional)',
                hintText: 'e.g. 9876543210@paytm',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 10),
            // Status chips
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppPalette.textSecondary),
              const SizedBox(width: 6),
              Text('Payment verification is manual — confirm once received.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppPalette.textSecondary)),
            ]),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Cheque Panel
  // ─────────────────────────────────────────────────────────
  Widget _buildChequePanel() {
    return Padding(
      key: const ValueKey('cheque'),
      padding: const EdgeInsets.only(top: 16),
      child: DecoratedBox(
        decoration: appCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextFormField(
              controller: _chequeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Cheque Number *',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              validator: (_mode == PaymentMode.cheque)
                  ? (v) => (v == null || v.isEmpty)
                      ? 'Cheque number is required'
                      : null
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bankCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Bank Name *',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              validator: (_mode == PaymentMode.cheque)
                  ? (v) => (v == null || v.isEmpty)
                      ? 'Bank name is required'
                      : null
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: 'Cheque Date *',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.event_rounded),
                  onPressed: _pickDate,
                ),
              ),
              validator: (_mode == PaymentMode.cheque)
                  ? (v) => (v == null || v.isEmpty)
                      ? 'Cheque date is required'
                      : null
                  : null,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPalette.warningContainer,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppPalette.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cheque must be deposited within 2 working days.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppPalette.onWarningContainer),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // NEFT / RTGS Panel
  // ─────────────────────────────────────────────────────────
  Widget _buildNeftPanel() {
    return Padding(
      key: const ValueKey('neft'),
      padding: const EdgeInsets.only(top: 16),
      child: DecoratedBox(
        decoration: appCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Bank account info card (to-pay-to)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Transfer To',
                    style: AppTextStyles.caption
                        .copyWith(color: AppPalette.onPrimaryContainer)),
                const SizedBox(height: 6),
                _BankRow(label: 'Account',  value: '0392 0100 0847 21'),
                _BankRow(label: 'IFSC',     value: 'MAHB0001234'),
                _BankRow(label: 'Bank',     value: 'Bank of Maharashtra'),
                _BankRow(label: 'Branch',   value: 'Mumbai Central'),
              ]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _utrCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'UTR / Reference Number *',
                hintText: 'Enter 16–22 character UTR',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              validator: (_mode == PaymentMode.neft)
                  ? (v) {
                      if (v == null || v.isEmpty) return 'UTR number is required';
                      if (v.length < 12) return 'Enter a valid UTR number';
                      return null;
                    }
                  : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppPalette.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'NEFT/RTGS transfers may take up to 30 minutes to reflect.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppPalette.textSecondary),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Confirm sticky bar
  // ─────────────────────────────────────────────────────────
  Widget _buildConfirmBar() {
    final valid  = _entered > 0;
    final fmt    = NumberFormat('#,##,##0.00', 'en_IN');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Summary row
          if (valid)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Collecting via ${_mode.fullLabel}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppPalette.textSecondary)),
                  Text('Rs.${fmt.format(_entered)}',
                      style: AppTextStyles.labelLarge.copyWith(
                          color: AppPalette.primary,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
          // Button
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (valid && !_confirming) ? _confirm : null,
              style: (!valid)
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.outlineVariant,
                      foregroundColor: AppPalette.textDisabled)
                  : null,
              child: _confirming
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(valid
                          ? Icons.check_rounded
                          : Icons.lock_outline_rounded,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(valid
                          ? 'Confirm Collection'
                          : 'Enter Amount to Continue'),
                    ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _QrPlaceholder  — realistic QR visual with amount overlay
// ─────────────────────────────────────────────────────────────
class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return Column(children: [
      Container(
        width: 210, height: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.outlineVariant, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: Stack(alignment: Alignment.center, children: [
          // QR icon fills the box
          const Icon(Icons.qr_code_2_rounded,
              size: 196, color: AppPalette.primary),
          // Bank logo overlay in centre of QR
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppPalette.outlineVariant),
            ),
            child: const Icon(Icons.account_balance_rounded,
                size: 22, color: AppPalette.primary),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      // Amount pill below QR
      if (amount > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text('Rs.${fmt.format(amount)}',
              style: AppTextStyles.labelLarge.copyWith(
                  color: AppPalette.onPrimaryContainer,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text('Enter amount above to generate QR',
              style: AppTextStyles.caption
                  .copyWith(color: AppPalette.textSecondary)),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// _ReceiptSheet  — success bottom sheet (GPay/PhonePe style)
// ─────────────────────────────────────────────────────────────
class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({
    required this.customerName,
    required this.accountNo,
    required this.amount,
    required this.mode,
    required this.referenceNo,
    required this.timestamp,
    required this.onDone,
  });

  final String customerName, accountNo, referenceNo, timestamp;
  final double amount;
  final PaymentMode mode;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppPalette.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 28),
        // Success icon
        Container(
          width: 72, height: 72,
          decoration: const BoxDecoration(
            color: AppPalette.successContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: AppPalette.success, size: 38),
        ),
        const SizedBox(height: 14),
        Text('Collection Recorded',
            style: AppTextStyles.titleLarge
                .copyWith(color: AppPalette.textPrimary)),
        const SizedBox(height: 4),
        Text('Payment has been successfully recorded.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppPalette.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        // Receipt card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppPalette.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppPalette.outlineVariant),
          ),
          child: Column(children: [
            // Amount
            Text('Rs.${fmt.format(amount)}',
                style: AppTextStyles.amountLarge.copyWith(
                    color: AppPalette.success,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _ReceiptRow(label: 'Customer',  value: customerName),
            _ReceiptRow(label: 'Account',   value: accountNo),
            _ReceiptRow(label: 'Mode',      value: mode.fullLabel),
            _ReceiptRow(label: 'Reference', value: referenceNo, mono: true),
            _ReceiptRow(label: 'Time',      value: timestamp),
          ]),
        ),
        const SizedBox(height: 24),
        // Actions
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt download — coming soon'))),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small helper widgets
// ─────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white54)),
          Text(value,
              style: AppTextStyles.labelSmall
                  .copyWith(color: Colors.white, fontSize: 11)),
        ]),
      );
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.onTap,
    required this.selected,
    this.sub,
  });
  final String label;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppPalette.primaryContainer : AppPalette.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? AppPalette.primary.withOpacity(0.5)
                  : AppPalette.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(children: [
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(
                    color: selected
                        ? AppPalette.onPrimaryContainer
                        : AppPalette.textPrimary,
                    fontWeight: FontWeight.w600)),
            if (sub != null)
              Text(sub!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppPalette.textSecondary, fontSize: 10)),
          ]),
        ),
      );
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppPalette.onPrimaryContainer
                        .withOpacity(0.7))),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppPalette.onPrimaryContainer,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ]),
      );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value, this.mono = false});
  final String label, value;
  final bool mono;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppPalette.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: mono ? 0.5 : 0,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ]),
      );
}
