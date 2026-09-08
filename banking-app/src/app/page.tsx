"use client";
import { useRouter } from "next/navigation";
import styles from "./page.module.css";

export default function SplashPage() {
  const router = useRouter();
  return (
    <div className="app-wrapper">
      <div className="phone-frame">
        {/* Status bar */}
        <div className="status-bar dark" style={{ background: "var(--color-bg-dark)" }}>
          <span>10:30 AM</span>
          <div className="status-bar__icons">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 6s4-4 11-4 11 4 11 4"/><path d="M5 10s3-3 7-3 7 3 7 3"/><path d="M9 14s1.5-1.5 3-1.5 3 1.5 3 1.5"/><circle cx="12" cy="18" r="1" fill="currentColor"/></svg>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="15" height="10" rx="2"/><path d="M22 11v2"/></svg>
          </div>
        </div>

        {/* Screen */}
        <div className={styles.splashScreen}>
          <div className={styles.splashContent}>
            <div className={`${styles.logoWrapper} fade-in-up`}>
              <div className="splash-logo">B</div>
              <h1 className={styles.appTitle}>BankFlow</h1>
              <p className={styles.appTagline}>
                Smart banking at your fingertips. Manage, track, and grow your money.
              </p>
            </div>

            <div className={`${styles.featureList} fade-in-up fade-in-up-2`}>
              {[
                { icon: "💳", label: "Instant Transfers" },
                { icon: "📊", label: "Smart Analytics" },
                { icon: "🔒", label: "Bank-Grade Security" },
              ].map((f) => (
                <div key={f.label} className={styles.featureItem}>
                  <span>{f.icon}</span>
                  <span>{f.label}</span>
                </div>
              ))}
            </div>
          </div>

          <div className={`${styles.splashFooter} fade-in-up fade-in-up-3`}>
            <button
              className={styles.getStartedBtn}
              onClick={() => router.push("/auth")}
            >
              GET STARTED
            </button>
            <p className={styles.termsText}>
              By continuing you agree to our{" "}
              <span className={styles.termsLink}>Terms of Service</span> &amp;{" "}
              <span className={styles.termsLink}>Privacy Policy</span>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
