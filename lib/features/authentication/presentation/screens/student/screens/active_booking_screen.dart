import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/constants/app_colors.dart';
import '/algorithms/cancellation_algorithm.dart';
import 'booking_information_screen.dart';

class StudentActiveBookingScreen extends StatefulWidget {
  final String bookingId;
  final String hostelName;
  final String roomNumber;
  final String bookingStatus;
  final String hostelId;
  final String roomId;
  final String floorId;

  const StudentActiveBookingScreen({
    super.key,
    required this.bookingId,
    required this.hostelName,
    required this.roomNumber,
    this.bookingStatus = 'Payment Received',
    required this.hostelId,
    required this.roomId,
    required this.floorId,
  });

  @override
  State<StudentActiveBookingScreen> createState() =>
      _StudentActiveBookingScreenState();
}

class _StudentActiveBookingScreenState
    extends State<StudentActiveBookingScreen> {
  bool _isCancelling = false;

  // Map Firestore status values → step labels
  static const List<String> _steps = [
    'Pending',
    'Payment Received',
    'Room Reserved',
  ];

  // Map status string to step index
  int _currentStep(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'payment_received':
      case 'payment received':
        return 1;
      case 'confirmed':
      case 'room reserved':
        return 2;
      default:
        return 0;
    }
  }

  Future<void> _cancelBooking() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to cancel this booking? '
          'Your room will be released and this cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final result = await CancellationAlgorithm.cancel(
        bookingId: widget.bookingId,
        cancelledBy: user?.uid ?? 'unknown',
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled. Your room has been released.'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to home — booking no longer active
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to cancel booking.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _currentStep(widget.bookingStatus);
    final isCancellable = widget.bookingStatus.toLowerCase() != 'confirmed' &&
        widget.bookingStatus.toLowerCase() != 'room reserved';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Active Booking',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Booking summary card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Booking ID',
                      widget.bookingId.length > 10
                          ? '${widget.bookingId.substring(0, 10)}…'
                          : widget.bookingId),
                  const SizedBox(height: 10),
                  _infoRow('Hostel', widget.hostelName),
                  const SizedBox(height: 10),
                  _infoRow('Room', widget.roomNumber),
                  const SizedBox(height: 10),
                  _infoRow('Status', widget.bookingStatus,
                      valueColor: AppColors.primary),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Progress stepper ──────────────────────────────────────
            const Text(
              'Booking Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Column(
              children: List.generate(_steps.length, (index) {
                final isDone = index <= step;
                final isLast = index == _steps.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppColors.primary
                                : Colors.grey.shade200,
                          ),
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 36,
                            color: isDone
                                ? AppColors.primary
                                : Colors.grey.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        _steps[index],
                        style: TextStyle(
                          fontWeight: isDone
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isDone ? Colors.black : Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),

            const Spacer(),

            // ── View booking info ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentBookingInformationScreen(
                      bookingId: widget.bookingId,
                      hostelId: widget.hostelId,
                      roomId: widget.roomId,
                      floorId: widget.floorId,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'View Booking Information',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Cancel button (only when not yet confirmed) ───────────
            if (isCancellable)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isCancelling
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red.shade600,
                          ),
                        )
                      : const Text(
                          'Cancel Booking',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
