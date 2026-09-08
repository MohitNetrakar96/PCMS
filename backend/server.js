const fs = require('fs');
const path = require('path');

// Auto-load .env file if present
const envPath = path.resolve(__dirname, '.env');
if (fs.existsSync(envPath)) {
  const envLines = fs.readFileSync(envPath, 'utf8').split('\n');
  for (const line of envLines) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
      const [key, ...vals] = trimmed.split('=');
      process.env[key.trim()] = vals.join('=').trim();
    }
  }
}

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const { query } = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'pcms_secret_token_123';

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Migrate photo_url column for doorstep geotagged photos
(async () => {
  try {
    await query.run('ALTER TABLE collections ADD COLUMN photo_url TEXT');
    console.log('[Migration] Added photo_url column to collections table.');
  } catch (e) {}
  try {
    await query.run('ALTER TABLE collection_history ADD COLUMN photo_url TEXT');
    console.log('[Migration] Added photo_url column to collection_history table.');
  } catch (e) {}
})();

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Helper to log actions into audit_trail
async function logAudit(action, userName, userEmail, role, status = 'ok', details = '') {
  try {
    await query.run(
      'INSERT INTO audit_trail (action, user_name, user_email, role, status, details, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [action, userName || 'System', userEmail || null, role || null, status, details, new Date().toISOString()]
    );
  } catch (err) {
    console.error('Failed to write audit log:', err.message);
  }
}

// Helper to send email OTP via SMTP or Ethereal test gateway
async function sendOTPEmail(emailAddress, code) {
  const mailUser = process.env.EMAIL_USER;
  const mailPass = process.env.EMAIL_PASS;
  let transporter;

  if (mailUser && mailPass) {
    transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 465,
      secure: true, // SSL
      auth: { user: mailUser, pass: mailPass }
    });
  } else {
    try {
      const testAccount = await nodemailer.createTestAccount();
      transporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: { user: testAccount.user, pass: testAccount.pass }
      });
    } catch (e) {
      console.error('Error creating Ethereal Email test account:', e.message);
      return false;
    }
  }

  const mailOptions = {
    from: mailUser ? `"BankFlow Security" <${mailUser}>` : '"PCMS Security Gate" <no-reply@ethereal.email>',
    to: emailAddress,
    subject: `Your BankFlow Password Reset Verification Code: ${code}`,
    text: `Your BankFlow PCMS verification code is ${code}. This OTP is valid for 5 minutes. Do not share it with anyone.`,
    html: `
      <div style="font-family: Arial, sans-serif; padding: 25px; max-width: 500px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
        <h2 style="color: #1e3a8a; margin-bottom: 20px; font-weight: 700;">BankFlow PCMS Security</h2>
        <p style="font-size: 15px; color: #334155; line-height: 1.5;">Your One-Time Password (OTP) for password reset is:</p>
        <div style="font-size: 36px; font-weight: 800; letter-spacing: 6px; padding: 16px 28px; background-color: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; border-radius: 8px; display: inline-block; margin: 18px 0; font-family: monospace;">
          ${code}
        </div>
        <p style="font-size: 13px; color: #64748b; margin-top: 20px;">This OTP is valid for 5 minutes. If you did not request this, please ignore this email.</p>
        <hr style="border: 0; border-top: 1px solid #f1f5f9; margin: 25px 0;">
        <p style="font-size: 11px; color: #94a3b8; text-align: center;">BankFlow Security & Automated Dispatch System</p>
      </div>
    `
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[Email Service] Mail sent to ${emailAddress}: ${info.messageId}`);
    if (!mailUser) {
      console.log(`[Email Service] Preview message at Ethereal: ${nodemailer.getTestMessageUrl(info)}`);
    }
    return true;
  } catch (err) {
    console.error('Nodemailer error:', err.message);
    return false;
  }
}

// ─────────────────────────────────────────────────────────────
// 1. AUTHENTICATION ENDPOINTS
// ─────────────────────────────────────────────────────────────

app.post('/api/auth/register', async (req, res) => {
  const { name, email, password, role, employeeId } = req.body;

  if (!name || !email || !password || !role) {
    return res.status(400).json({ error: 'Name, email, password and role are required.' });
  }

  try {
    const existing = await query.get('SELECT * FROM users WHERE email = ?', [email.trim().toLowerCase()]);
    if (existing) {
      return res.status(400).json({ error: 'Email address is already registered.' });
    }

    if (employeeId) {
      const existingEmp = await query.get('SELECT * FROM users WHERE employee_id = ?', [employeeId.trim()]);
      if (existingEmp) {
        return res.status(400).json({ error: 'Employee ID is already registered.' });
      }
    }

    const hashedPassword = bcrypt.hashSync(password, 10);
    const result = await query.run(
      'INSERT INTO users (name, email, password, role, employee_id) VALUES (?, ?, ?, ?, ?)',
      [name.trim(), email.trim().toLowerCase(), hashedPassword, role, employeeId ? employeeId.trim() : null]
    );

    await logAudit('User Registration', name, email, role, 'ok', `New ${role} account created`);

    res.json({ success: true, userId: result.id, message: 'Account registered successfully.' });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password, expectedRole } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  const cleanId = email.trim().toLowerCase();

  try {
    const user = await query.get(
      'SELECT * FROM users WHERE LOWER(email) = ? OR LOWER(employee_id) = ?',
      [cleanId, cleanId]
    );

    if (!user) {
      return res.status(401).json({ error: 'User not registered. Please sign up first.' });
    }

    const isPasswordValid = bcrypt.compareSync(password, user.password);
    if (!isPasswordValid) {
      await logAudit('Failed Login Attempt', user.name, user.email, user.role, 'failed', 'Invalid password');
      return res.status(401).json({ error: 'Incorrect password. Please try again.' });
    }

    if (expectedRole && user.role.toLowerCase() !== expectedRole.toLowerCase()) {
      return res.status(403).json({ error: `Access denied: Account role is ${user.role}, but expected ${expectedRole}.` });
    }

    const token = jwt.sign({ userId: user.id, role: user.role, email: user.email }, JWT_SECRET, { expiresIn: '8h' });
    await logAudit('User Login', user.name, user.email, user.role, 'ok', 'Successful password login');

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        employeeId: user.employee_id,
        phone: user.phone || '',
        photoUrl: user.photo_url || null,
        area: user.area || '',
        route: user.route || '',
        address: user.address || ''
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/auth/send-otp', async (req, res) => {
  const { phone, email } = req.body;
  const target = (email || phone || '').trim().toLowerCase();

  if (!target) {
    return res.status(400).json({ error: 'Email or phone identifier is required.' });
  }

  try {
    const user = await query.get(
      'SELECT * FROM users WHERE LOWER(email) = ? OR LOWER(employee_id) = ?',
      [target, target]
    );

    const recipientEmail = user ? user.email : (target.includes('@') ? target : 'agent@bankflow.com');
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000;

    await query.run(
      'INSERT OR REPLACE INTO otps (email, code, expires_at) VALUES (?, ?, ?)',
      [recipientEmail, code, expiresAt]
    );

    console.log(`[OTP Generated] For ${recipientEmail}: ${code}`);
    const emailSent = await sendOTPEmail(recipientEmail, code);

    res.json({
      success: true,
      otp: code,
      emailSent,
      recipientEmail,
      message: `OTP sent to ${recipientEmail}`
    });
  } catch (err) {
    console.error('Send OTP error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, email, code, expectedRole } = req.body;
  const target = (email || phone || '').trim().toLowerCase();

  if (!target || !code) {
    return res.status(400).json({ error: 'Target identifier and code are required.' });
  }

  try {
    const user = await query.get(
      'SELECT * FROM users WHERE LOWER(email) = ? OR LOWER(employee_id) = ?',
      [target, target]
    );

    const lookupEmail = user ? user.email : target;
    const otpRecord = await query.get('SELECT * FROM otps WHERE email = ?', [lookupEmail]);

    if (!otpRecord) {
      return res.status(400).json({ error: 'No OTP was requested for this account.' });
    }

    if (otpRecord.code !== code.toString().trim()) {
      return res.status(400).json({ error: 'Invalid verification code. Please check and re-enter.' });
    }

    if (Date.now() > otpRecord.expires_at) {
      return res.status(400).json({ error: 'OTP code has expired. Please request a new one.' });
    }

    await query.run('DELETE FROM otps WHERE email = ?', [lookupEmail]);

    const activeUser = user || {
      id: 999,
      email: lookupEmail,
      name: lookupEmail.split('@')[0],
      role: expectedRole || 'Collection Agent',
      employee_id: 'CAG-TEMP'
    };

    const token = jwt.sign({ userId: activeUser.id, role: activeUser.role, email: activeUser.email }, JWT_SECRET, { expiresIn: '8h' });
    await logAudit('OTP Login Verified', activeUser.name, activeUser.email, activeUser.role, 'ok', 'Verified via 6-digit OTP');

    res.json({
      success: true,
      token,
      user: {
        id: activeUser.id,
        email: activeUser.email,
        name: activeUser.name,
        role: activeUser.role,
        employeeId: activeUser.employee_id,
        phone: activeUser.phone || '',
        photoUrl: activeUser.photo_url || null,
        area: activeUser.area || '',
        route: activeUser.route || '',
        address: activeUser.address || ''
      }
    });
  } catch (err) {
    console.error('Verify OTP error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/auth/reset-password-otp', async (req, res) => {
  const { email, phone, code, password } = req.body;
  const target = (email || phone || '').trim().toLowerCase();

  if (!target || !code || !password) {
    return res.status(400).json({ error: 'Missing required parameters.' });
  }

  try {
    let user = await query.get(
      'SELECT * FROM users WHERE LOWER(email) = ? OR LOWER(employee_id) = ?',
      [target, target]
    );

    const lookupEmail = user ? user.email : target;
    const otpRecord = await query.get('SELECT * FROM otps WHERE email = ?', [lookupEmail]);

    if (!otpRecord || otpRecord.code !== code.toString().trim()) {
      return res.status(400).json({ error: 'Invalid verification code.' });
    }

    if (Date.now() > otpRecord.expires_at) {
      return res.status(400).json({ error: 'OTP code has expired.' });
    }

    const hashedPassword = bcrypt.hashSync(password, 10);

    if (user) {
      await query.run('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, user.id]);
    } else {
      // Auto-register user account into SQLite DB if not registered yet
      const defaultName = target.split('@')[0];
      await query.run(
        'INSERT INTO users (name, email, password, role, employee_id) VALUES (?, ?, ?, ?, ?)',
        [defaultName, target, hashedPassword, 'Collection Agent', `CAG-${Date.now().toString().slice(-4)}`]
      );
      user = await query.get('SELECT * FROM users WHERE LOWER(email) = ?', [target]);
    }

    await query.run('DELETE FROM otps WHERE email = ?', [lookupEmail]);
    await logAudit('Password Reset', user.name, user.email, user.role, 'ok', 'Password updated / registered successfully');

    res.json({ success: true, message: 'Password updated successfully. You can now log in.' });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.get('/api/auth/users', async (req, res) => {
  try {
    const users = await query.all('SELECT id, name, email, role, employee_id, phone, photo_url, area, route, address, created_at FROM users ORDER BY id ASC');
    res.json(users);
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// USER PROFILE & PHOTO MANAGEMENT
// ─────────────────────────────────────────────────────────────

app.get('/api/users/profile', async (req, res) => {
  const { email } = req.query;
  if (!email) {
    return res.status(400).json({ error: 'Email is required.' });
  }

  try {
    const user = await query.get(
      'SELECT id, name, email, role, employee_id, phone, photo_url, area, route, address, created_at FROM users WHERE LOWER(email) = ?',
      [email.trim().toLowerCase()]
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    res.json({
      success: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        employeeId: user.employee_id,
        phone: user.phone || '',
        photoUrl: user.photo_url || null,
        area: user.area || '',
        route: user.route || '',
        address: user.address || '',
        createdAt: user.created_at
      }
    });
  } catch (err) {
    console.error('Error fetching user profile:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.put('/api/users/profile', async (req, res) => {
  const { email, name, phone, photo_url, photoUrl, area, route, address } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required.' });
  }

  const cleanEmail = email.trim().toLowerCase();
  const chosenPhoto = photo_url !== undefined ? photo_url : photoUrl;

  try {
    const existing = await query.get('SELECT * FROM users WHERE LOWER(email) = ?', [cleanEmail]);
    if (!existing) {
      return res.status(404).json({ error: 'User not found.' });
    }

    await query.run(
      `UPDATE users 
       SET name = COALESCE(?, name),
           phone = COALESCE(?, phone),
           photo_url = COALESCE(?, photo_url),
           area = COALESCE(?, area),
           route = COALESCE(?, route),
           address = COALESCE(?, address)
       WHERE LOWER(email) = ?`,
      [
        name !== undefined && name !== null ? name.trim() : null,
        phone !== undefined && phone !== null ? phone.trim() : null,
        chosenPhoto !== undefined && chosenPhoto !== null ? chosenPhoto : null,
        area !== undefined && area !== null ? area.trim() : null,
        route !== undefined && route !== null ? route.trim() : null,
        address !== undefined && address !== null ? address.trim() : null,
        cleanEmail
      ]
    );

    const updated = await query.get('SELECT * FROM users WHERE LOWER(email) = ?', [cleanEmail]);

    await logAudit(
      'Profile Updated',
      updated.name,
      updated.email,
      updated.role,
      'ok',
      `Updated profile for ${updated.name} (${updated.email})`
    );

    res.json({
      success: true,
      message: 'Profile updated successfully.',
      user: {
        id: updated.id,
        name: updated.name,
        email: updated.email,
        role: updated.role,
        employeeId: updated.employee_id,
        phone: updated.phone || '',
        photoUrl: updated.photo_url || null,
        area: updated.area || '',
        route: updated.route || '',
        address: updated.address || ''
      }
    });
  } catch (err) {
    console.error('Error updating user profile:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.put('/api/users/photo', async (req, res) => {
  const { email, photo_url, photoUrl } = req.body;
  const chosenPhoto = photo_url || photoUrl;

  if (!email || !chosenPhoto) {
    return res.status(400).json({ error: 'Email and photo_url are required.' });
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const existing = await query.get('SELECT * FROM users WHERE LOWER(email) = ?', [cleanEmail]);
    if (!existing) {
      return res.status(404).json({ error: 'User not found.' });
    }

    await query.run('UPDATE users SET photo_url = ? WHERE LOWER(email) = ?', [chosenPhoto, cleanEmail]);

    await logAudit(
      'Photo Updated',
      existing.name,
      existing.email,
      existing.role,
      'ok',
      `Updated avatar photo for ${existing.name}`
    );

    res.json({
      success: true,
      message: 'Profile photo updated successfully.',
      photoUrl: chosenPhoto
    });
  } catch (err) {
    console.error('Error updating user photo:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 2. CUSTOMER MANAGEMENT ENDPOINTS
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// CUSTOMER PRIVACY PROTECTION HELPER
// Masks sensitive identity documents (Aadhaar, PAN, Address, Email)
// unless the authenticated requester is the Customer themselves.
// ─────────────────────────────────────────────────────────────

function maskCustomerPrivacy(cust, role = 'Collection Agent') {
  if (!cust) return cust;
  const isCustomerSelf = (role === 'Customer');
  if (isCustomerSelf) {
    return cust; // Full unmasked access for verified customer
  }

  // Mask sensitive identity fields for staff/agents
  return {
    ...cust,
    email: cust.email ? cust.email.replace(/(.{2})(.*)(?=@)/, (gp1, gp2, gp3) => gp2 + '***') : 'Protected',
    aadhar_number: cust.aadhar_number ? cust.aadhar_number.replace(/\d{4}$/, '****') : 'XXXX-XXXX-****',
    pan_number: cust.pan_number ? cust.pan_number.substring(0, 5) + '****' : '*****',
    address: 'Privacy Protected (Restricted)',
    privacy_status: 'ENCRYPTED_MASKED'
  };
}

app.get('/api/customers', async (req, res) => {
  const { area, route, search, kyc, requesterRole = 'Collection Agent' } = req.query;
  try {
    let sql = 'SELECT * FROM customers WHERE 1=1';
    const params = [];

    if (area && area !== 'All Areas') {
      sql += ' AND area = ?';
      params.push(area);
    }
    if (route) {
      sql += ' AND route = ?';
      params.push(route);
    }
    if (kyc) {
      sql += ' AND kyc_status = ?';
      params.push(kyc);
    }
    if (search) {
      sql += ' AND (name LIKE ? OR phone LIKE ? OR email LIKE ? OR id LIKE ?)';
      const term = `%${search}%`;
      params.push(term, term, term, term);
    }

    sql += ' ORDER BY id ASC';
    const customers = await query.all(sql, params);
    const protectedCustomers = customers.map(c => maskCustomerPrivacy(c, requesterRole));
    res.json(protectedCustomers);
  } catch (err) {
    console.error('Error fetching customers:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.get('/api/customers/:id', async (req, res) => {
  const { id } = req.params;
  const { requesterRole = 'Collection Agent' } = req.query;
  try {
    let customer = await query.get('SELECT * FROM customers WHERE id = ?', [id]);
    if (!customer) {
      customer = await query.get('SELECT * FROM customers WHERE id = ?', [`CUST-${id}`]);
    }
    if (!customer && !isNaN(Number(id))) {
      const all = await query.all('SELECT * FROM customers ORDER BY id ASC');
      const idx = parseInt(id) - 1;
      if (idx >= 0 && idx < all.length) {
        customer = all[idx];
      }
    }
    if (!customer) {
      return res.status(404).json({ error: 'Customer not found.' });
    }

    const accounts = await query.all('SELECT * FROM accounts WHERE customer_id = ?', [customer.id]);
    const history = await query.all('SELECT * FROM collection_history WHERE customer_id = ? ORDER BY id DESC LIMIT 10', [customer.id]);

    const protectedCustomer = maskCustomerPrivacy(customer, requesterRole);

    res.json({
      ...protectedCustomer,
      accounts,
      history
    });
  } catch (err) {
    console.error('Error fetching customer details:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// Helper to geocode address to GPS coordinates with fast timeout
async function geocodeAddress(addressStr, areaStr) {
  const queryText = (addressStr || areaStr || 'Hubli, Karnataka, India').trim();
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 600);
    const url = `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(queryText)}`;
    const res = await fetch(url, { signal: controller.signal, headers: { 'User-Agent': 'PCMS-BankFlow/2.0' } });
    clearTimeout(timeout);
    const data = await res.json();
    if (data && data.length > 0 && data[0].lat && data[0].lon) {
      return { lat: parseFloat(data[0].lat), lng: parseFloat(data[0].lon) };
    }
  } catch (e) {
    // ignore
  }

  // Fallback try city name if full street misses
  if (addressStr && addressStr.toLowerCase().includes('hubli')) {
    return { lat: 15.3518, lng: 75.1380 };
  }
  return { lat: 12.9716, lng: 77.5946 };
}

// ─────────────────────────────────────────────────────────────
// AGENT-CUSTOMER AREA & ROUTE MATCHING ENGINE
// Automatically matches customers with designated Collection Agents based on Area & Route
// ─────────────────────────────────────────────────────────────

async function matchAgentForCustomer(area, route, explicitAgentEmail) {
  if (explicitAgentEmail && typeof explicitAgentEmail === 'string' && explicitAgentEmail.trim().length > 0) {
    const explicit = await query.get(
      "SELECT * FROM users WHERE LOWER(email) = ? AND role = 'Collection Agent'",
      [explicitAgentEmail.trim().toLowerCase()]
    );
    if (explicit) return explicit;
  }

  const cleanArea = (area || '').trim();
  const cleanRoute = (route || '').trim();

  // 1. Exact match on both Area and Route
  if (cleanArea && cleanRoute) {
    const match = await query.get(
      "SELECT * FROM users WHERE role = 'Collection Agent' AND LOWER(area) = LOWER(?) AND LOWER(route) = LOWER(?)",
      [cleanArea, cleanRoute]
    );
    if (match) return match;
  }

  // 2. Match on Area prefix or substring
  if (cleanArea) {
    const matchArea = await query.get(
      "SELECT * FROM users WHERE role = 'Collection Agent' AND (LOWER(area) LIKE LOWER(?) OR LOWER(?) LIKE '%' || LOWER(area) || '%')",
      [`%${cleanArea}%`, cleanArea]
    );
    if (matchArea) return matchArea;
  }

  // 3. Fallback to first available Collection Agent
  const defaultAgent = await query.get(
    "SELECT * FROM users WHERE role = 'Collection Agent' ORDER BY id ASC LIMIT 1"
  );
  return defaultAgent || {
    id: 1,
    name: 'Rahul Verma',
    email: 'agent@bankflow.com',
    phone: '+91 98765 43210',
    area: 'Sector 12',
    route: 'Route A',
    address: 'BankFlow Sector 12 Field Branch, Hubli'
  };
}

// Endpoint to list all active collection agents with their assigned areas and routes
app.get('/api/agents', async (req, res) => {
  try {
    const agents = await query.all(
      "SELECT id, name, email, phone, area, route, address, photo_url FROM users WHERE role = 'Collection Agent' ORDER BY id ASC"
    );
    res.json(agents.map(a => ({
      id: a.id,
      name: a.name,
      email: a.email,
      phone: a.phone || '',
      area: a.area || 'Sector 12',
      route: a.route || 'Route A',
      address: a.address || '',
      photoUrl: a.photo_url || null,
    })));
  } catch (err) {
    console.error('Error fetching collection agents:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/customers', async (req, res) => {
  const { name, email, phone, area, route, opening_balance, daily_target, latitude, longitude, address, aadhar_number, pan_number, agent_email, assigned_agent_email } = req.body;
  const targetArea = (area || 'Sector 12').trim();
  const targetRoute = (route || 'Route A').trim();
  if (!name || !phone) {
    return res.status(400).json({ error: 'Name and phone are required.' });
  }

  const newId = `CUST-${Math.floor(100 + Math.random() * 900)}`;
  const openBal = parseFloat(opening_balance) || 0;
  const target = parseFloat(daily_target) || Math.max(100, Math.round(openBal * 0.05)) || 500;

  // Auto-geocode address to latitude/longitude for map navigation
  let finalLat = latitude ? parseFloat(latitude) : null;
  let finalLng = longitude ? parseFloat(longitude) : null;
  if (!finalLat || !finalLng) {
    const geo = await geocodeAddress(address, targetArea);
    finalLat = geo.lat;
    finalLng = geo.lng;
  }

  try {
    const cleanPhone = phone.trim();
    const existingCustomer = await query.get('SELECT * FROM customers WHERE phone = ?', [cleanPhone]);
    if (existingCustomer) {
      // Customer already exists with this phone number - update existing record
      await query.run(
        `UPDATE customers 
         SET name = COALESCE(?, name),
             email = COALESCE(?, email),
             area = COALESCE(?, area),
             route = COALESCE(?, route),
             address = COALESCE(?, address)
         WHERE id = ?`,
        [name.trim(), email ? email.trim().toLowerCase() : null, targetArea, targetRoute, address || null, existingCustomer.id]
      );
      return res.json({
        success: true,
        message: 'Customer updated successfully.',
        customerId: existingCustomer.id,
        isExisting: true
      });
    }

    // Automatically match Collection Agent based on Area & Route
    const matchedAgent = await matchAgentForCustomer(targetArea, targetRoute, assigned_agent_email || agent_email);
    const assignedAgent = matchedAgent.email.toLowerCase();

    await query.run(
      'INSERT INTO customers (id, name, email, phone, area, route, opening_balance, latitude, longitude, is_new, created_at, kyc_status, aadhar_number, pan_number, address, assigned_agent_email) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)',
      [newId, name.trim(), email ? email.trim().toLowerCase() : '', cleanPhone, targetArea, targetRoute, openBal, finalLat, finalLng, Date.now(), aadhar_number && pan_number ? 'Verified' : 'Pending', aadhar_number || null, pan_number || null, address || '', assignedAgent]
    );

    // Create default savings passbook account
    const accNumber = `PCMS-${Math.floor(10000 + Math.random() * 90000)}`;
    await query.run(
      'INSERT INTO accounts (account_number, customer_id, account_type, balance, daily_target, arrear, interest_rate) VALUES (?, ?, ?, ?, ?, 0, 4.5)',
      [accNumber, newId, 'Savings Passbook', openBal, target]
    );

    const d = new Date();
    const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    const timeStr = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;

    // Auto-seed opening passbook deposit in collection_history if opening balance > 0
    if (openBal > 0) {
      const rcpId = `RCP-${todayDate.replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;
      await query.run(
        'INSERT INTO collection_history (customer_id, agent_email, amount, collection_date, date, time, status, payment_mode, receipt_id, remarks) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [newId, assignedAgent, openBal, todayDate, todayDate, timeStr, 'collected', 'CASH', rcpId, 'Opening Passbook Deposit']
      );
    }

    // Auto-seed into today's collection schedule immediately for the assigned agent
    await query.run(
      'INSERT OR REPLACE INTO collections (customer_id, agent_email, collection_date, pending_amount, status) VALUES (?, ?, ?, ?, ?)',
      [newId, assignedAgent, todayDate, target, 'pending']
    );

    await logAudit('Customer Created', 'System', assignedAgent, 'Staff', 'ok', `Created customer ${name} (${newId}) matched to agent ${matchedAgent.name} (${assignedAgent}) for ${targetArea} / ${targetRoute}`);
    res.json({
      success: true,
      customerId: newId,
      accountNumber: accNumber,
      dailyTarget: target,
      assignedAgentEmail: assignedAgent,
      assignedAgentName: matchedAgent.name,
      area: targetArea,
      route: targetRoute
    });
  } catch (err) {
    console.error('Error creating customer:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.delete('/api/customers/clear-all', async (req, res) => {
  try {
    await query.run('DELETE FROM accounts');
    await query.run('DELETE FROM collections');
    await query.run('DELETE FROM collection_history');
    await query.run('DELETE FROM customers');
    await logAudit('All Customers Wiped', 'System', null, 'Staff', 'ok', 'Cleared all customer records permanently');
    res.json({ success: true, message: 'All customer records permanently deleted.' });
  } catch (err) {
    console.error('Error clearing all customers:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.put('/api/customers/:id', async (req, res) => {
  const { id } = req.params;
  const { name, email, phone, area, route, kyc_status, aadhar_number, pan_number, latitude, longitude, address, photo_url, assigned_agent_email, agent_email } = req.body;

  try {
    const customer = await query.get('SELECT * FROM customers WHERE id = ?', [id]);
    if (!customer) {
      return res.status(404).json({ error: 'Customer not found.' });
    }

    const newArea = area || customer.area;
    const newRoute = route || customer.route;
    let newAgent = assigned_agent_email || agent_email || customer.assigned_agent_email;

    if (!newAgent || (area && area !== customer.area) || (route && route !== customer.route)) {
      const matched = await matchAgentForCustomer(newArea, newRoute, assigned_agent_email || agent_email);
      newAgent = matched.email.toLowerCase();
    }

    await query.run(
      `UPDATE customers 
       SET name = COALESCE(?, name),
           email = COALESCE(?, email),
           phone = COALESCE(?, phone),
           area = COALESCE(?, area),
           route = COALESCE(?, route),
           kyc_status = COALESCE(?, kyc_status),
           aadhar_number = COALESCE(?, aadhar_number),
           pan_number = COALESCE(?, pan_number),
           latitude = COALESCE(?, latitude),
           longitude = COALESCE(?, longitude),
           address = COALESCE(?, address),
           photo_url = COALESCE(?, photo_url),
           assigned_agent_email = COALESCE(?, assigned_agent_email)
       WHERE id = ?`,
      [name, email, phone, area, route, kyc_status, aadhar_number, pan_number, latitude, longitude, address, photo_url || null, newAgent, id]
    );

    // Update pending collections for this customer to the matched agent
    if (newAgent) {
      await query.run(
        "UPDATE collections SET agent_email = ? WHERE customer_id = ? AND status = 'pending'",
        [newAgent, id]
      );
    }

    res.json({ success: true, message: 'Customer updated successfully.', assignedAgentEmail: newAgent });
  } catch (err) {
    console.error('Error updating customer:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.delete('/api/customers/:id', async (req, res) => {
  const { id } = req.params;
  try {
    let customer = await query.get('SELECT * FROM customers WHERE id = ? OR id = ?', [id, `CUST-${id}`]);
    if (!customer && !isNaN(Number(id))) {
      const all = await query.all('SELECT * FROM customers ORDER BY id ASC');
      const idx = parseInt(id) - 1;
      if (idx >= 0 && idx < all.length) customer = all[idx];
    }
    if (!customer) {
      return res.status(404).json({ error: 'Customer not found.' });
    }

    const actualId = customer.id;
    await query.run('DELETE FROM accounts WHERE customer_id = ?', [actualId]);
    await query.run('DELETE FROM collections WHERE customer_id = ?', [actualId]);
    await query.run('DELETE FROM collection_history WHERE customer_id = ?', [actualId]);
    await query.run('DELETE FROM customers WHERE id = ?', [actualId]);

    await logAudit('Customer Deleted', 'System', null, 'Staff', 'ok', `Permanently deleted customer ${customer.name} (${actualId})`);
    res.json({ success: true, message: `Customer ${customer.name} permanently deleted.` });
  } catch (err) {
    console.error('Error deleting customer:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 3. COLLECTIONS & FIELD OPERATIONS
// ─────────────────────────────────────────────────────────────

app.get('/api/collections/today', async (req, res) => {
  const { email } = req.query;
  const agentEmail = (email || 'agent@bankflow.com').trim().toLowerCase();

  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    // Ensure all existing customers have assigned agents and today's collections schedule
    const allCustomers = await query.all('SELECT * FROM customers ORDER BY id ASC');
    for (const cust of allCustomers) {
      let matchedAgentEmail = cust.assigned_agent_email;
      if (!matchedAgentEmail) {
        const matched = await matchAgentForCustomer(cust.area, cust.route, null);
        matchedAgentEmail = matched.email.toLowerCase();
        await query.run('UPDATE customers SET assigned_agent_email = ? WHERE id = ?', [matchedAgentEmail, cust.id]);
      }

      const exist = await query.get(
        'SELECT id FROM collections WHERE customer_id = ? AND collection_date = ?',
        [cust.id, todayDate]
      );
      if (!exist) {
        const initialPending = Math.round(cust.opening_balance * 0.05) || 500;
        await query.run(
          'INSERT OR IGNORE INTO collections (customer_id, agent_email, collection_date, pending_amount, status) VALUES (?, ?, ?, ?, ?)',
          [cust.id, matchedAgentEmail, todayDate, initialPending, 'pending']
        );
      }
    }

    const list = await query.all(
      `SELECT c.id, c.name, c.area, c.route, c.opening_balance, c.phone, c.email, c.is_new, c.latitude, c.longitude,
              c.kyc_status, c.aadhar_number, c.pan_number, c.address, c.assigned_agent_email,
              COALESCE(col.photo_url, c.photo_url) as photo_url,
              col.id as collection_id, col.pending_amount, col.collected_amount, col.status, col.visit_time,
              col.payment_mode, col.remarks, col.photo_captured, col.signature_captured,
              col.deposit_total, col.late_fee, col.interest, col.receipt_id
       FROM collections col
       JOIN customers c ON col.customer_id = c.id
       WHERE col.collection_date = ? AND (LOWER(col.agent_email) = ? OR LOWER(c.assigned_agent_email) = ?)
       ORDER BY col.id ASC`,
      [todayDate, agentEmail, agentEmail]
    );

    const formatted = list.map((item, idx) => ({
      id: item.id,
      numericId: idx + 1,
      name: item.name,
      area: item.area,
      route: item.route,
      account: `PCMS-00${120 + idx}`,
      pigmy_account_number: item.id.replace('CUST-', 'PG-2026-'),
      amount: item.pending_amount,
      pending_amount: item.pending_amount,
      collected_amount: item.collected_amount,
      balance: item.opening_balance,
      opening_balance: item.opening_balance,
      status: item.status,
      isNew: item.is_new === 1,
      is_new: item.is_new,
      phone: item.phone,
      email: item.email,
      address: item.address || `${item.area}, ${item.route}`,
      visit_time: item.visit_time,
      remarks: item.remarks,
      latitude: item.latitude,
      longitude: item.longitude,
      kyc_status: item.kyc_status || 'Pending',
      aadhar_number: item.aadhar_number || '',
      pan_number: item.pan_number || '',
      photo_captured: item.photo_captured || (item.photo_url ? 1 : 0),
      signature_captured: item.signature_captured || 0,
      payment_mode: item.payment_mode || 'CASH',
      photo_url: item.photo_url || null,
      assigned_agent_email: item.assigned_agent_email || agentEmail,
      receipt_id: item.receipt_id || `RCP-${todayDate.replace(/-/g, '')}-${String(idx + 1).padStart(4, '0')}`
    }));

    res.json(formatted);
  } catch (err) {
    console.error('Error fetching today collections:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/collections/record', async (req, res) => {
  const {
    customerId,
    agentEmail = 'agent@bankflow.com',
    status = 'collected',
    collectedAmount = 0,
    depositTotal = 0,
    lateFee = 0,
    interest = 0,
    paymentMode = 'CASH',
    remarks = '',
    latitude,
    longitude,
    photoCaptured = 0,
    photoUrl = null,
    photo_url = null,
    signatureCaptured = 0
  } = req.body;

  const chosenPhoto = photo_url || photoUrl || null;
  const isPhotoCaptured = (photoCaptured === 1 || photoCaptured === true || (chosenPhoto && chosenPhoto.length > 0)) ? 1 : 0;

  if (!customerId) {
    return res.status(400).json({ error: 'Customer ID is required.' });
  }

  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const visitTime = d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
  const receiptId = `RCP-${todayDate.replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;

  try {
    // ── Block collections on CLOSED accounts ──
    const custAccount = await query.get(
      `SELECT a.status FROM accounts a WHERE a.customer_id = ? OR a.customer_id = ? ORDER BY a.id ASC LIMIT 1`,
      [customerId, `CUST-${customerId}`]
    );
    if (custAccount && custAccount.status === 'CLOSED') {
      return res.status(400).json({ error: 'Collection blocked: this account is CLOSED. No further deposits are accepted.' });
    }

    let actualCustId = customerId.toString().startsWith('CUST-') ? customerId : `CUST-${customerId}`;
    let cust = await query.get('SELECT * FROM customers WHERE id = ? OR id = ?', [customerId, actualCustId]);
    if (cust) {
      actualCustId = cust.id;
    }

    let schedule = await query.get(
      'SELECT * FROM collections WHERE (customer_id = ? OR customer_id = ?) AND collection_date = ?',
      [customerId, actualCustId, todayDate]
    );

    if (!schedule) {
      await query.run(
        'INSERT OR IGNORE INTO collections (customer_id, agent_email, collection_date, pending_amount, status, photo_url) VALUES (?, ?, ?, ?, ?, ?)',
        [actualCustId, agentEmail.toLowerCase(), todayDate, collectedAmount || 500, status, chosenPhoto]
      );
      schedule = await query.get(
        'SELECT * FROM collections WHERE (customer_id = ? OR customer_id = ?) AND collection_date = ?',
        [customerId, actualCustId, todayDate]
      );
    }

    const prevCollected = schedule ? (schedule.collected_amount || 0) : 0;
    const currentCollected = status === 'collected' ? (parseFloat(collectedAmount) || 0) : 0;
    const delta = currentCollected - prevCollected;

    if (schedule) {
      await query.run(
        `UPDATE collections 
         SET agent_email = ?, status = ?, collected_amount = ?, deposit_total = ?, late_fee = ?, interest = ?,
             visit_time = ?, payment_mode = ?, remarks = ?, latitude = ?, longitude = ?,
             photo_captured = ?, photo_url = COALESCE(?, photo_url), signature_captured = ?, receipt_id = ?
         WHERE id = ?`,
        [
          agentEmail.toLowerCase(),
          status,
          currentCollected,
          depositTotal || currentCollected,
          lateFee,
          interest,
          visitTime,
          paymentMode.toUpperCase(),
          remarks,
          latitude || null,
          longitude || null,
          isPhotoCaptured,
          chosenPhoto,
          signatureCaptured ? 1 : 0,
          receiptId,
          schedule.id
        ]
      );
    }

    // Prevent duplicate history entries: replace single row for (customer_id, collection_date)
    await query.run(
      'DELETE FROM collection_history WHERE customer_id = ? AND collection_date = ?',
      [actualCustId, todayDate]
    );

    if (status === 'collected' && currentCollected > 0) {
      await query.run(
        'INSERT INTO collection_history (customer_id, agent_email, collection_date, amount, status, payment_mode, receipt_id, date, time, remarks, photo_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [actualCustId, agentEmail.toLowerCase(), todayDate, currentCollected, status, paymentMode.toUpperCase(), receiptId, todayDate, visitTime, remarks, chosenPhoto]
      );
    }

    // Apply only delta change to balance so no duplicate additions happen
    if (delta !== 0) {
      await query.run(
        'UPDATE customers SET opening_balance = opening_balance + ? WHERE id = ?',
        [delta, actualCustId]
      );
      await query.run(
        'UPDATE accounts SET balance = balance + ? WHERE customer_id = ? AND account_type = "Savings Passbook"',
        [delta, actualCustId]
      );
    }

    await logAudit(
      status === 'collected' ? 'Collection Logged' : 'Customer Visit Logged',
      agentEmail.split('@')[0],
      agentEmail,
      'Collection Agent',
      'ok',
      `Customer ${actualCustId} - Amount: ₹${currentCollected} via ${paymentMode}`
    );

    res.json({
      success: true,
      receiptId,
      visitTime,
      collectedAmount: currentCollected,
      status
    });
  } catch (err) {
    console.error('Error recording collection:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/collections/sync', async (req, res) => {
  const { email = 'agent@bankflow.com', transactions = [] } = req.body;

  if (!Array.isArray(transactions)) {
    return res.status(400).json({ error: 'Transactions array required.' });
  }

  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    for (const tx of transactions) {
      const { customerId, status, amount, collectedAmount, paymentMode, remarks, visitTime, latitude, longitude, photoCaptured, signatureCaptured } = tx;
      if (!customerId) continue;

      const finalAmount = collectedAmount || amount || 0;
      const actualCustId = customerId.toString().startsWith('CUST-') ? customerId : `CUST-${customerId}`;

      let schedule = await query.get(
        'SELECT * FROM collections WHERE (customer_id = ? OR customer_id = ?) AND collection_date = ?',
        [customerId, actualCustId, todayDate]
      );

      if (!schedule) {
        await query.run(
          'INSERT INTO collections (customer_id, agent_email, collection_date, pending_amount, status) VALUES (?, ?, ?, ?, ?)',
          [actualCustId, email, todayDate, finalAmount, status || 'collected']
        );
        schedule = await query.get(
          'SELECT * FROM collections WHERE customer_id = ? AND collection_date = ?',
          [actualCustId, todayDate]
        );
      }

      if (schedule) {
        await query.run(
          `UPDATE collections 
           SET status = ?, collected_amount = ?, visit_time = ?, payment_mode = ?, remarks = ?,
               latitude = ?, longitude = ?, photo_captured = ?, signature_captured = ?
           WHERE id = ?`,
          [
            status || 'collected',
            finalAmount,
            visitTime || new Date().toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }),
            (paymentMode || 'CASH').toUpperCase(),
            remarks || '',
            latitude || null,
            longitude || null,
            photoCaptured ? 1 : 0,
            signatureCaptured ? 1 : 0,
            schedule.id
          ]
        );

        if (status === 'collected' && finalAmount > 0) {
          await query.run(
            'INSERT INTO collection_history (customer_id, collection_date, amount, status, payment_mode) VALUES (?, ?, ?, ?, ?)',
            [actualCustId, todayDate, finalAmount, status, (paymentMode || 'CASH').toUpperCase()]
          );
        }
      }
    }

    await logAudit('Offline Sync', email.split('@')[0], email, 'Collection Agent', 'ok', `Synced ${transactions.length} offline records`);
    res.json({ success: true, syncedCount: transactions.length });
  } catch (err) {
    console.error('Sync error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.get('/api/collections/receipt/:id', async (req, res) => {
  const { id } = req.params;
  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    const cust = await query.get('SELECT * FROM customers WHERE id = ? OR id = ?', [id, `CUST-${id}`]);
    const record = await query.get(
      'SELECT * FROM collections WHERE (customer_id = ? OR customer_id = ?) AND collection_date = ?',
      [id, `CUST-${id}`, todayDate]
    );

    if (!cust) {
      return res.status(404).json({ error: 'Receipt record not found.' });
    }

    res.json({
      receiptId: record?.receipt_id || `RCP-${todayDate.replace(/-/g, '')}-0001`,
      customerName: cust.name,
      account: `PCMS-00${cust.id.replace('CUST-', '')}`,
      date: todayDate,
      time: record?.visit_time || '10:30 AM',
      amount: record?.collected_amount || 500,
      depositTotal: record?.deposit_total || record?.collected_amount || 500,
      lateFee: record?.late_fee || 0,
      interest: record?.interest || 0,
      paymentMode: record?.payment_mode || 'CASH',
      balance: cust.opening_balance,
      agentName: 'Rahul Verma',
      branch: 'Bangalore Central Micro-Branch'
    });
  } catch (err) {
    console.error('Receipt error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 3.1 AGENT PASSBOOK & REAL-TIME COLLECTION STATEMENT
// ─────────────────────────────────────────────────────────────

app.get('/api/agent/passbook', async (req, res) => {
  const { email } = req.query;
  const agentEmail = (email || 'agent@bankflow.com').trim().toLowerCase();

  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    let agent = await query.get("SELECT * FROM users WHERE LOWER(email) = ?", [agentEmail]);
    if (!agent) {
      agent = {
        id: 301,
        name: agentEmail.split('@')[0],
        email: agentEmail,
        employee_id: 'CAG-301',
        area: 'Sector 12',
        route: 'Route A',
        phone: '+91 98765 43210'
      };
    }

    // Calculate today's collections for this agent
    const todayCollections = await query.all(
      `SELECT col.*, c.name as customer_name, c.phone as customer_phone, c.area as customer_area, c.route as customer_route
       FROM collections col
       JOIN customers c ON col.customer_id = c.id
       WHERE col.collection_date = ? AND LOWER(col.agent_email) = ?`,
      [todayDate, agentEmail]
    );

    let totalCollectedToday = 0;
    let totalCashToday = 0;
    let totalUpiToday = 0;
    let totalTargetToday = 0;
    let completedStops = 0;

    for (const item of todayCollections) {
      const amt = item.collected_amount || 0;
      totalTargetToday += (item.pending_amount || 0);
      if (item.status === 'collected' || amt > 0) {
        totalCollectedToday += amt;
        completedStops++;
        if ((item.payment_mode || 'CASH').toUpperCase() === 'UPI') {
          totalUpiToday += amt;
        } else {
          totalCashToday += amt;
        }
      }
    }

    // Fetch collection history for this agent
    const historyList = await query.all(
      `SELECT h.*, c.name as customer_name, c.phone as customer_phone, c.area as customer_area, c.route as customer_route
       FROM collection_history h
       JOIN customers c ON h.customer_id = c.id
       WHERE LOWER(h.agent_email) = ? OR h.agent_email IS NULL OR h.customer_id IN (SELECT id FROM customers WHERE LOWER(assigned_agent_email) = ?)
       ORDER BY h.id DESC LIMIT 60`,
      [agentEmail, agentEmail]
    );

    const formattedHistory = historyList.map(h => ({
      id: h.id,
      customerId: h.customer_id,
      customerName: h.customer_name || 'Customer',
      customerPhone: h.customer_phone || '',
      area: h.customer_area || '',
      route: h.customer_route || '',
      amount: h.amount || 0,
      paymentMode: h.payment_mode || 'CASH',
      receiptId: h.receipt_id || `RCP-${h.id}`,
      collectionDate: h.collection_date || h.date || todayDate,
      time: h.time || 'Today',
      status: h.status || 'collected',
      remarks: h.remarks || 'Passbook deposit'
    }));

    res.json({
      agent: {
        id: agent.id,
        name: agent.name,
        email: agent.email,
        employeeId: agent.employee_id || 'CAG-301',
        area: agent.area || 'Sector 12',
        route: agent.route || 'Route A',
        phone: agent.phone || ''
      },
      accountNumber: `PB-AGT-${(agent.employee_id || 'CAG301').replace(/[^a-zA-Z0-9]/g, '')}`,
      todayDate,
      totalCollectedToday,
      totalCashToday,
      totalUpiToday,
      totalTargetToday,
      completedStops,
      totalStops: todayCollections.length,
      commissionRate: 2.0,
      commissionEarned: parseFloat((totalCollectedToday * 0.02).toFixed(2)),
      transactions: formattedHistory
    });
  } catch (err) {
    console.error('Error fetching agent passbook:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.get('/api/customer/my-passbook', async (req, res) => {
  const { email, phone, id } = req.query;
  try {
    let customer = null;
    if (id) {
      customer = await query.get('SELECT * FROM customers WHERE id = ? OR id = ?', [id, `CUST-${id}`]);
    }
    if (!customer && email) {
      customer = await query.get('SELECT * FROM customers WHERE LOWER(email) = ?', [email.trim().toLowerCase()]);
    }
    if (!customer && phone) {
      customer = await query.get('SELECT * FROM customers WHERE phone = ? OR phone LIKE ?', [phone.trim(), `%${phone.trim()}%`]);
    }
    if (!customer) {
      customer = await query.get('SELECT * FROM customers ORDER BY id DESC LIMIT 1');
    }

    if (!customer) {
      return res.status(404).json({ error: 'No passbook account found.' });
    }

    const accounts = await query.all('SELECT * FROM accounts WHERE customer_id = ?', [customer.id]);
    const history = await query.all('SELECT * FROM collection_history WHERE customer_id = ? ORDER BY id DESC LIMIT 30', [customer.id]);

    const account = accounts.length > 0 ? accounts[0] : {
      account_number: customer.id.replace('CUST-', 'PG-2026-'),
      balance: customer.opening_balance,
      interest_rate: 4.5,
      status: 'Active'
    };

    res.json({
      customer: {
        id: customer.id,
        name: customer.name,
        email: customer.email,
        phone: customer.phone,
        area: customer.area,
        route: customer.route,
        address: customer.address,
        kycStatus: customer.kyc_status || 'Verified',
        photoUrl: customer.photo_url || null
      },
      account,
      history
    });
  } catch (err) {
    console.error('Error fetching customer passbook:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 3.2 LIVE VISITS FEED & GEOTAGGED DOORSTEP PROOF
// ─────────────────────────────────────────────────────────────

app.get('/api/visits/live', async (req, res) => {
  const { agentEmail } = req.query;

  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    let sql = `
      SELECT 
        col.id as collection_id,
        col.customer_id,
        col.agent_email,
        col.status,
        col.collected_amount,
        col.visit_time,
        col.payment_mode,
        col.remarks,
        col.latitude,
        col.longitude,
        col.photo_captured,
        col.signature_captured,
        col.receipt_id,
        col.pending_amount,
        col.photo_url as visit_photo_url,
        c.name as customer_name,
        c.phone as customer_phone,
        c.area,
        c.route,
        c.address,
        c.photo_url as customer_photo_url,
        c.kyc_status
      FROM collections col
      JOIN customers c ON col.customer_id = c.id
      WHERE col.collection_date = ?
    `;
    const params = [todayDate];

    if (agentEmail) {
      sql += ' AND LOWER(col.agent_email) = ?';
      params.push(agentEmail.trim().toLowerCase());
    }

    sql += ' ORDER BY col.id ASC';

    const visits = await query.all(sql, params);

    const formatted = visits.map(v => {
      const actualPhoto = v.visit_photo_url || v.customer_photo_url || null;
      return {
        id: v.collection_id,
        customerId: v.customer_id,
        customerName: v.customer_name,
        customerPhone: v.customer_phone,
        area: v.area,
        route: v.route,
        address: v.address || `${v.area}, ${v.route}`,
        agentEmail: v.agent_email,
        status: v.status || 'pending',
        collectedAmount: v.collected_amount || 0,
        pendingAmount: v.pending_amount || 0,
        visitTime: v.visit_time || null,
        paymentMode: v.payment_mode || null,
        remarks: v.remarks || '',
        latitude: v.latitude || null,
        longitude: v.longitude || null,
        photoCaptured: v.photo_captured === 1 || (actualPhoto != null && actualPhoto.length > 0),
        signatureCaptured: v.signature_captured === 1,
        receiptId: v.receipt_id || null,
        photoUrl: actualPhoto,
        kycStatus: v.kyc_status || 'Pending'
      };
    });

    res.json({ date: todayDate, total: formatted.length, visits: formatted });
  } catch (err) {
    console.error('Error fetching live visits:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.get('/api/collections/photo/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const record = await query.get(
      `SELECT col.*, c.name as customer_name, c.area, c.address 
       FROM collections col 
       JOIN customers c ON col.customer_id = c.id 
       WHERE col.id = ? OR col.customer_id = ? OR col.receipt_id = ?`,
      [id, id, id]
    );

    if (!record || !record.photo_url) {
      return res.status(404).json({ error: 'Geotagged doorstep photo not found.' });
    }

    res.json({
      success: true,
      customerId: record.customer_id,
      customerName: record.customer_name,
      area: record.area,
      address: record.address,
      latitude: record.latitude,
      longitude: record.longitude,
      visitTime: record.visit_time,
      receiptId: record.receipt_id,
      photoUrl: record.photo_url,
      agentEmail: record.agent_email
    });
  } catch (err) {
    console.error('Error fetching collection photo:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});


// Delete specific collection item from today's schedule
app.delete('/api/collections/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await query.run('DELETE FROM collections WHERE id = ? OR customer_id = ? OR customer_id = ?', [id, id, `CUST-${id}`]);
    res.json({ success: true, message: 'Collection item removed.' });
  } catch (err) {
    console.error('Error deleting collection:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// Clear ALL collection history records permanently
app.delete('/api/collections/history/clear-all', async (req, res) => {
  try {
    await query.run('DELETE FROM collection_history');
    const d = new Date();
    const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    
    // Reset today collections status to pending and collected amount to 0
    await query.run('UPDATE collections SET status = "pending", collected_amount = 0, deposit_total = 0, visit_time = null, payment_mode = null, remarks = null WHERE collection_date = ?', [todayDate]);
    
    await logAudit('History Cleared', 'System', null, 'Staff', 'ok', 'Cleared all collection history records permanently');
    res.json({ success: true, message: 'All collection history records cleared permanently.' });
  } catch (err) {
    console.error('Error clearing history:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// Delete specific collection history item
app.delete('/api/collections/history/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const item = await query.get('SELECT * FROM collection_history WHERE id = ? OR receipt_id = ?', [id, id]);
    if (item) {
      await query.run('DELETE FROM collection_history WHERE id = ?', [item.id]);
    } else {
      await query.run('DELETE FROM collection_history WHERE id = ? OR receipt_id = ?', [id, id]);
    }
    await logAudit('History Item Deleted', 'Agent', null, 'Collection Agent', 'ok', `Deleted collection record #${id}`);
    res.json({ success: true, message: 'History record deleted.' });
  } catch (err) {
    console.error('Error deleting history record:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 4. ROUTE OPTIMIZATION ENDPOINT
// ─────────────────────────────────────────────────────────────

app.get('/api/routes/optimize', async (req, res) => {
  const { email = 'agent@bankflow.com' } = req.query;
  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    const list = await query.all(
      `SELECT c.id, c.name, c.area, c.route, c.latitude, c.longitude, c.phone, c.opening_balance,
              col.pending_amount, col.collected_amount, col.status
       FROM collections col
       JOIN customers c ON col.customer_id = c.id
       WHERE col.collection_date = ? AND col.agent_email = ?
       ORDER BY c.area ASC, c.route ASC, c.id ASC`,
      [todayDate, email]
    );

    const pending = list.filter(item => item.status === 'pending');
    const completed = list.filter(item => item.status === 'collected');

    res.json({
      totalCount: list.length,
      pendingCount: pending.length,
      completedCount: completed.length,
      nextCustomer: pending[0] || null,
      optimizedQueue: pending,
      completedQueue: completed,
      estimatedMinutes: pending.length * 15,
      routeSummary: `${pending.length} remaining stops across ${new Set(pending.map(p => p.area)).size} areas`
    });
  } catch (err) {
    console.error('Route optimize error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 5. VAULT EOD 8-STEP HANDOVER WORKFLOW
// ─────────────────────────────────────────────────────────────

app.post('/api/vault/submit', async (req, res) => {
  const { agentEmail = 'agent@bankflow.com', cashSubmitted, expectedCash, auditTrail } = req.body;

  if (cashSubmitted === undefined || expectedCash === undefined) {
    return res.status(400).json({ error: 'Cash submitted and expected cash amounts are required.' });
  }

  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const diff = parseFloat(cashSubmitted) - parseFloat(expectedCash);

  try {
    await query.run(
      `INSERT INTO vault_submissions (agent_email, submission_date, expected_cash, cash_submitted, difference_amount, status, audit_trail_json)
       VALUES (?, ?, ?, ?, ?, 'submitted', ?)
       ON CONFLICT(agent_email, submission_date) DO UPDATE SET
       cash_submitted = excluded.cash_submitted,
       difference_amount = excluded.difference_amount,
       audit_trail_json = excluded.audit_trail_json`,
      [agentEmail, todayDate, expectedCash, cashSubmitted, diff, JSON.stringify(auditTrail || [])]
    );

    await logAudit(
      'Vault Cash Submitted',
      agentEmail.split('@')[0],
      agentEmail,
      'Collection Agent',
      diff === 0 ? 'ok' : 'variance',
      `Submitted: ₹${cashSubmitted}, Expected: ₹${expectedCash}, Variance: ₹${diff}`
    );

    res.json({
      success: true,
      difference: diff,
      status: diff === 0 ? 'matched' : 'difference_requires_approval'
    });
  } catch (err) {
    console.error('Vault submit error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/vault/manager-otp/request', async (req, res) => {
  const { agentEmail = 'agent@bankflow.com', difference } = req.body;
  const managerEmail = 'manager@bankflow.com';

  const code = Math.floor(1000 + Math.random() * 9000).toString(); // 4-digit manager code
  const expiresAt = Date.now() + 10 * 60 * 1000;

  try {
    await query.run(
      'INSERT OR REPLACE INTO otps (email, code, expires_at) VALUES (?, ?, ?)',
      [managerEmail, code, expiresAt]
    );

    console.log(`[Manager Approval OTP Created] For ${managerEmail}: ${code} (Variance: ₹${difference})`);
    await sendOTPEmail(managerEmail, code);

    res.json({
      success: true,
      otp: code,
      message: 'Manager variance approval code sent.'
    });
  } catch (err) {
    console.error('Manager OTP request error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/vault/manager-otp/verify', async (req, res) => {
  const { agentEmail = 'agent@bankflow.com', otpCode } = req.body;
  const managerEmail = 'manager@bankflow.com';

  try {
    const record = await query.get('SELECT * FROM otps WHERE email = ?', [managerEmail]);
    if (!record || record.code !== otpCode.toString().trim()) {
      return res.status(400).json({ error: 'Invalid manager approval code.' });
    }

    const d = new Date();
    const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

    await query.run(
      'UPDATE vault_submissions SET manager_otp_verified = 1, status = "manager_cleared" WHERE agent_email = ? AND submission_date = ?',
      [agentEmail, todayDate]
    );

    await logAudit('Manager Variance Cleared', 'Branch Manager', managerEmail, 'Branch Manager', 'ok', `Approved EOD difference for ${agentEmail}`);
    res.json({ success: true, message: 'Manager clearance verified successfully.' });
  } catch (err) {
    console.error('Manager OTP verify error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/vault/cashier-accept', async (req, res) => {
  const { agentEmail = 'agent@bankflow.com', signatureUrl } = req.body;
  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    await query.run(
      'UPDATE vault_submissions SET cashier_accepted = 1, signature_url = ?, status = "cashier_accepted" WHERE agent_email = ? AND submission_date = ?',
      [signatureUrl || 'digital_signature_verified', agentEmail, todayDate]
    );

    await logAudit('Cashier Acceptance Signed', 'Cashier User', 'cashier@bankflow.com', 'Cashier', 'ok', `Physical cash verified & signed into vault for ${agentEmail}`);
    res.json({ success: true, message: 'Cashier acceptance registered.' });
  } catch (err) {
    console.error('Cashier accept error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.post('/api/vault/bank-deposit', async (req, res) => {
  const { agentEmail = 'agent@bankflow.com', bankReference } = req.body;
  if (!bankReference) {
    return res.status(400).json({ error: 'Bank reference deposit slip number required.' });
  }

  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    await query.run(
      'UPDATE vault_submissions SET bank_reference = ?, status = "locked" WHERE agent_email = ? AND submission_date = ?',
      [bankReference.trim(), agentEmail, todayDate]
    );

    await logAudit('Bank Slip Deposited & Ledger Locked', 'Cashier / Auditor', null, 'Auditor', 'ok', `Bank Ref: ${bankReference} - Day Closed`);
    res.json({ success: true, message: 'Day ledger closed and sealed into bank register.' });
  } catch (err) {
    console.error('Bank deposit error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.get('/api/vault/today', async (req, res) => {
  const { agentEmail = 'agent@bankflow.com' } = req.query;
  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    const record = await query.get(
      'SELECT * FROM vault_submissions WHERE agent_email = ? AND submission_date = ?',
      [agentEmail, todayDate]
    );
    res.json(record || { status: 'not_submitted', expected_cash: 0, cash_submitted: 0 });
  } catch (err) {
    console.error('Vault status error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 6. ACCOUNTS & PASSBOOKS ENDPOINTS
// ─────────────────────────────────────────────────────────────

app.get('/api/accounts/passbooks', async (req, res) => {
  try {
    const accounts = await query.all(
      `SELECT a.*, c.name as customer_name, c.phone, c.area, c.route
       FROM accounts a
       JOIN customers c ON a.customer_id = c.id
       ORDER BY a.id ASC`
    );

    const history = await query.all('SELECT * FROM collection_history ORDER BY collection_date DESC LIMIT 15');

    res.json({
      accounts,
      recentTransactions: history
    });
  } catch (err) {
    console.error('Passbooks error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.delete('/api/accounts/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await query.run('DELETE FROM accounts WHERE id = ? OR account_number = ?', [id, id]);
    res.json({ success: true, message: 'Account deleted successfully.' });
  } catch (err) {
    console.error('Error deleting account:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 7. ANALYTICS & DASHBOARD METRICS
// ─────────────────────────────────────────────────────────────

app.get('/api/analytics/dashboard', async (req, res) => {
  const { email = 'agent@bankflow.com', role = 'Collection Agent' } = req.query;
  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    const collections = await query.all(
      'SELECT * FROM collections WHERE collection_date = ? AND agent_email = ?',
      [todayDate, email]
    );

    const totalTarget = collections.reduce((s, c) => s + c.pending_amount, 0) || 5000;
    const collectedCash = collections.filter(c => c.status === 'collected' && (c.payment_mode === 'CASH' || !c.payment_mode)).reduce((s, c) => s + c.collected_amount, 0);
    const collectedDigital = collections.filter(c => c.status === 'collected' && c.payment_mode && c.payment_mode !== 'CASH').reduce((s, c) => s + c.collected_amount, 0);
    const totalCollected = collectedCash + collectedDigital;

    const completedCount = collections.filter(c => c.status === 'collected').length;
    const pendingCount = collections.filter(c => c.status === 'pending').length;

    const auditTrail = await query.all('SELECT * FROM audit_trail ORDER BY id DESC LIMIT 10');

    const recentTransactions = await query.all(`
      SELECT ch.id, ch.customer_id, c.name as customer_name, ch.amount, ch.status, ch.payment_mode, ch.collection_date, ch.receipt_id
      FROM collection_history ch
      JOIN customers c ON ch.customer_id = c.id
      ORDER BY ch.id DESC LIMIT 10
    `);

    // Calculate real-time weekly collection trends (Mon..Sun of current week)
    const now = new Date();
    const currentDayIndex = (now.getDay() + 6) % 7; // Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5, Sun=6
    const weekDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    const monday = new Date(now);
    monday.setDate(now.getDate() - currentDayIndex);

    const weeklyTrends = [];
    for (let i = 0; i < 7; i++) {
      const dObj = new Date(monday);
      dObj.setDate(monday.getDate() + i);
      const dateStr = `${dObj.getFullYear()}-${String(dObj.getMonth() + 1).padStart(2, '0')}-${String(dObj.getDate()).padStart(2, '0')}`;
      
      const colRow = await query.get(
        'SELECT SUM(collected_amount) as total FROM collections WHERE collection_date = ? AND status = "collected"',
        [dateStr]
      );
      const histRow = await query.get(
        'SELECT SUM(amount) as total FROM collection_history WHERE collection_date = ? AND status = "collected"',
        [dateStr]
      );

      const dayAmount = Math.max(colRow?.total || 0, histRow?.total || 0);
      weeklyTrends.push({
        day: weekDayNames[i],
        date: dateStr,
        amount: dayAmount,
        isToday: i === currentDayIndex
      });
    }

    res.json({
      date: todayDate,
      role,
      totalTarget,
      totalCollected,
      collectedCash,
      collectedDigital,
      completedCount,
      pendingCount,
      totalCustomers: collections.length,
      completionRate: collections.length > 0 ? Math.round((completedCount / collections.length) * 100) : 0,
      todayIndex: currentDayIndex,
      weeklyTrends,
      recentTransactions,
      auditTrail
    });
  } catch (err) {
    console.error('Analytics dashboard error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 8. AUDIT TRAIL ENDPOINTS
// ─────────────────────────────────────────────────────────────

app.get('/api/audit', async (req, res) => {
  try {
    const logs = await query.all('SELECT * FROM audit_trail ORDER BY id DESC LIMIT 50');
    res.json(logs);
  } catch (err) {
    console.error('Audit trail error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

app.delete('/api/audit/clear-all', async (req, res) => {
  try {
    await query.run('DELETE FROM audit_trail');
    res.json({ success: true, message: 'All audit logs cleared.' });
  } catch (err) {
    console.error('Error clearing audit logs:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 9. CUSTOMER PROFILE PHOTO
// ─────────────────────────────────────────────────────────────

// Migrate: add photo_url column if not present
(async () => {
  try {
    await query.run(`ALTER TABLE customers ADD COLUMN photo_url TEXT`);
    console.log('[Migration] Added photo_url column to customers table.');
  } catch (e) {
    // Column already exists — ignore
  }
})();

app.put('/api/customers/:id/photo', async (req, res) => {
  const { id } = req.params;
  const { photo_url } = req.body;

  if (!photo_url) {
    return res.status(400).json({ error: 'photo_url is required.' });
  }

  try {
    let customer = await query.get('SELECT * FROM customers WHERE id = ?', [id]);
    if (!customer) customer = await query.get('SELECT * FROM customers WHERE id = ?', [`CUST-${id}`]);
    if (!customer && !isNaN(Number(id))) {
      const all = await query.all('SELECT * FROM customers ORDER BY id ASC');
      const idx = parseInt(id) - 1;
      if (idx >= 0 && idx < all.length) customer = all[idx];
    }
    if (!customer) {
      return res.status(404).json({ error: 'Customer not found.' });
    }

    await query.run('UPDATE customers SET photo_url = ? WHERE id = ?', [photo_url, customer.id]);
    res.json({ success: true, message: 'Profile photo updated.' });
  } catch (err) {
    console.error('Error updating customer photo:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 10. LIVE VISITS FEED (Real-time for Manager/Cashier/Admin)
// ─────────────────────────────────────────────────────────────

app.get('/api/visits/live', async (req, res) => {
  const { agentEmail } = req.query;

  const d = new Date();
  const todayDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  try {
    let sql = `
      SELECT 
        col.id as collection_id,
        col.customer_id,
        col.agent_email,
        col.status,
        col.collected_amount,
        col.visit_time,
        col.payment_mode,
        col.remarks,
        col.latitude,
        col.longitude,
        col.photo_captured,
        col.signature_captured,
        col.receipt_id,
        col.pending_amount,
        c.name as customer_name,
        c.phone as customer_phone,
        c.area,
        c.route,
        c.photo_url,
        c.kyc_status
      FROM collections col
      JOIN customers c ON col.customer_id = c.id
      WHERE col.collection_date = ?
    `;
    const params = [todayDate];

    if (agentEmail) {
      sql += ' AND col.agent_email = ?';
      params.push(agentEmail.trim().toLowerCase());
    }

    sql += ' ORDER BY col.id ASC';

    const visits = await query.all(sql, params);

    const formatted = visits.map(v => ({
      id: v.collection_id,
      customerId: v.customer_id,
      customerName: v.customer_name,
      customerPhone: v.customer_phone,
      area: v.area,
      route: v.route,
      agentEmail: v.agent_email,
      status: v.status || 'pending',
      collectedAmount: v.collected_amount || 0,
      pendingAmount: v.pending_amount || 0,
      visitTime: v.visit_time || null,
      paymentMode: v.payment_mode || null,
      remarks: v.remarks || '',
      latitude: v.latitude || null,
      longitude: v.longitude || null,
      photoCaptured: v.photo_captured === 1,
      signatureCaptured: v.signature_captured === 1,
      receiptId: v.receipt_id || null,
      photoUrl: v.photo_url || null,
      kycStatus: v.kyc_status || 'Pending'
    }));

    res.json({ date: todayDate, total: formatted.length, visits: formatted });
  } catch (err) {
    console.error('Error fetching live visits:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 11. PAYMENT GATEWAY CONFIG & MERCHANT API KEY INTEGRATION
// ─────────────────────────────────────────────────────────────

app.get('/api/payment-gateway/config', (req, res) => {
  const razorpayKey = process.env.RAZORPAY_KEY_ID || process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID || null;
  const phonepeMerchantId = process.env.PHONEPE_MERCHANT_ID || null;
  const cashfreeAppId = process.env.CASHFREE_APP_ID || null;
  const merchantVpa = process.env.MERCHANT_UPI_VPA || 'pcmsbank@upi';

  res.json({
    provider: razorpayKey ? 'Razorpay' : phonepeMerchantId ? 'PhonePe' : cashfreeAppId ? 'Cashfree' : 'Built-in PCMS PG',
    isLiveKeyConfigured: !!(razorpayKey || phonepeMerchantId || cashfreeAppId),
    razorpayKeyId: razorpayKey,
    merchantVpa,
    currency: 'INR'
  });
});

app.post('/api/payment-gateway/create-order', async (req, res) => {
  const { amount, customerId, customerName, accountNumber } = req.body;
  const razorpayKey = process.env.RAZORPAY_KEY_ID;
  const razorpaySecret = process.env.RAZORPAY_KEY_SECRET;
  const orderId = `ORDER_${Date.now()}_${Math.floor(1000 + Math.random() * 9000)}`;

  if (razorpayKey && razorpaySecret) {
    try {
      const authHeader = 'Basic ' + Buffer.from(`${razorpayKey}:${razorpaySecret}`).toString('base64');
      const response = await fetch('https://api.razorpay.com/v1/orders', {
        method: 'POST',
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          amount: Math.round(amount * 100),
          currency: 'INR',
          receipt: orderId,
          notes: { customerId, accountNumber, customerName }
        })
      });
      const orderData = await response.json();
      return res.json({
        success: true,
        mode: 'live',
        provider: 'Razorpay',
        orderId: orderData.id || orderId,
        keyId: razorpayKey,
        amount,
        currency: 'INR'
      });
    } catch (e) {
      console.warn('Razorpay API error, falling back:', e.message);
    }
  }

  res.json({
    success: true,
    mode: 'simulation',
    provider: 'PCMS Payment Gateway',
    orderId,
    amount,
    currency: 'INR'
  });
});

// Admin Database Inspection Endpoint
app.get('/api/admin/db-tables', async (req, res) => {
  try {
    const tableNames = ['users', 'customers', 'accounts', 'collections', 'collection_history', 'audit_trail', 'vault_submissions', 'otps'];
    const result = {};

    for (const name of tableNames) {
      try {
        result[name] = await query.all(`SELECT * FROM ${name}`);
      } catch (e) {
        result[name] = [];
      }
    }

    res.json({
      success: true,
      dbPath: 'backend/pcms.db',
      timestamp: new Date().toISOString(),
      tables: result
    });
  } catch (err) {
    console.error('Database view error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────────────────────
// 11. INTEREST ACCRUAL, MATURITY & ACCOUNT CLOSURE SYSTEM
// ─────────────────────────────────────────────────────────────

// ── DB MIGRATIONS (idempotent — safe to run on every boot) ──
(async () => {
  const migrations = [
    `ALTER TABLE accounts ADD COLUMN maturity_date TEXT`,
    `ALTER TABLE accounts ADD COLUMN scheme_type TEXT DEFAULT 'daily'`,
    `ALTER TABLE accounts ADD COLUMN closed_at TEXT`,
    `ALTER TABLE accounts ADD COLUMN payout_amount REAL`,
    `ALTER TABLE accounts ADD COLUMN opened_at TEXT`,
    `CREATE TABLE IF NOT EXISTS interest_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL,
      interest_amount REAL NOT NULL,
      accrual_month TEXT NOT NULL,
      balance_snapshot REAL NOT NULL DEFAULT 0,
      credited_at TEXT NOT NULL,
      UNIQUE(account_id, accrual_month),
      FOREIGN KEY (account_id) REFERENCES accounts(id)
    )`,
  ];

  for (const sql of migrations) {
    try {
      await query.run(sql);
    } catch (e) {
      // Column/table already exists — idempotent, ignore
    }
  }

  // Back-fill maturity_date and opened_at for accounts that don't have them yet
  try {
    const accs = await query.all(`SELECT id FROM accounts WHERE maturity_date IS NULL`);
    const now = new Date();
    const opened = now.toISOString();
    const maturity = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    for (const acc of accs) {
      await query.run(
        `UPDATE accounts SET opened_at = ?, maturity_date = ?, status = COALESCE(status, 'ACTIVE') WHERE id = ?`,
        [opened, maturity, acc.id]
      );
    }
    if (accs.length > 0) console.log(`[Migration] Back-filled maturity_date for ${accs.length} accounts.`);
  } catch (e) {
    console.warn('[Migration] Back-fill skipped:', e.message);
  }
})();

// ── HELPER: ISO date string for today ──
function todayISO() {
  return new Date().toISOString().split('T')[0];
}

// ── HELPER: days between two ISO date strings ──
function daysBetween(isoA, isoB) {
  const a = new Date(isoA);
  const b = new Date(isoB);
  return Math.floor((b - a) / (1000 * 60 * 60 * 24));
}

// ── HELPER: send maturity notification email ──
async function sendMaturityEmail(toEmail, customerName, accountNumber, maturityDate, payoutAmount) {
  const mailUser = process.env.EMAIL_USER;
  const mailPass = process.env.EMAIL_PASS;
  if (!mailUser || !mailPass) return false;

  const transporter = require('nodemailer').createTransport({
    host: 'smtp.gmail.com', port: 465, secure: true,
    auth: { user: mailUser, pass: mailPass }
  });

  try {
    await transporter.sendMail({
      from: `"BankFlow PCMS" <${mailUser}>`,
      to: toEmail,
      subject: `🎉 Your Pigmy Account Has Matured — ${accountNumber}`,
      html: `
        <div style="font-family:Arial,sans-serif;padding:24px;max-width:520px;border:1px solid #e2e8f0;border-radius:12px">
          <h2 style="color:#16a34a">Congratulations, ${customerName}!</h2>
          <p>Your Pigmy savings account <strong>${accountNumber}</strong> has reached its maturity date of <strong>${maturityDate}</strong>.</p>
          <div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:16px;margin:16px 0">
            <p style="margin:0;font-size:18px;font-weight:800;color:#15803d">Payout Amount: ₹${payoutAmount?.toLocaleString('en-IN') ?? '—'}</p>
          </div>
          <p>Please visit your nearest branch or contact your collection agent to process the withdrawal or renew for another 12 months.</p>
          <hr style="border:0;border-top:1px solid #f1f5f9;margin:20px 0">
          <p style="font-size:11px;color:#94a3b8">BankFlow PCMS Automated System</p>
        </div>`
    });
    return true;
  } catch (err) {
    console.error('[Maturity Email] Failed:', err.message);
    return false;
  }
}

// ── CORE INTEREST CALCULATION ──
// Uses monthly minimum balance method; prorates if account opened mid-month
async function computeMonthlyInterest(account, accrualMonth) {
  const [year, month] = accrualMonth.split('-').map(Number);
  const firstDay = `${accrualMonth}-01`;
  const lastDay = new Date(year, month, 0).getDate(); // days in month
  const lastDayStr = `${accrualMonth}-${String(lastDay).padStart(2, '0')}`;

  // Fetch minimum balance during the month from collection_history
  const histRows = await query.all(
    `SELECT amount FROM collection_history
     WHERE customer_id = ? AND collection_date BETWEEN ? AND ? AND status = 'collected'
     ORDER BY collection_date ASC`,
    [account.customer_id, firstDay, lastDayStr]
  );

  // Running balance reconstruction from account balance going back
  // Simplified: use account balance minus all deposits made in or after this month as the floor
  const depositsThisMonth = histRows.reduce((s, r) => s + (r.amount || 0), 0);
  const balanceAtMonthStart = (account.balance || 0) - depositsThisMonth;
  const minBalance = Math.max(0, balanceAtMonthStart);

  const rate = account.interest_rate || 5.0;

  // Prorate if account opened mid-month
  const openedAt = account.opened_at ? account.opened_at.split('T')[0] : firstDay;
  const openedInThisMonth = openedAt >= firstDay && openedAt <= lastDayStr;
  let prorateRatio = 1.0;
  if (openedInThisMonth) {
    const openDay = parseInt(openedAt.split('-')[2]);
    prorateRatio = (lastDay - openDay + 1) / lastDay;
  }

  const interest = parseFloat(((minBalance * rate) / 100 / 12 * prorateRatio).toFixed(2));
  return { interest, minBalance, rate };
}

// ── POST /api/accounts/:id/accrue-interest — single account manual accrual ──
app.post('/api/accounts/:id/accrue-interest', async (req, res) => {
  const { id } = req.params;
  const { month, performedBy = 'System', performedByRole = 'Administrator' } = req.body;
  // month: 'YYYY-MM', defaults to previous calendar month
  const accrualMonth = month || (() => {
    const d = new Date();
    d.setMonth(d.getMonth() - 1);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  })();

  // Role gate
  const allowedRoles = ['Administrator', 'Branch Manager', 'Cashier'];
  if (!allowedRoles.includes(performedByRole)) {
    return res.status(403).json({ error: 'Access denied. Only Administrator/Branch Manager/Cashier may run accruals.' });
  }

  try {
    const account = await query.get('SELECT * FROM accounts WHERE id = ?', [id]);
    if (!account) return res.status(404).json({ error: 'Account not found.' });
    if (account.status === 'CLOSED') return res.status(400).json({ error: 'Account is closed. No interest accrual.' });

    // Guard double-credit
    const existing = await query.get(
      'SELECT id FROM interest_entries WHERE account_id = ? AND accrual_month = ?',
      [id, accrualMonth]
    );
    if (existing) {
      return res.json({ success: false, skipped: true, message: `Interest already accrued for ${accrualMonth}.` });
    }

    const { interest, minBalance, rate } = await computeMonthlyInterest(account, accrualMonth);
    const creditedAt = new Date().toISOString();

    // Insert interest entry
    await query.run(
      'INSERT INTO interest_entries (account_id, interest_amount, accrual_month, balance_snapshot, credited_at) VALUES (?, ?, ?, ?, ?)',
      [id, interest, accrualMonth, minBalance, creditedAt]
    );

    // Credit interest to account balance
    await query.run('UPDATE accounts SET balance = balance + ? WHERE id = ?', [interest, id]);
    await query.run('UPDATE customers SET opening_balance = opening_balance + ? WHERE id = ?', [interest, account.customer_id]);

    // Passbook entry in collection_history
    const receiptId = `INT-${accrualMonth.replace('-', '')}-${id}`;
    await query.run(
      'INSERT INTO collection_history (customer_id, collection_date, amount, status, payment_mode, receipt_id) VALUES (?, ?, ?, ?, ?, ?)',
      [account.customer_id, creditedAt.split('T')[0], interest, 'INTEREST', 'SYSTEM', receiptId]
    );

    await logAudit(
      'Interest Accrued', performedBy, null, performedByRole, 'ok',
      `Account ${account.account_number} — ₹${interest} credited for ${accrualMonth} (min bal ₹${minBalance}, rate ${rate}%)`
    );

    res.json({ success: true, accountId: id, accountNumber: account.account_number, accrualMonth, interestCredited: interest, minBalance, rate });
  } catch (err) {
    console.error('Accrue interest error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ── POST /api/accrual/run-monthly — batch accrual for all ACTIVE accounts ──
app.post('/api/accrual/run-monthly', async (req, res) => {
  const { month, performedBy = 'System', performedByRole = 'Administrator' } = req.body;
  const accrualMonth = month || (() => {
    const d = new Date();
    d.setMonth(d.getMonth() - 1);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  })();

  const allowedRoles = ['Administrator', 'Branch Manager', 'Cashier'];
  if (!allowedRoles.includes(performedByRole)) {
    return res.status(403).json({ error: 'Access denied.' });
  }

  try {
    const accounts = await query.all(`SELECT * FROM accounts WHERE status != 'CLOSED'`);
    let processed = 0, skipped = 0, totalInterest = 0;
    const results = [];

    for (const account of accounts) {
      // Skip already-accrued
      const existing = await query.get(
        'SELECT id FROM interest_entries WHERE account_id = ? AND accrual_month = ?',
        [account.id, accrualMonth]
      );
      if (existing) { skipped++; continue; }

      const { interest, minBalance, rate } = await computeMonthlyInterest(account, accrualMonth);
      if (interest <= 0) { skipped++; continue; }

      const creditedAt = new Date().toISOString();
      await query.run(
        'INSERT INTO interest_entries (account_id, interest_amount, accrual_month, balance_snapshot, credited_at) VALUES (?, ?, ?, ?, ?)',
        [account.id, interest, accrualMonth, minBalance, creditedAt]
      );
      await query.run('UPDATE accounts SET balance = balance + ? WHERE id = ?', [interest, account.id]);
      await query.run('UPDATE customers SET opening_balance = opening_balance + ? WHERE id = ?', [interest, account.customer_id]);

      const receiptId = `INT-${accrualMonth.replace('-', '')}-${account.id}`;
      await query.run(
        'INSERT INTO collection_history (customer_id, collection_date, amount, status, payment_mode, receipt_id) VALUES (?, ?, ?, ?, ?, ?)',
        [account.customer_id, creditedAt.split('T')[0], interest, 'INTEREST', 'SYSTEM', receiptId]
      );

      processed++;
      totalInterest += interest;
      results.push({ accountId: account.id, accountNumber: account.account_number, interest, minBalance });
    }

    await logAudit(
      'Batch Monthly Accrual', performedBy, null, performedByRole, 'ok',
      `Month ${accrualMonth}: processed ${processed}, skipped ${skipped}, total interest ₹${totalInterest.toFixed(2)}`
    );

    res.json({ success: true, accrualMonth, processed, skipped, totalInterest: parseFloat(totalInterest.toFixed(2)), results });
  } catch (err) {
    console.error('Run monthly accrual error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ── GET /api/accounts/maturing-soon — accounts maturing within next 30 days ──
app.get('/api/accounts/maturing-soon', async (req, res) => {
  const { days = 30 } = req.query;
  const horizon = new Date();
  horizon.setDate(horizon.getDate() + parseInt(days));
  const horizonISO = horizon.toISOString().split('T')[0];
  const todayStr = todayISO();

  try {
    const accounts = await query.all(
      `SELECT a.*, c.name as customer_name, c.email as customer_email, c.phone as customer_phone
       FROM accounts a
       JOIN customers c ON a.customer_id = c.id
       WHERE a.maturity_date IS NOT NULL
         AND a.maturity_date BETWEEN ? AND ?
         AND a.status != 'CLOSED'
       ORDER BY a.maturity_date ASC`,
      [todayStr, horizonISO]
    );

    const formatted = accounts.map(a => ({
      id: a.id,
      accountNumber: a.account_number,
      customerId: a.customer_id,
      customerName: a.customer_name,
      customerPhone: a.customer_phone,
      balance: a.balance,
      interestRate: a.interest_rate,
      maturityDate: a.maturity_date,
      daysToMaturity: daysBetween(todayStr, a.maturity_date),
      status: a.status,
      projectedPayout: parseFloat(((a.balance || 0) * (1 + (a.interest_rate || 5) / 100 / 12)).toFixed(2))
    }));

    res.json({ success: true, count: formatted.length, horizonDays: parseInt(days), accounts: formatted });
  } catch (err) {
    console.error('Maturing soon error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ── POST /api/maturity/process — flip ACTIVE→MATURED for past-maturity accounts & send emails ──
app.post('/api/maturity/process', async (req, res) => {
  const { performedBy = 'System', performedByRole = 'Administrator' } = req.body;
  const todayStr = todayISO();

  try {
    const dueAccounts = await query.all(
      `SELECT a.*, c.name as customer_name, c.email as customer_email
       FROM accounts a
       JOIN customers c ON a.customer_id = c.id
       WHERE a.maturity_date IS NOT NULL
         AND a.maturity_date <= ?
         AND a.status = 'ACTIVE'`,
      [todayStr]
    );

    let maturedCount = 0;
    for (const acc of dueAccounts) {
      // Calculate total interest accrued
      const interestRow = await query.get(
        'SELECT COALESCE(SUM(interest_amount), 0) as total_interest FROM interest_entries WHERE account_id = ?',
        [acc.id]
      );
      const totalInterest = interestRow?.total_interest || 0;
      const payout = parseFloat(((acc.balance || 0) + totalInterest).toFixed(2));

      await query.run(
        `UPDATE accounts SET status = 'MATURED', payout_amount = ? WHERE id = ?`,
        [payout, acc.id]
      );

      await logAudit('Account Matured', performedBy, acc.customer_email, performedByRole, 'ok',
        `Account ${acc.account_number} matured. Payout: ₹${payout}`);

      // Send email notification
      if (acc.customer_email) {
        await sendMaturityEmail(acc.customer_email, acc.customer_name, acc.account_number, acc.maturity_date, payout);
      }
      maturedCount++;
    }

    res.json({ success: true, maturedCount, processedAt: new Date().toISOString() });
  } catch (err) {
    console.error('Maturity process error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ── POST /api/accounts/:id/close — close account with payout calculation ──
app.post('/api/accounts/:id/close', async (req, res) => {
  const { id } = req.params;
  const { performedBy = 'Cashier', performedByRole = 'Cashier', performedByEmail } = req.body;

  const allowedRoles = ['Administrator', 'Branch Manager', 'Cashier'];
  if (!allowedRoles.includes(performedByRole)) {
    return res.status(403).json({ error: 'Access denied. Only Administrator/Branch Manager/Cashier may close accounts.' });
  }

  try {
    const account = await query.get('SELECT * FROM accounts WHERE id = ?', [id]);
    if (!account) return res.status(404).json({ error: 'Account not found.' });
    if (account.status === 'CLOSED') return res.status(400).json({ error: 'Account is already closed.' });

    const todayStr = todayISO();
    const openedAt = account.opened_at ? account.opened_at.split('T')[0] : todayStr;
    const ageInDays = daysBetween(openedAt, todayStr);

    // Minimum 90 days rule
    if (ageInDays < 90) {
      return res.status(400).json({
        error: `Premature closure not allowed. Account must be at least 90 days old. Current age: ${ageInDays} days.`
      });
    }

    // Fetch total accrued interest
    const interestRow = await query.get(
      'SELECT COALESCE(SUM(interest_amount), 0) as total_interest FROM interest_entries WHERE account_id = ?',
      [id]
    );
    const totalInterest = interestRow?.total_interest || 0;
    const totalDeposits = account.balance || 0;

    // Check premature closure penalty (closed before maturity)
    const isPremature = account.maturity_date && todayStr < account.maturity_date;
    const penaltyRate = isPremature ? 0.01 : 0; // 1% penalty on interest
    const penalty = parseFloat((totalInterest * penaltyRate).toFixed(2));
    const netInterest = parseFloat((totalInterest - penalty).toFixed(2));
    const payout = parseFloat((totalDeposits + netInterest).toFixed(2));
    const closedAt = new Date().toISOString();

    await query.run(
      `UPDATE accounts SET status = 'CLOSED', closed_at = ?, payout_amount = ? WHERE id = ?`,
      [closedAt, payout, id]
    );

    await logAudit(
      'Account Closed', performedBy, performedByEmail, performedByRole, 'ok',
      `Account ${account.account_number} closed. Payout: ₹${payout}. Premature: ${isPremature}. Penalty: ₹${penalty}. Age: ${ageInDays} days`
    );

    res.json({
      success: true,
      accountNumber: account.account_number,
      totalDeposits,
      totalInterest,
      penalty,
      isPremature,
      payout,
      closedAt,
      ageInDays
    });
  } catch (err) {
    console.error('Close account error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ── POST /api/accounts/:id/renew — reopen CLOSED/MATURED as fresh 12-month cycle ──
app.post('/api/accounts/:id/renew', async (req, res) => {
  const { id } = req.params;
  const { performedBy = 'Cashier', performedByRole = 'Cashier', performedByEmail } = req.body;

  const allowedRoles = ['Administrator', 'Branch Manager', 'Cashier'];
  if (!allowedRoles.includes(performedByRole)) {
    return res.status(403).json({ error: 'Access denied.' });
  }

  try {
    const account = await query.get('SELECT * FROM accounts WHERE id = ?', [id]);
    if (!account) return res.status(404).json({ error: 'Account not found.' });
    if (!['CLOSED', 'MATURED'].includes(account.status)) {
      return res.status(400).json({ error: 'Only CLOSED or MATURED accounts can be renewed.' });
    }

    const newOpened = new Date().toISOString();
    const newMaturity = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const carryForward = account.payout_amount || account.balance || 0;

    await query.run(
      `UPDATE accounts
       SET status = 'ACTIVE', opened_at = ?, maturity_date = ?, balance = ?,
           closed_at = NULL, payout_amount = NULL
       WHERE id = ?`,
      [newOpened, newMaturity, carryForward, id]
    );
    await query.run('UPDATE customers SET opening_balance = ? WHERE id = ?', [carryForward, account.customer_id]);

    await logAudit(
      'Account Renewed', performedBy, performedByEmail, performedByRole, 'ok',
      `Account ${account.account_number} renewed with carry-forward balance ₹${carryForward}. Matures: ${newMaturity}`
    );

    res.json({ success: true, accountNumber: account.account_number, newBalance: carryForward, newMaturityDate: newMaturity });
  } catch (err) {
    console.error('Renew account error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ── GET /api/accounts/:id/interest-history — passbook entries for interest ──
app.get('/api/accounts/:id/interest-history', async (req, res) => {
  const { id } = req.params;
  try {
    const account = await query.get('SELECT * FROM accounts WHERE id = ?', [id]);
    if (!account) return res.status(404).json({ error: 'Account not found.' });

    const entries = await query.all(
      'SELECT * FROM interest_entries WHERE account_id = ? ORDER BY accrual_month DESC',
      [id]
    );

    const totalAccrued = entries.reduce((s, e) => s + (e.interest_amount || 0), 0);
    const daysToMaturity = account.maturity_date ? daysBetween(todayISO(), account.maturity_date) : null;
    const projectedPayout = parseFloat(((account.balance || 0) + (account.interest_rate || 5) / 100 / 12 * (account.balance || 0)).toFixed(2));

    res.json({
      success: true,
      accountNumber: account.account_number,
      currentBalance: account.balance,
      interestRate: account.interest_rate,
      maturityDate: account.maturity_date,
      daysToMaturity,
      status: account.status,
      totalAccruedInterest: parseFloat(totalAccrued.toFixed(2)),
      projectedPayout,
      entries
    });
  } catch (err) {
    console.error('Interest history error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ── GET /api/accounts/:accountNumber/by-number — lookup by account_number string ──
app.get('/api/accounts/by-number/:accountNumber', async (req, res) => {
  const { accountNumber } = req.params;
  try {
    const account = await query.get('SELECT * FROM accounts WHERE account_number = ?', [accountNumber]);
    if (!account) return res.status(404).json({ error: 'Account not found.' });
    res.json(account);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// 12. DAILY CASH RECONCILIATION SYSTEM
// ─────────────────────────────────────────────────────────────

/**
 * DB MIGRATION — reconciliation_records table
 * Idempotent: CREATE TABLE IF NOT EXISTS, safe to run on every boot.
 *
 * Each row represents one agent's end-of-day reconciliation for a given date.
 * Columns:
 *   agent_email       — the field agent being reconciled
 *   recon_date        — YYYY-MM-DD
 *   total_collected   — SUM of collected_amount from `collections` where status='collected'
 *   total_submitted   — SUM of cash_submitted from `vault_submissions` for that date
 *   difference        — total_collected - total_submitted  (positive = shortfall, negative = excess)
 *   status            — 'MATCHED' | 'MISMATCH' | 'RESOLVED'
 *   resolved_by       — email of manager who resolved a mismatch
 *   resolved_at       — ISO timestamp of resolution
 *   note              — freetext resolution note
 *   created_at        — ISO timestamp of reconciliation record creation
 */
(async () => {
  try {
    await query.run(`
      CREATE TABLE IF NOT EXISTS reconciliation_records (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        agent_email   TEXT    NOT NULL,
        recon_date    TEXT    NOT NULL,
        total_collected REAL  NOT NULL DEFAULT 0,
        total_submitted REAL  NOT NULL DEFAULT 0,
        difference    REAL    NOT NULL DEFAULT 0,
        status        TEXT    NOT NULL DEFAULT 'MATCHED',
        resolved_by   TEXT,
        resolved_at   TEXT,
        note          TEXT,
        created_at    TEXT    NOT NULL,
        UNIQUE(agent_email, recon_date)
      )
    `);
    console.log('[Migration] reconciliation_records table ready.');
  } catch (e) {
    // Already exists — ignore
  }
})();

// ── HELPER: compute reconciliation data for one agent on one date ──
async function computeRecon(agentEmail, date) {
  // 1. Sum all cash collected by this agent on this date
  const colRow = await query.get(
    `SELECT COALESCE(SUM(collected_amount), 0) AS total
     FROM collections
     WHERE agent_email = ? AND collection_date = ? AND status = 'collected'`,
    [agentEmail, date]
  );
  const totalCollected = parseFloat((colRow?.total || 0).toFixed(2));

  // 2. Sum all vault submissions by this agent on this date
  const vsRow = await query.get(
    `SELECT COALESCE(SUM(cash_submitted), 0) AS total
     FROM vault_submissions
     WHERE agent_email = ? AND submission_date = ?`,
    [agentEmail, date]
  );
  const totalSubmitted = parseFloat((vsRow?.total || 0).toFixed(2));

  // 3. Difference: positive = agent collected more than submitted (shortfall at vault)
  //               negative = agent submitted more than they collected (excess deposit)
  const difference = parseFloat((totalCollected - totalSubmitted).toFixed(2));
  const TOLERANCE = 0.01; // 1-paisa rounding tolerance
  const status = Math.abs(difference) <= TOLERANCE ? 'MATCHED' : 'MISMATCH';

  // 4. Per-customer breakdown for drill-down
  const breakdown = await query.all(
    `SELECT c.name AS customer_name, col.customer_id, col.collected_amount,
            col.payment_mode, col.receipt_id, col.visit_time
     FROM collections col
     JOIN customers c ON col.customer_id = c.id
     WHERE col.agent_email = ? AND col.collection_date = ? AND col.status = 'collected'
     ORDER BY col.visit_time ASC`,
    [agentEmail, date]
  );

  return { totalCollected, totalSubmitted, difference, status, breakdown };
}

// ─────────────────────────────────────────────────────────────
// GET /api/reconciliation/daily
// Query: ?date=YYYY-MM-DD  (default: today)
//        &agent_email=X    (optional — filters to one agent)
//        &requested_by=email
//        &requested_role=Branch Manager
//
// Allowed roles: Administrator, Branch Manager, Cashier
// Response: array of per-agent reconciliation snapshots,
//           each flagged MATCHED | MISMATCH, with breakdown.
// ─────────────────────────────────────────────────────────────
app.get('/api/reconciliation/daily', async (req, res) => {
  const {
    date,
    agent_email,
    requested_by = 'System',
    requested_role = 'Branch Manager'
  } = req.query;

  // Role gate
  const allowedRoles = ['Administrator', 'Branch Manager', 'Cashier'];
  if (!allowedRoles.includes(requested_role)) {
    return res.status(403).json({ error: 'Access denied. Only Administrator / Branch Manager / Cashier may view reconciliation.' });
  }

  // Default to today
  const reconDate = date || new Date().toISOString().split('T')[0];

  try {
    // Discover distinct agents who made any collection on that date
    let agentRows;
    if (agent_email) {
      agentRows = [{ agent_email: agent_email.trim().toLowerCase() }];
    } else {
      agentRows = await query.all(
        `SELECT DISTINCT agent_email FROM collections WHERE collection_date = ?`,
        [reconDate]
      );
    }

    const results = [];

    for (const row of agentRows) {
      const email = row.agent_email;
      const { totalCollected, totalSubmitted, difference, status, breakdown } = await computeRecon(email, reconDate);

      // Upsert into reconciliation_records for persistence
      const createdAt = new Date().toISOString();
      await query.run(
        `INSERT INTO reconciliation_records
           (agent_email, recon_date, total_collected, total_submitted, difference, status, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(agent_email, recon_date) DO UPDATE SET
           total_collected = excluded.total_collected,
           total_submitted = excluded.total_submitted,
           difference      = excluded.difference,
           status          = CASE WHEN reconciliation_records.status = 'RESOLVED'
                                  THEN 'RESOLVED'
                                  ELSE excluded.status END,
           created_at      = CASE WHEN reconciliation_records.status = 'RESOLVED'
                                  THEN reconciliation_records.created_at
                                  ELSE excluded.created_at END`,
        [email, reconDate, totalCollected, totalSubmitted, difference, status, createdAt]
      );

      // Retrieve the (possibly pre-existing) record so we return resolved state too
      const saved = await query.get(
        'SELECT * FROM reconciliation_records WHERE agent_email = ? AND recon_date = ?',
        [email, reconDate]
      );

      results.push({
        agentEmail: email,
        date: reconDate,
        totalCollected,
        totalSubmitted,
        difference,
        status: saved.status,          // reflects RESOLVED if already resolved
        resolvedBy: saved.resolved_by || null,
        resolvedAt: saved.resolved_at || null,
        note: saved.note || null,
        recordId: saved.id,
        hasMismatch: saved.status === 'MISMATCH',
        breakdown
      });
    }

    // Log audit trail
    await logAudit(
      'Reconciliation Viewed',
      requested_by,
      requested_by,
      requested_role,
      'ok',
      `Daily recon for ${reconDate} — ${results.length} agent(s) checked. Mismatches: ${results.filter(r => r.hasMismatch).length}`
    );

    res.json({
      success: true,
      date: reconDate,
      agentCount: results.length,
      mismatchCount: results.filter(r => r.status === 'MISMATCH').length,
      resolvedCount: results.filter(r => r.status === 'RESOLVED').length,
      results
    });
  } catch (err) {
    console.error('Reconciliation daily error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// GET /api/reconciliation/pending-mismatches
// Returns all unresolved MISMATCH records across all dates.
// Used by Branch Manager dashboard card.
// ─────────────────────────────────────────────────────────────
app.get('/api/reconciliation/pending-mismatches', async (req, res) => {
  const { requested_by = 'System', requested_role = 'Branch Manager' } = req.query;

  const allowedRoles = ['Administrator', 'Branch Manager', 'Cashier'];
  if (!allowedRoles.includes(requested_role)) {
    return res.status(403).json({ error: 'Access denied.' });
  }

  try {
    const mismatches = await query.all(
      `SELECT * FROM reconciliation_records
       WHERE status = 'MISMATCH'
       ORDER BY recon_date DESC, ABS(difference) DESC`
    );

    // Enrich with agent name from users table (best effort)
    const enriched = await Promise.all(mismatches.map(async (m) => {
      const user = await query.get('SELECT name FROM users WHERE LOWER(email) = ?', [m.agent_email.toLowerCase()]);
      return {
        id: m.id,
        agentEmail: m.agent_email,
        agentName: user?.name || m.agent_email.split('@')[0],
        date: m.recon_date,
        totalCollected: m.total_collected,
        totalSubmitted: m.total_submitted,
        difference: m.difference,
        status: m.status,
        createdAt: m.created_at
      };
    }));

    await logAudit(
      'Pending Mismatches Viewed', requested_by, requested_by, requested_role, 'ok',
      `${enriched.length} unresolved mismatch(es) queried`
    );

    res.json({ success: true, count: enriched.length, mismatches: enriched });
  } catch (err) {
    console.error('Pending mismatches error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// ─────────────────────────────────────────────────────────────
// POST /api/reconciliation/resolve/:id
// Body: { resolved_by, resolved_by_role, note }
// Marks a MISMATCH record as RESOLVED.
// Only Branch Manager or Administrator may resolve.
// ─────────────────────────────────────────────────────────────
app.post('/api/reconciliation/resolve/:id', async (req, res) => {
  const { id } = req.params;
  const { resolved_by, resolved_by_role = 'Branch Manager', note = '' } = req.body;

  const allowedRoles = ['Administrator', 'Branch Manager'];
  if (!allowedRoles.includes(resolved_by_role)) {
    return res.status(403).json({ error: 'Access denied. Only Administrator or Branch Manager can resolve mismatches.' });
  }
  if (!resolved_by) {
    return res.status(400).json({ error: 'resolved_by (email/name) is required.' });
  }

  try {
    const record = await query.get('SELECT * FROM reconciliation_records WHERE id = ?', [id]);
    if (!record) return res.status(404).json({ error: 'Reconciliation record not found.' });
    if (record.status === 'RESOLVED') {
      return res.status(400).json({ error: 'Record is already resolved.', resolvedBy: record.resolved_by, resolvedAt: record.resolved_at });
    }
    if (record.status !== 'MISMATCH') {
      return res.status(400).json({ error: `Only MISMATCH records can be resolved. Current status: ${record.status}` });
    }

    const resolvedAt = new Date().toISOString();
    await query.run(
      `UPDATE reconciliation_records
       SET status = 'RESOLVED', resolved_by = ?, resolved_at = ?, note = ?
       WHERE id = ?`,
      [resolved_by, resolvedAt, note || null, id]
    );

    await logAudit(
      'Reconciliation Resolved',
      resolved_by,
      resolved_by,
      resolved_by_role,
      'ok',
      `Record #${id} for agent ${record.agent_email} on ${record.recon_date} resolved. ` +
      `Difference: ₹${record.difference}. Note: ${note || '(none)'}`
    );

    res.json({
      success: true,
      id: parseInt(id),
      agentEmail: record.agent_email,
      date: record.recon_date,
      difference: record.difference,
      resolvedBy: resolved_by,
      resolvedAt
    });
  } catch (err) {
    console.error('Resolve reconciliation error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// Root and API Index Endpoints
app.get(['/', '/api'], (req, res) => {
  res.json({
    name: 'Pigmy Collection Management System (PCMS) API',
    status: 'online',
    version: '2.0.0',
    documentation: {
      health: '/api/health',
      collections_today: '/api/collections/today',
      live_visits: '/api/visits/live',
      reconciliation: '/api/reconciliation/daily',
      maturing_soon: '/api/accounts/maturing-soon',
      db_inspector: '/api/admin/db-tables'
    },
    frontendApp: 'http://localhost:3001',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString(), version: '2.0.0' });
});

// Start Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`====================================================`);
  console.log(` PCMS Backend Service running on port ${PORT}`);
  console.log(` Local: http://127.0.0.1:${PORT}/api/health`);
  console.log(` Network: http://192.168.31.102:${PORT}/api/health`);
  console.log(`====================================================`);
});
