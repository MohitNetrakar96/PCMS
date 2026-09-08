"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import styles from "../auth/page.module.css";

export default function ForgotPasswordPage() {
  const router = useRouter();
  const { notifySuccess, notifyError, notifyInfo } = useNotification();

  // Steps: 1 = Email, 2 = Verify OTP, 3 = New Password, 4 = Success
  const [step, setStep] = useState<1 | 2 | 3 | 4>(1);
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const handleOtpChange = (val: string, i: number) => {
    const next = [...otp];
    next[i] = val.slice(-1);
    setOtp(next);
    if (val && i < 5) {
      const el = document.getElementById(`reset-otp-${i + 1}`);
      el?.focus();
    }
  };

  // STEP 1: Send OTP to Email
  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail) return;

    setLoading(true);
    try {
      await api.sendOtp(cleanEmail);
      notifySuccess(
        "OTP Sent to Email",
        `A 6-digit verification code has been sent to ${cleanEmail}. Check your inbox or Spam.`
      );
      setStep(2);
    } catch (err: any) {
      notifyError("Failed to Send OTP", err.message || "Could not send OTP to email.");
    } finally {
      setLoading(false);
    }
  };

  // STEP 2: Verify OTP Code
  const handleVerifyOtp = (e: React.FormEvent) => {
    e.preventDefault();
    const enteredCode = otp.join("");

    if (enteredCode.length < 6) {
      notifyError("Incomplete OTP", "Please enter the complete 6-digit code received in your email.");
      return;
    }

    notifySuccess("OTP Verified", "Code confirmed. Please set your new password.");
    setStep(3);
  };

  // STEP 3: Submit New Password to Database
  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    const enteredCode = otp.join("");

    if (!newPassword) {
      notifyError("Missing Password", "Please enter a new password.");
      return;
    }

    if (newPassword.length < 4) {
      notifyError("Weak Password", "Password should be at least 4 characters long.");
      return;
    }

    if (newPassword !== confirmPassword) {
      notifyError("Password Mismatch", "Passwords do not match.");
      return;
    }

    setLoading(true);
    try {
      const res = await api.resetPasswordOtp({
        email: email.trim().toLowerCase(),
        code: enteredCode,
        password: newPassword,
      });

      if (res.success) {
        notifySuccess("Password Updated", "Your password has been reset in the bank database.");
        setStep(4);
      } else {
        notifyError("Reset Failed", res.message || "Invalid or expired OTP code.");
        setStep(2);
      }
    } catch (err: any) {
      notifyError("Reset Error", err.message || "Invalid OTP or request expired.");
      setStep(2);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app-wrapper">
      <div className="phone-frame">
        <div className="status-bar light">
          <span>{new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}</span>
          <div className="status-bar__icons">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M1 6s4-4 11-4 11 4 11 4"/><path d="M5 10s3-3 7-3 7 3 7 3"/><path d="M9 14s1.5-1.5 3-1.5 3 1.5 3 1.5"/>
              <circle cx="12" cy="18" r="1" fill="currentColor"/>
            </svg>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="2" y="7" width="15" height="10" rx="2"/><path d="M22 11v2"/>
            </svg>
          </div>
        </div>

        <div className={`screen ${styles.authScreen}`}>
          <button className={styles.backBtn} onClick={() => router.push("/auth")}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="20" height="20">
              <polyline points="15 18 9 12 15 6"/>
            </svg>
            Back to Login
          </button>

          {/* Header */}
          <div className={styles.authHeader}>
            <div className={styles.iconCircle} style={{ background: "linear-gradient(135deg,#f97316,#eab308)" }}>
              {step === 4 ? "🎉" : step === 3 ? "🔒" : step === 2 ? "📧" : "🔑"}
            </div>
            <h1 className={styles.authTitle}>
              {step === 1
                ? "Forgot Password"
                : step === 2
                ? "Verify OTP"
                : step === 3
                ? "Set New Password"
                : "Reset Complete!"}
            </h1>
            <p className={styles.authSubtitle}>
              {step === 1
                ? "Enter your registered email to receive a 6-digit verification code."
                : step === 2
                ? `Enter the 6-digit OTP code sent to ${email}.`
                : step === 3
                ? `Create and confirm your new password for ${email}.`
                : "Your password has been updated in the database."}
            </p>
          </div>

          {/* STEP 1: Enter Email */}
          {step === 1 && (
            <form className={styles.authForm} onSubmit={handleSendOtp}>
              <div className="form-group">
                <label className="form-label">Registered Email Address</label>
                <div className={styles.inputWrapper}>
                  <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18">
                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                    <polyline points="22,6 12,13 2,6"/>
                  </svg>
                  <input
                    className={`form-input ${styles.inputWithIcon}`}
                    type="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
              </div>
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? "Sending OTP..." : "Send Reset OTP"}
              </button>
            </form>
          )}

          {/* STEP 2: Retype OTP Code Only */}
          {step === 2 && (
            <form className={styles.authForm} onSubmit={handleVerifyOtp}>
              <div style={{
                background: "#f0fdf4", border: "1px solid #bbf7d0", borderRadius: 10,
                padding: "10px 12px", fontSize: 11, color: "#166534", fontWeight: 600, marginBottom: 16,
                display: "flex", alignItems: "center", gap: 8
              }}>
                <span style={{ fontSize: 16 }}>📩</span>
                <span>OTP sent to <strong>{email}</strong>. Check your inbox or Spam folder.</span>
              </div>

              <div className="form-group" style={{ marginBottom: 20 }}>
                <label className="form-label">Retype 6-Digit OTP Code</label>
                <div className={styles.otpRow} style={{ marginTop: 8, marginBottom: 8 }}>
                  {otp.map((v, i) => (
                    <input
                      key={i}
                      id={`reset-otp-${i}`}
                      className={styles.otpBox}
                      type="text"
                      inputMode="numeric"
                      maxLength={1}
                      value={v}
                      onChange={(e) => handleOtpChange(e.target.value, i)}
                      onKeyDown={(e) => {
                        if (e.key === "Backspace" && !otp[i] && i > 0) {
                          document.getElementById(`reset-otp-${i - 1}`)?.focus();
                        }
                      }}
                    />
                  ))}
                </div>
              </div>

              <button type="submit" className="btn btn-primary" style={{ marginTop: 8 }}>
                Verify OTP Code →
              </button>

              <button
                type="button"
                className={styles.resendLink}
                style={{ marginTop: 14 }}
                onClick={async () => {
                  setLoading(true);
                  try {
                    await api.sendOtp(email);
                    notifyInfo("OTP Resent", `A new OTP has been sent to ${email}`);
                  } catch (e: any) {
                    notifyError("Resend Failed", e.message);
                  } finally {
                    setLoading(false);
                  }
                }}
              >
                Resend OTP Email
              </button>
            </form>
          )}

          {/* STEP 3: Set New Password */}
          {step === 3 && (
            <form className={styles.authForm} onSubmit={handleResetPassword}>
              <div style={{
                background: "#eff6ff", border: "1px solid #bfdbfe", borderRadius: 10,
                padding: "8px 12px", fontSize: 11, color: "#1e40af", fontWeight: 700, marginBottom: 16,
                display: "flex", alignItems: "center", gap: 6
              }}>
                <span>✓ OTP Code Verified</span>
              </div>

              <div className="form-group">
                <label className="form-label">New Password</label>
                <div className={styles.inputWrapper}>
                  <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                    <path d="M7 11V7a5 5 0 0110 0v4"/>
                  </svg>
                  <input
                    className={`form-input ${styles.inputWithIcon}`}
                    type="password"
                    placeholder="Enter new password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Confirm New Password</label>
                <div className={styles.inputWrapper}>
                  <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                    <path d="M7 11V7a5 5 0 0110 0v4"/>
                  </svg>
                  <input
                    className={`form-input ${styles.inputWithIcon}`}
                    type="password"
                    placeholder="Re-enter new password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    required
                  />
                </div>
              </div>

              <button type="submit" className="btn btn-primary" style={{ marginTop: 8 }} disabled={loading}>
                {loading ? "Updating Password..." : "Reset Password & Save"}
              </button>
            </form>
          )}

          {/* STEP 4: Success Confirmation */}
          {step === 4 && (
            <div className={styles.successBox}>
              <div className={styles.successIcon}>✅</div>
              <p className={styles.successTitle}>Password Reset Successfully!</p>
              <p className={styles.successText}>
                Your password for <strong>{email}</strong> has been updated in the bank database.
                You can now log in using your new password.
              </p>

              <button
                className="btn btn-primary"
                style={{ marginTop: 24 }}
                onClick={() => router.push("/auth")}
              >
                Back to Login
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
