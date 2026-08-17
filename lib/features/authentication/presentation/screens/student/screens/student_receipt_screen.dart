import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '/core/constants/app_colors.dart';
import 'package:makhub/core/constants/payment_constants.dart';

class StudentReceiptScreen extends StatefulWidget {
  final String bookingId;

  const StudentReceiptScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<StudentReceiptScreen> createState() => _StudentReceiptScreenState();
}

class _StudentReceiptScreenState extends State<StudentReceiptScreen> {
  bool isLoading = true;
  bool _isDownloading = false;

  // ── Fields loaded from Firestore ────────────────────────────────────────
  String bookingId = "";
  String studentName = "";
  String hostelName = "";
  String roomNumber = "";
  String bookingStatus = "";
  String receiptNumber = "";
  String transactionId = "";
  String date = "";
  String time = "";

  // Additional fields included in the PDF but not shown separately on-screen.
  String reportingDate = "Not set";
  String paymentMethod = "Mobile Money";

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    try {
      // ── BOOKING ──────────────────────────────────────────────────────────
      final bookingSnapshot = await FirebaseFirestore.instance
          .collection("bookings")
          .doc(widget.bookingId)
          .get();

      if (!bookingSnapshot.exists) {
        throw Exception("Booking not found");
      }

      final booking = bookingSnapshot.data()!;

      // Use the human-readable bookingId field; fall back to doc ID for
      // bookings that predate this feature.
      bookingId = (booking["bookingId"] ?? '').toString().isNotEmpty
          ? booking["bookingId"].toString()
          : widget.bookingId;

      final studentId = booking["studentId"];
      final hostelId = booking["hostelId"];
      final floorId = booking["floorId"];
      final roomId = booking["roomId"];

      // ── STUDENT ──────────────────────────────────────────────────────────
      final studentSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(studentId)
          .get();

      if (studentSnapshot.exists) {
        final student = studentSnapshot.data()!;
        studentName = student["fullName"]?.toString() ?? "";
      }

      // ── HOSTEL ───────────────────────────────────────────────────────────
      final hostelSnapshot = await FirebaseFirestore.instance
          .collection("hostels")
          .doc(hostelId)
          .get();

      if (hostelSnapshot.exists) {
        final hostel = hostelSnapshot.data()!;
        hostelName = hostel["hostelName"]?.toString() ?? "";

        // Reporting date lives on the hostel document.
        final reportingTs = hostel["reportingDate"] as Timestamp?;
        if (reportingTs != null) {
          final d = reportingTs.toDate();
          reportingDate =
              "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
        }
      }

      // ── ROOM ─────────────────────────────────────────────────────────────
      final roomSnapshot = await FirebaseFirestore.instance
          .collection("hostels")
          .doc(hostelId)
          .collection("floors")
          .doc(floorId)
          .collection("rooms")
          .doc(roomId)
          .get();

      if (roomSnapshot.exists) {
        final room = roomSnapshot.data()!;
        roomNumber = "Room ${room["roomNumber"]}";
      }

      // ── DATE ─────────────────────────────────────────────────────────────
      if (booking["bookingDate"] != null) {
        final bookingDate = (booking["bookingDate"] as Timestamp).toDate();
        date = "${bookingDate.day}/${bookingDate.month}/${bookingDate.year}";
        time =
            "${bookingDate.hour}:${bookingDate.minute.toString().padLeft(2, '0')}";
      }

      bookingStatus = booking["bookingStatus"] ?? "";

      // ── TRANSACTION ──────────────────────────────────────────────────────
      final paymentSnapshot = await FirebaseFirestore.instance
          .collection("payments")
          .where("bookingId", isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        final payment = paymentSnapshot.docs.first.data();
        transactionId = (payment["transactionReference"] ??
                payment["transactionID"] ??
                payment["ref"] ??
                "N/A")
            .toString();
        paymentMethod =
            (payment["paymentMethod"] ?? "Mobile Money").toString();
      } else {
        transactionId = "N/A";
      }

      // Receipt number is derived from the human-readable bookingId
      // (or last 5 chars of doc ID as a legacy fallback).
      receiptNumber =
          "RCPT-${bookingId.length >= 5 ? bookingId.substring(bookingId.length - 5) : bookingId}";

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ── PDF generation & download ───────────────────────────────────────────

  Future<void> _downloadReceipt() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final pdfBytes = await _buildPdf();

      // Save to the device's Documents directory (works on Android & iOS).
      final Directory dir = await getApplicationDocumentsDirectory();
      final String fileName = "MakHub_Receipt_$receiptNumber.pdf";
      final File file = File("${dir.path}/$fileName");
      await file.writeAsBytes(pdfBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Receipt saved to ${file.path}"),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "Share",
            textColor: Colors.white,
            onPressed: () {
              Printing.sharePdf(
                bytes: pdfBytes,
                filename: fileName,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();
    final primaryColor = PdfColor.fromInt(AppColors.primary.toARGB32());
    const sectionGrey = PdfColor.fromInt(0xFF9E9E9E);
    const lightBg = PdfColor.fromInt(0xFFF3F4F6);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "MakHub",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.Text(
                  "Booking Receipt",
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: sectionGrey,
                  ),
                ),
              ],
            ),
            pw.Divider(color: primaryColor, thickness: 1.5),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              receiptNumber,
              style: pw.TextStyle(fontSize: 9, color: sectionGrey),
            ),
            pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: pw.TextStyle(fontSize: 9, color: sectionGrey),
            ),
          ],
        ),
        build: (context) => [
          // ── Status banner ─────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                "Booking ${_humanStatus(bookingStatus)}",
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Booking details ───────────────────────────────────────────
          _pdfSectionTitle("Booking Details", primaryColor),
          _pdfTable([
            ["Receipt Number", receiptNumber],
            ["Booking ID", bookingId],
            ["Student Name", studentName],
            ["Hostel Name", hostelName],
            ["Room Number", roomNumber],
            ["Booking Status", _humanStatus(bookingStatus)],
            ["Reporting Date", reportingDate],
          ]),
          pw.SizedBox(height: 16),

          // ── Payment breakdown ─────────────────────────────────────────
          _pdfSectionTitle("Payment Breakdown", primaryColor),
          _pdfTable([
            ["Booking Fee", "UGX ${PaymentConstants.bookingFee}"],
            ["Service Fee", "UGX ${PaymentConstants.serviceFee}"],
            ["Mobile Money Fee", "UGX ${PaymentConstants.mobileMoneyCharge}"],
          ]),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(
                AppColors.primary.withValues(alpha: 0.08).toARGB32(),
              ),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Total Paid",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                    color: primaryColor,
                  ),
                ),
                pw.Text(
                  "UGX ${PaymentConstants.totalAmount}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Transaction details ───────────────────────────────────────
          _pdfSectionTitle("Transaction Details", primaryColor),
          _pdfTable([
            ["Date", date.isNotEmpty ? date : "N/A"],
            ["Time", time.isNotEmpty ? time : "N/A"],
            ["Payment Method", paymentMethod],
            ["Transaction ID", transactionId],
          ]),
          pw.SizedBox(height: 20),

          // ── Non-refundable note ───────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF8E1),
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFFFC107),
              ),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              "Note: Booking fee is non-refundable. Once payment is completed, "
              "the booking fee cannot be refunded.",
              style: pw.TextStyle(
                fontSize: 10,
                color: const PdfColor.fromInt(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  pw.Widget _pdfSectionTitle(String title, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _pdfTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFE0E0E0),
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontSize: 10,
                  color: const PdfColor.fromInt(0xFF757575),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: pw.Text(
                row[1],
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _humanStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'checked_in':
        return 'Checked In';
      default:
        return raw.isNotEmpty ? raw : 'Pending';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Receipt",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Payment confirmation",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // ── Receipt Card ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          child: const Icon(
                            Icons.verified_outlined,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _infoRow("Receipt Number", receiptNumber),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _infoRow("Booking ID", bookingId),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _infoRow("Student Name", studentName),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _infoRow("Hostel Name", hostelName),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _infoRow("Room Number", roomNumber),
                        const SizedBox(height: 25),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 20),

                        // Payment Breakdown
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Payment Breakdown",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _infoRow(
                          "Booking Fee",
                          "UGX ${PaymentConstants.bookingFee}",
                        ),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _infoRow(
                          "Service Fee",
                          "UGX ${PaymentConstants.serviceFee}",
                        ),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _infoRow(
                          "Mobile Money Fee",
                          "UGX ${PaymentConstants.mobileMoneyCharge}",
                        ),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _infoRow(
                            "Total Paid",
                            "UGX ${PaymentConstants.totalAmount}",
                            bold: true,
                            valueColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 20),

                        // Transaction Details
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Transaction Details",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _infoRow("Date", date),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _infoRow("Time", time),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _infoRow("Transaction ID", transactionId),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ── Download Button ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadReceipt,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 22),
                      label: Text(
                        _isDownloading ? "Saving..." : "Download Receipt",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool bold = false,
    Color valueColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: bold ? 16 : 15,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
