"use client";
import React, { useState } from "react";
import styles from "./PaymentGatewayModal.module.css";

interface PaymentGatewayModalProps {
  isOpen: boolean;
  onClose: () => void;
  amount: number;
  customerName: string;
  accountNumber: string;
  onSuccess: (paymentDetails: { paymentMode: string; transactionId: string; amount: number }) => void;
}

export default function PaymentGatewayModal({
  isOpen,
  onClose,
  amount,
  customerName,
  accountNumber,
  onSuccess,
}: PaymentGatewayModalProps) {
  const [method, setMethod] = useState<"upi" | "card" | "netbanking">("upi");
  const [processing, setProcessing] = useState(false);
  const [step, setStep] = useState<"select" | "processing" | "success">("select");

  // Card Form State
  const [cardNumber, setCardNumber] = useState("");
  const [cardExp, setCardExp] = useState("");
  const [cardCvv, setCardCvv] = useState("");
  const [selectedBank, setSelectedBank] = useState("HDFC");

  if (!isOpen) return null;

  const upiId = "pcmsbank@upi";
  const upiLink = `upi://pay?pa=${upiId}&pn=PCMS+Bank&am=${amount}&tn=Deposit+${accountNumber}`;
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${encodeURIComponent(upiLink)}`;

  const handleProcessPayment = (mode: string) => {
    setProcessing(true);
    setStep("processing");

    setTimeout(() => {
      setStep("success");
      const txId = `PG-UPI-${Date.now()}-${Math.floor(100 + Math.random() * 900)}`;

      setTimeout(() => {
        setProcessing(false);
        setStep("select");
        onSuccess({
          paymentMode: mode,
          transactionId: txId,
          amount,
        });
      }, 1200);
    }, 2000);
  };

  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className={styles.header}>
          <div className={styles.brand}>
            <div className={styles.brandLogo}>💳</div>
            <div>
              <h3 className={styles.title}>PCMS Payment Gateway</h3>
              <p className={styles.subtitle}>Secure Instant Checkout</p>
            </div>
          </div>
          <button type="button" className={styles.closeBtn} onClick={onClose} disabled={processing}>
            ✕
          </button>
        </div>

        {step === "processing" ? (
          <div className={styles.simulatingOverlay}>
            <div className={styles.spinner} />
            <h4 style={{ fontSize: 15, fontWeight: 800, color: "#0f172a", margin: "0 0 4px 0" }}>
              Processing Payment…
            </h4>
            <p style={{ fontSize: 12, color: "#64748b", margin: 0 }}>
              Communicating with bank servers for ₹{amount.toLocaleString()}
            </p>
          </div>
        ) : step === "success" ? (
          <div className={styles.simulatingOverlay}>
            <div className={styles.successCheck}>✓</div>
            <h4 style={{ fontSize: 16, fontWeight: 800, color: "#16a34a", margin: "0 0 4px 0" }}>
              Payment Successful!
            </h4>
            <p style={{ fontSize: 12, color: "#64748b", margin: 0 }}>
              Reflecting live on Agent &amp; Manager Dashboards
            </p>
          </div>
        ) : (
          <>
            {/* Amount Banner */}
            <div className={styles.amountBanner}>
              <div>
                <span className={styles.amtLabel}>Payable Deposit</span>
                <p style={{ fontSize: 12, color: "#e2e8f0", margin: 0, fontWeight: 600 }}>
                  {customerName} ({accountNumber})
                </p>
              </div>
              <span className={styles.amtVal}>₹{amount.toLocaleString()}</span>
            </div>

            {/* Payment Method Selector */}
            <div className={styles.methodTabs}>
              <button
                type="button"
                className={`${styles.tabBtn} ${method === "upi" ? styles.tabBtnActive : ""}`}
                onClick={() => setMethod("upi")}
              >
                <span style={{ fontSize: 16 }}>📱</span>
                <span>UPI / QR</span>
              </button>
              <button
                type="button"
                className={`${styles.tabBtn} ${method === "card" ? styles.tabBtnActive : ""}`}
                onClick={() => setMethod("card")}
              >
                <span style={{ fontSize: 16 }}>💳</span>
                <span>Card</span>
              </button>
              <button
                type="button"
                className={`${styles.tabBtn} ${method === "netbanking" ? styles.tabBtnActive : ""}`}
                onClick={() => setMethod("netbanking")}
              >
                <span style={{ fontSize: 16 }}>🏦</span>
                <span>NetBanking</span>
              </button>
            </div>

            {/* UPI View */}
            {method === "upi" && (
              <div className={styles.qrContainer}>
                <img src={qrUrl} alt="UPI QR Code" className={styles.qrImage} />
                <p style={{ fontSize: 11, fontWeight: 700, color: "#0f172a", margin: "0 0 2px 0" }}>
                  Scan QR with any UPI App
                </p>
                <p style={{ fontSize: 10, color: "#64748b", margin: 0 }}>GPay · PhonePe · Paytm · BHIM</p>
                <div className={styles.upiAppsRow}>
                  <button
                    type="button"
                    className={styles.upiAppBtn}
                    onClick={() => handleProcessPayment("UPI - GPay")}
                  >
                    GPay
                  </button>
                  <button
                    type="button"
                    className={styles.upiAppBtn}
                    onClick={() => handleProcessPayment("UPI - PhonePe")}
                  >
                    PhonePe
                  </button>
                  <button
                    type="button"
                    className={styles.upiAppBtn}
                    onClick={() => handleProcessPayment("UPI - Paytm")}
                  >
                    Paytm
                  </button>
                </div>
              </div>
            )}

            {/* Card View */}
            {method === "card" && (
              <div className={styles.cardForm}>
                <div className={styles.inputGroup}>
                  <label className={styles.inputLabel}>Card Number</label>
                  <input
                    type="text"
                    className={styles.inputField}
                    placeholder="4532 •••• •••• 8921"
                    value={cardNumber}
                    onChange={(e) => setCardNumber(e.target.value)}
                  />
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                  <div className={styles.inputGroup}>
                    <label className={styles.inputLabel}>Expiry (MM/YY)</label>
                    <input
                      type="text"
                      className={styles.inputField}
                      placeholder="08/28"
                      value={cardExp}
                      onChange={(e) => setCardExp(e.target.value)}
                    />
                  </div>
                  <div className={styles.inputGroup}>
                    <label className={styles.inputLabel}>CVV</label>
                    <input
                      type="password"
                      className={styles.inputField}
                      placeholder="•••"
                      maxLength={4}
                      value={cardCvv}
                      onChange={(e) => setCardCvv(e.target.value)}
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Netbanking View */}
            {method === "netbanking" && (
              <div className={styles.cardForm}>
                <div className={styles.inputGroup}>
                  <label className={styles.inputLabel}>Select Bank</label>
                  <select
                    className={styles.inputField}
                    value={selectedBank}
                    onChange={(e) => setSelectedBank(e.target.value)}
                  >
                    <option value="HDFC">HDFC Bank</option>
                    <option value="SBI">State Bank of India</option>
                    <option value="ICICI">ICICI Bank</option>
                    <option value="Axis">Axis Bank</option>
                    <option value="Kotak">Kotak Mahindra</option>
                  </select>
                </div>
              </div>
            )}

            {/* Process Pay Button */}
            <button
              type="button"
              className={styles.payBtn}
              onClick={() =>
                handleProcessPayment(
                  method === "upi" ? "UPI DIGITAL" : method === "card" ? "DEBIT/CREDIT CARD" : `NETBANKING (${selectedBank})`
                )
              }
            >
              🔒 Complete Payment ₹{amount.toLocaleString()}
            </button>
          </>
        )}
      </div>
    </div>
  );
}
