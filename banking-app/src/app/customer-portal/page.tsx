"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import PaymentGatewayModal from "@/components/PaymentGatewayModal";
import styles from "./page.module.css";

const VISIT_STATUSES_MAP: Record<string, { label: string; color: string; bg: string; icon: string }> = {
  collected:        { label: "Collected Today", color: "#16a34a", bg: "#dcfce7", icon: "✅" },
  not_available:    { label: "Not Available",   color: "#d97706", bg: "#fef3c7", icon: "🚫" },
  house_locked:     { label: "House Locked",    color: "#dc2626", bg: "#fee2e2", icon: "🔒" },
  payment_tomorrow: { label: "Pay Tomorrow",    color: "#7c3aed", bg: "#ede9fe", icon: "📅" },
  shifted:          { label: "Shifted",          color: "#475569", bg: "#f1f5f9", icon: "🚚" },
  pending:          { label: "Agent on Route",   color: "#2563eb", bg: "#eff6ff", icon: "⏳" },
};

export default function CustomerPortalPage() {
  const router = useRouter();
  const { notifySuccess, notifyWarning, notifyError } = useNotification();

  const [customer, setCustomer] = useState<any>(null);
  const [todayVisit, setTodayVisit] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [photoUrl, setPhotoUrl] = useState<string | null>(null);
  const [savingPhoto, setSavingPhoto] = useState(false);
  const [isGatewayOpen, setIsGatewayOpen] = useState(false);
  const [interestData, setInterestData] = useState<any>(null);
  const [closureModal, setClosureModal] = useState<"close" | "renew" | null>(null);
  const [closureLoading, setClosureLoading] = useState(false);

  const customerId = "1"; // Default active customer profile

  const loadData = async () => {
    try {
      const data = await api.getCustomer(customerId, "Customer");
      if (data) {
        setCustomer(data);
        if (data.photo_url) setPhotoUrl(data.photo_url);

        // Load interest history for the first account
        const acctId = data.accounts?.[0]?.id;
        if (acctId) {
          const ih = await api.getInterestHistory(acctId);
          if (ih) setInterestData(ih);
        }
      }

      const visitsData = await api.getLiveVisits();
      if (visitsData?.visits) {
        const found = visitsData.visits.find((v: any) => v.customerId === data?.id || v.customerId === customerId);
        if (found) setTodayVisit(found);
      }
    } catch (e: any) {
      console.warn("Error loading customer portal data:", e.message);
    } finally {
      setLoading(false);
    }
  };

  const handleCloseAccount = async () => {
    const acctId = customer?.accounts?.[0]?.id;
    if (!acctId) return;
    setClosureLoading(true);
    try {
      const res = await api.closeAccount(acctId, { performedBy: "Cashier", performedByRole: "Cashier" });
      notifySuccess("Account Closed", `Payout: ₹${res.payout?.toLocaleString()}. Penalty: ₹${res.penalty ?? 0}.`);
      setClosureModal(null);
      await loadData();
    } catch (e: any) {
      notifyError("Closure Failed", e.message || "Could not close account.");
    } finally {
      setClosureLoading(false);
    }
  };

  const handleRenewAccount = async () => {
    const acctId = customer?.accounts?.[0]?.id;
    if (!acctId) return;
    setClosureLoading(true);
    try {
      const res = await api.renewAccount(acctId, { performedBy: "Customer", performedByRole: "Cashier" });
      notifySuccess("Account Renewed!", `New maturity: ${res.newMaturityDate}. Balance carried: ₹${res.newBalance?.toLocaleString()}.`);
      setClosureModal(null);
      await loadData();
    } catch (e: any) {
      notifyError("Renewal Failed", e.message || "Could not renew account.");
    } finally {
      setClosureLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(() => loadData(), 20000); // 20s polling for real-time tracking
    return () => clearInterval(interval);
  }, []);

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setSavingPhoto(true);

    try {
      const reader = new FileReader();
      reader.onload = async (event) => {
        const base64 = event.target?.result as string;
        setPhotoUrl(base64);
        try {
          await api.updateCustomerPhoto(customer?.id || customerId, base64);
          notifySuccess("Photo Updated", "Your profile photograph has been saved!");
        } catch {
          notifyWarning("Photo Uploaded", "Saved locally. Will sync online.");
        }
        setSavingPhoto(false);
      };
      reader.readAsDataURL(file);
    } catch {
      setSavingPhoto(false);
    }
  };

  const handlePaymentSuccess = async (details: { paymentMode: string; transactionId: string; amount: number }) => {
    setIsGatewayOpen(false);
    const agentEmail = "agent@bankflow.com";
    const payAmt = customer?.accounts?.[0]?.daily_target || customer?.opening_balance * 0.05 || 500;

    try {
      await api.recordCollection({
        customerId: customer?.id || customerId,
        agentEmail,
        status: "collected",
        collectedAmount: payAmt,
        depositTotal: payAmt,
        paymentMode: details.paymentMode.toUpperCase(),
        remarks: "Online Payment via Customer Portal",
      });

      notifySuccess(
        "Payment Completed!",
        `₹${payAmt} paid successfully via ${details.paymentMode}. Reflected live on your Agent's Dashboard!`
      );

      loadData();
      router.push(`/receipt/${customer?.id || customerId}`);
    } catch (err: any) {
      notifyError("Error", err.message || "Failed to process payment.");
    }
  };

  if (loading) {
    return (
      <div className="app-wrapper">
        <div className="phone-frame">
          <div className="screen">
            <div className="screen-content" style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%" }}>
              <div style={{ textAlign: "center" }}>
                <div style={{ width: 40, height: 40, border: "3px solid #2563eb", borderTopColor: "transparent", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto 12px" }} />
                <p style={{ color: "#64748b", fontSize: 13 }}>Loading Customer Portal…</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!customer) {
    return (
      <div className="app-wrapper">
        <div className="phone-frame">
          <div className="screen">
            <div className="screen-content" style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "100%", padding: 24, textAlign: "center" }}>
              <p style={{ fontSize: 48, margin: "0 0 12px 0" }}>👤</p>
              <h3 style={{ fontSize: 18, fontWeight: 800, color: "#0f172a", marginBottom: 6 }}>No Active Customer Profile</h3>
              <p style={{ fontSize: 13, color: "#64748b", marginBottom: 20 }}>
                Please register or select a live customer profile to view your passbook and make payments.
              </p>
              <button
                className="btn btn-primary"
                onClick={() => router.push("/collection")}
              >
                ➕ Go to Collections / Add Customer
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const name = customer.name;
  const phone = customer.phone || "";
  const acct = customer.accounts?.[0];
  const acctNo = acct?.account_number || `PCMS-00${customer.id}`;
  const balance = acct?.balance ?? customer.opening_balance ?? 0;
  const dailyTarget = acct?.daily_target ?? Math.round(balance * 0.05) ?? 0;
  const visitStatus = todayVisit?.status || "pending";
  const statusInfo = VISIT_STATUSES_MAP[visitStatus] || VISIT_STATUSES_MAP.pending;

  return (
    <div className="app-wrapper">
      <div className="phone-frame">
        <div className="status-bar light">
          <span>{new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}</span>
          <div className="status-bar__icons">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 6s4-4 11-4 11 4 11 4"/><path d="M5 10s3-3 7-3 7 3 7 3"/><path d="M9 14s1.5-1.5 3-1.5 3 1.5 3 1.5"/><circle cx="12" cy="18" r="1" fill="currentColor"/></svg>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="15" height="10" rx="2"/><path d="M22 11v2"/></svg>
          </div>
        </div>

        <div className="screen">
          <div className="screen-content">

            {/* Top Bar */}
            <div className={styles.header}>
              <div className={styles.brand}>
                <div className={styles.brandLogo}>👤</div>
                <div>
                  <h3 className={styles.title}>Customer Portal</h3>
                  <p className={styles.subTitle}>My Pigmy &amp; Loan Passbook</p>
                </div>
              </div>
              <button
                type="button"
                className={styles.switchViewBtn}
                onClick={() => router.push("/dashboard")}
                title="Switch to Staff Dashboard"
              >
                <span>💼 Staff View</span>
              </button>
            </div>

            {/* Profile Card */}
            <div className={styles.profileCard}>
              <div className={styles.photoContainer}>
                {photoUrl ? (
                  <img src={photoUrl} alt={name} className={styles.custPhoto} />
                ) : (
                  <div className={styles.photoFallback}>
                    {name.split(" ").map((n: string) => n[0]).join("").substring(0, 2).toUpperCase()}
                  </div>
                )}
                <label className={styles.cameraBtn} title="Upload/Change Profile Photo">
                  {savingPhoto ? "⏳" : "📷"}
                  <input
                    type="file"
                    accept="image/*"
                    capture="environment"
                    onChange={handlePhotoUpload}
                    style={{ display: "none" }}
                  />
                </label>
              </div>

              <div className={styles.profileInfo}>
                <h2 className={styles.custName}>{name}</h2>
                <p className={styles.custPhone}>{phone}</p>
                <span className={styles.acctTag}>{acctNo}</span>
              </div>
            </div>

            {/* Financial Balances Grid */}
            <div className={styles.balanceGrid}>
              <div className={styles.balCard}>
                <p className={styles.balLabel}>Pigmy Savings Balance</p>
                <h3 className={styles.balVal} style={{ color: "#16a34a" }}>
                  ₹{balance.toLocaleString()}
                </h3>
              </div>
              <div className={styles.balCard}>
                <p className={styles.balLabel}>Daily Target</p>
                <h3 className={styles.balVal} style={{ color: "#2563eb" }}>
                  ₹{dailyTarget}
                </h3>
              </div>
            </div>

            {/* ── Maturity Countdown Card ── */}
            {interestData && (
              <div style={{
                background: interestData.status === "MATURED" ? "linear-gradient(135deg,#16a34a,#15803d)"
                  : interestData.status === "CLOSED" ? "linear-gradient(135deg,#64748b,#475569)"
                  : "linear-gradient(135deg,#2563eb,#1d4ed8)",
                borderRadius: 14, padding: "14px 16px", color: "#fff", marginBottom: 12
              }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <div>
                    <p style={{ margin: 0, fontSize: 10, fontWeight: 700, opacity: 0.8, textTransform: "uppercase", letterSpacing: 1 }}>
                      {interestData.status === "MATURED" ? "🎉 Account Matured!" : interestData.status === "CLOSED" ? "🔒 Account Closed" : "⏳ Pigmy Account"}
                    </p>
                    <p style={{ margin: "4px 0 0", fontSize: 18, fontWeight: 900 }}>
                      {interestData.status === "ACTIVE" && interestData.daysToMaturity !== null
                        ? `Matures in ${interestData.daysToMaturity} days`
                        : interestData.status === "MATURED"
                        ? `Matured on ${interestData.maturityDate}`
                        : "Account Settled"}
                    </p>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <p style={{ margin: 0, fontSize: 10, opacity: 0.8 }}>Interest Rate</p>
                    <p style={{ margin: 0, fontSize: 16, fontWeight: 900 }}>{interestData.interestRate ?? 5}% p.a.</p>
                  </div>
                </div>
                <div style={{ display: "flex", gap: 8, marginTop: 10, padding: "8px 0 0", borderTop: "1px solid rgba(255,255,255,0.2)" }}>
                  <div style={{ flex: 1, textAlign: "center" }}>
                    <p style={{ margin: 0, fontSize: 10, opacity: 0.75 }}>Total Deposited</p>
                    <p style={{ margin: 0, fontSize: 13, fontWeight: 800 }}>₹{balance.toLocaleString()}</p>
                  </div>
                  <div style={{ flex: 1, textAlign: "center", borderLeft: "1px solid rgba(255,255,255,0.2)" }}>
                    <p style={{ margin: 0, fontSize: 10, opacity: 0.75 }}>Interest Accrued</p>
                    <p style={{ margin: 0, fontSize: 13, fontWeight: 800 }}>₹{interestData.totalAccruedInterest?.toFixed(2) ?? "0.00"}</p>
                  </div>
                  <div style={{ flex: 1, textAlign: "center", borderLeft: "1px solid rgba(255,255,255,0.2)" }}>
                    <p style={{ margin: 0, fontSize: 10, opacity: 0.75 }}>Projected Payout</p>
                    <p style={{ margin: 0, fontSize: 13, fontWeight: 800 }}>₹{interestData.projectedPayout?.toLocaleString()}</p>
                  </div>
                </div>
              </div>
            )}

            {/* Close / Renew Account Buttons */}
            {interestData && (interestData.status === "MATURED" || interestData.status === "ACTIVE") && (
              <div style={{ display: "flex", gap: 8, marginBottom: 12 }}>
                {interestData.status === "MATURED" && (
                  <button
                    onClick={() => setClosureModal("renew")}
                    style={{ flex: 1, background: "#dcfce7", color: "#16a34a", border: "1px solid #bbf7d0", borderRadius: 10, padding: "10px 0", fontWeight: 800, fontSize: 12, cursor: "pointer" }}
                  >
                    🔄 Renew 12 Months
                  </button>
                )}
                <button
                  onClick={() => setClosureModal("close")}
                  style={{ flex: 1, background: "#fee2e2", color: "#dc2626", border: "1px solid #fecaca", borderRadius: 10, padding: "10px 0", fontWeight: 800, fontSize: 12, cursor: "pointer" }}
                >
                  🔒 Close Account
                </button>
              </div>
            )}

            {/* Pay Installment Button */}
            {interestData?.status !== "CLOSED" && (
              <button
                type="button"
                className={styles.payNowBtn}
                onClick={() => setIsGatewayOpen(true)}
              >
                <span>💳 Pay Daily Deposit ₹{dailyTarget}</span>
              </button>
            )}

            {/* Real-time Agent Visit Tracker */}
            <div className={styles.visitTracker}>
              <div className={styles.trackerTitle}>
                <span>📡 Collection Agent Tracking</span>
                <span style={{ fontSize: 9, color: "#16a34a", fontWeight: 700 }}>● REAL-TIME</span>
              </div>

              <div className={styles.agentCard}>
                <div className={styles.agentAvatar}>👤</div>
                <div>
                  <p className={styles.agentName}>Rahul Verma (Collection Agent)</p>
                  <p style={{ fontSize: 10, color: "#64748b", margin: 0 }}>Gandhi Nagar / Sector 12 Route</p>
                </div>
              </div>

              <div
                className={styles.statusBanner}
                style={{ background: statusInfo.bg, color: statusInfo.color }}
              >
                <span>{statusInfo.icon} Today&apos;s Visit Status</span>
                <span>{statusInfo.label}</span>
              </div>
            </div>

            {/* Recent Passbook History — with INTEREST entries styled distinctly */}
            <div className={styles.historySection}>
              <p style={{ fontSize: 13, fontWeight: 800, color: "#0f172a", marginBottom: 8 }}>
                📜 Recent Passbook History
              </p>
              {customer?.history && customer.history.length > 0 ? (
                customer.history.slice(0, 6).map((h: any, i: number) => {
                  const isInterest = h.status === "INTEREST";
                  return (
                    <div key={i} className={styles.historyRow}
                      style={{ background: isInterest ? "#f0fdf4" : undefined, border: isInterest ? "1px solid #bbf7d0" : undefined, borderRadius: isInterest ? 8 : undefined }}
                    >
                      <div>
                        <p style={{ fontSize: 12, fontWeight: 700, color: isInterest ? "#16a34a" : "#0f172a", margin: 0 }}>
                          {isInterest ? "📈 " : ""}₹{h.amount} {isInterest ? "(Interest Credit)" : `(${h.payment_mode || "CASH"})`}
                        </p>
                        <p style={{ fontSize: 10, color: "#64748b", margin: 0 }}>
                          {h.collection_date} {isInterest ? "· System Credited" : ""}
                        </p>
                      </div>
                      {!isInterest && (
                        <button
                          type="button"
                          className={styles.receiptBtn}
                          onClick={() => router.push(`/receipt/${customer?.id || customerId}`)}
                        >
                          Receipt 📄
                        </button>
                      )}
                      {isInterest && (
                        <span style={{ fontSize: 10, background: "#dcfce7", color: "#15803d", padding: "2px 8px", borderRadius: 100, fontWeight: 700 }}>INTEREST</span>
                      )}
                    </div>
                  );
                })
              ) : (
                <div style={{ textAlign: "center", padding: "12px 0", color: "#94a3b8", fontSize: 12 }}>
                  No recent passbook transactions
                </div>
              )}
            </div>

          </div>

          <BottomNav active="cards" />
        </div>
      </div>

      <PaymentGatewayModal
        isOpen={isGatewayOpen}
        onClose={() => setIsGatewayOpen(false)}
        amount={dailyTarget}
        customerName={name}
        accountNumber={acctNo}
        onSuccess={handlePaymentSuccess}
      />

      {/* ── Closure / Renewal Confirmation Modal ── */}
      {closureModal && (
        <div style={{
          position: "fixed", inset: 0, background: "rgba(0,0,0,0.55)", display: "flex",
          alignItems: "center", justifyContent: "center", zIndex: 9999, padding: 24
        }}>
          <div style={{ background: "#fff", borderRadius: 16, padding: 24, width: "100%", maxWidth: 360, boxShadow: "0 20px 60px rgba(0,0,0,0.25)" }}>
            <p style={{ fontSize: 28, margin: "0 0 8px", textAlign: "center" }}>
              {closureModal === "close" ? "🔒" : "🔄"}
            </p>
            <h3 style={{ fontWeight: 900, textAlign: "center", margin: "0 0 10px", color: "#0f172a" }}>
              {closureModal === "close" ? "Close Account?" : "Renew Account?"}
            </h3>
            <p style={{ fontSize: 13, color: "#64748b", textAlign: "center", marginBottom: 20, lineHeight: 1.5 }}>
              {closureModal === "close"
                ? `Your payout will be calculated as Total Deposits + Accrued Interest${interestData?.status !== "MATURED" ? " (minus 1% premature penalty)" : ""}. This action is irreversible.`
                : `Your account will be renewed for another 12 months. Current payout of ₹${balance.toLocaleString()} will become the opening balance.`
              }
            </p>
            <div style={{ display: "flex", gap: 10 }}>
              <button
                onClick={() => setClosureModal(null)}
                disabled={closureLoading}
                style={{ flex: 1, padding: "11px 0", background: "#f1f5f9", color: "#475569", border: "none", borderRadius: 10, fontWeight: 700, cursor: "pointer" }}
              >
                Cancel
              </button>
              <button
                onClick={closureModal === "close" ? handleCloseAccount : handleRenewAccount}
                disabled={closureLoading}
                style={{
                  flex: 1, padding: "11px 0",
                  background: closureModal === "close" ? "#dc2626" : "#16a34a",
                  color: "#fff", border: "none", borderRadius: 10, fontWeight: 800, cursor: "pointer"
                }}
              >
                {closureLoading ? "Processing…" : closureModal === "close" ? "Confirm Close" : "Confirm Renew"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
