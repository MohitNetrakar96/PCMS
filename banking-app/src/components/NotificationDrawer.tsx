"use client";
import React from "react";
import { useNotification, NotificationItem } from "@/context/NotificationContext";
import styles from "./NotificationDrawer.module.css";

const ICONS = {
  success: "✓",
  error: "✕",
  warning: "⚠️",
  info: "ℹ️"
};

const TYPE_CLASSES = {
  success: styles.itemSuccess,
  error: styles.itemError,
  warning: styles.itemWarning,
  info: styles.itemInfo
};

export default function NotificationDrawer() {
  const { isDrawerOpen, closeDrawer, history, unreadCount, markAllAsRead, clearHistory } = useNotification();

  if (!isDrawerOpen) return null;

  return (
    <div className={styles.overlay} onClick={closeDrawer}>
      <div className={styles.drawer} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <div className={styles.headerLeft}>
            <h3 className={styles.headerTitle}>Notifications</h3>
            {unreadCount > 0 && <span className={styles.badge}>{unreadCount} new</span>}
          </div>
          <button type="button" className={styles.closeIconBtn} onClick={closeDrawer} aria-label="Close drawer">
            ✕
          </button>
        </div>

        <div className={styles.actionBar}>
          <button type="button" className={styles.actionBtn} onClick={markAllAsRead}>
            Mark all as read
          </button>
          <button type="button" className={styles.clearBtn} onClick={clearHistory}>
            Clear all
          </button>
        </div>

        <div className={styles.list}>
          {history.map((item: NotificationItem) => (
            <div key={item.id} className={`${styles.item} ${!item.read ? styles.itemUnread : ""}`}>
              <div className={`${styles.itemIcon} ${TYPE_CLASSES[item.type]}`}>
                <span>{ICONS[item.type]}</span>
              </div>
              <div className={styles.itemContent}>
                <div className={styles.itemTop}>
                  <p className={styles.itemTitle}>{item.title}</p>
                  <span className={styles.itemTime}>{item.timestamp}</span>
                </div>
                {item.message && <p className={styles.itemMessage}>{item.message}</p>}
              </div>
            </div>
          ))}

          {history.length === 0 && (
            <div className={styles.emptyState}>
              <span style={{ fontSize: 32 }}>🔔</span>
              <p style={{ fontSize: 13, fontWeight: 600, color: "#64748b", margin: 0 }}>All caught up!</p>
              <p style={{ fontSize: 11, color: "#94a3b8", margin: 0 }}>No new notifications</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
