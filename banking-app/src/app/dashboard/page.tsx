"use client";
import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import LiveVisitFeed from "@/components/LiveVisitFeed";
import styles from "./page.module.css";

const ROLE_DATA: Record<string, {
  title: string;
  balanceLabel: string;
  stat1Label: string;
  stat2Label: string;
  quickActions: { icon: string; label: string; path: string; bg: string }[];
  spendingTitle: string;
}> = {
  "Collection Agent": {
    title: "Collection Agent",
    balanceLabel: "Total Cash Collected Today",
    stat1Label: "Target Due Today",
    stat2Label: "Visited",
    quickActions: [
      { icon: "📋", label: "Collections", path: "/collection", bg: "var(--gradient-blue)" },
      { icon: "👣", label: "Next Route", path: "/next-customer", bg: "linear-gradient(135deg,#7c3aed,#ec4899)" },
      { icon: "📊", label: "EOD Summary", path: "/daily-summary", bg: "linear-gradient(135deg,#f97316,#eab308)" },
      { icon: "💼", label: "Submit Cash", path: "/submit-cash", bg: "linear-gradient(135deg,#1e293b,#334155)" },
    ],
    spendingTitle: "Today's Target Overview",
  },
  "Branch Manager": {
    title: "Branch Manager",
    balanceLabel: "Total Branch Collections",
    stat1Label: "Active Routes Today",
    stat2Label: "Target Progress",
    quickActions: [
      { icon: "📋", label: "Agents Route", path: "/collection", bg: "var(--gradient-blue)" },
      { icon: "📊", label: "Branch Summary", path: "/daily-summary", bg: "linear-gradient(135deg,#7c3aed,#ec4899)" },
      { icon: "💼", label: "Accept Handovers", path: "/submit-cash", bg: "linear-gradient(135deg,#f97316,#eab308)" },
      { icon: "📅", label: "Monthly Calendar", path: "/calendar", bg: "linear-gradient(135deg,#22c55e,#06b6d4)" },
    ],
    spendingTitle: "Branch Collection Status",
  },
  "Cashier": {
    title: "Cashier",
    balanceLabel: "Total Vault Cash Accepted",
    stat1Label: "Pending To Accept",
    stat2Label: "Verified Handovers",
    quickActions: [
      { icon: "💼", label: "Accept Cash", path: "/submit-cash", bg: "var(--gradient-blue)" },
      { icon: "📊", label: "Cash Register", path: "/daily-summary", bg: "linear-gradient(135deg,#7c3aed,#ec4899)" },
      { icon: "🏦", label: "Branch Deposit", path: "/submit-cash", bg: "linear-gradient(135deg,#f97316,#eab308)" },
      { icon: "📋", label: "Handover Logs", path: "/collection", bg: "linear-gradient(135deg,#22c55e,#06b6d4)" },
    ],
    spendingTitle: "Cash Acceptance Breakdown",
  },
  "Administrator": {
    title: "Administrator",
    balanceLabel: "Total Branch Collections (All)",
    stat1Label: "Active System Users",
    stat2Label: "Branch Network",
    quickActions: [
      { icon: "👥", label: "Manage Users", path: "/settings", bg: "var(--gradient-blue)" },
      { icon: "📊", label: "Full Report", path: "/daily-summary", bg: "linear-gradient(135deg,#7c3aed,#ec4899)" },
      { icon: "🔒", label: "Audit logs", path: "/analytics", bg: "linear-gradient(135deg,#f97316,#eab308)" },
      { icon: "🏦", label: "Branch Config", path: "/settings", bg: "linear-gradient(135deg,#22c55e,#06b6d4)" },
    ],
    spendingTitle: "System Wide Collection Overview",
  },
  "Auditor": {
    title: "Auditor",
    balanceLabel: "Total Verified Collections",
    stat1Label: "Variance Records",
    stat2Label: "Compliance Rate",
    quickActions: [
      { icon: "🔒", label: "Audit Trail", path: "/analytics", bg: "var(--gradient-blue)" },
      { icon: "📊", label: "Verification", path: "/daily-summary", bg: "linear-gradient(135deg,#7c3aed,#ec4899)" },
      { icon: "📋", label: "Branch Logs", path: "/collection", bg: "linear-gradient(135deg,#f97316,#eab308)" },
      { icon: "👥", label: "User Access", path: "/settings", bg: "linear-gradient(135deg,#22c55e,#06b6d4)" },
    ],
    spendingTitle: "Audit Verification Health",
  }
};

export default function DashboardPage() {
  const router = useRouter();
  const { notifySuccess, confirmDialog } = useNotification();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [userName, setUserName] = useState("Mohit");
  const [userRole, setUserRole] = useState("Collection Agent");
  const [realtimeStats, setRealtimeStats] = useState({
    balanceAmount: "₹0.00",
    stat1Val: "₹5,000",
    stat2Val: "0 / 8",
    collectedPct: 0,
    remainingVal: "₹5,000",
    transactions: [] as any[]
  });

  // ── Reconciliation state (Branch Manager / Cashier / Admin only) ──
  const [pendingMismatches, setPendingMismatches] = useState<any[]>([]);
  const [reconDrillDown, setReconDrillDown] = useState<any[]>([]);
  const [showReconModal, setShowReconModal] = useState(false);
  const [reconResolveId, setReconResolveId] = useState<number | null>(null);
  const [reconNote, setReconNote] = useState("");
  const [reconLoading, setReconLoading] = useState(false);
  const [userEmail, setUserEmail] = useState("agent@bankflow.com");

  useEffect(() => {
    const sessionName = localStorage.getItem("pcms_session_name");
    const sessionRole = localStorage.getItem("pcms_session_role");
    const sessionEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
    if (sessionName) setUserName(sessionName);
    if (sessionRole) setUserRole(sessionRole);
    setUserEmail(sessionEmail);

    const loadDashboard = async () => {
      const liveData = await api.getDashboardAnalytics(sessionEmail, sessionRole || "Collection Agent");
      if (liveData) {
        const totalTarget = liveData.totalTarget || 2500;
        const totalCollected = liveData.totalCollected || 0;
        const remaining = Math.max(0, totalTarget - totalCollected);
        const pct = totalTarget > 0 ? Math.min(100, Math.round((totalCollected / totalTarget) * 100)) : 0;
        
        let txList: any[] = [];
        if (liveData.recentTransactions && liveData.recentTransactions.length > 0) {
          txList = liveData.recentTransactions.slice(0, 5).map((t: any) => ({
            id: t.id,
            icon: "💰",
            name: `Collection: ${t.customer_name || 'Customer'}`,
            date: t.collection_date ? `${t.collection_date}` : "Today",
            amount: t.amount || 0,
            bg: "#d1fae5",
            isPositive: true,
            badge: t.payment_mode || "CASH"
          }));
        } else if (liveData.auditTrail && liveData.auditTrail.length > 0) {
          txList = liveData.auditTrail.slice(0, 5).map((a: any, i: number) => {
            const amountMatch = a.details ? a.details.match(/₹([0-9]+)/) : null;
            const parsedAmount = amountMatch ? parseInt(amountMatch[1]) : 0;
            return {
              id: a.id || Date.now() + i,
              icon: a.status === "ok" ? "👤" : "⚠️",
              name: a.action,
              date: a.created_at ? new Date(a.created_at).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }) : "Today",
              amount: parsedAmount,
              bg: a.status === "ok" ? "#d1fae5" : "#fee2e2",
              isPositive: a.status === "ok",
              badge: parsedAmount > 0 ? "Collected" : "Verified"
            };
          });
        }

        setRealtimeStats({
          balanceAmount: `₹${totalCollected.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`,
          stat1Val: `₹${totalTarget.toLocaleString()}`,
          stat2Val: `${liveData.completedCount || 0} / ${liveData.totalCustomers || 8}`,
          collectedPct: pct,
          remainingVal: `₹${remaining.toLocaleString()}`,
          transactions: txList
        });
      } else {
        const records = JSON.parse(localStorage.getItem("pcms_collections_today") || "[]");
        const collectedAmt = records
          .filter((r: any) => r.status === "collected")
          .reduce((sum: number, r: any) => sum + (r.amount || 0), 0);

        const visitedCount = records.length;
        const totalExpected = 2500;
        const remainingAmt = Math.max(0, totalExpected - collectedAmt);
        const pct = Math.min(100, Math.round((collectedAmt / totalExpected) * 100));

        const txList = records.map((r: any, i: number) => ({
          id: Date.now() + i,
          icon: r.status === "collected" ? "👤" : r.status === "house_locked" ? "🔒" : "🚫",
          name: `${r.status === "collected" ? "Collection" : "Visit"}: ${r.customerName || 'Customer'}`,
          date: `Today, ${r.timestamp || 'Now'}`,
          amount: r.amount || 0,
          bg: r.status === "collected" ? "#d1fae5" : "#fee2e2",
          isPositive: r.status === "collected"
        }));

        setRealtimeStats({
          balanceAmount: `₹${collectedAmt.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`,
          stat1Val: `₹${totalExpected.toLocaleString()}`,
          stat2Val: `${visitedCount} / 8`,
          collectedPct: pct,
          remainingVal: `₹${remainingAmt.toLocaleString()}`,
          transactions: txList
        });
      }

      // ── Load pending reconciliation mismatches for authorized roles ──
      const role = sessionRole || "Collection Agent";
      if (["Administrator", "Branch Manager", "Cashier"].includes(role)) {
        const mData = await api.getPendingMismatches(sessionEmail, role);
        if (mData?.mismatches) setPendingMismatches(mData.mismatches);
      }
    };

    loadDashboard();
  }, [userRole]);

  /** Open the full daily reconciliation drill-down for today */
  const handleOpenReconModal = async () => {
    setReconLoading(true);
    try {
      const today = new Date().toISOString().split("T")[0];
      const data = await api.getDailyReconciliation({
        date: today,
        requestedBy: userEmail,
        requestedRole: userRole,
      });
      setReconDrillDown(data.results || []);
      // Refresh badge count
      const mData = await api.getPendingMismatches(userEmail, userRole);
      if (mData?.mismatches) setPendingMismatches(mData.mismatches);
    } catch (e: any) {
      console.warn("Recon drill-down error:", e.message);
    } finally {
      setReconLoading(false);
      setShowReconModal(true);
    }
  };

  /** Resolve a mismatch from the modal */
  const handleResolveRecon = async () => {
    if (!reconResolveId) return;
    setReconLoading(true);
    try {
      await api.resolveReconciliation(reconResolveId, {
        resolved_by: userEmail,
        resolved_by_role: userRole,
        note: reconNote || "Reviewed and approved by manager",
      });
      notifySuccess("Resolved!", "Reconciliation mismatch marked as resolved.");
      setReconResolveId(null);
      setReconNote("");
      // Refresh both modal data and badge count
      const today = new Date().toISOString().split("T")[0];
      const data = await api.getDailyReconciliation({ date: today, requestedBy: userEmail, requestedRole: userRole });
      setReconDrillDown(data.results || []);
      const mData = await api.getPendingMismatches(userEmail, userRole);
      if (mData?.mismatches) setPendingMismatches(mData.mismatches);
    } catch (e: any) {
      notifySuccess("Error", e.message || "Could not resolve record.");
    } finally {
      setReconLoading(false);
    }
  };

  const handleClearDashboardHistory = async (e: React.MouseEvent) => {
    e.stopPropagation();
    const ok = await confirmDialog({
      title: "Clear All History?",
      message: "Are you sure you want to permanently clear all collection history records?",
      confirmText: "Clear All",
      type: "danger"
    });
    if (!ok) return;

    await api.clearAllCollectionHistory();
    setRealtimeStats((prev) => ({
      ...prev,
      balanceAmount: "₹0.00",
      collectedPct: 0,
      transactions: []
    }));
    notifySuccess("History Cleared", "All collection records wiped.");
  };

  const handleDeleteDashboardTx = async (id: string | number, e: React.MouseEvent) => {
    e.stopPropagation();
    const ok = await confirmDialog({
      title: "Delete Transaction?",
      message: "Are you sure you want to permanently delete this transaction record?",
      confirmText: "Delete",
      type: "danger"
    });
    if (!ok) return;

    await api.deleteCollectionHistory(id);
    setRealtimeStats((prev) => ({
      ...prev,
      transactions: prev.transactions.filter((t, idx) => t.id !== id && idx !== id)
    }));
    notifySuccess("Transaction Deleted", "Record removed permanently.");
  };

  const currentData = ROLE_DATA[userRole] || ROLE_DATA["Collection Agent"];

  const displayData = {
    ...currentData,
    balanceAmount: realtimeStats.balanceAmount,
    stat1Val: realtimeStats.stat1Val,
    stat2Val: realtimeStats.stat2Val,
    donutData: [
      { color: "#22c55e", label: "Collected Cash", value: realtimeStats.balanceAmount.replace(".00",""), pct: realtimeStats.collectedPct },
      { color: "#3b82f6", label: "Remaining Targets", value: realtimeStats.remainingVal, pct: 100 - realtimeStats.collectedPct },
      { color: "#e2e8f0", label: "Pending", value: "₹0", pct: 0 },
    ],
    transactions: realtimeStats.transactions,
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const pct1 = (displayData.donutData[0]?.pct || 50) / 100;
    const pct2 = (displayData.donutData[1]?.pct || 50) / 100;

    const dpr = window.devicePixelRatio || 1;
    const size = 120;
    canvas.width = size * dpr;
    canvas.height = size * dpr;
    canvas.style.width = `${size}px`;
    canvas.style.height = `${size}px`;
    ctx.scale(dpr, dpr);

    const cx = size / 2;
    const cy = size / 2;
    const r = 46;
    const lineW = 10;

    // Background ring
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.strokeStyle = "#e2e8f0";
    ctx.lineWidth = lineW;
    ctx.stroke();

    // Outer ring
    const start = -Math.PI / 2;
    const end = start + Math.PI * 2 * pct1;
    const grad = ctx.createLinearGradient(0, 0, size, size);
    grad.addColorStop(0, "#22c55e");
    grad.addColorStop(1, "#16a34a");
    ctx.beginPath();
    ctx.arc(cx, cy, r, start, end);
    ctx.strokeStyle = grad;
    ctx.lineWidth = lineW;
    ctx.lineCap = "round";
    ctx.stroke();

    // Inner ring background
    const r2 = 32;
    const lw2 = 8;
    ctx.beginPath();
    ctx.arc(cx, cy, r2, 0, Math.PI * 2);
    ctx.strokeStyle = "#f0f4ff";
    ctx.lineWidth = lw2;
    ctx.stroke();

    // Inner ring
    const end2 = start + Math.PI * 2 * pct2;
    const grad2 = ctx.createLinearGradient(0, 0, size, size);
    grad2.addColorStop(0, "#3b82f6");
    grad2.addColorStop(1, "#2563eb");
    ctx.beginPath();
    ctx.arc(cx, cy, r2, start, end2);
    ctx.strokeStyle = grad2;
    ctx.lineWidth = lw2;
    ctx.lineCap = "round";
    ctx.stroke();
  }, [displayData.donutData]);

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
            <Header name={userName} greeting={`${displayData.title} Dashboard 👋`} />

            {/* Balance card */}
            <div className={`balance-section fade-in-up fade-in-up-1`}>
              <p className="balance-label">{displayData.balanceLabel}</p>
              <h2 className="balance-amount">{displayData.balanceAmount}</h2>
              <div className="balance-stats">
                <div className="stat-item">
                  <div className="stat-icon">
                    <svg viewBox="0 0 24 24" fill="none"><path d="M12 5v14M5 12l7-7 7 7" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  </div>
                  <div>
                    <p className="stat-label">{displayData.stat1Label}</p>
                    <p className="stat-value">{displayData.stat1Val}</p>
                  </div>
                </div>
                <div className="stat-item">
                  <div className="stat-icon">
                    <svg viewBox="0 0 24 24" fill="none"><path d="M12 19V5M5 12l7 7 7-7" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  </div>
                  <div>
                    <p className="stat-label">{displayData.stat2Label}</p>
                    <p className="stat-value">{displayData.stat2Val}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Customer Portal Shortcut Banner */}
            <div style={{ margin: "0 16px 12px", display: "flex", justifyContent: "space-between", alignItems: "center", background: "#f8fafc", padding: "10px 14px", borderRadius: 14, border: "1px solid #e2e8f0" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <span style={{ fontSize: 18 }}>👤</span>
                <div>
                  <p style={{ fontSize: 12, fontWeight: 700, color: "#0f172a", margin: 0 }}>Customer Portal View</p>
                  <p style={{ fontSize: 10, color: "#64748b", margin: 0 }}>View balances, upload photo &amp; pay deposit</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => router.push("/customer-portal")}
                style={{ background: "linear-gradient(135deg, #2563eb, #1d4ed8)", color: "#ffffff", border: "none", borderRadius: 8, padding: "6px 12px", fontSize: 11, fontWeight: 700, cursor: "pointer" }}
              >
                Open Portal ➔
              </button>
            </div>

            {/* Quick actions */}
            <div className="section-header fade-in-up fade-in-up-2">
              <p className="section-title">Quick Actions</p>
            </div>
            <div className="quick-actions fade-in-up fade-in-up-2">
              {displayData.quickActions.map((qa) => (
                <div key={qa.label} className="quick-action" onClick={() => router.push(qa.path)}>
                  <div className="qa-icon" style={{ background: qa.bg, color: "#fff", fontSize: 24, display: "flex", alignItems: "center", justifyContent: "center" }}>
                    {qa.icon}
                  </div>
                  <span className="qa-label">{qa.label}</span>
                </div>
              ))}
            </div>

            {/* ── Pending Reconciliation Card (Branch Manager / Cashier / Admin) ── */}
            {(userRole === "Branch Manager" || userRole === "Administrator" || userRole === "Cashier") && (
              <div
                style={{
                  margin: "0 0 12px", background: pendingMismatches.length > 0
                    ? "linear-gradient(135deg,#dc2626,#b91c1c)"
                    : "linear-gradient(135deg,#16a34a,#15803d)",
                  borderRadius: 14, padding: "14px 16px", cursor: "pointer",
                  boxShadow: pendingMismatches.length > 0 ? "0 4px 20px rgba(220,38,38,0.35)" : "none"
                }}
                onClick={handleOpenReconModal}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    <span style={{ fontSize: 22 }}>🏦</span>
                    <div>
                      <p style={{ margin: 0, fontSize: 13, fontWeight: 900, color: "#fff" }}>
                        Pending Reconciliation
                      </p>
                      <p style={{ margin: 0, fontSize: 11, color: "rgba(255,255,255,0.8)" }}>
                        {pendingMismatches.length > 0
                          ? `${pendingMismatches.length} agent(s) have unresolved cash mismatch`
                          : "All agents reconciled ✓ Tap to view today's report"}
                      </p>
                    </div>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    {pendingMismatches.length > 0 && (
                      <div style={{
                        background: "#fff", color: "#dc2626", borderRadius: "50%",
                        width: 28, height: 28, display: "flex", alignItems: "center",
                        justifyContent: "center", fontWeight: 900, fontSize: 13,
                        boxShadow: "0 2px 8px rgba(0,0,0,0.15)"
                      }}>
                        {pendingMismatches.length}
                      </div>
                    )}
                    <span style={{ color: "rgba(255,255,255,0.7)", fontSize: 16 }}>›</span>
                  </div>
                </div>

                {/* Mini mismatch list preview — top 2 agents */}
                {pendingMismatches.length > 0 && (
                  <div style={{ marginTop: 10, padding: "8px 0 0", borderTop: "1px solid rgba(255,255,255,0.2)" }}>
                    {pendingMismatches.slice(0, 2).map((m: any) => (
                      <div key={m.id} style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                        <span style={{ fontSize: 11, color: "#fecaca" }}>
                          {m.agentName} · {m.date}
                        </span>
                        <span style={{ fontSize: 11, color: "#fff", fontWeight: 800 }}>
                          Δ ₹{Math.abs(m.difference).toFixed(2)} {m.difference > 0 ? "⬆ short" : "⬇ excess"}
                        </span>
                      </div>
                    ))}
                    {pendingMismatches.length > 2 && (
                      <p style={{ margin: "4px 0 0", fontSize: 10, color: "rgba(255,255,255,0.6)" }}>
                        +{pendingMismatches.length - 2} more — tap to view all
                      </p>
                    )}
                  </div>
                )}
              </div>
            )}

            {/* Donut chart */}
            <div className={`${styles.chartCard} fade-in-up fade-in-up-3`}>
              <div className={styles.chartHeader}>
                <p className={styles.chartTitle}>{displayData.spendingTitle}</p>
                <div className={styles.timePills}>
                  {["Today", "Week", "Month", "All"].map((t, i) => (
                    <button key={t} className={`${styles.timePill} ${i === 0 ? styles.timePillActive : ""}`}>{t}</button>
                  ))}
                </div>
              </div>
              <div className="donut-section">
                <div className="donut-container">
                  <canvas ref={canvasRef} />
                  <div className="donut-center">
                    <p className="donut-pct">{displayData.donutData[0].pct}%</p>
                    <p className="donut-sub">{displayData.donutData[0].label.split(" ")[0]}</p>
                  </div>
                </div>
                <div className="donut-legend">
                  {displayData.donutData.map((l) => (
                    <div key={l.label} className="legend-item">
                      <div className="legend-dot" style={{ background: l.color }} />
                      <span className="legend-label">{l.label}</span>
                      <span className="legend-value">{l.value}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Transactions */}
            <div className="section-header fade-in-up fade-in-up-4" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <p className="section-title">Recent Transactions</p>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <button
                  type="button"
                  onClick={handleClearDashboardHistory}
                  style={{ background: "#fee2e2", color: "#dc2626", border: "none", borderRadius: 8, padding: "4px 8px", fontSize: 10, fontWeight: 700, cursor: "pointer", display: "flex", alignItems: "center", gap: 2 }}
                >
                  🗑️ Clear All
                </button>
                <button className="section-link" onClick={() => router.push("/collection")}>See All</button>
              </div>
            </div>
            <div className={`tx-list fade-in-up fade-in-up-4`}>
              {displayData.transactions.map((tx) => (
                <div key={tx.id} className="tx-item" onClick={() => router.push("/collection")}>
                  <div className="tx-icon" style={{ background: tx.bg, display: "flex", alignItems: "center", justifyContent: "center" }}>{tx.icon}</div>
                  <div className="tx-info">
                    <p className="tx-name">{tx.name}</p>
                    <p className="tx-date">{tx.date}</p>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
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
                      onClick={(e) => handleDeleteDashboardTx(tx.id, e)}
                      style={{ background: "transparent", border: "none", color: "#ef4444", fontSize: 13, cursor: "pointer", padding: "2px" }}
                    >
                      🗑️
                    </button>
                  </div>
                </div>
              ))}
              {displayData.transactions.length === 0 && (
                <div style={{ textAlign: "center", padding: "16px 0", color: "var(--color-text-secondary)" }}>
                  <p style={{ fontSize: 12, margin: 0 }}>No recent transactions</p>
                </div>
              )}
            </div>

            {/* Live Visit Feed for Branch Manager / Cashier / Admin */}
            {(userRole === "Branch Manager" || userRole === "Cashier" || userRole === "Administrator" || userRole === "Auditor") && (
              <div className="fade-in-up fade-in-up-4" style={{ margin: "8px 0" }}>
                <div className="section-header" style={{ padding: "0 16px 6px" }}>
                  <p className="section-title">📡 Real-Time Agent Visits</p>
                </div>
                <div style={{ background: "#ffffff", borderRadius: 16, margin: "0 8px", border: "1px solid #e2e8f0", overflow: "hidden" }}>
                  <LiveVisitFeed autoRefreshMs={30000} showTitle={false} maxRows={8} />
                </div>
              </div>
            )}

            {/* PCMS Module Shortcuts */}
            <div className="section-header fade-in-up fade-in-up-4">
              <p className="section-title">PCMS Modules</p>
            </div>
            <div className={`${styles.pcmsGrid} fade-in-up fade-in-up-4`}>
              {[
                { icon: "💳", label: "Customer Pay", sub: "Direct PG Checkout", bg: "linear-gradient(135deg,#16a34a,#15803d)", path: "/payment" },
                { icon: "📋", label: "Today's Collections", sub: "View daily schedule", bg: "linear-gradient(135deg,#2563eb,#06b6d4)", path: "/collection" },
                { icon: "📊", label: "Daily Summary", sub: "Reports & performance", bg: "linear-gradient(135deg,#7c3aed,#ec4899)", path: "/daily-summary" },
                { icon: "💼", label: "Submit Cash", sub: "End of day closing", bg: "linear-gradient(135deg,#1e293b,#334155)", path: "/submit-cash" },
                { icon: "👣", label: "Next Customer", sub: "Route optimized", bg: "linear-gradient(135deg,#f97316,#eab308)", path: "/next-customer" },
              ].map(m => (
                <div key={m.label} className={styles.pcmsCard} style={{ background: m.bg }} onClick={() => router.push(m.path)}>
                  <span className={styles.pcmsIcon}>{m.icon}</span>
                  <p className={styles.pcmsLabel}>{m.label}</p>
                  <p className={styles.pcmsSub}>{m.sub}</p>
                </div>
              ))}
            </div>
          </div>
          <BottomNav active="home" />
        </div>
      </div>

      {/* ── Daily Reconciliation Drill-Down Modal ── */}
      {showReconModal && (
        <div style={{
          position: "fixed", inset: 0, background: "rgba(0,0,0,0.6)", zIndex: 9999,
          display: "flex", alignItems: "flex-end", justifyContent: "center"
        }}>
          <div style={{
            background: "#fff", borderRadius: "20px 20px 0 0", width: "100%", maxWidth: 430,
            maxHeight: "88vh", overflow: "hidden", display: "flex", flexDirection: "column",
            boxShadow: "0 -8px 40px rgba(0,0,0,0.2)"
          }}>
            {/* Modal Header */}
            <div style={{ padding: "16px 20px 12px", borderBottom: "1px solid #f1f5f9", display: "flex", justifyContent: "space-between", alignItems: "center", flexShrink: 0 }}>
              <div>
                <h3 style={{ margin: 0, fontSize: 15, fontWeight: 900, color: "#0f172a" }}>🏦 Daily Cash Reconciliation</h3>
                <p style={{ margin: 0, fontSize: 11, color: "#64748b" }}>{new Date().toLocaleDateString("en-IN", { weekday: "long", day: "numeric", month: "long" })}</p>
              </div>
              <button
                onClick={() => { setShowReconModal(false); setReconResolveId(null); setReconNote(""); }}
                style={{ background: "#f1f5f9", border: "none", borderRadius: "50%", width: 32, height: 32, fontSize: 16, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}
              >✕</button>
            </div>

            {/* Scrollable content */}
            <div style={{ flex: 1, overflowY: "auto", padding: "12px 20px 24px" }}>
              {reconLoading ? (
                <div style={{ textAlign: "center", padding: 32, color: "#94a3b8" }}>
                  <div style={{ width: 32, height: 32, border: "3px solid #2563eb", borderTopColor: "transparent", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto 10px" }} />
                  Loading reconciliation data…
                </div>
              ) : reconDrillDown.length === 0 ? (
                <p style={{ textAlign: "center", color: "#94a3b8", padding: 24, fontSize: 13 }}>
                  No collection activity found for today.
                </p>
              ) : (
                reconDrillDown.map((r: any) => {
                  const isResolvedOrMatch = r.status === "MATCHED" || r.status === "RESOLVED";
                  return (
                    <div key={r.agentEmail} style={{
                      background: isResolvedOrMatch ? "#f0fdf4" : "#fff5f5",
                      border: `1px solid ${isResolvedOrMatch ? "#bbf7d0" : "#fecaca"}`,
                      borderRadius: 12, padding: "12px 14px", marginBottom: 10
                    }}>
                      {/* Agent header row */}
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
                        <div>
                          <p style={{ margin: 0, fontSize: 13, fontWeight: 800, color: "#0f172a" }}>
                            {r.agentEmail.split("@")[0]}
                          </p>
                          <p style={{ margin: 0, fontSize: 10, color: "#64748b" }}>{r.agentEmail}</p>
                        </div>
                        <span style={{
                          background: r.status === "MATCHED" ? "#dcfce7" : r.status === "RESOLVED" ? "#dbeafe" : "#fee2e2",
                          color: r.status === "MATCHED" ? "#16a34a" : r.status === "RESOLVED" ? "#2563eb" : "#dc2626",
                          padding: "3px 10px", borderRadius: 100, fontSize: 10, fontWeight: 800
                        }}>
                          {r.status === "MATCHED" ? "✓ MATCHED" : r.status === "RESOLVED" ? "✓ RESOLVED" : "⚠ MISMATCH"}
                        </span>
                      </div>

                      {/* Figures row */}
                      <div style={{ display: "flex", gap: 8, marginBottom: 8 }}>
                        <div style={{ flex: 1, background: "#f8fafc", borderRadius: 8, padding: "6px 10px", textAlign: "center" }}>
                          <p style={{ margin: 0, fontSize: 9, color: "#64748b" }}>Collected</p>
                          <p style={{ margin: 0, fontSize: 13, fontWeight: 800, color: "#16a34a" }}>₹{r.totalCollected.toFixed(2)}</p>
                        </div>
                        <div style={{ flex: 1, background: "#f8fafc", borderRadius: 8, padding: "6px 10px", textAlign: "center" }}>
                          <p style={{ margin: 0, fontSize: 9, color: "#64748b" }}>Submitted</p>
                          <p style={{ margin: 0, fontSize: 13, fontWeight: 800, color: "#2563eb" }}>₹{r.totalSubmitted.toFixed(2)}</p>
                        </div>
                        <div style={{ flex: 1, background: r.hasMismatch ? "#fee2e2" : "#f0fdf4", borderRadius: 8, padding: "6px 10px", textAlign: "center" }}>
                          <p style={{ margin: 0, fontSize: 9, color: "#64748b" }}>Difference</p>
                          <p style={{ margin: 0, fontSize: 13, fontWeight: 800, color: r.hasMismatch ? "#dc2626" : "#16a34a" }}>
                            {r.difference >= 0 ? "+" : ""}₹{r.difference.toFixed(2)}
                          </p>
                        </div>
                      </div>

                      {/* Customer breakdown */}
                      {r.breakdown && r.breakdown.length > 0 && (
                        <div style={{ marginBottom: 8 }}>
                          <p style={{ margin: "0 0 4px", fontSize: 10, fontWeight: 700, color: "#475569" }}>
                            Collections breakdown ({r.breakdown.length} customers):
                          </p>
                          {r.breakdown.slice(0, 3).map((b: any, i: number) => (
                            <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "2px 0" }}>
                              <span style={{ fontSize: 10, color: "#64748b" }}>{b.customer_name}</span>
                              <span style={{ fontSize: 10, fontWeight: 700, color: "#0f172a" }}>₹{b.collected_amount} · {b.payment_mode}</span>
                            </div>
                          ))}
                          {r.breakdown.length > 3 && (
                            <p style={{ fontSize: 10, color: "#94a3b8", margin: "2px 0 0" }}>+{r.breakdown.length - 3} more</p>
                          )}
                        </div>
                      )}

                      {/* Resolution info (if already resolved) */}
                      {r.status === "RESOLVED" && (
                        <div style={{ background: "#dbeafe", borderRadius: 6, padding: "5px 8px", fontSize: 10, color: "#1e40af" }}>
                          ✓ Resolved by {r.resolvedBy} · {r.note || "No note"}
                        </div>
                      )}

                      {/* Resolve button for mismatches (only for BM/Admin) */}
                      {r.hasMismatch && (userRole === "Branch Manager" || userRole === "Administrator") && (
                        reconResolveId === r.recordId ? (
                          <div style={{ marginTop: 8 }}>
                            <input
                              type="text"
                              placeholder="Resolution note (optional)"
                              value={reconNote}
                              onChange={(e) => setReconNote(e.target.value)}
                              style={{ width: "100%", padding: "7px 10px", borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12, marginBottom: 6, boxSizing: "border-box" }}
                            />
                            <div style={{ display: "flex", gap: 6 }}>
                              <button
                                onClick={() => { setReconResolveId(null); setReconNote(""); }}
                                style={{ flex: 1, padding: "7px 0", background: "#f1f5f9", color: "#475569", border: "none", borderRadius: 8, fontWeight: 700, fontSize: 11, cursor: "pointer" }}
                              >Cancel</button>
                              <button
                                onClick={handleResolveRecon}
                                disabled={reconLoading}
                                style={{ flex: 2, padding: "7px 0", background: "#2563eb", color: "#fff", border: "none", borderRadius: 8, fontWeight: 800, fontSize: 11, cursor: "pointer" }}
                              >{reconLoading ? "Saving…" : "✓ Confirm Resolve"}</button>
                            </div>
                          </div>
                        ) : (
                          <button
                            onClick={() => setReconResolveId(r.recordId)}
                            style={{ marginTop: 8, width: "100%", padding: "8px 0", background: "#fee2e2", color: "#dc2626", border: "1px solid #fecaca", borderRadius: 8, fontWeight: 800, fontSize: 11, cursor: "pointer" }}
                          >
                            ✎ Resolve Mismatch
                          </button>
                        )
                      )}
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
