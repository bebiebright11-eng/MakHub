import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/payment_constants.dart';
import '/features/admin/services/finance_service.dart';

/// Personnel Withdrawal Request Screen.
///
/// The hostel personnel enters a NUMBER OF BOOKINGS.
/// The withdrawal amount is calculated automatically (read-only):
///
///   amount = numberOfBookings × PaymentConstants.bookingFee
///
/// On submit, a document is written to `withdrawal_requests` with:
///   hostelId, hostelName, personnelId, numberOfBookings,
///   amount, dateRequested, status = 'Pending'
///
/// Balances are NOT modified here — only after Admin approves.
class PersonnelWithdrawalRequestScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;
  final String personnelId;
  final String personnelName;
  final int maxBookings; // upper bound = current pending bookings

  const PersonnelWithdrawalRequestScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
    required this.personnelId,
    required this.personnelName,
    required this.maxBookings,
  });

  @override
  State<PersonnelWithdrawalRequestScreen> createState() =>
      _PersonnelWithdrawalRequestScreenState();
}

class _PersonnelWithdrawalRequestScreenState
    extends State<PersonnelWithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingsController = TextEditingController();

  int _numberOfBookings = 0;
  bool _submitting = false;

  double get _calculatedAmount =>
      _numberOfBookings * PaymentConstants.bookingFee.toDouble();

  @override
  void dispose() {
    _bookingsController.dispose();
    super.dispose();
  }

  void _onBookingsChanged(String value) {
    final parsed = int.tryParse(value.trim()) ?? 0;
    setState(() => _numberOfBookings = parsed);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // ── Write the withdrawal request ────────────────────────────────
      final requestRef = db.collection('withdrawal_requests').doc();
      batch.set(requestRef, {
        'hostelId': widget.hostelId,
        'hostelName': widget.hostelName,
        'personnelId': widget.personnelId,
        'personnelName': widget.personnelName,
        'numberOfBookings': _numberOfBookings,
        'amount': _calculatedAmount,
        'dateRequested': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      // ── Notify every admin ──────────────────────────────────────────
      // Admins are users with role == 'admin'. We write a notification
      // to each admin's users/{uid}/notifications subcollection so it
      // appears in their Alerts page and increments the badge.
      try {
        final adminSnap = await db
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();

        for (final adminDoc in adminSnap.docs) {
          final notifRef = db
              .collection('users')
              .doc(adminDoc.id)
              .collection('notifications')
              .doc();
          batch.set(notifRef, {
            'title': 'Withdrawal Request — ${widget.hostelName}',
            'subtitle':
                '${widget.hostelName} requested a withdrawal of '
                '${FinanceService.formatUGX(_calculatedAmount)}. '
                'Tap to review.',
            'type': 'withdrawal',
            'hostelId': widget.hostelId,
            'hostelName': widget.hostelName,
            'personnelId': widget.personnelId,
            'amount': _calculatedAmount,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      } catch (_) {
        // Notification failure must not block the withdrawal request itself
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Request Withdrawal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You have ${widget.maxBookings} pending booking${widget.maxBookings == 1 ? '' : 's'} '
                        'available to withdraw against.\n'
                        'Each booking earns ${FinanceService.formatUGX(PaymentConstants.bookingFee.toDouble())}.',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('WITHDRAWAL DETAILS'),
              const SizedBox(height: 12),

              // ── Number of Bookings input ───────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number of Bookings field
                    Text(
                      'Number of Bookings',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bookingsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: _onBookingsChanged,
                      decoration: InputDecoration(
                        hintText: 'e.g. 3',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the number of bookings.';
                        }
                        final n = int.tryParse(value.trim());
                        if (n == null || n <= 0) {
                          return 'Must be at least 1 booking.';
                        }
                        if (n > widget.maxBookings) {
                          return 'Cannot exceed ${widget.maxBookings} pending bookings.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Auto-calculated amount (read-only)
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _numberOfBookings > 0
                                  ? FinanceService.formatUGX(
                                      _calculatedAmount)
                                  : 'UGX 0',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _numberOfBookings > 0
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                          Icon(Icons.lock_outline,
                              size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Auto-calculated',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),

                    // Breakdown hint
                    if (_numberOfBookings > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$_numberOfBookings booking${_numberOfBookings == 1 ? '' : 's'} '
                        '× ${FinanceService.formatUGX(PaymentConstants.bookingFee.toDouble())} '
                        '= ${FinanceService.formatUGX(_calculatedAmount)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Note about approval
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Withdrawal requests are reviewed by the MakHub admin. '
                      'Your balance will be updated once approved.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Submit button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Withdrawal Request',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      );
}
