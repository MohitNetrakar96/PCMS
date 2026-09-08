"use client";
import { useState, useEffect } from "react";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import styles from "./page.module.css";

export default function CardsPage() {
  const { notifySuccess, confirmDialog } = useNotification();
  const [activeCard, setActiveCard] = useState(0);
  const [agentName, setAgentName] = useState("Rahul Verma");
  const [ledgers, setLedgers] = useState<any[]>([]);

  useEffect(() => {
    const sessionName = localStorage.getItem("pcms_session_name");
    if (sessionName) {
      setAgentName(sessionName);
    }

    loadData();
  }, []);

  const loadData = async () => {
    const data = await api.getPassbooks();
    if (data && data.accounts) {
      const gradients = ["var(--gradient-card1)", "var(--gradient-card2)", "var(--gradient-card3)", "var(--gradient-hero)"];
      const mapped = data.accounts.map((acc: any, idx: number) => ({
        id: acc.id,
        account_number: acc.account_number,
        customer_id: acc.customer_id,
        type: acc.account_type.toUpperCase(),
        balance: `₹${acc.balance.toLocaleString()}`,
        number: `A/C: ${acc.account_number}`,
        holder: acc.customer_name,
        area: acc.area || "Area",
        gradient: gradients[idx % gradients.length],
        history: (data.recentTransactions || [])
          .filter((t: any) => t.customer_id === acc.customer_id)
          .map((t: any) => ({
            id: t.id,
            date: t.collection_date,
            desc: `${t.payment_mode || 'Cash'} collection`,
            amount: `+₹${t.amount}`,
            status: "Success"
          }))
      }));
      setLedgers(mapped);
    }
  };

  const handleDeleteAccount = async () => {
    if (!currentLedger?.id) return;
    const ok = await confirmDialog({
      title: `Delete Account ${currentLedger.number}?`,
      message: `Are you sure you want to permanently delete passbook account for ${currentLedger.holder}?`,
      confirmText: "Delete Account",
      type: "danger"
    });
    if (!ok) return;

    await api.deleteAccount(currentLedger.id);
    await loadData();
    setActiveCard(0);
    notifySuccess("Account Deleted", `Account ${currentLedger.number} was removed.`);
  };

  const handleClearHistory = async () => {
    const ok = await confirmDialog({
      title: "Clear History?",
      message: "Are you sure you want to clear all transaction history records permanently?",
      confirmText: "Clear All",
      type: "danger"
    });
    if (!ok) return;

    await api.clearAllCollectionHistory();
    await loadData();
    notifySuccess("History Cleared", "Ledger statement history wiped.");
  };

  const currentLedger = ledgers[activeCard] || ledgers[0] || {
    id: 1, type: "SAVINGS PASSBOOK", balance: "₹0", number: "A/C: —", holder: "—", area: "—", gradient: "var(--gradient-card1)", history: []
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
            <Header name={agentName} greeting="Ledger Directory" />

            {/* Card carousel */}
            <div className={`${styles.cardCarousel} fade-in-up`}>
              {ledgers.map((card: any, i: number) => (
                <div
                  key={card.id}
                  className={`credit-card ${styles.cardItem} ${i === activeCard ? styles.cardActive : styles.cardInactive}`}
                  style={{ background: card.gradient, zIndex: ledgers.length - Math.abs(i - activeCard) }}
                  onClick={() => setActiveCard(i)}
                >
                  <div>
                    <div className="card-chip" />
                    <p className="card-type" style={{ letterSpacing: "1px", fontSize: "10px" }}>{card.type}</p>
                  </div>
                  <div>
                    <p className="card-balance" style={{ fontSize: "24px" }}>{card.balance}</p>
                    <p className="card-number" style={{ fontSize: "13px" }}>{card.number}</p>
                  </div>
                  <div className="card-footer">
                    <div>
                      <p style={{ fontSize: 9, opacity: 0.8 }}>DEPOSITOR</p>
                      <p className="card-holder" style={{ fontSize: "13px" }}>{card.holder}</p>
                    </div>
                    <div style={{ textAlign: "right" }}>
                      <p style={{ fontSize: 9, opacity: 0.8 }}>AREA</p>
                      <p className="card-expiry" style={{ fontSize: "13px" }}>{card.area}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Dots */}
            <div className={styles.dots}>
              {ledgers.map((_: any, i: number) => (
                <button key={i} className={`${styles.dot} ${i === activeCard ? styles.dotActive : ""}`} onClick={() => setActiveCard(i)} />
              ))}
            </div>

            {/* Card actions */}
            <div className={`${styles.cardActions} fade-in-up fade-in-up-1`}>
              {[
                { icon: "💰", label: "Collect" },
                { icon: "📝", label: "KYC Photo" },
                { icon: "📊", label: "Ledger" },
                { icon: "✉️", label: "SMS Alert" },
              ].map((a) => (
                <div key={a.label} className={styles.cardAction}>
                  <div className={styles.cardActionIcon}>{a.icon}</div>
                  <span className={styles.cardActionLabel}>{a.label}</span>
                </div>
              ))}
            </div>

            {/* Card details */}
            <div className={`${styles.detailsCard} fade-in-up fade-in-up-2`}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
                <p className={styles.detailsTitle} style={{ margin: 0 }}>Account Parameters</p>
                {currentLedger?.id && (
                  <button
                    type="button"
                    onClick={handleDeleteAccount}
                    style={{ background: "#fee2e2", color: "#dc2626", border: "none", borderRadius: 8, padding: "4px 8px", fontSize: 11, fontWeight: 700, cursor: "pointer", display: "flex", alignItems: "center", gap: 4 }}
                  >
                    🗑️ Delete Account
                  </button>
                )}
              </div>
              {[
                { label: "Account Number", value: currentLedger.number },
                { label: "Depositor Name", value: currentLedger.holder },
                { label: "Geographic Area", value: currentLedger.area },
                { label: "Account Type", value: currentLedger.type },
                { label: "Current Balance", value: currentLedger.balance },
              ].map((d) => (
                <div key={d.label} className={styles.detailRow}>
                  <span className={styles.detailLabel}>{d.label}</span>
                  <span className={styles.detailValue}>{d.value}</span>
                </div>
              ))}
            </div>

            {/* Recent Statement */}
            <div className={`${styles.detailsCard} fade-in-up fade-in-up-3`} style={{ marginTop: 12, marginBottom: 16 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
                <p className={styles.detailsTitle} style={{ margin: 0 }}>Recent Ledger Transactions</p>
                <button
                  type="button"
                  onClick={handleClearHistory}
                  style={{ background: "transparent", color: "#ef4444", border: "1px solid #fee2e2", borderRadius: 6, padding: "3px 8px", fontSize: 10, fontWeight: 700, cursor: "pointer" }}
                >
                  Clear All
                </button>
              </div>
              {(currentLedger.history || []).map((h: any, i: number) => (
                <div key={i} className={styles.detailRow} style={{ padding: "8px 0", borderBottom: i < (currentLedger.history?.length || 0) - 1 ? "1px solid var(--color-bg-muted)" : "none" }}>
                  <div>
                    <p style={{ fontSize: 13, fontWeight: 700, color: "var(--color-text-primary-light)" }}>{h.desc}</p>
                    <p style={{ fontSize: 10, color: "var(--color-text-secondary-light)", marginTop: 2 }}>{h.date}</p>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <p style={{ fontSize: 13, fontWeight: 800, color: "#16a34a" }}>{h.amount}</p>
                    <p style={{ fontSize: 10, color: "#16a34a", marginTop: 2 }}>{h.status}</p>
                  </div>
                </div>
              ))}
              {(!currentLedger.history || currentLedger.history.length === 0) && (
                <p style={{ fontSize: 12, color: "var(--color-text-secondary)", textAlign: "center", padding: "12px 0" }}>No recent transactions</p>
              )}
            </div>
          </div>
          <BottomNav active="cards" />
        </div>
      </div>
    </div>
  );
}
