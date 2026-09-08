"use client";
import React from "react";
import { useNotification } from "@/context/NotificationContext";
import styles from "./Header.module.css";

interface HeaderProps {
  name: string;
  greeting: string;
  dark?: boolean;
}

export default function Header({ name, greeting, dark = false }: HeaderProps) {
  const { toggleDrawer, unreadCount } = useNotification();

  return (
    <div className={`app-header ${dark ? styles.dark : ""}`}>
      <div className="header-left">
        <div className="avatar">{name.charAt(0)}</div>
        <div>
          <p className={`header-greeting ${dark ? styles.greetingDark : ""}`}>{greeting}</p>
          <p className={`header-name ${dark ? styles.nameDark : ""}`}>{name}</p>
        </div>
      </div>
      <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
        <div style={{ position: "relative" }}>
          <button
            type="button"
            className="hamburger-btn"
            style={dark ? { background: "rgba(255,255,255,0.1)" } : {}}
            onClick={toggleDrawer}
            title="Notifications"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke={dark ? "white" : "var(--color-text-primary-light)"} strokeWidth="2" strokeLinecap="round">
              <path d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6 6 0 10-12 0v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
          </button>
          {unreadCount > 0 && (
            <span
              style={{
                position: "absolute",
                top: -2,
                right: -2,
                background: "#ef4444",
                color: "#fff",
                fontSize: 9,
                fontWeight: 800,
                padding: "1px 5px",
                borderRadius: 10,
                border: "2px solid #fff"
              }}
            >
              {unreadCount}
            </span>
          )}
        </div>
        <button type="button" className="hamburger-btn" style={dark ? { background: "rgba(255,255,255,0.1)" } : {}}>
          <svg viewBox="0 0 24 24" fill="none" stroke={dark ? "white" : "var(--color-text-primary-light)"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <line x1="3" y1="6" x2="21" y2="6" />
            <line x1="3" y1="12" x2="21" y2="12" />
            <line x1="3" y1="18" x2="21" y2="18" />
          </svg>
        </button>
      </div>
    </div>
  );
}
