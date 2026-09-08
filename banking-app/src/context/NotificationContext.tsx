"use client";
import React, { createContext, useContext, useState } from "react";

export type NotificationType = "success" | "error" | "warning" | "info";

export interface NotificationItem {
  id: string;
  type: NotificationType;
  title: string;
  message?: string;
  timestamp: string;
  read?: boolean;
}

export interface ConfirmDialogOptions {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  type?: "danger" | "warning" | "info";
}

interface ConfirmState extends ConfirmDialogOptions {
  isOpen: boolean;
  resolve?: (val: boolean) => void;
}

interface NotificationContextType {
  notifications: NotificationItem[];
  history: NotificationItem[];
  isDrawerOpen: boolean;
  unreadCount: number;
  confirmState: ConfirmState;
  notify: (type: NotificationType, title: string, message?: string, duration?: number) => void;
  notifySuccess: (title: string, message?: string) => void;
  notifyError: (title: string, message?: string) => void;
  notifyWarning: (title: string, message?: string) => void;
  notifyInfo: (title: string, message?: string) => void;
  dismissNotification: (id: string) => void;
  confirmDialog: (options: ConfirmDialogOptions) => Promise<boolean>;
  closeConfirm: (result: boolean) => void;
  toggleDrawer: () => void;
  closeDrawer: () => void;
  clearHistory: () => void;
  markAllAsRead: () => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [history, setHistory] = useState<NotificationItem[]>([
    {
      id: "init-1",
      type: "success",
      title: "Device Synced",
      message: "Collection route schedule loaded successfully.",
      timestamp: "10:30 AM",
      read: false
    },
    {
      id: "init-2",
      type: "info",
      title: "Daily Collection Goal",
      message: "Target for today: ₹5,000 across 8 customer accounts.",
      timestamp: "09:15 AM",
      read: false
    }
  ]);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [confirmState, setConfirmState] = useState<ConfirmState>({
    isOpen: false,
    title: "",
    message: "",
    confirmText: "Confirm",
    cancelText: "Cancel",
    type: "danger"
  });

  const notify = (type: NotificationType, title: string, message?: string, duration = 3500) => {
    const id = `${Date.now()}-${Math.random().toString(36).substr(2, 5)}`;
    const timeStr = new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" });
    const newItem: NotificationItem = { id, type, title, message, timestamp: timeStr, read: false };

    setNotifications((prev) => [newItem, ...prev.slice(0, 1)]);
    setHistory((prev) => [newItem, ...prev.slice(0, 19)]);

    if (duration > 0) {
      setTimeout(() => {
        dismissNotification(id);
      }, duration);
    }
  };

  const notifySuccess = (title: string, message?: string) => notify("success", title, message);
  const notifyError = (title: string, message?: string) => notify("error", title, message);
  const notifyWarning = (title: string, message?: string) => notify("warning", title, message);
  const notifyInfo = (title: string, message?: string) => notify("info", title, message);

  const dismissNotification = (id: string) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id));
  };

  const confirmDialog = (options: ConfirmDialogOptions): Promise<boolean> => {
    return new Promise((resolve) => {
      setConfirmState({
        isOpen: true,
        title: options.title,
        message: options.message,
        confirmText: options.confirmText || "Delete",
        cancelText: options.cancelText || "Cancel",
        type: options.type || "danger",
        resolve
      });
    });
  };

  const closeConfirm = (result: boolean) => {
    if (confirmState.resolve) {
      confirmState.resolve(result);
    }
    setConfirmState((prev) => ({ ...prev, isOpen: false }));
  };

  const toggleDrawer = () => {
    setIsDrawerOpen((prev) => !prev);
  };

  const closeDrawer = () => {
    setIsDrawerOpen(false);
  };

  const clearHistory = () => {
    setHistory([]);
  };

  const markAllAsRead = () => {
    setHistory((prev) => prev.map((h) => ({ ...h, read: true })));
  };

  const unreadCount = history.filter((h) => !h.read).length;

  return (
    <NotificationContext.Provider
      value={{
        notifications,
        history,
        isDrawerOpen,
        unreadCount,
        confirmState,
        notify,
        notifySuccess,
        notifyError,
        notifyWarning,
        notifyInfo,
        dismissNotification,
        confirmDialog,
        closeConfirm,
        toggleDrawer,
        closeDrawer,
        clearHistory,
        markAllAsRead
      }}
    >
      {children}
    </NotificationContext.Provider>
  );
}

export function useNotification() {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error("useNotification must be used within a NotificationProvider");
  }
  return context;
}
