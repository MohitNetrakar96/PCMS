const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const bcrypt = require('bcryptjs');

const dbPath = path.resolve(__dirname, 'pcms.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening SQLite database:', err.message);
  } else {
    console.log('Connected to SQLite database at:', dbPath);
    initializeTables();
  }
});

// Helper to run queries using promises (for async/await support)
const query = {
  run: (sql, params = []) => {
    return new Promise((resolve, reject) => {
      db.run(sql, params, function (err) {
        if (err) reject(err);
        else resolve({ id: this.lastID, changes: this.changes });
      });
    });
  },
  get: (sql, params = []) => {
    return new Promise((resolve, reject) => {
      db.get(sql, params, (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  },
  all: (sql, params = []) => {
    return new Promise((resolve, reject) => {
      db.all(sql, params, (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });
  }
};

async function initializeTables() {
  try {
    // 1. Users Table
    await query.run(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        employee_id TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    `);

    // 2. OTPs Table
    await query.run(`
      CREATE TABLE IF NOT EXISTS otps (
        email TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        expires_at INTEGER NOT NULL
      )
    `);

    // 3. Devices Table
    await query.run(`
      CREATE TABLE IF NOT EXISTS devices (
        email TEXT NOT NULL,
        device_id TEXT NOT NULL,
        PRIMARY KEY (email, device_id)
      )
    `);

    // 4. Customers Table
    await query.run(`
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT NOT NULL,
        area TEXT NOT NULL,
        route TEXT NOT NULL,
        opening_balance REAL NOT NULL,
        latitude REAL,
        longitude REAL,
        is_new INTEGER DEFAULT 0,
        created_at INTEGER,
        kyc_status TEXT DEFAULT 'Pending',
        aadhar_number TEXT,
        pan_number TEXT,
        address TEXT
      )
    `);

    // 5. Collections Table
    await query.run(`
      CREATE TABLE IF NOT EXISTS collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        agent_email TEXT NOT NULL,
        collection_date TEXT NOT NULL,
        pending_amount REAL NOT NULL,
        collected_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'pending',
        visit_time TEXT,
        payment_mode TEXT,
        remarks TEXT,
        latitude REAL,
        longitude REAL,
        photo_captured INTEGER DEFAULT 0,
        signature_captured INTEGER DEFAULT 0,
        deposit_total REAL DEFAULT 0,
        late_fee REAL DEFAULT 0,
        interest REAL DEFAULT 0,
        receipt_id TEXT,
        UNIQUE(customer_id, collection_date)
      )
    `);

    // 6. Collection History Table
    await query.run(`
      CREATE TABLE IF NOT EXISTS collection_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        collection_date TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        payment_mode TEXT,
        receipt_id TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    `);

    // 7. Accounts & Passbooks Table
    await query.run(`
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_number TEXT UNIQUE NOT NULL,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        account_type TEXT NOT NULL, -- 'Savings Passbook' or 'Loan Passbook'
        balance REAL NOT NULL,
        daily_target REAL DEFAULT 500,
        arrear REAL DEFAULT 0,
        interest_rate REAL DEFAULT 4.5,
        status TEXT DEFAULT 'Active'
      )
    `);

    // 8. Vault Submissions (EOD Handover 8-Step Register)
    await query.run(`
      CREATE TABLE IF NOT EXISTS vault_submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agent_email TEXT NOT NULL,
        submission_date TEXT NOT NULL,
        expected_cash REAL NOT NULL,
        cash_submitted REAL NOT NULL,
        difference_amount REAL DEFAULT 0,
        manager_otp_verified INTEGER DEFAULT 0,
        cashier_accepted INTEGER DEFAULT 0,
        bank_reference TEXT,
        signature_url TEXT,
        status TEXT DEFAULT 'pending', -- 'pending', 'manager_cleared', 'cashier_accepted', 'locked'
        audit_trail_json TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(agent_email, submission_date)
      )
    `);

    // 9. Audit Trail Table
    await query.run(`
      CREATE TABLE IF NOT EXISTS audit_trail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_email TEXT,
        role TEXT,
        status TEXT DEFAULT 'ok',
        details TEXT,
        created_at TEXT NOT NULL
      )
    `);

    // Dynamic Alterations for Backward Compatibility
    const alters = [
      "ALTER TABLE customers ADD COLUMN kyc_status TEXT DEFAULT 'Pending'",
      "ALTER TABLE customers ADD COLUMN aadhar_number TEXT",
      "ALTER TABLE customers ADD COLUMN pan_number TEXT",
      "ALTER TABLE customers ADD COLUMN address TEXT",
      "ALTER TABLE customers ADD COLUMN photo_url TEXT",
      "ALTER TABLE customers ADD COLUMN assigned_agent_email TEXT",
      "ALTER TABLE collections ADD COLUMN photo_captured INTEGER DEFAULT 0",
      "ALTER TABLE collections ADD COLUMN signature_captured INTEGER DEFAULT 0",
      "ALTER TABLE collections ADD COLUMN deposit_total REAL DEFAULT 0",
      "ALTER TABLE collections ADD COLUMN late_fee REAL DEFAULT 0",
      "ALTER TABLE collections ADD COLUMN interest REAL DEFAULT 0",
      "ALTER TABLE collections ADD COLUMN receipt_id TEXT",
      "ALTER TABLE collection_history ADD COLUMN receipt_id TEXT",
      "ALTER TABLE collection_history ADD COLUMN agent_email TEXT",
      "ALTER TABLE collection_history ADD COLUMN date TEXT",
      "ALTER TABLE collection_history ADD COLUMN time TEXT",
      "ALTER TABLE collection_history ADD COLUMN remarks TEXT",
      "ALTER TABLE users ADD COLUMN phone TEXT",
      "ALTER TABLE users ADD COLUMN photo_url TEXT",
      "ALTER TABLE users ADD COLUMN area TEXT",
      "ALTER TABLE users ADD COLUMN route TEXT",
      "ALTER TABLE users ADD COLUMN address TEXT"
    ];

    for (const alt of alters) {
      try { await query.run(alt); } catch (_) {}
    }

    console.log('Database tables initialized and verified.');
    console.log('Database tables ready for fresh deployment (no mock users/seed data).');
  } catch (err) {
    console.error('Error initializing tables:', err);
  }
}

module.exports = {
  db,
  query
};
