"use client";
import React from "react";
import { useNotification, NotificationItem } from "@/context/NotificationContext";
import styles from "./NotificationBar.module.css";

const ICONS = {
  success: "✓",
  error: "✕",
  warning: "⚠️",
  info: "ℹ️"
};

export default function NotificationBar() {
  const { notifications, dismissNotification } = useNotification();

  if (!notifications || notifications.length === 0) return null;

  return (
    <div className={styles.container}>
      {notifications.map((n: NotificationItem) => (
        <div key={n.id} className={`${styles.toast} ${styles[n.type]}`}>
          <div className={styles.iconCircle}>
            <span>{ICONS[n.type]}</span>
          </div>
          <div className={styles.content}>
            <div className={styles.title}>
              <span>{n.title}</span>
              <span className={styles.time}>{n.timestamp}</span>
            </div>
            {n.message && <p className={styles.message}>{n.message}</p>}
          </div>
          <button
            type="button"
            className={styles.closeBtn}
            onClick={() => dismissNotification(n.id)}
            aria-label="Dismiss notification"
          >
            ✕
          </button>
          <div className={styles.progressBar} />
        </div>
      ))}
    </div>
  );
}
