"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import styles from "./page.module.css";

const ROLES = ["Administrator", "Branch Manager", "Cashier", "Collection Agent", "Customer", "Auditor"];

export default function AuthPage() {
  const router = useRouter();
  const { notifySuccess, notifyError, notifyInfo } = useNotification();
  const [tab, setTab] = useState<"email" | "otp">("email");
  const [step, setStep] = useState<"login" | "otp" | "forgot" | "register">("login");
  const [role, setRole] = useState("Collection Agent");
  const [email, setEmail] = useState("");
  const [name, setName] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const [forgotEmail, setForgotEmail] = useState("");
  const [forgotSent, setForgotSent] = useState(false);
  const [lastOtp, setLastOtp] = useState<string | null>(null);
  const [registerSuccess, setRegisterSuccess] = useState(false);
  const [showRole, setShowRole] = useState(false);
  const [alertMsg, setAlertMsg] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleOtpChange = (val: string, i: number) => {
    const next = [...otp];
    next[i] = val.slice(-1);
    setOtp(next);
    if (val && i < 5) {
      const el = document.getElementById(`otp-${i + 1}`);
      el?.focus();
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanEmail = email.trim().toLowerCase();
    setLoading(true);

    if (tab === "otp" && step === "login") {
      try {
        const otpRes = await api.sendOtp(cleanEmail);
        const codeMsg = otpRes.otp ? ` (Code: ${otpRes.otp})` : "";
        setLastOtp(otpRes.otp || null);
        notifyInfo("OTP Generated", `Verification code sent to ${cleanEmail}${codeMsg}`);
        setStep("otp");
      } catch (err: any) {
        notifyError("OTP Failed", err.message || "Failed to send OTP.");
      } finally {
        setLoading(false);
      }
      return;
    }

    try {
      const res = await api.login({ email: cleanEmail, password });
      if (res.success && res.user) {
        localStorage.setItem("pcms_session_name", res.user.name);
        localStorage.setItem("pcms_session_role", res.user.role);
        localStorage.setItem("pcms_session_email", res.user.email);
        notifySuccess("Login Successful", `Welcome back, ${res.user.name}!`);
        if (res.user.role === "Customer") {
          router.push("/customer-portal");
        } else {
          router.push("/dashboard");
        }
      } else {
        notifyError("Authentication Failed", "Please check your credentials.");
      }
    } catch (err: any) {
      notifyError("Login Failed", err.message || "Please check credentials.");
    } finally {
      setLoading(false);
    }
  };

  const handleOtpVerify = async () => {
    const cleanEmail = email.trim().toLowerCase();
    const enteredCode = otp.join("");
    if (enteredCode.length < 4) {
      notifyError("Incomplete OTP", "Please enter the complete verification code.");
      return;
    }

    setLoading(true);
    try {
      const res = await api.verifyOtp({ email: cleanEmail, code: enteredCode, expectedRole: role });
      if (res.success && res.user) {
        localStorage.setItem("pcms_session_name", res.user.name);
        localStorage.setItem("pcms_session_role", res.user.role);
        localStorage.setItem("pcms_session_email", res.user.email);
        notifySuccess("OTP Verified", `Authenticated as ${res.user.name}`);
        if (res.user.role === "Customer") {
          router.push("/customer-portal");
        } else {
          router.push("/dashboard");
        }
      } else {
        notifyError("Verification Failed", "Invalid verification code.");
      }
    } catch (err: any) {
      notifyError("Verification Error", err.message || "Invalid or expired OTP code.");
    } finally {
      setLoading(false);
    }
  };

  const handleForgot = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.sendOtp(forgotEmail.trim());
      notifySuccess("Reset Link Sent", `Password reset instructions sent to ${forgotEmail}`);
      setForgotSent(true);
    } catch (err: any) {
      notifyError("Reset Error", err.message || "Failed to send reset code.");
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== confirmPassword) {
      notifyError("Password Mismatch", "Passwords do not match.");
      return;
    }
    setLoading(true);
    try {
      const res = await api.register({
        name,
        email: email.trim().toLowerCase(),
        password,
        role
      });
      if (res.success) {
        notifySuccess("Account Created", "Your staff profile is active. Please log in.");
        setRegisterSuccess(true);
      } else {
        notifyError("Registration Failed", "Could not complete registration.");
      }
    } catch (err: any) {
      notifyError("Registration Error", err.message || "An error occurred.");
    } finally {
      setLoading(false);
    }
  };

  // ── Forgot Password Redirect ──
  if (step === "forgot") {
    router.push("/forgot-password");
    return null;
  }

  // ── OTP Step ──
  if (step === "otp") {
    return (
      <div className="app-wrapper">
        <div className="phone-frame">
          <div className="status-bar light"><span>10:30 AM</span><div className="status-bar__icons"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 6s4-4 11-4 11 4 11 4"/><path d="M5 10s3-3 7-3 7 3 7 3"/><path d="M9 14s1.5-1.5 3-1.5 3 1.5 3 1.5"/><circle cx="12" cy="18" r="1" fill="currentColor"/></svg><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="15" height="10" rx="2"/><path d="M22 11v2"/></svg></div></div>
          <div className={`screen ${styles.authScreen}`}>
            <button className={styles.backBtn} onClick={() => setStep("login")}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="20" height="20"><polyline points="15 18 9 12 15 6"/></svg>
              Back
            </button>
            <div className={`${styles.authHeader} fade-in-up`}>
              <div className={styles.iconCircle} style={{ background: "linear-gradient(135deg,#2563eb,#06b6d4)" }}>📧</div>
              <h1 className={styles.authTitle}>Verify OTP</h1>
              <p className={styles.authSubtitle}>A 6-digit OTP has been sent to<br /><strong>{email}</strong></p>
            </div>
            <div className={`${styles.otpRow} fade-in-up fade-in-up-1`}>
              {otp.map((v, i) => (
                <input key={i} id={`otp-${i}`} className={styles.otpBox} type="text" inputMode="numeric" maxLength={1} value={v}
                  onChange={(e) => handleOtpChange(e.target.value, i)}
                  onKeyDown={(e) => { if (e.key === "Backspace" && !otp[i] && i > 0) document.getElementById(`otp-${i - 1}`)?.focus(); }}
                />
              ))}
            </div>
            <div className={`${styles.authForm} fade-in-up fade-in-up-2`}>
              <button className="btn btn-primary" onClick={handleOtpVerify}>Verify & Login</button>
              <button className={styles.resendLink}>Resend OTP in 30s</button>
            </div>
            {alertMsg && (
              <div className={styles.alertOverlay} onClick={() => setAlertMsg(null)}>
                <div className={styles.alertBox} onClick={(e) => e.stopPropagation()}>
                  <div className={styles.alertIconWrapper}>⚠️</div>
                  <h3 className={styles.alertHeaderTitle}>Notification</h3>
                  <p className={styles.alertText}>{alertMsg}</p>
                  <button type="button" className={styles.alertOkBtn} onClick={() => setAlertMsg(null)}>OK</button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  // ── Register Screen ──
  if (step === "register") {
    return (
      <div className="app-wrapper">
        <div className="phone-frame">
          <div className="status-bar light">
            <span>10:30 AM</span>
            <div className="status-bar__icons">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 6s4-4 11-4 11 4 11 4"/><path d="M5 10s3-3 7-3 7 3 7 3"/><path d="M9 14s1.5-1.5 3-1.5 3 1.5 3 1.5"/><circle cx="12" cy="18" r="1" fill="currentColor"/></svg>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="15" height="10" rx="2"/><path d="M22 11v2"/></svg>
            </div>
          </div>
          <div className={`screen ${styles.authScreen}`}>
            <button className={styles.backBtn} onClick={() => { setStep("login"); setRegisterSuccess(false); }}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="20" height="20"><polyline points="15 18 9 12 15 6"/></svg>
              Back to Login
            </button>
            <div className={`${styles.authHeader} fade-in-up`}>
              <div className={styles.iconCircle} style={{ background: "linear-gradient(135deg,#7c3aed,#ec4899)" }}>👤</div>
              <h1 className={styles.authTitle}>Create Account</h1>
              <p className={styles.authSubtitle}>Get started with BankFlow PCMS</p>
            </div>

            {!registerSuccess ? (
              <form suppressHydrationWarning className={`${styles.authForm} fade-in-up fade-in-up-1`} onSubmit={handleRegister}>
                <div className="form-group">
                  <label className="form-label">Full Name</label>
                  <div className={styles.inputWrapper}>
                    <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                    <input suppressHydrationWarning className={`form-input ${styles.inputWithIcon}`} type="text" placeholder="John Doe" value={name} onChange={(e) => setName(e.target.value)} required />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <div className={styles.inputWrapper}>
                    <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                    <input suppressHydrationWarning className={`form-input ${styles.inputWithIcon}`} type="email" placeholder="you@bankflow.com" value={email} onChange={(e) => setEmail(e.target.value)} required />
                  </div>
                </div>

                {/* Role Selector */}
                <div className={styles.roleSection} style={{ marginBottom: 14 }}>
                  <label className="form-label">Select Role</label>
                  <div
                    className={`${styles.roleSelector} ${showRole ? styles.roleSelectorOpen : ""}`}
                    onClick={() => setShowRole(!showRole)}
                  >
                    <div className={styles.roleLeft}>
                      <div className={styles.roleDot} />
                      <span className={styles.roleValue}>{role}</span>
                    </div>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="16" height="16" style={{ transition: "transform 0.2s", transform: showRole ? "rotate(180deg)" : "rotate(0deg)" }}>
                      <polyline points="6 9 12 15 18 9" />
                    </svg>
                  </div>
                  {showRole && (
                    <div className={styles.roleDropdown}>
                      {ROLES.map((r) => (
                        <button
                          key={r}
                          type="button"
                          suppressHydrationWarning
                          className={`${styles.roleOption} ${role === r ? styles.roleOptionActive : ""}`}
                          onClick={() => { setRole(r); setShowRole(false); }}
                        >
                          {role === r ? (
                            <svg className={styles.roleCheck} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                          ) : (
                            <div style={{ width: 16, flexShrink: 0 }} />
                          )}
                          {r}
                          <div className={`${styles.roleOptionDot} ${role === r ? styles.roleOptionDotActive : ""}`} />
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                <div className="form-group">
                  <label className="form-label">Password</label>
                  <div className={styles.inputWrapper}>
                    <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                    <input suppressHydrationWarning className={`form-input ${styles.inputWithIcon}`} type="password" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} required />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Confirm Password</label>
                  <div className={styles.inputWrapper}>
                    <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                    <input suppressHydrationWarning className={`form-input ${styles.inputWithIcon}`} type="password" placeholder="••••••••" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} required />
                  </div>
                </div>

                <button suppressHydrationWarning type="submit" className="btn btn-primary" style={{ marginTop: 8 }}>Sign Up</button>
              </form>
            ) : (
              <div className={styles.successBox}>
                <div className={styles.successIcon}>🎉</div>
                <p className={styles.successTitle}>Account Created!</p>
                <p className={styles.successText}>Welcome, <strong>{name}</strong>! Your account has been successfully created with the role of <strong>{role}</strong>.</p>
                <button className="btn btn-primary" style={{ marginTop: 24 }} onClick={() => { setStep("login"); setRegisterSuccess(false); }}>
                  Go to Sign In
                </button>
              </div>
            )}
            {alertMsg && (
              <div className={styles.alertOverlay} onClick={() => setAlertMsg(null)}>
                <div className={styles.alertBox} onClick={(e) => e.stopPropagation()}>
                  <div className={styles.alertIconWrapper}>⚠️</div>
                  <h3 className={styles.alertHeaderTitle}>Notification</h3>
                  <p className={styles.alertText}>{alertMsg}</p>
                  <button type="button" className={styles.alertOkBtn} onClick={() => setAlertMsg(null)}>OK</button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  // ── Main Login Screen ──
  return (
    <div className="app-wrapper">
      <div className="phone-frame">
        <div className="status-bar light"><span>10:30 AM</span><div className="status-bar__icons"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 6s4-4 11-4 11 4 11 4"/><path d="M5 10s3-3 7-3 7 3 7 3"/><path d="M9 14s1.5-1.5 3-1.5 3 1.5 3 1.5"/><circle cx="12" cy="18" r="1" fill="currentColor"/></svg><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="15" height="10" rx="2"/><path d="M22 11v2"/></svg></div></div>
        <div className={`screen ${styles.authScreen}`}>
          {/* Logo */}
          <div className={`${styles.authHeader} fade-in-up`}>
            <div className={styles.authLogo}>B</div>
            <h1 className={styles.authTitle}>BankFlow PCMS</h1>
            <p className={styles.authSubtitle}>Payment Collection Management System</p>
          </div>

          {/* Device + Offline badges */}
          <div className={`${styles.badgeRow} fade-in-up fade-in-up-1`}>
            <div className={styles.infoBadge} style={{ background: "#eff6ff", color: "#2563eb" }}>
              <span>📱</span> Device Registered
            </div>
            <div className={styles.infoBadge} style={{ background: "#f0fdf4", color: "#16a34a" }}>
              <span>🌐</span> Online
            </div>
          </div>

          {/* Login tabs */}
          <div className={`${styles.toggleWrapper} fade-in-up fade-in-up-2`}>
            <button suppressHydrationWarning type="button" className={`${styles.toggleBtn} ${tab === "email" ? styles.toggleActive : ""}`} onClick={() => setTab("email")}>Email + Password</button>
            <button suppressHydrationWarning type="button" className={`${styles.toggleBtn} ${tab === "otp" ? styles.toggleActive : ""}`} onClick={() => setTab("otp")}>Email + OTP</button>
          </div>

          {/* Form */}
          <form suppressHydrationWarning className={`${styles.authForm} fade-in-up fade-in-up-2`} onSubmit={handleLogin}>
            <div className="form-group">
              <label className="form-label">Email Address</label>
              <div className={styles.inputWrapper}>
                <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                <input suppressHydrationWarning className={`form-input ${styles.inputWithIcon}`} type="email" placeholder="you@bankflow.com" value={email} onChange={(e) => setEmail(e.target.value)} required />
              </div>
            </div>
            {tab === "email" && (
              <div className="form-group">
                <label className="form-label">Password</label>
                <div className={styles.inputWrapper}>
                  <svg className={styles.inputIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                  <input suppressHydrationWarning className={`form-input ${styles.inputWithIcon}`} type="password" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} required />
                </div>
              </div>
            )}
            <div style={{ textAlign: "right", marginTop: 4 }}>
              <button
                suppressHydrationWarning
                type="button"
                className={styles.forgotLink}
                onClick={() => router.push("/forgot-password")}
              >
                Forgot Password?
              </button>
            </div>
            <button suppressHydrationWarning type="submit" className="btn btn-primary">
              {tab === "otp" ? "Send OTP" : "Sign In"}
            </button>
          </form>

          <div className={`${styles.switchModeRow} fade-in-up fade-in-up-3`}>
            <span>Don&apos;t have an account?</span>
            <button suppressHydrationWarning type="button" className={styles.switchModeBtn} onClick={() => setStep("register")}>Sign Up</button>
          </div>

          {/* Session timeout notice */}
          <div className={`${styles.sessionNotice} fade-in-up fade-in-up-3`}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="14" height="14"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            Session auto-expires after 30 minutes of inactivity
          </div>
          {alertMsg && (
            <div className={styles.alertOverlay} onClick={() => setAlertMsg(null)}>
              <div className={styles.alertBox} onClick={(e) => e.stopPropagation()}>
                <div className={styles.alertIconWrapper}>⚠️</div>
                <h3 className={styles.alertHeaderTitle}>Notification</h3>
                <p className={styles.alertText}>{alertMsg}</p>
                <button type="button" className={styles.alertOkBtn} onClick={() => setAlertMsg(null)}>OK</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
