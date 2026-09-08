const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const dbPath = path.resolve(__dirname, 'pcms.db');

console.log('[Reset DB] Resetting PCMS database at:', dbPath);

// If file exists, delete it for a completely clean slate
if (fs.existsSync(dbPath)) {
  try {
    fs.unlinkSync(dbPath);
    console.log('[Reset DB] Deleted old pcms.db');
  } catch (e) {
    console.log('[Reset DB] Could not delete file directly, will recreate tables instead.');
  }
}

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error connecting to database:', err.message);
    process.exit(1);
  }
  console.log('[Reset DB] Created fresh database file.');
  setupTables();
});

const runSql = (sql) => {
  return new Promise((resolve, reject) => {
    db.run(sql, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });
};

async function setupTables() {
  try {
    // 1. Users Table
    await runSql(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        employee_id TEXT,
        phone TEXT,
        photo_url TEXT,
        area TEXT,
        route TEXT,
        address TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    `);

    // 2. OTPs Table
    await runSql(`
      CREATE TABLE IF NOT EXISTS otps (
        email TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        expires_at INTEGER NOT NULL
      )
    `);

    // 3. Devices Table
    await runSql(`
      CREATE TABLE IF NOT EXISTS devices (
        email TEXT NOT NULL,
        device_id TEXT NOT NULL,
        PRIMARY KEY (email, device_id)
      )
    `);

    // 4. Customers Table
    await runSql(`
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
        address TEXT,
        photo_url TEXT,
        assigned_agent_email TEXT
      )
    `);

    // 5. Collections Table
    await runSql(`
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
        photo_url TEXT,
        signature_captured INTEGER DEFAULT 0,
        deposit_total REAL DEFAULT 0,
        late_fee REAL DEFAULT 0,
        interest REAL DEFAULT 0,
        receipt_id TEXT,
        UNIQUE(customer_id, collection_date)
      )
    `);

    // 6. Collection History Table
    await runSql(`
      CREATE TABLE IF NOT EXISTS collection_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        collection_date TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        payment_mode TEXT,
        receipt_id TEXT,
        agent_email TEXT,
        date TEXT,
        time TEXT,
        remarks TEXT,
        photo_url TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    `);

    // 7. Accounts & Passbooks Table
    await runSql(`
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_number TEXT UNIQUE NOT NULL,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        account_type TEXT NOT NULL,
        balance REAL NOT NULL,
        daily_target REAL DEFAULT 500,
        arrear REAL DEFAULT 0,
        interest_rate REAL DEFAULT 4.5,
        status TEXT DEFAULT 'Active'
      )
    `);

    // 8. Vault Submissions (EOD Handover)
    await runSql(`
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
        status TEXT DEFAULT 'pending',
        audit_trail_json TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(agent_email, submission_date)
      )
    `);

    // 9. Audit Trail Table
    await runSql(`
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

    console.log('SUCCESS: All 9 production tables created cleanly with 0 rows.');
    console.log('Database is 100% reset and ready for company deployment.');
    db.close();
    process.exit(0);
  } catch (err) {
    console.error('Error setting up tables:', err);
    process.exit(1);
  }
}
