"use client";
import React, { useState, useEffect, useCallback } from "react";
import { api } from "@/services/api";
import styles from "./LiveVisitFeed.module.css";

const STATUS_STYLES: Record<string, { label: string; color: string; bg: string; icon: string }> = {
  collected:        { label: "Collected",    color: "#16a34a", bg: "#dcfce7", icon: "✓" },
  not_available:    { label: "Not Available", color: "#d97706", bg: "#fef3c7", icon: "🚫" },
  house_locked:     { label: "House Locked", color: "#dc2626", bg: "#fee2e2", icon: "🔒" },
  payment_tomorrow: { label: "Pay Tomorrow", color: "#7c3aed", bg: "#ede9fe", icon: "📅" },
  shifted:          { label: "Shifted",       color: "#475569", bg: "#f1f5f9", icon: "🚚" },
  pending:          { label: "Pending",       color: "#94a3b8", bg: "#f8fafc", icon: "⏳" },
};

function getInitials(name: string) {
  return name.split(" ").map(n => n[0]).join("").substring(0, 2).toUpperCase();
}

interface LiveVisitFeedProps {
  agentEmail?: string;       // if set, only show this agent's visits
  autoRefreshMs?: number;    // default 30000 (30s)
  showTitle?: boolean;
  maxRows?: number;
}

export default function LiveVisitFeed({
  agentEmail,
  autoRefreshMs = 30000,
  showTitle = true,
  maxRows,
}: LiveVisitFeedProps) {
  const [visits, setVisits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);

  const load = useCallback(async (silent = false) => {
    if (!silent) setRefreshing(true);
    try {
      const data = await api.getLiveVisits(agentEmail);
      setVisits(data.visits || []);
      setLastRefresh(new Date());
    } catch {
      // silently fail, keep old data
    } finally {
      setRefreshing(false);
      setLoading(false);
    }
  }, [agentEmail]);

  // Initial load
  useEffect(() => {
    load(false);
  }, [load]);

  // Auto-refresh
  useEffect(() => {
    const timer = setInterval(() => load(true), autoRefreshMs);
    return () => clearInterval(timer);
  }, [load, autoRefreshMs]);

  const displayVisits = maxRows ? visits.slice(0, maxRows) : visits;

  // Summary counts
  const collected = visits.filter(v => v.status === "collected").length;
  const pending = visits.filter(v => v.status === "pending").length;
  const noContact = visits.filter(v => ["not_available", "house_locked", "shifted"].includes(v.status)).length;
  const totalCollected = visits.reduce((s, v) => s + (v.collectedAmount || 0), 0);

  return (
    <div className={styles.feed}>
      {showTitle && (
        <div className={styles.feedHeader}>
          <div className={styles.feedTitle}>
            📡 Live Visit Feed
            <span className={styles.liveIndicator}>
              <span className={styles.liveDot} />
              LIVE
            </span>
          </div>
          <button
            className={styles.refreshBtn}
            onClick={() => load(false)}
            disabled={refreshing}
            title="Refresh"
          >
            <span className={refreshing ? styles.refreshing : ""}>↻</span>
          </button>
        </div>
      )}

      {/* Summary stats */}
      <div className={styles.statsRow}>
        <div className={styles.statChip}>
          <span style={{ color: "#16a34a" }}>{collected}</span>
          <small>Collected</small>
        </div>
        <div className={styles.statChip}>
          <span style={{ color: "#94a3b8" }}>{pending}</span>
          <small>Pending</small>
        </div>
        <div className={styles.statChip}>
          <span style={{ color: "#dc2626" }}>{noContact}</span>
          <small>No Contact</small>
        </div>
        <div className={styles.statChip}>
          <span style={{ color: "#2563eb", fontSize: 12 }}>₹{totalCollected > 0 ? (totalCollected / 1000).toFixed(1) + "K" : "0"}</span>
          <small>Collected</small>
        </div>
      </div>

      {loading ? (
        <div className={styles.emptyState}>
          <div style={{ width: 28, height: 28, border: "2px solid #2563eb", borderTopColor: "transparent", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto 8px" }} />
          Loading visits…
        </div>
      ) : displayVisits.length === 0 ? (
        <div className={styles.emptyState}>
          <p style={{ fontSize: 22, marginBottom: 6 }}>🗂️</p>
          No visits recorded today yet.
        </div>
      ) : (
        displayVisits.map((v) => {
          const s = STATUS_STYLES[v.status] || STATUS_STYLES.pending;
          const isPending = v.status === "pending";
          return (
            <div key={v.id} className={`${styles.row} ${isPending ? styles.pendingRow : ""}`}>
              {/* Avatar */}
              {v.photoUrl ? (
                <img src={v.photoUrl} alt={v.customerName} className={styles.rowAvatar} />
              ) : (
                <div className={styles.rowAvatarFallback}>
                  {getInitials(v.customerName || "?")}
                </div>
              )}

              {/* Body */}
              <div className={styles.rowBody}>
                <div className={styles.rowName}>{v.customerName}</div>
                <div className={styles.rowMeta}>
                  {v.visitTime && <span className={styles.rowTime}>{v.visitTime}</span>}
                  <span className={styles.rowIcons}>
                    {v.photoCaptured && <span className={styles.iconTag} title="Photo captured">📷</span>}
                    {v.signatureCaptured && <span className={styles.iconTag} title="Signature captured">✍️</span>}
                    {v.latitude && <span className={styles.iconTag} title="GPS recorded">📍</span>}
                  </span>
                </div>
              </div>

              {/* Right: status + amount */}
              <div className={styles.rowRight}>
                <span
                  className={styles.statusBadge}
                  style={{ background: s.bg, color: s.color }}
                >
                  {s.icon} {s.label}
                </span>
                {v.collectedAmount > 0 && (
                  <span className={styles.rowAmount}>₹{v.collectedAmount.toLocaleString()}</span>
                )}
              </div>
            </div>
          );
        })
      )}

      {lastRefresh && (
        <div style={{ textAlign: "center", padding: "6px 0 10px", fontSize: 9, color: "#94a3b8" }}>
          Last updated: {lastRefresh.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", second: "2-digit" })}
        </div>
      )}
    </div>
  );
}
