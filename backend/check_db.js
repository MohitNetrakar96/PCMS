const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'pcms.db');
console.log('Opening database at:', dbPath);

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Failed to open database:', err.message);
    process.exit(1);
  }
});

db.serialize(() => {
  // Query table list
  db.all("SELECT name FROM sqlite_master WHERE type='table';", [], (err, tables) => {
    if (err) {
      console.error('Error fetching tables:', err.message);
      process.exit(1);
    }
    console.log('\n--- SQLite Tables ---');
    console.log(tables.map(t => t.name).join(', '));

    // Query users
    db.all("SELECT id, name, email, role, employee_id FROM users;", [], (err, users) => {
      if (err) {
        console.error('Error querying users:', err.message);
      } else {
        console.log('\n--- Registered Users ---');
        console.table(users);
      }

      // Query active devices
      db.all("SELECT * FROM devices;", [], (err, devices) => {
        if (err) {
          console.error('Error querying devices:', err.message);
        } else {
          console.log('\n--- Registered Devices ---');
          console.table(devices);
        }
        
        db.close();
      });
    });
  });
});
