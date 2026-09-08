"use client";
import React from "react";
import { useNotification } from "@/context/NotificationContext";
import styles from "./ConfirmModal.module.css";

export default function ConfirmModal() {
  const { confirmState, closeConfirm } = useNotification();

  if (!confirmState || !confirmState.isOpen) return null;

  const { title, message, confirmText, cancelText, type = "danger" } = confirmState;

  const iconClass = type === "warning" ? styles.warningIcon : type === "info" ? styles.infoIcon : styles.dangerIcon;
  const btnClass = type === "warning" ? styles.warningBtn : type === "info" ? styles.infoBtn : styles.dangerBtn;
  const iconEmoji = type === "warning" ? "⚠️" : type === "info" ? "ℹ️" : "🗑️";

  return (
    <div className={styles.overlay} onClick={() => closeConfirm(false)}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={`${styles.iconWrap} ${iconClass}`}>
          <span>{iconEmoji}</span>
        </div>
        <h3 className={styles.title}>{title}</h3>
        <p className={styles.message}>{message}</p>
        <div className={styles.btnRow}>
          <button type="button" className={styles.cancelBtn} onClick={() => closeConfirm(false)}>
            {cancelText || "Cancel"}
          </button>
          <button type="button" className={`${styles.confirmBtn} ${btnClass}`} onClick={() => closeConfirm(true)}>
            {confirmText || "Confirm"}
          </button>
        </div>
      </div>
    </div>
  );
}
