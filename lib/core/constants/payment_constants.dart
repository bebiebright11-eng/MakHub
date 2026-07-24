class PaymentConstants {
  // Fixed charges
  static const int bookingFee = 100000;
  static const int mobileMoneyCharge = 2500;
  static const int serviceFee = 10000;

  // Total amount to pay
  static int get totalAmount =>
      bookingFee + mobileMoneyCharge + serviceFee;
}