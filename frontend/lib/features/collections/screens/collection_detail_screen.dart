import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String name;
  final String loanId;
  final double amount;
  final CollectionStatus status;
  final String phone;
  final String address;
  final double principal;
  final double emi;
  final String dueDate;

  const CollectionDetailScreen({
    super.key,
    required this.name,
    required this.loanId,
    required this.amount,
    required this.status,
    required this.phone,
    required this.address,
    required this.principal,
    required this.emi,
    required this.dueDate,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  int _selectedPaymentMode = 0; // 0=Cash, 1=UPI, 2=Cheque
  late TextEditingController _amountController;
  late TextEditingController _remarksController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.amount.toStringAsFixed(0));
    _remarksController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  void _markAsCollected() {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Collection recorded successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _markNotAvailable() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool showForm = widget.status != CollectionStatus.collected;

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160.0,
            pinned: true,
            backgroundColor: AppPalette.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppPalette.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40), // for safe area
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      foregroundColor: AppPalette.primary,
                      child: Text(
                        _getInitials(widget.name),
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.name,
                      style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    ),
                    Text(
                      widget.loanId,
                      style: AppTextStyles.caption.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusAmountCard(),
                const SizedBox(height: 16),
                _buildLoanInfoCard(),
                const SizedBox(height: 16),
                _buildContactCard(),
                const SizedBox(height: 16),
                if (showForm) _buildCollectionFormCard(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: showForm
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        onPressed: _markAsCollected,
                        child: const Text('Mark as Collected'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppPalette.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        onPressed: _markNotAvailable,
                        child: const Text('Mark Not Available'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusAmountCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(status: widget.status),
              const Spacer(),
              Text('Due Amount', style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              AmountText(
                amount: widget.amount,
                style: AppTextStyles.amountLarge,
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Text('EMI', style: AppTextStyles.bodySmall),
              const Spacer(),
              AmountText(
                amount: widget.emi,
                style: AppTextStyles.bodyMediumNumeric,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Loan Information'),
          InfoRow(label: 'Loan Number', value: widget.loanId),
          InfoRow(label: 'Principal', value: '₹ ${widget.principal.toStringAsFixed(0)}'),
          const InfoRow(label: 'Interest Rate', value: '12.5% p.a.'),
          const InfoRow(label: 'Tenure', value: '24 months'),
          InfoRow(
            label: 'Due Date',
            value: widget.dueDate,
            valueColor: AppPalette.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Contact'),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: AppPalette.primary, size: 20),
              const SizedBox(width: 8),
              Text(widget.phone, style: AppTextStyles.bodyMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.call_rounded),
                color: AppPalette.tertiary,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: AppPalette.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.address, style: AppTextStyles.bodyMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionFormCard() {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Record Collection'),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Collected Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter amount';
                if (double.tryParse(val) == null) return 'Enter valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Payment Mode', style: AppTextStyles.labelSmall.copyWith(color: AppPalette.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPaymentModeChip(0, 'Cash'),
                const SizedBox(width: 8),
                _buildPaymentModeChip(1, 'UPI'),
                const SizedBox(width: 8),
                _buildPaymentModeChip(2, 'Cheque'),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentModeChip(int index, String label) {
    final isSelected = _selectedPaymentMode == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedPaymentMode = index;
          });
        }
      },
      selectedColor: AppPalette.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppPalette.onPrimaryContainer : AppPalette.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
