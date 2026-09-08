# BankFlow PCMS - Flutter Mobile Application

Native Flutter mobile application for the **Pigmy Collection Management System (PCMS)**.

---

## 📱 Features Included
* **Multi-Role Authentication**: Agent, Branch Manager, Cashier, Administrator, Customer, and Auditor with JWT session persistence.
* **Doorstep Collections**: Daily customer queue, search, balance calculation, and digital receipt generation.
* **Turn-by-Turn Navigation**: Next (#1) and Next-Next (#2) stop targets with instant Google Maps driving launch.
* **Camera & KYC Photo Capture**: Live camera upload for customer KYC photographs.
* **Customer Passbook & Dynamic UPI QR**: 12-month interest maturity countdown and UPI QR generator (`upi://pay?pa=pcmsbank@upi...`).
* **Cash Reconciliation**: Daily collections vs vault submissions discrepancy detection and manager resolution.

---

## 🚀 How to Run the App

1. Ensure your PCMS Backend server is running:
   ```bash
   cd ../backend
   node server.js
   ```

2. Run on Android Emulator or Connected Device:
   ```bash
   cd mobile_app
   flutter pub get
   flutter run
   ```

3. Build Android APK:
   ```bash
   flutter build apk --release
   ```
