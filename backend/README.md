# PCMS Backend SMS Configurations

This server supports routing OTP verification codes directly to real mobile phones using two methods:

---

## Method 1: Textbelt (Zero Setup, 1 Free SMS/day)
The server is integrated with **Textbelt**, a public SMS gateway. 
* It requires **no API keys** or configuration files.
* **Limitation**: The free tier restricts messages to **1 SMS per day per IP address**.
* **Usage**: If you request an OTP code, Textbelt will route a real SMS to your phone. If the 1-message limit is reached, it returns a status showing the limit was reached and defaults to showing the mock OTP in the app alert popup.

---

## Method 2: Twilio (Unlimited Free Trial Messages)
For unlimited testing on your mobile number:
1. Create a free account at **[Twilio.com](https://www.twilio.com)**.
2. In the Twilio Console, copy your **Account SID**, **Auth Token**, and buy/generate a free **Twilio Phone Number**.
3. Register and verify your phone number under the **Verified Caller IDs** section in the Twilio dashboard (trial accounts can only send SMS to verified numbers).
4. Set the following environment variables in your terminal before starting the server (or write them into a `.env` file in this directory):
   ```bash
   TWILIO_ACCOUNT_SID="your_account_sid"
   TWILIO_AUTH_TOKEN="your_auth_token"
   TWILIO_PHONE_NUMBER="your_twilio_number"
   ```
5. Restart the server: `node server.js`.
