"use client";
import { useEffect, useRef, useState } from "react";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import styles from "./page.module.css";

const periods = ["1D", "1W", "1M", "3M", "6M", "All"];

export default function AnalyticsPage() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const { notifySuccess, confirmDialog } = useNotification();
  const [activePeriod, setActivePeriod] = useState("1W");
  const [userName, setUserName] = useState("Rahul Verma");
  const [userRole, setUserRole] = useState("Collection Agent");

  const [weeklyTrends, setWeeklyTrends] = useState<{ day: string; date: string; amount: number; isToday: boolean }[]>([]);
  const [todayIndex, setTodayIndex] = useState((new Date().getDay() + 6) % 7);

  const [realtimeStats, setRealtimeStats] = useState({
    totalCollected: "₹0",
    totalPending: "₹0",
    spendingTrendsLabel: "Collection Trends",
    spendingTrendsVal: "₹0",
    txList: [] as any[]
  });

  useEffect(() => {
    const sessionName = localStorage.getItem("pcms_session_name");
    const sessionRole = localStorage.getItem("pcms_session_role");
    const sessionEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
    if (sessionName) setUserName(sessionName);
    if (sessionRole) setUserRole(sessionRole);

    const now = new Date();
    const currentDayIdx = (now.getDay() + 6) % 7;
    setTodayIndex(currentDayIdx);

    const loadAnalytics = async () => {
      const data = await api.getDashboardAnalytics(sessionEmail, sessionRole || "Collection Agent");
      if (data) {
        let mappedList: any[] = [];
        if (data.recentTransactions && data.recentTransactions.length > 0) {
          mappedList = data.recentTransactions.slice(0, 8).map((t: any) => ({
            icon: "💰",
            name: `Collection: ${t.customer_name || 'Customer'}`,
            date: t.collection_date ? `${t.collection_date}` : "Today",
            amount: t.amount || 0,
            bg: "#d1fae5",
            isPositive: true,
            badge: t.payment_mode || "CASH"
          }));
        }

        if (data.weeklyTrends && data.weeklyTrends.length > 0) {
          setWeeklyTrends(data.weeklyTrends);
        }

        setRealtimeStats({
          totalCollected: `₹${data.totalCollected.toLocaleString()}`,
          totalPending: `₹${Math.max(0, data.totalTarget - data.totalCollected).toLocaleString()}`,
          spendingTrendsLabel: "Collection Trends",
          spendingTrendsVal: `₹${data.totalCollected.toLocaleString()}`,
          txList: mappedList
        });
      } else {
        const records = JSON.parse(localStorage.getItem("pcms_collections_today") || "[]");
        const collectedAmt = records
          .filter((r: any) => r.status === "collected")
          .reduce((sum: number, r: any) => sum + (r.amount || 0), 0);

        const txList = records.map((r: any, i: number) => ({
          id: Date.now() + i,
          icon: r.status === "collected" ? "👤" : r.status === "house_locked" ? "🔒" : "🚫",
          name: `${r.status === "collected" ? "Collection" : "Visit"}: ${r.customerName || 'Customer'}`,
          date: `Today, ${r.timestamp || 'Now'}`,
          amount: r.amount || 0,
          bg: r.status === "collected" ? "#d1fae5" : "#fee2e2",
          isPositive: r.status === "collected",
          badge: r.status === "collected" ? "CASH" : "Logged"
        }));

        setRealtimeStats({
          totalCollected: `₹${collectedAmt.toLocaleString()}`,
          totalPending: `₹0`,
          spendingTrendsLabel: "Collection Trends",
          spendingTrendsVal: `₹${collectedAmt.toLocaleString()}`,
          txList: txList
        });
      }

      // Load maturing accounts
      const matData = await api.getMaturingSoon(30);
      if (matData?.accounts) setMaturingSoon(matData.accounts);
    };

    loadAnalytics();
  }, []);

  const [maturingSoon, setMaturingSoon] = useState<any[]>([]);
  const [accrualResult, setAccrualResult] = useState<any>(null);
  const [accrualLoading, setAccrualLoading] = useState(false);
  const [maturityLoading, setMaturityLoading] = useState(false);

  const handleRunAccrual = async () => {
    const ok = await confirmDialog({
      title: "Run Monthly Interest Accrual?",
      message: "This will compute and credit interest to all ACTIVE accounts for last month. Accounts already accrued will be skipped.",
      confirmText: "Run Accrual",
      type: "info"
    });
    if (!ok) return;
    setAccrualLoading(true);
    try {
      const res = await api.runMonthlyAccrual({ performedBy: userName, performedByRole: userRole });
      setAccrualResult(res);
      notifySuccess("Accrual Complete", `${res.processed} accounts processed, ${res.skipped} skipped. Total interest: ₹${res.totalInterest}.`);
    } catch (e: any) {
      notifySuccess("Error", e.message || "Accrual failed.");
    } finally {
      setAccrualLoading(false);
    }
  };

  const handleProcessMaturity = async () => {
    setMaturityLoading(true);
    try {
      const res = await api.processMaturity({ performedBy: userName, performedByRole: userRole });
      if (res.maturedCount > 0) {
        notifySuccess("Maturity Processed", `${res.maturedCount} account(s) marked MATURED and customers notified by email.`);
        const matData = await api.getMaturingSoon(30);
        if (matData?.accounts) setMaturingSoon(matData.accounts);
      } else {
        notifySuccess("Maturity Check", "No accounts due for maturity today.");
      }
    } catch (e: any) {
      notifySuccess("Error", e.message || "Maturity processing failed.");
    } finally {
      setMaturityLoading(false);
    }
  };

  const handleClearAll = async () => {
    const ok = await confirmDialog({
      title: "Clear All Logs?",
      message: "Are you sure you want to permanently clear all collection logs and audit records?",
      confirmText: "Clear All",
      type: "danger"
    });
    if (!ok) return;

    await api.clearAllCollectionHistory();
    await api.clearAllAuditLogs();
    setRealtimeStats((prev) => ({
      ...prev,
      totalCollected: "₹0",
      spendingTrendsVal: "₹0",
      txList: []
    }));
    notifySuccess("Logs Cleared", "All collection logs have been wiped.");
  };

  const handleDeleteItem = async (id: string | number, e: React.MouseEvent) => {
    e.stopPropagation();
    const ok = await confirmDialog({
      title: "Delete Log Entry?",
      message: "Are you sure you want to permanently delete this transaction record?",
      confirmText: "Delete",
      type: "danger"
    });
    if (!ok) return;

    await api.deleteCollectionHistory(id);
    setRealtimeStats((prev) => ({
      ...prev,
      txList: prev.txList.filter((item, idx) => (item.id !== id && idx !== id))
    }));
    notifySuccess("Record Deleted", "Transaction log entry removed.");
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    const w = 340, h = 160;
    canvas.width = w * dpr;
    canvas.height = h * dpr;
    canvas.style.width = `${w}px`;
    canvas.style.height = `${h}px`;
    ctx.scale(dpr, dpr);

    const weekDayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const baseAmounts = weeklyTrends.length > 0
      ? weeklyTrends.map(t => t.amount)
      : [0, 0, 0, 0, 0, 0, 0];

    const max = Math.max(...baseAmounts, 100);
    const barW = 28;
    const gap = (w - baseAmounts.length * barW) / (baseAmounts.length + 1);

    baseAmounts.forEach((val, i) => {
      const x = gap + i * (barW + gap);
      const barH = val > 0 ? Math.max(12, (val / max) * (h - 40)) : 6;
      const y = h - barH - 24;

      const isCurrentDay = i === todayIndex;

      ctx.shadowColor = isCurrentDay ? "rgba(236,72,153,0.3)" : "rgba(37,99,235,0.25)";
      ctx.shadowBlur = 8;
      ctx.shadowOffsetY = 4;

      const grad = ctx.createLinearGradient(0, y, 0, h - 24);
      grad.addColorStop(0, isCurrentDay ? "#ec4899" : "#2563eb");
      grad.addColorStop(1, isCurrentDay ? "rgba(236,72,153,0.35)" : "rgba(37,99,235,0.3)");

      ctx.beginPath();
      const radius = 6;
      ctx.moveTo(x + radius, y);
      ctx.lineTo(x + barW - radius, y);
      ctx.quadraticCurveTo(x + barW, y, x + barW, y + radius);
      ctx.lineTo(x + barW, h - 24);
      ctx.lineTo(x, h - 24);
      ctx.lineTo(x, y + radius);
      ctx.quadraticCurveTo(x, y, x + radius, y);
      ctx.fillStyle = grad;
      ctx.fill();
      ctx.shadowBlur = 0;

      ctx.fillStyle = isCurrentDay ? "#ec4899" : "#94a3b8";
      ctx.font = isCurrentDay ? "bold 11px Outfit, sans-serif" : "10px Outfit, sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(weekDayNames[i], x + barW / 2, h - 6);
    });
  }, [weeklyTrends, todayIndex, activePeriod]);

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
            <Header name={userName} greeting="PCMS Analytics" />

            {/* Summary */}
            <div className={`${styles.summaryRow} fade-in-up`}>
              <div className={styles.summaryCard} style={{ background: "linear-gradient(135deg,#2563eb,#06b6d4)" }}>
                <p className={styles.summaryLabel}>Total Collected</p>
                <p className={styles.summaryValue}>{realtimeStats.totalCollected}</p>
                <p className={styles.summaryChange}>↑ Today&apos;s collections</p>
              </div>
              <div className={styles.summaryCard} style={{ background: "linear-gradient(135deg,#7c3aed,#ec4899)" }}>
                <p className={styles.summaryLabel}>Total Pending</p>
                <p className={styles.summaryValue}>{realtimeStats.totalPending}</p>
                <p className={styles.summaryChange}>⏳ Target balance</p>
              </div>
            </div>

            {/* Bar chart */}
            <div className={`${styles.chartCard} fade-in-up fade-in-up-1`}>
              <div className={styles.chartTop}>
                <div>
                  <p className={styles.chartLabel}>{realtimeStats.spendingTrendsLabel}</p>
                  <p className={styles.chartBalance}>{realtimeStats.spendingTrendsVal}</p>
                </div>
              </div>
              {/* Period selector */}
              <div className={styles.periodRow}>
                {periods.map((p) => (
                  <button
                    key={p}
                    className={`${styles.periodBtn} ${activePeriod === p ? styles.periodActive : ""}`}
                    onClick={() => setActivePeriod(p)}
                  >
                    {p}
                  </button>
                ))}
              </div>
              <div style={{ overflowX: "auto" }}>
                <canvas ref={canvasRef} style={{ display: "block" }} />
              </div>
            </div>

            {/* ── Admin: Maturing Soon + Run Accrual ── */}
            {(userRole === "Administrator" || userRole === "Branch Manager" || userRole === "Cashier") && (
              <>
                {/* Run Monthly Accrual Card */}
                <div style={{ background: "#fff", borderRadius: 14, border: "1px solid #e2e8f0", padding: 16, marginBottom: 12 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
                    <div>
                      <p style={{ margin: 0, fontSize: 13, fontWeight: 800, color: "#0f172a" }}>📈 Monthly Interest Accrual</p>
                      <p style={{ margin: 0, fontSize: 11, color: "#64748b" }}>Credit last month's interest to all ACTIVE accounts</p>
                    </div>
                    <div style={{ display: "flex", gap: 8 }}>
                      <button
                        onClick={handleProcessMaturity}
                        disabled={maturityLoading}
                        style={{ background: "#dcfce7", color: "#16a34a", border: "1px solid #bbf7d0", borderRadius: 8, padding: "7px 10px", fontSize: 11, fontWeight: 800, cursor: "pointer" }}
                      >
                        {maturityLoading ? "…" : "🎓 Process Maturity"}
                      </button>
                      <button
                        onClick={handleRunAccrual}
                        disabled={accrualLoading}
                        style={{ background: "#eff6ff", color: "#2563eb", border: "1px solid #bfdbfe", borderRadius: 8, padding: "7px 10px", fontSize: 11, fontWeight: 800, cursor: "pointer" }}
                      >
                        {accrualLoading ? "Running…" : "▶ Run Accrual"}
                      </button>
                    </div>
                  </div>
                  {accrualResult && (
                    <div style={{ background: "#f8fafc", borderRadius: 8, padding: "8px 12px", fontSize: 11 }}>
                      <strong>Last Run — {accrualResult.accrualMonth}:</strong>{" "}
                      {accrualResult.processed} accounts processed, {accrualResult.skipped} skipped,{" "}
                      total interest credited: <strong style={{ color: "#16a34a" }}>₹{accrualResult.totalInterest}</strong>
                    </div>
                  )}
                </div>

                {/* Maturing Soon Card */}
                <div style={{ background: "#fff", borderRadius: 14, border: "1px solid #e2e8f0", padding: 16, marginBottom: 12 }}>
                  <p style={{ margin: "0 0 10px", fontSize: 13, fontWeight: 800, color: "#0f172a" }}>
                    ⏳ Maturing Soon <span style={{ fontSize: 11, fontWeight: 500, color: "#64748b" }}>(next 30 days)</span>
                  </p>
                  {maturingSoon.length === 0 ? (
                    <p style={{ fontSize: 12, color: "#94a3b8", textAlign: "center", padding: "8px 0" }}>No accounts maturing in the next 30 days.</p>
                  ) : (
                    maturingSoon.map((acc: any) => (
                      <div key={acc.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px 0", borderBottom: "1px solid #f1f5f9" }}>
                        <div>
                          <p style={{ margin: 0, fontSize: 12, fontWeight: 700, color: "#0f172a" }}>{acc.customerName}</p>
                          <p style={{ margin: 0, fontSize: 10, color: "#64748b" }}>{acc.accountNumber} · Bal ₹{acc.balance?.toLocaleString()}</p>
                        </div>
                        <div style={{ textAlign: "right" }}>
                          <span style={{ background: acc.daysToMaturity <= 7 ? "#fee2e2" : "#fef3c7", color: acc.daysToMaturity <= 7 ? "#dc2626" : "#d97706", padding: "2px 8px", borderRadius: 100, fontSize: 11, fontWeight: 800 }}>
                            {acc.daysToMaturity}d left
                          </span>
                          <p style={{ margin: "2px 0 0", fontSize: 10, color: "#16a34a", fontWeight: 700 }}>Payout ~₹{acc.projectedPayout?.toLocaleString()}</p>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </>
            )}

            {/* Transactions */}
            <div className="section-header fade-in-up fade-in-up-2" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <p className="section-title">Collections Logs</p>
              <button
                type="button"
                onClick={handleClearAll}
                style={{ background: "#fee2e2", color: "#dc2626", border: "none", borderRadius: 8, padding: "5px 10px", fontSize: 11, fontWeight: 700, cursor: "pointer", display: "flex", alignItems: "center", gap: 4 }}
              >
                🗑️ Clear All
              </button>
            </div>
            <div className="tx-list fade-in-up fade-in-up-2" style={{ paddingBottom: 16 }}>
              {realtimeStats.txList.map((tx, i) => (
                <div key={i} className="tx-item">
                  <div className="tx-icon" style={{ background: tx.bg, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>{tx.icon}</div>
                  <div className="tx-info">
                    <p className="tx-name">{tx.name}</p>
                    <p className="tx-date">{tx.date}</p>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    {tx.amount > 0 ? (
                      <span className={`tx-amount ${tx.isPositive ? "positive" : "negative"}`}>
                        {tx.isPositive ? "+" : "-"}₹{tx.amount.toLocaleString()}
                      </span>
                    ) : (
                      <span style={{ fontSize: 11, fontWeight: 700, padding: "3px 8px", borderRadius: 6, background: "var(--color-bg-muted)", color: "var(--color-text-secondary)" }}>
                        {tx.badge || "Verified"}
                      </span>
                    )}
                    <button
                      type="button"
                      title="Delete record"
                      onClick={(e) => handleDeleteItem(tx.id || i, e)}
                      style={{ background: "transparent", border: "none", color: "#ef4444", fontSize: 14, cursor: "pointer", padding: "2px" }}
                    >
                      🗑️
                    </button>
                  </div>
                </div>
              ))}
              {realtimeStats.txList.length === 0 && (
                <div style={{ textAlign: "center", padding: "24px 0", color: "var(--color-text-secondary)" }}>
                  <p style={{ fontSize: 24, margin: 0 }}>✨</p>
                  <p style={{ fontSize: 12, marginTop: 4 }}>No collection logs</p>
                </div>
              )}
            </div>
          </div>
          <BottomNav active="analytics" />
        </div>
      </div>
    </div>
  );
}
