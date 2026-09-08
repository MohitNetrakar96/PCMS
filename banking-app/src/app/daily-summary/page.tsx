"use client";
import { useRef, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import { api } from "@/services/api";
import styles from "./page.module.css";

const HOURS = ["8", "9", "10", "11", "12", "1", "2", "3", "4", "5", "6", "7"];

export default function DailySummaryPage() {
  const router = useRouter();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [submitted, setSubmitted] = useState(false);
  const [exporting, setExporting] = useState<"pdf" | "excel" | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const [summary, setSummary] = useState({
    totalVisited: 8,
    totalCollected: 4,
    totalPending: 4,
    failedVisits: 0,
    totalAmount: 2500,
    cashCollection: 1500,
    upiCollection: 1000,
    chequeCollection: 0,
    collectionPct: 50,
    cashInHand: 1500,
    agentExpenses: 120,
    agentName: "Rahul Verma",
    agentEmail: "agent@bankflow.com",
    branch: "Gandhi Nagar Branch",
    date: new Date().toLocaleDateString("en-IN", { weekday: "long", day: "numeric", month: "long", year: "numeric" }),
  });

  const [hourlyList, setHourlyList] = useState([0, 1, 2, 3, 5, 7, 9, 11, 11, 12, 13, 14]);

  useEffect(() => {
    const sessionName = localStorage.getItem("pcms_session_name") || "Rahul Verma";
    const sessionEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";

    const loadSummary = async () => {
      const serverList = await api.getTodayCollections(sessionEmail);
      const records = (serverList && serverList.length > 0) ? serverList : JSON.parse(localStorage.getItem("pcms_collections_today") || "[]");

      const totalExpectedCount = records.length || 8;
      const visitedRecords = records.filter((r: any) => r.status && r.status !== "pending");
      const visitedCount = visitedRecords.length;
      const collectedRecords = records.filter((r: any) => r.status === "collected");
      const collectedCount = collectedRecords.length;
      const failedCount = records.filter((r: any) => r.status && r.status !== "collected" && r.status !== "pending").length;
      const pendingCount = Math.max(0, totalExpectedCount - visitedCount);

      const totalCollectedAmt = collectedRecords.reduce((sum: number, r: any) => sum + (r.collected_amount || r.amount || 0), 0);
      const cashAmt = collectedRecords.filter((r: any) => (r.payment_mode || r.paymentMode) === "CASH" || !(r.payment_mode || r.paymentMode)).reduce((sum: number, r: any) => sum + (r.collected_amount || r.amount || 0), 0);
      const upiAmt = collectedRecords.filter((r: any) => (r.payment_mode || r.paymentMode) === "UPI" || (r.payment_mode || r.paymentMode) === "QR").reduce((sum: number, r: any) => sum + (r.collected_amount || r.amount || 0), 0);
      const chequeAmt = collectedRecords.filter((r: any) => (r.payment_mode || r.paymentMode) === "CHEQUE" || (r.payment_mode || r.paymentMode) === "NEFT").reduce((sum: number, r: any) => sum + (r.collected_amount || r.amount || 0), 0);

      const collectionPct = totalExpectedCount > 0 ? Math.min(100, Math.round((collectedCount / totalExpectedCount) * 100)) : 0;

      setSummary({
        totalVisited: visitedCount,
        totalCollected: collectedCount,
        totalPending: pendingCount,
        failedVisits: failedCount,
        totalAmount: totalCollectedAmt,
        cashCollection: cashAmt,
        upiCollection: upiAmt,
        chequeCollection: chequeAmt,
        collectionPct: collectionPct,
        cashInHand: cashAmt,
        agentExpenses: 120,
        agentName: sessionName,
        agentEmail: sessionEmail,
        branch: "Bangalore Central Branch",
        date: new Date().toLocaleDateString("en-IN", { weekday: "long", day: "numeric", month: "long", year: "numeric" }),
      });

      const hourly = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      let cumulative = 0;
      const step = (collectedCount || 1) / 12;
      for (let i = 0; i < 12; i++) {
        cumulative += step;
        hourly[i] = Math.min(collectedCount, Math.round(cumulative));
      }
      hourly[11] = collectedCount;
      setHourlyList(hourly);
    };

    loadSummary();
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const W = canvas.width;
    const H = canvas.height;
    const padL = 28, padR = 12, padT = 16, padB = 28;
    const chartW = W - padL - padR;
    const chartH = H - padT - padB;
    const maxVal = Math.max(10, summary.totalCollected + 2);

    ctx.clearRect(0, 0, W, H);

    // Grid lines
    for (let i = 0; i <= 5; i++) {
      const y = padT + chartH - (i / 5) * chartH;
      ctx.strokeStyle = "#f1f5f9";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(padL, y);
      ctx.lineTo(padL + chartW, y);
      ctx.stroke();
      ctx.fillStyle = "#94a3b8";
      ctx.font = "10px sans-serif";
      ctx.textAlign = "right";
      ctx.fillText(String(Math.round((i / 5) * maxVal)), padL - 4, y + 4);
    }

    // Area fill
    const gradient = ctx.createLinearGradient(0, padT, 0, H);
    gradient.addColorStop(0, "rgba(37,99,235,0.25)");
    gradient.addColorStop(1, "rgba(37,99,235,0)");

    ctx.beginPath();
    hourlyList.forEach((val, i) => {
      const x = padL + (i / (hourlyList.length - 1)) * chartW;
      const y = padT + chartH - (val / maxVal) * chartH;
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    });
    const lastX = padL + chartW;
    const firstX = padL;
    ctx.lineTo(lastX, padT + chartH);
    ctx.lineTo(firstX, padT + chartH);
    ctx.closePath();
    ctx.fillStyle = gradient;
    ctx.fill();

    // Line
    ctx.beginPath();
    ctx.strokeStyle = "#2563eb";
    ctx.lineWidth = 2.5;
    ctx.lineJoin = "round";
    ctx.lineCap = "round";
    hourlyList.forEach((val, i) => {
      const x = padL + (i / (hourlyList.length - 1)) * chartW;
      const y = padT + chartH - (val / maxVal) * chartH;
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    });
    ctx.stroke();

    // Dots
    hourlyList.forEach((val, i) => {
      const x = padL + (i / (hourlyList.length - 1)) * chartW;
      const y = padT + chartH - (val / maxVal) * chartH;
      ctx.beginPath();
      ctx.arc(x, y, 3, 0, Math.PI * 2);
      ctx.fillStyle = "#2563eb";
      ctx.fill();
      ctx.fillStyle = "#94a3b8";
      ctx.font = "8px sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(HOURS[i], x, H - 8);
    });
  }, [summary, hourlyList]);

  const handleExport = (type: "pdf" | "excel") => {
    setExporting(type);
    setTimeout(() => setExporting(null), 2000);
  };

  const handleSubmitBranch = () => {
    setSubmitting(true);
    setTimeout(() => { setSubmitting(false); setSubmitted(true); }, 2200);
  };

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
            {/* Header */}
            <div className={styles.header}>
              <div>
                <h1 className={styles.title}>Daily Summary</h1>
                <p className={styles.subtitle}>{summary.date}</p>
              </div>
              <div className={styles.agentBadge}>
                <div className={styles.agentAvatar}>{summary.agentName.charAt(0)}</div>
              </div>
            </div>

            {/* Agent Card */}
            <div className={`${styles.agentCard} fade-in-up`}>
              <div className={styles.agentInfo}>
                <p className={styles.agentName}>{summary.agentName}</p>
                <p className={styles.agentDetail}>{summary.agentEmail}</p>
                <p className={styles.agentDetail}>{summary.branch}</p>
              </div>
              <div className={styles.collPctCircle}>
                <svg viewBox="0 0 80 80" width="72" height="72">
                  <circle cx="40" cy="40" r="32" fill="none" stroke="#e2e8f0" strokeWidth="7"/>
                  <circle cx="40" cy="40" r="32" fill="none" stroke="#2563eb" strokeWidth="7"
                    strokeDasharray={`${(summary.collectionPct / 100) * 201} 201`}
                    strokeDashoffset="50" strokeLinecap="round" transform="rotate(-90 40 40)"/>
                  <text x="40" y="44" textAnchor="middle" fontSize="15" fontWeight="900" fill="#2563eb">{summary.collectionPct}%</text>
                </svg>
                <p className={styles.pctLabel}>Collection</p>
              </div>
            </div>

            {/* Stats Grid */}
            <div className={`${styles.statsGrid} fade-in-up`}>
              {[
                { label: "Visited", value: summary.totalVisited, color: "#eff6ff", text: "#2563eb", icon: "👣" },
                { label: "Collected", value: summary.totalCollected, color: "#dcfce7", text: "#16a34a", icon: "✅" },
                { label: "Pending", value: summary.totalPending, color: "#fef3c7", text: "#d97706", icon: "⏳" },
                { label: "Failed", value: summary.failedVisits, color: "#fee2e2", text: "#dc2626", icon: "❌" },
              ].map(s => (
                <div key={s.label} className={styles.statCard} style={{ background: s.color }}>
                  <span className={styles.statIcon}>{s.icon}</span>
                  <p className={styles.statNum} style={{ color: s.text }}>{s.value}</p>
                  <p className={styles.statLabel}>{s.label}</p>
                </div>
              ))}
            </div>

            {/* Collection Breakdown */}
            <div className={`${styles.section} fade-in-up`}>
              <p className={styles.sectionTitle}>💰 Collection Breakdown</p>
              {[
                { label: "Total Amount", value: `₹${summary.totalAmount.toLocaleString()}`, pct: 100, color: "#2563eb" },
                { label: "Cash Collection", value: `₹${summary.cashCollection}`, pct: summary.totalAmount > 0 ? Math.round(summary.cashCollection / summary.totalAmount * 100) : 0, color: "#22c55e" },
                { label: "UPI Collection", value: `₹${summary.upiCollection}`, pct: summary.totalAmount > 0 ? Math.round(summary.upiCollection / summary.totalAmount * 100) : 0, color: "#8b5cf6" },
                { label: "Cheque Collection", value: `₹${summary.chequeCollection}`, pct: summary.totalAmount > 0 ? Math.round(summary.chequeCollection / summary.totalAmount * 100) : 0, color: "#f97316" },
              ].map(r => (
                <div key={r.label} className={styles.breakdownRow}>
                  <div className={styles.breakdownTop}>
                    <span className={styles.breakdownLabel}>{r.label}</span>
                    <span className={styles.breakdownVal}>{r.value}</span>
                  </div>
                  <div className={styles.breakdownBarBg}>
                    <div className={styles.breakdownBarFill} style={{ width: `${r.pct}%`, background: r.color }} />
                  </div>
                </div>
              ))}
            </div>

            {/* Cash in Hand & Expenses */}
            <div className={`${styles.handSection} fade-in-up`}>
              <div className={styles.handCard} style={{ background: "linear-gradient(135deg,#dcfce7,#f0fdf4)", border: "1.5px solid #86efac" }}>
                <p className={styles.handIcon}>💵</p>
                <p className={styles.handAmt}>₹{summary.cashInHand.toLocaleString()}</p>
                <p className={styles.handLabel}>Cash in Hand</p>
              </div>
              <div className={styles.handCard} style={{ background: "linear-gradient(135deg,#fef3c7,#fffbeb)", border: "1.5px solid #fde68a" }}>
                <p className={styles.handIcon}>🧾</p>
                <p className={styles.handAmt}>₹{summary.agentExpenses}</p>
                <p className={styles.handLabel}>Agent Expenses</p>
              </div>
            </div>

            {/* Performance Graph */}
            <div className={`${styles.section} fade-in-up`}>
              <p className={styles.sectionTitle}>📈 Daily Performance Graph</p>
              <p className={styles.graphSubtitle}>Collections by hour (8 AM – 7 PM)</p>
              <canvas ref={canvasRef} width={310} height={130} className={styles.chart} />
            </div>

            {/* Export Actions */}
            <div className={`${styles.exportRow} fade-in-up`}>
              <button className={`${styles.exportBtn} ${exporting === "pdf" ? styles.exporting : ""}`} onClick={() => handleExport("pdf")}>
                {exporting === "pdf" ? "⏳ Generating…" : "📄 Download PDF"}
              </button>
              <button className={`${styles.exportBtn} ${styles.excelBtn} ${exporting === "excel" ? styles.exporting : ""}`} onClick={() => handleExport("excel")}>
                {exporting === "excel" ? "⏳ Exporting…" : "📊 Export Excel"}
              </button>
            </div>

            {/* Submit to Branch */}
            <div style={{ padding: "0 16px 8px" }} className="fade-in-up">
              {submitted ? (
                <div className={styles.submittedBox}>
                  <p>✅ Summary submitted to <strong>{summary.branch}</strong>!</p>
                </div>
              ) : (
                <button className={`btn btn-primary ${submitting ? styles.submitting : ""}`} onClick={handleSubmitBranch} disabled={submitting}>
                  {submitting ? "⏳ Submitting to Branch…" : "🏦 Submit Summary to Branch"}
                </button>
              )}
            </div>

            {/* Submit Cash CTA */}
            <div style={{ padding: "0 16px 16px" }} className="fade-in-up">
              <button className={styles.submitCashBtn} onClick={() => router.push("/submit-cash")}>
                💼 Proceed to Submit Cash →
              </button>
            </div>
          </div>
          <BottomNav active="analytics" />
        </div>
      </div>
    </div>
  );
}
