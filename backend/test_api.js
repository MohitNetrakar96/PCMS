const http = require('http');

async function request(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    req.on('error', reject);
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('--- STARTING PCMS BACKEND ENDPOINT VERIFICATION ---');

  // 1. Health check
  console.log('\n[1] Testing GET /api/health');
  const health = await request({ host: 'localhost', port: 3000, path: '/api/health', method: 'GET' });
  console.log('Health response:', health.data);

  // 2. Login as Collection Agent
  console.log('\n[2] Testing POST /api/auth/login');
  const login = await request(
    { host: 'localhost', port: 3000, path: '/api/auth/login', method: 'POST', headers: { 'Content-Type': 'application/json' } },
    { email: 'agent@bankflow.com', password: 'password', expectedRole: 'Collection Agent' }
  );
  console.log('Login status:', login.status, 'Success:', login.data?.success, 'User:', login.data?.user?.email);

  // 3. Send OTP
  console.log('\n[3] Testing POST /api/auth/send-otp');
  const otpRes = await request(
    { host: 'localhost', port: 3000, path: '/api/auth/send-otp', method: 'POST', headers: { 'Content-Type': 'application/json' } },
    { email: 'agent@bankflow.com' }
  );
  console.log('OTP Result:', otpRes.data);

  // 4. Verify OTP
  console.log('\n[4] Testing POST /api/auth/verify-otp');
  const verifyRes = await request(
    { host: 'localhost', port: 3000, path: '/api/auth/verify-otp', method: 'POST', headers: { 'Content-Type': 'application/json' } },
    { email: 'agent@bankflow.com', code: otpRes.data?.otp, expectedRole: 'Collection Agent' }
  );
  console.log('OTP Verify Status:', verifyRes.status, 'User:', verifyRes.data?.user?.email);

  // 5. Fetch Today's Collections Schedule
  console.log('\n[5] Testing GET /api/collections/today');
  const collRes = await request({ host: 'localhost', port: 3000, path: '/api/collections/today?email=agent@bankflow.com', method: 'GET' });
  console.log('Fetched today collections count:', Array.isArray(collRes.data) ? collRes.data.length : collRes.data);

  // 6. Record a Collection
  console.log('\n[6] Testing POST /api/collections/record');
  const recordRes = await request(
    { host: 'localhost', port: 3000, path: '/api/collections/record', method: 'POST', headers: { 'Content-Type': 'application/json' } },
    { customerId: 'CUST-101', agentEmail: 'agent@bankflow.com', status: 'collected', collectedAmount: 500, paymentMode: 'CASH' }
  );
  console.log('Record Collection:', recordRes.data);

  // 7. Route Optimization
  console.log('\n[7] Testing GET /api/routes/optimize');
  const routeRes = await request({ host: 'localhost', port: 3000, path: '/api/routes/optimize?email=agent@bankflow.com', method: 'GET' });
  console.log('Route Summary:', routeRes.data?.routeSummary, 'Pending stops:', routeRes.data?.pendingCount);

  // 8. Accounts & Passbooks
  console.log('\n[8] Testing GET /api/accounts/passbooks');
  const accRes = await request({ host: 'localhost', port: 3000, path: '/api/accounts/passbooks', method: 'GET' });
  console.log('Passbook Accounts Count:', accRes.data?.accounts?.length);

  // 9. Vault Handover Submission
  console.log('\n[9] Testing POST /api/vault/submit');
  const vaultRes = await request(
    { host: 'localhost', port: 3000, path: '/api/vault/submit', method: 'POST', headers: { 'Content-Type': 'application/json' } },
    { agentEmail: 'agent@bankflow.com', cashSubmitted: 500, expectedCash: 500 }
  );
  console.log('Vault Submit Result:', vaultRes.data);

  // 10. Dashboard Analytics
  console.log('\n[10] Testing GET /api/analytics/dashboard');
  const dashRes = await request({ host: 'localhost', port: 3000, path: '/api/analytics/dashboard?email=agent@bankflow.com', method: 'GET' });
  console.log('Dashboard Analytics Target:', dashRes.data?.totalTarget, 'Collected:', dashRes.data?.totalCollected);

  console.log('\n--- ALL BACKEND TEST CALLS FINISHED SUCCESSFULLY ---');
  process.exit(0);
}

runTests().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
