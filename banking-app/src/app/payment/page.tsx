"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import PaymentGatewayModal from "@/components/PaymentGatewayModal";
import styles from "./page.module.css";

export default function PaymentPage() {
  const router = useRouter();
  const { notifySuccess, notifyError } = useNotification();

  const [customerList, setCustomerList] = useState<any[]>([]);
  const [selectedCustomerId, setSelectedCustomerId] = useState<string>("");
  const [amount, setAmount] = useState<string>("500");
  const [remarks, setRemarks] = useState("");
  const [isGatewayOpen, setIsGatewayOpen] = useState(false);
  const [loading, setLoading] = useState(true);

  // Load active customers
  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      try {
        const list = await api.getTodayCollections("agent@bankflow.com");
        if (list && list.length > 0) {
          setCustomerList(list);
          setSelectedCustomerId(list[0].id.toString());
          if (list[0].pending_amount) {
            setAmount(list[0].pending_amount.toString());
          }
        }
      } catch (e: any) {
        console.warn("Error loading customers for payment:", e.message);
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, []);

  const selectedCustomer = customerList.find((c) => c.id.toString() === selectedCustomerId) || customerList[0] || null;

  const numericAmount = parseFloat(amount) || 0;

  const handleSelectCustomer = (idStr: string) => {
    setSelectedCustomerId(idStr);
    const found = customerList.find((c) => c.id.toString() === idStr);
    if (found && found.pending_amount) {
      setAmount(found.pending_amount.toString());
    }
  };

  const handleLaunchGateway = () => {
    if (numericAmount <= 0) {
      notifyError("Invalid Amount", "Please enter a deposit amount greater than ₹0.");
      return;
    }
    setIsGatewayOpen(true);
  };

  const handlePaymentSuccess = async (details: { paymentMode: string; transactionId: string; amount: number }) => {
    setIsGatewayOpen(false);
    const agentEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";

    try {
      await api.recordCollection({
        customerId: selectedCustomer.id,
        agentEmail,
        status: "collected",
        collectedAmount: numericAmount,
        depositTotal: numericAmount,
        paymentMode: details.paymentMode.toUpperCase(),
        remarks: remarks || "Direct Customer Payment via Gateway",
      });

      notifySuccess(
        "Payment Received!",
        `₹${numericAmount.toLocaleString()} paid to Agent ${agentEmail.split("@")[0]} via ${details.paymentMode}. Reflected live on Agent Dashboard!`
      );

      router.push(`/receipt/${selectedCustomer.id}`);
    } catch (err: any) {
      notifyError("Error", err.message || "Failed to record payment.");
    }
  };

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
            <Header name="Customer Portal" greeting="PCMS Deposit Checkout" />

            {!selectedCustomer ? (
              <div style={{ padding: "32px 16px", textAlign: "center" }}>
                <p style={{ fontSize: 48, margin: "0 0 12px 0" }}>👤</p>
                <h3 style={{ fontSize: 18, fontWeight: 800, color: "#0f172a", marginBottom: 6 }}>No Customers Registered</h3>
                <p style={{ fontSize: 13, color: "#64748b", marginBottom: 20 }}>
                  Please register a customer profile before launching the payment gateway.
                </p>
                <button
                  className="btn btn-primary"
                  onClick={() => router.push("/collection")}
                >
                  ➕ Go to Collections / Add Customer
                </button>
              </div>
            ) : (
              <>

            {/* Customer Hero Banner */}
            <div className={styles.heroCard}>
              <p className={styles.cardTitle}>Direct Customer Deposit</p>
              <h2 className={styles.custName}>{selectedCustomer.name}</h2>
              <p className={styles.acctNum}>
                {selectedCustomer.account || `PCMS-00${selectedCustomer.id}`} · {selectedCustomer.area}
              </p>
            </div>

            {/* Collection Agent Banner */}
            <div className={styles.agentBanner}>
              <div className={styles.agentInfo}>
                <div className={styles.agentAvatar}>👤</div>
                <div>
                  <span className={styles.agentLabel}>Assigned Collection Agent</span>
                  <p className={styles.agentName}>Rahul Verma (agent@bankflow.com)</p>
                </div>
              </div>
              <span style={{ fontSize: 10, background: "#dcfce7", color: "#15803d", padding: "2px 8px", borderRadius: 100, fontWeight: 700 }}>
                ONLINE
              </span>
            </div>

            {/* Customer Selector if multiple */}
            {customerList.length > 1 && (
              <div className={styles.section}>
                <p className={styles.sectionTitle}>👤 Select Customer Profile</p>
                <select
                  className="form-input"
                  value={selectedCustomerId}
                  onChange={(e) => handleSelectCustomer(e.target.value)}
                >
                  {customerList.map((c) => (
                    <option key={c.id} value={c.id.toString()}>
                      {c.name} — {c.account || `PCMS-00${c.id}`} ({c.area})
                    </option>
                  ))}
                </select>
              </div>
            )}

            {/* Amount Section */}
            <div className={styles.section}>
              <p className={styles.sectionTitle}>💰 Enter Payment Amount</p>
              <div className={styles.inputGroup}>
                <label className={styles.inputLabel}>Deposit Amount</label>
                <div className={styles.amtInputWrap}>
                  <span className={styles.rupee}>₹</span>
                  <input
                    type="number"
                    className={styles.amtInput}
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="Enter amount"
                  />
                </div>
              </div>

              {/* Fast Chips */}
              <div className={styles.quickAmts}>
                {["100", "200", "500", "1000", "2000"].map((v) => (
                  <button
                    key={v}
                    type="button"
                    className={`${styles.chip} ${amount === v ? styles.chipActive : ""}`}
                    onClick={() => setAmount(v)}
                  >
                    ₹{v}
                  </button>
                ))}
              </div>
            </div>

            {/* Remarks */}
            <div className={styles.section}>
              <p className={styles.sectionTitle}>💬 Payment Remarks (Optional)</p>
              <input
                type="text"
                className="form-input"
                placeholder="e.g. Pigmy daily installment payment"
                value={remarks}
                onChange={(e) => setRemarks(e.target.value)}
              />
            </div>

            {/* Pay Now Button */}
            <button type="button" className={styles.payBtn} onClick={handleLaunchGateway}>
              <span>💳 Pay ₹{numericAmount.toLocaleString()} via Gateway</span>
              <span className={styles.gateBadge}>RAZORPAY TEST</span>
            </button>
            </>
            )}
          </div>

          <BottomNav active="cards" />
        </div>
      </div>

      {selectedCustomer && (
        <PaymentGatewayModal
          isOpen={isGatewayOpen}
          onClose={() => setIsGatewayOpen(false)}
          amount={numericAmount}
          customerName={selectedCustomer.name}
          accountNumber={selectedCustomer.account || `PCMS-00${selectedCustomer.id}`}
          onSuccess={handlePaymentSuccess}
        />
      )}
    </div>
  );
}
