"use client";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import BottomNav from "@/components/BottomNav";
import styles from "./page.module.css";

const settingsItems = [
  { icon: "👤", label: "Personal Information", sublabel: "Name, email, address", bg: "var(--gradient-blue)", path: "" },
  { icon: "🔒", label: "Security", sublabel: "Password, biometrics, PIN", bg: "linear-gradient(135deg,#7c3aed,#ec4899)", path: "" },
  { icon: "🔔", label: "Notifications", sublabel: "Push, email, SMS alerts", bg: "linear-gradient(135deg,#f97316,#eab308)", path: "" },
  { icon: "📋", label: "Today's Collection List", sublabel: "View daily collection schedule", bg: "linear-gradient(135deg,#2563eb,#06b6d4)", path: "/collection" },
  { icon: "👥", label: "Customer Visit", sublabel: "Visit & collect from customers", bg: "linear-gradient(135deg,#22c55e,#16a34a)", path: "/collection" },
  { icon: "💳", label: "Payment Methods", sublabel: "Cards, bank accounts", bg: "var(--gradient-card1)", path: "/cards" },
  { icon: "📊", label: "Analytics", sublabel: "Spending insights & charts", bg: "linear-gradient(135deg,#22c55e,#06b6d4)", path: "/analytics" },
  { icon: "🗄️", label: "Database Inspector", sublabel: "View all SQLite tables & live records", bg: "linear-gradient(135deg,#1e293b,#0f172a)", path: "/database" },
  { icon: "🌍", label: "Currency Exchange", sublabel: "Exchange rates & transfer", bg: "linear-gradient(135deg,#06b6d4,#2563eb)", path: "/exchange" },
  { icon: "📅", label: "Payment Calendar", sublabel: "Schedule & reminders", bg: "linear-gradient(135deg,#ec4899,#8b5cf6)", path: "/calendar" },
  { icon: "❓", label: "Help & Support", sublabel: "FAQs, contact us", bg: "linear-gradient(135deg,#64748b,#94a3b8)", path: "" },
  { icon: "🚪", label: "Sign Out", sublabel: "Log out of your account", bg: "linear-gradient(135deg,#ef4444,#dc2626)", path: "/auth" },
];

export default function SettingsPage() {
  const router = useRouter();
  const [userName, setUserName] = useState("Alex Johnson");
  const [userEmail, setUserEmail] = useState("alex.johnson@bankflow.com");

  useEffect(() => {
    const sessionName = localStorage.getItem("pcms_session_name");
    const sessionEmail = localStorage.getItem("pcms_session_email");
    if (sessionName) {
      setUserName(sessionName);
    }
    if (sessionEmail) {
      setUserEmail(sessionEmail);
    }
  }, []);

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

        <div className="screen">
          <div className="screen-content">
            {/* Profile header */}
            <div className="profile-header fade-in-up">
              <div className="profile-avatar">{userName.charAt(0)}</div>
              <p className="profile-name">{userName}</p>
              <p className="profile-email">{userEmail}</p>
            </div>

            {/* Stats */}
            <div className="profile-card-wrapper fade-in-up fade-in-up-1">
              <div className="profile-stat">
                <p className="profile-stat-value">$267K</p>
                <p className="profile-stat-label">Balance</p>
              </div>
              <div className="profile-divider" />
              <div className="profile-stat">
                <p className="profile-stat-value">3</p>
                <p className="profile-stat-label">Cards</p>
              </div>
              <div className="profile-divider" />
              <div className="profile-stat">
                <p className="profile-stat-value">142</p>
                <p className="profile-stat-label">Transfers</p>
              </div>
            </div>

            {/* Settings list */}
            <div className="settings-list fade-in-up fade-in-up-2">
              {settingsItems.map((item) => (
                <div
                  key={item.label}
                  className="settings-item"
                  onClick={() => item.path && router.push(item.path)}
                  style={{ cursor: item.path ? "pointer" : "default" }}
                >
                  <div className="settings-icon" style={{ background: item.bg }}>
                    <span style={{ fontSize: 18 }}>{item.icon}</span>
                  </div>
                  <div className="settings-info">
                    <p className="settings-label">{item.label}</p>
                    <p className="settings-sublabel">{item.sublabel}</p>
                  </div>
                  <div className="settings-chevron">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <polyline points="9 18 15 12 9 6" />
                    </svg>
                  </div>
                </div>
              ))}
            </div>

            <div style={{ padding: "16px 16px 8px", textAlign: "center" }}>
              <p style={{ fontSize: 12, color: "var(--color-text-secondary-light)" }}>BankFlow v2.0.0 · © 2026</p>
            </div>
          </div>
          <BottomNav active="settings" />
        </div>
      </div>
    </div>
  );
}
