// PCMS BankFlow Mobile App - Unit & Model Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pcms_mobile/models/user_model.dart';
import 'package:pcms_mobile/models/customer_model.dart';
import 'package:pcms_mobile/models/collection_model.dart';
import 'package:pcms_mobile/models/account_model.dart';
import 'package:pcms_mobile/models/audit_model.dart';
import 'package:pcms_mobile/models/reconciliation_model.dart';
import 'package:pcms_mobile/models/vault_model.dart';
import 'package:pcms_mobile/providers/auth_provider.dart';

void main() {
  group('UserModel Tests', () {
    test('fromJson and toJson should correctly serialize/deserialize', () {
      final json = {
        'id': 101,
        'name': 'Rahul Verma',
        'email': 'rahul@bankflow.com',
        'role': 'Collection Agent',
        'employee_id': 'CAG-101',
      };
      final user = UserModel.fromJson(json, token: 'jwt_token_abc');
      expect(user.id, 101);
      expect(user.name, 'Rahul Verma');
      expect(user.email, 'rahul@bankflow.com');
      expect(user.role, 'Collection Agent');
      expect(user.employeeId, 'CAG-101');
      expect(user.token, 'jwt_token_abc');

      final backToJson = user.toJson();
      expect(backToJson['email'], 'rahul@bankflow.com');
      expect(backToJson['token'], 'jwt_token_abc');
    });
  });

  group('CustomerModel Tests', () {
    test('fromJson should handle masked KYC fields and balances', () {
      final json = {
        'id': 'CUST-101',
        'name': 'Suresh Patil',
        'email': 'su***@example.com',
        'phone': '9876543210',
        'area': 'Hubli Central',
        'route': 'Route A',
        'opening_balance': 5000.0,
        'latitude': 15.3647,
        'longitude': 75.1240,
        'kyc_status': 'Verified',
        'aadhar_number': 'XXXX-XXXX-1234',
        'pan_number': 'ABCDE****',
        'address': 'Station Road, Hubli',
      };
      final cust = CustomerModel.fromJson(json);
      expect(cust.id, 'CUST-101');
      expect(cust.name, 'Suresh Patil');
      expect(cust.openingBalance, 5000.0);
      expect(cust.latitude, 15.3647);
      expect(cust.kycStatus, 'Verified');
    });
  });

  group('CollectionModel Tests', () {
    test('fromJson should parse pending and collected records with GPS', () {
      final json = {
        'id': 'COL-1',
        'customer_id': 'CUST-101',
        'name': 'Suresh Patil',
        'phone': '9876543210',
        'email': 'suresh@bankflow.com',
        'area': 'Hubli Central',
        'route': 'Route A',
        'pigmy_account_number': 'PG-2026-101',
        'amount': 500.0,
        'pending_amount': 500.0,
        'collected_amount': 500.0,
        'balance': 5500.0,
        'status': 'collected',
        'visit_time': '10:30 AM',
        'payment_mode': 'CASH',
        'receipt_id': 'RCP-20260907-0001',
        'latitude': 15.3518,
        'longitude': 75.1380,
      };
      final col = CollectionModel.fromJson(json);
      expect(col.customerId, 'CUST-101');
      expect(col.collectedAmount, 500.0);
      expect(col.status, 'collected');
      expect(col.receiptId, 'RCP-20260907-0001');
    });
  });

  group('AccountModel and InterestEntry Tests', () {
    test('fromJson should parse active passbook account and compute metrics', () {
      final json = {
        'id': 1,
        'account_number': 'PCMS-00120',
        'customer_id': 'CUST-101',
        'account_type': 'Savings Passbook',
        'balance': 12500.0,
        'daily_target': 500.0,
        'interest_rate': 5.0,
        'status': 'ACTIVE',
        'maturity_date': '2027-09-07',
        'daysToMaturity': 365,
        'projectedPayout': 13125.0,
      };
      final acc = AccountModel.fromJson(json);
      expect(acc.accountNumber, 'PCMS-00120');
      expect(acc.balance, 12500.0);
      expect(acc.interestRate, 5.0);
      expect(acc.daysToMaturity, 365);
    });

    test('InterestEntryModel should correctly parse accrual records', () {
      final json = {
        'id': 1,
        'account_id': 10,
        'interest_amount': 52.08,
        'accrual_month': '2026-08',
        'balance_snapshot': 12500.0,
        'credited_at': '2026-09-01T00:00:00Z',
      };
      final entry = InterestEntryModel.fromJson(json);
      expect(entry.accountId, 10);
      expect(entry.interestAmount, 52.08);
      expect(entry.accrualMonth, '2026-08');
    });
  });

  group('Reconciliation and Vault Models', () {
    test('ReconciliationRecordModel should parse matched and mismatch states', () {
      final json = {
        'recordId': 5,
        'agentEmail': 'agent@bankflow.com',
        'recon_date': '2026-09-07',
        'totalCollected': 5000.0,
        'totalSubmitted': 4500.0,
        'difference': 500.0,
        'status': 'MISMATCH',
        'hasMismatch': true,
      };
      final recon = ReconciliationRecordModel.fromJson(json);
      expect(recon.id, 5);
      expect(recon.difference, 500.0);
      expect(recon.hasMismatch, true);
      expect(recon.status, 'MISMATCH');
    });

    test('VaultSubmissionModel should parse 8-step handover clearance', () {
      final json = {
        'id': 1,
        'agent_email': 'agent@bankflow.com',
        'submission_date': '2026-09-07',
        'expected_cash': 5000.0,
        'cash_submitted': 5000.0,
        'difference_amount': 0.0,
        'status': 'locked',
        'manager_otp_verified': 1,
        'cashier_accepted': 1,
        'bank_reference': 'SBI-DEP-12345',
      };
      final vault = VaultSubmissionModel.fromJson(json);
      expect(vault.expectedCash, 5000.0);
      expect(vault.managerOtpVerified, true);
      expect(vault.cashierAccepted, true);
      expect(vault.bankReference, 'SBI-DEP-12345');
    });
  });

  group('AuditLogModel Tests', () {
    test('fromJson should parse audit log events', () {
      final json = {
        'id': 1,
        'action': 'Collection Logged',
        'user_name': 'Rahul Verma',
        'user_email': 'agent@bankflow.com',
        'role': 'Collection Agent',
        'status': 'ok',
        'details': 'Customer CUST-101 - Amount: ₹500 via CASH',
        'created_at': '2026-09-07T10:00:00Z',
      };
      final log = AuditLogModel.fromJson(json);
      expect(log.action, 'Collection Logged');
      expect(log.status, 'ok');
      expect(log.role, 'Collection Agent');
    });
  });

  group('AuthProvider Tests', () {
    test('login with empty credentials should fail immediately with validation error', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final auth = AuthProvider();
      final result = await auth.login('', '');
      expect(result, false);
      expect(auth.isAuthenticated, false);
      expect(auth.errorMessage, 'Email and password are required.');
    });

    test('logout should clear user and reset error state', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final auth = AuthProvider();
      await auth.logout();
      expect(auth.isAuthenticated, false);
      expect(auth.user, null);
      expect(auth.errorMessage, null);
    });
  });
}

