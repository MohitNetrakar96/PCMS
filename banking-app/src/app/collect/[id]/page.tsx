"use client";
import { useState, useEffect } from "react";
import { useRouter, useParams } from "next/navigation";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import PaymentGatewayModal from "@/components/PaymentGatewayModal";
import styles from "./page.module.css";

const EMPTY_CUSTOMER = { name: "", account: "", dailyAmount: 0, balance: 0, arrear: 0 };

type PaymentMode = "cash" | "upi" | "cheque" | "neft";
type EntryType = "regular" | "partial" | "advance" | "arrear";

export default function CollectPage() {
  const router = useRouter();
  const params = useParams();
  const id = Array.isArray(params.id) ? params.id[0] : params.id ?? "1";
  const { notifySuccess, notifyWarning, notifyError } = useNotification();
  const [customer, setCustomer] = useState(EMPTY_CUSTOMER);
  const [notFound, setNotFound] = useState(false);

  const [entries, setEntries] = useState([{ id: 1, amount: "0", type: "regular" as EntryType }]);
  const [paymentMode, setPaymentMode] = useState<PaymentMode>("cash");
  const [includeLoan, setIncludeLoan] = useState(false);
  const [loanAmount, setLoanAmount] = useState("0");
  const [showQR, setShowQR] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [chequeNo, setChequeNo] = useState("");
  const [lateFeeDays, setLateFeeDays] = useState(0);
  const [duplicateConfirmed, setDuplicateConfirmed] = useState(false);
  const [isGatewayOpen, setIsGatewayOpen] = useState(false);

  useEffect(() => {
    const loadCustomer = async () => {
      const live = await api.getCustomer(id);
      if (live) {
        const dailyTarget = Math.round(live.opening_balance * 0.05) || 500;
        setCustomer({
          name: live.name,
          account: `PCMS-00${live.id.replace('CUST-', '')}`,
          dailyAmount: dailyTarget,
          balance: live.opening_balance,
          arrear: 0
        });
        setEntries([{ id: 1, amount: dailyTarget.toString(), type: "regular" }]);
      } else {
        setNotFound(true);
      }
    };
    loadCustomer();
  }, [id]);

  const addEntry = () => {
    setDuplicateConfirmed(false);
    setEntries([...entries, { id: Date.now(), amount: "", type: "regular" }]);
  };
  const removeEntry = (id: number) => {
    setDuplicateConfirmed(false);
    setEntries(entries.filter((e) => e.id !== id));
  };

  const hasDuplicateEntries = () => {
    const types = entries.map(e => e.type);
    return new Set(types).size !== types.length;
  };

  const totalAmount = entries.reduce((s, e) => s + (parseFloat(e.amount) || 0), 0) + (includeLoan ? parseFloat(loanAmount) || 0 : 0);
  const lateFee = lateFeeDays > 0 ? Math.round(totalAmount * 0.01 * lateFeeDays) : 0;
  const interest = Math.round(totalAmount * 0.005);
  const grandTotal = totalAmount + lateFee + interest;

  const processCollectionSubmission = async (selectedPaymentMode: string) => {
    // Retrieve stashed visit details (photo, signature, etc.)
    const tempVisitStr = localStorage.getItem("pcms_temp_visit");
    const tempVisit = tempVisitStr ? JSON.parse(tempVisitStr) : {};
    const agentEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";

    const newRecord = {
      customerId: id,
      customerName: customer.name,
      account: customer.account,
      status: "collected",
      amount: grandTotal,
      depositTotal: totalAmount,
      lateFee: lateFee,
      interest: interest,
      paymentMode: selectedPaymentMode.toUpperCase(),
      remarks: tempVisit.remarks || "",
      timestamp: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
      signed: tempVisit.signed || false,
      photoUrl: tempVisit.photoUrl || null,
      gpsCoords: tempVisit.gpsCoords || ""
    };

    // Save to daily collections list
    const records = JSON.parse(localStorage.getItem("pcms_collections_today") || "[]");
    const cleanRecords = records.filter((r: any) => r.customerId !== id);
    localStorage.setItem("pcms_collections_today", JSON.stringify([...cleanRecords, newRecord]));

    // Record on backend server
    await api.recordCollection({
      customerId: id || "1",
      agentEmail,
      status: "collected",
      collectedAmount: grandTotal,
      depositTotal: totalAmount,
      lateFee,
      interest,
      paymentMode: selectedPaymentMode.toUpperCase(),
      remarks: tempVisit.remarks || "",
      photoCaptured: tempVisit.photoUrl ? 1 : 0,
      signatureCaptured: tempVisit.signed ? 1 : 0,
    });

    // Clear temp stash
    localStorage.removeItem("pcms_temp_visit");

    notifySuccess(
      "Payment Received!",
      `₹${grandTotal.toLocaleString()} collected via ${selectedPaymentMode}. Reflected live on Agent & Manager dashboards.`
    );

    router.push(`/receipt/${id}`);
  };

  const handleSubmit = async () => {
    const hasEmpty = entries.some(e => !e.amount || parseFloat(e.amount) <= 0);
    if (hasEmpty) {
      notifyError("Invalid Amount", "Please enter a valid deposit amount.");
      return;
    }
    if (hasDuplicateEntries() && !duplicateConfirmed) {
      notifyWarning("Duplicate Entry", "Please review duplicate entries and check confirmation.");
      return;
    }

    if (paymentMode !== "cash") {
      setIsGatewayOpen(true);
    } else {
      await processCollectionSubmission("CASH");
    }
  };

  const handleGatewaySuccess = async (details: { paymentMode: string; transactionId: string; amount: number }) => {
    setIsGatewayOpen(false);
    await processCollectionSubmission(details.paymentMode);
  };

  if (submitted) {
    return (
      <div className="app-wrapper">
        <div className="phone-frame">
          <div className="status-bar light"><span>10:30 AM</span></div>
          <div className={styles.successScreen}>
            <div className={styles.successIcon}>✅</div>
            <h2 className={styles.successTitle}>Collection Successful!</h2>
            <p className={styles.successSub}>Receipt generated for {customer.name}</p>
            <div className={styles.receiptCard}>
              {[
                { label: "Customer", value: customer.name },
                { label: "Account", value: customer.account },
                { label: "Amount Collected", value: `₹${grandTotal.toLocaleString()}` },
                { label: "Payment Mode", value: paymentMode.toUpperCase() },
                { label: "New Balance", value: `₹${(customer.balance + totalAmount).toLocaleString()}` },
                { label: "Timestamp", value: new Date().toLocaleString("en-IN") },
              ].map((r) => (
                <div key={r.label} className={styles.receiptRow}>
                  <span className={styles.receiptLabel}>{r.label}</span>
                  <span className={styles.receiptValue}>{r.value}</span>
                </div>
              ))}
            </div>
            <button className="btn btn-primary" style={{ margin: "0 24px" }} onClick={() => router.push("/collection")}>
              Back to Collection List
            </button>
          </div>
        </div>
      </div>
    );
  }

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
            <div className={styles.topBar}>
              <button className={styles.backBtn} onClick={() => router.back()}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="20" height="20"><polyline points="15 18 9 12 15 6"/></svg>
              </button>
              <h1 className={styles.pageTitle}>Collect Amount</h1>
              <div className={styles.offlineBadge}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="12" height="12"><path d="M1 1l22 22M16.72 11.06A10.94 10.94 0 0119 12.55M5 12.55a10.94 10.94 0 015.17-2.39M10.71 5.05A16 16 0 0122.56 9M1.42 9a15.91 15.91 0 014.7-2.88M8.53 16.11a6 6 0 016.95 0M12 20h.01"/></svg>
                Offline OK
              </div>
            </div>

            {/* Customer banner */}
            <div className={`${styles.customerBanner} fade-in-up`}>
              <div className={styles.custAvatar}>{customer.name.charAt(0)}</div>
              <div>
                <p className={styles.custName}>{customer.name}</p>
                <p className={styles.custAcc}>{customer.account}</p>
              </div>
              <div className={styles.custBalance}>
                <p className={styles.balLabel}>Balance</p>
                <p className={styles.balVal}>₹{customer.balance.toLocaleString()}</p>
              </div>
            </div>

            {/* Deposit entries */}
            <div className={`${styles.section} fade-in-up fade-in-up-1`}>
              <div className={styles.sectionHeader}>
                <p className={styles.sectionTitle}>💰 Deposit Entries</p>
                <button className={styles.addEntryBtn} onClick={addEntry}>+ Add</button>
              </div>
              {entries.map((entry, i) => (
                <div key={entry.id} className={styles.entryRow}>
                  <select
                    className={styles.entryTypeSelect}
                    value={entry.type}
                    onChange={(e) => {
                      const upd = [...entries];
                      upd[i].type = e.target.value as EntryType;
                      setEntries(upd);
                    }}
                  >
                    <option value="regular">Regular</option>
                    <option value="partial">Partial</option>
                    <option value="advance">Advance</option>
                    <option value="arrear">Arrear</option>
                  </select>
                  <div className={styles.amountBox}>
                    <span className={styles.rupeeSign}>₹</span>
                    <input
                      className={styles.amountInput}
                      type="number"
                      value={entry.amount}
                      onChange={(e) => {
                        const upd = [...entries];
                        upd[i].amount = e.target.value;
                        setEntries(upd);
                      }}
                    />
                  </div>
                  {entries.length > 1 && (
                    <button className={styles.removeBtn} onClick={() => removeEntry(entry.id)}>✕</button>
                  )}
                </div>
              ))}
               {customer.arrear > 0 && (
                <div className={styles.arrearNotice}>
                  ⚠️ Pending arrear: ₹{customer.arrear} — select &quot;Arrear&quot; type above
                </div>
              )}
              {hasDuplicateEntries() && (
                <div className={styles.duplicateWarning}>
                  <p>⚠️ <strong>Duplicate Entry Warning:</strong> You have added multiple entries of the same type.</p>
                  <label className={styles.confirmCheckboxRow}>
                    <input type="checkbox" checked={duplicateConfirmed} onChange={(e) => setDuplicateConfirmed(e.target.checked)} />
                    <span>Confirm multiple deposit entries</span>
                  </label>
                </div>
              )}
            </div>

            {/* Loan EMI */}
            <div className={`${styles.section} fade-in-up fade-in-up-2`}>
              <label className={styles.toggleRow}>
                <span className={styles.sectionTitle}>🏦 Loan EMI Collection</span>
                <div className={`${styles.toggle} ${includeLoan ? styles.toggleOn : ""}`} onClick={() => setIncludeLoan(!includeLoan)}>
                  <div className={styles.toggleKnob} />
                </div>
              </label>
              {includeLoan && (
                <div className={styles.amountBox} style={{ marginTop: 10 }}>
                  <span className={styles.rupeeSign}>₹</span>
                  <input className={styles.amountInput} type="number" placeholder="EMI amount" value={loanAmount} onChange={(e) => setLoanAmount(e.target.value)} />
                </div>
              )}
            </div>

            {/* Payment Mode */}
            <div className={`${styles.section} fade-in-up fade-in-up-2`}>
              <p className={styles.sectionTitle}>💳 Payment Mode</p>
              <div className={styles.modeGrid}>
                {([
                  { id: "cash", label: "Cash", icon: "💵" },
                  { id: "upi", label: "UPI", icon: "📱" },
                  { id: "cheque", label: "Cheque", icon: "📝" },
                  { id: "neft", label: "NEFT/RTGS", icon: "🏦" },
                ] as { id: PaymentMode; label: string; icon: string }[]).map((m) => (
                  <button
                    key={m.id}
                    className={`${styles.modeBtn} ${paymentMode === m.id ? styles.modeBtnActive : ""}`}
                    onClick={() => { setPaymentMode(m.id); setShowQR(false); }}
                  >
                    <span style={{ fontSize: 22 }}>{m.icon}</span>
                    <span className={styles.modeLabel}>{m.label}</span>
                  </button>
                ))}
              </div>
              {paymentMode === "upi" && (
                <button className={styles.qrBtn} onClick={() => setShowQR(!showQR)}>
                  {showQR ? "Hide QR Code" : "Show UPI QR Code"}
                </button>
              )}
              {paymentMode === "upi" && showQR && (
                <div className={styles.qrBox}>
                  <div className={styles.qrCode}>
                    {/* QR pattern */}
                    <svg viewBox="0 0 100 100" width="140" height="140">
                      <rect x="10" y="10" width="25" height="25" fill="none" stroke="#1e293b" strokeWidth="3"/>
                      <rect x="15" y="15" width="15" height="15" fill="#1e293b"/>
                      <rect x="65" y="10" width="25" height="25" fill="none" stroke="#1e293b" strokeWidth="3"/>
                      <rect x="70" y="15" width="15" height="15" fill="#1e293b"/>
                      <rect x="10" y="65" width="25" height="25" fill="none" stroke="#1e293b" strokeWidth="3"/>
                      <rect x="15" y="70" width="15" height="15" fill="#1e293b"/>
                      {[40,50,60,45,55,42,58,48,52].map((x, i) => (
                        <rect key={i} x={x} y={[10,15,20,25,30,35,40,45,50][i]} width="5" height="5" fill="#1e293b"/>
                      ))}
                      {[40,50,60,45,55,42,58,48,52].map((x, i) => (
                        <rect key={i+9} x={[10,15,20,25,30,35,40,45,50][i]} y={x} width="5" height="5" fill="#1e293b"/>
                      ))}
                    </svg>
                  </div>
                  <p className={styles.qrLabel}>Scan to pay ₹{grandTotal.toLocaleString()}</p>
                  <p className={styles.qrUpi}>upi://pay?pa=bankflow@upi&am={grandTotal}</p>
                </div>
              )}
              {paymentMode === "cheque" && (
                <input className="form-input" style={{ marginTop: 10 }} type="text" placeholder="Cheque Number" value={chequeNo} onChange={(e) => setChequeNo(e.target.value)} />
              )}
            </div>

            {/* Summary */}
            <div className={`${styles.summaryCard} fade-in-up fade-in-up-3`}>
              <p className={styles.sectionTitle}>📊 Collection Summary</p>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10, paddingBottom: 10, borderBottom: "1px dashed var(--color-border)" }}>
                <span className={styles.summaryLabel}>Late Fee Days:</span>
                <input
                  type="number"
                  min="0"
                  value={lateFeeDays}
                  onChange={(e) => setLateFeeDays(Math.max(0, parseInt(e.target.value) || 0))}
                  style={{ width: 60, padding: "5px 8px", border: "1.5px solid var(--color-border)", borderRadius: 8, textAlign: "center", fontFamily: "var(--font-outfit)", fontWeight: 700, fontSize: 13, outline: "none" }}
                />
              </div>
              {[
                { label: "Deposit Total", value: `₹${totalAmount.toLocaleString()}`, highlight: false },
                { label: `Late Fee (${lateFeeDays} days × 1%)`, value: `₹${lateFee}`, highlight: false },
                { label: "Interest (0.5%)", value: `₹${interest}`, highlight: false },
              ].map((r) => (
                <div key={r.label} className={styles.summaryRow}>
                  <span className={styles.summaryLabel}>{r.label}</span>
                  <span className={styles.summaryValue}>{r.value}</span>
                </div>
              ))}
              <div className={styles.summaryDivider} />
              <div className={`${styles.summaryRow} ${styles.summaryTotal}`}>
                <span>Grand Total</span>
                <span className={styles.grandTotal}>₹{grandTotal.toLocaleString()}</span>
              </div>
              <div className={styles.summaryRow} style={{ marginTop: 8 }}>
                <span className={styles.summaryLabel}>New Balance After Payment</span>
                <span style={{ fontWeight: 700, color: "var(--color-success)", fontSize: 14 }}>
                  ₹{(customer.balance + totalAmount).toLocaleString()}
                </span>
              </div>
            </div>

            {/* Submit */}
            <div style={{ padding: "0 16px 16px", display: "flex", flexDirection: "column", gap: 10 }} className="fade-in-up">
              <button className="btn btn-primary" onClick={handleSubmit}>
                {paymentMode === "cash" ? "✅ Confirm Cash Collection" : "💳 Launch Payment Gateway"}
              </button>
              <button className="btn" style={{ background: "#f1f5f9", color: "var(--color-text-secondary-light)" }} onClick={() => router.back()}>Cancel</button>
            </div>
          </div>
        </div>
      </div>

      <PaymentGatewayModal
        isOpen={isGatewayOpen}
        onClose={() => setIsGatewayOpen(false)}
        amount={grandTotal}
        customerName={customer.name}
        accountNumber={customer.account}
        onSuccess={handleGatewaySuccess}
      />
    </div>
  );
}
