"use client";
import { useState } from "react";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import styles from "./page.module.css";

const currencies = ["USD", "EUR", "GBP", "UAH", "JPY", "AUD", "CAD"];
const rates: Record<string, Record<string, number>> = {
  USD: { EUR: 0.92, GBP: 0.79, UAH: 41.3, JPY: 155.2, AUD: 1.54, CAD: 1.37 },
  EUR: { USD: 1.09, GBP: 0.86, UAH: 44.9, JPY: 168.5, AUD: 1.67, CAD: 1.49 },
  GBP: { USD: 1.27, EUR: 1.16, UAH: 52.4, JPY: 196.8, AUD: 1.95, CAD: 1.74 },
};

export default function ExchangePage() {
  const [from, setFrom] = useState("USD");
  const [to, setTo] = useState("UAH");
  const [amount, setAmount] = useState("200");

  const rate = rates[from]?.[to] ?? 41.3;
  const converted = (parseFloat(amount || "0") * rate).toFixed(2);

  const swap = () => {
    const tmp = from;
    setFrom(to);
    setTo(tmp);
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
            <Header name="Alex Johnson" greeting="Exchange" />

            {/* Rate banner */}
            <div className={`${styles.rateBanner} fade-in-up`}>
              <div className={styles.rateInfo}>
                <p className={styles.rateLabel}>Live Exchange Rate</p>
                <p className={styles.rateValue}>1 {from} = {rate} {to}</p>
              </div>
              <div className={styles.rateTag}>LIVE</div>
            </div>

            {/* Exchange pair */}
            <div className={`${styles.exchangeCard} fade-in-up fade-in-up-1`}>
              {/* From */}
              <div className={styles.currencyBlock}>
                <label className={styles.currencyLabel}>You Send</label>
                <div className={styles.currencyInputRow}>
                  <select className={styles.currencySelect} value={from} onChange={(e) => setFrom(e.target.value)}>
                    {currencies.filter((c) => c !== to).map((c) => <option key={c}>{c}</option>)}
                  </select>
                  <input
                    className={styles.amountInput}
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                  />
                </div>
              </div>

              {/* Swap */}
              <button className={styles.swapBtn} onClick={swap}>
                <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" width="18" height="18">
                  <polyline points="17 1 21 5 17 9" /><path d="M3 11V9a4 4 0 014-4h14" />
                  <polyline points="7 23 3 19 7 15" /><path d="M21 13v2a4 4 0 01-4 4H3" />
                </svg>
              </button>

              {/* To */}
              <div className={styles.currencyBlock}>
                <label className={styles.currencyLabel}>You Receive</label>
                <div className={styles.currencyInputRow}>
                  <select className={styles.currencySelect} value={to} onChange={(e) => setTo(e.target.value)}>
                    {currencies.filter((c) => c !== from).map((c) => <option key={c}>{c}</option>)}
                  </select>
                  <div className={styles.convertedAmount}>{converted}</div>
                </div>
              </div>
            </div>

            {/* Fee info */}
            <div className={`${styles.feeCard} fade-in-up fade-in-up-2`}>
              {[
                { label: "Exchange Rate", value: `1 ${from} = ${rate} ${to}` },
                { label: "Transaction Fee", value: "0.5%" },
                { label: "You Will Receive", value: `${(parseFloat(converted) * 0.995).toFixed(2)} ${to}` },
                { label: "Delivery Time", value: "Instant" },
              ].map((r) => (
                <div key={r.label} className={styles.feeRow}>
                  <span className={styles.feeLabel}>{r.label}</span>
                  <span className={styles.feeValue}>{r.value}</span>
                </div>
              ))}
            </div>

            {/* Popular pairs */}
            <div className="section-header fade-in-up fade-in-up-3">
              <p className="section-title">Popular Pairs</p>
            </div>
            <div className={`${styles.pairsList} fade-in-up fade-in-up-3`}>
              {[
                { from: "USD", to: "EUR", rate: "0.92", change: "+0.3%" },
                { from: "USD", to: "GBP", rate: "0.79", change: "-0.1%" },
                { from: "EUR", to: "JPY", rate: "168.5", change: "+0.8%" },
              ].map((p) => (
                <div key={`${p.from}-${p.to}`} className={styles.pairItem}>
                  <div className={styles.pairFlags}>
                    <div className={styles.flag}>{p.from}</div>
                    <div className={styles.flagArrow}>→</div>
                    <div className={styles.flag}>{p.to}</div>
                  </div>
                  <div style={{ flex: 1, marginLeft: 12 }}>
                    <p className={styles.pairRate}>{p.from}/{p.to}</p>
                    <p className={styles.pairRateValue}>1 = {p.rate}</p>
                  </div>
                  <span className={styles.pairChange} style={{ color: p.change.startsWith("+") ? "var(--color-success)" : "var(--color-danger)" }}>{p.change}</span>
                </div>
              ))}
            </div>

            <div style={{ padding: "0 16px 16px" }} className="fade-in-up">
              <button className="btn btn-primary">Exchange Now</button>
            </div>
          </div>
          <BottomNav active="exchange" />
        </div>
      </div>
    </div>
  );
}
