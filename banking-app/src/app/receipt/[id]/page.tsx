"use client";
import { useState, useRef, useEffect } from "react";
import { useRouter, useParams } from "next/navigation";
import { api } from "@/services/api";
import styles from "./page.module.css";

const RECEIPT_DATA: Record<string, {
  customerName: string; account: string; amount: number; paymentMode: string;
  lateFee: number; interest: number; grandTotal: number; newBalance: number;
  area: string; route: string; agentName: string; agentEmail: string;
}> = {
  "1": { customerName: "Priya Sharma", account: "PCMS-00124", amount: 500, paymentMode: "CASH", lateFee: 10, interest: 3, grandTotal: 513, newBalance: 12913, area: "Sector 12", route: "Route A", agentName: "Rahul Verma", agentEmail: "rahul.verma@bankflow.com" },
  "2": { customerName: "Rajesh Kumar", account: "PCMS-00215", amount: 300, paymentMode: "UPI", lateFee: 6, interest: 2, grandTotal: 308, newBalance: 9058, area: "Gandhi Nagar", route: "Route B", agentName: "Rahul Verma", agentEmail: "rahul.verma@bankflow.com" },
  "3": { customerName: "Sunita Devi", account: "PCMS-00318", amount: 200, paymentMode: "CASH", lateFee: 0, interest: 1, grandTotal: 201, newBalance: 5401, area: "Sector 12", route: "Route A", agentName: "Rahul Verma", agentEmail: "rahul.verma@bankflow.com" },
  "4": { customerName: "Mohan Lal", account: "PCMS-00422", amount: 1000, paymentMode: "NEFT", lateFee: 20, interest: 5, grandTotal: 1025, newBalance: 35125, area: "Lake View Colony", route: "Route C", agentName: "Rahul Verma", agentEmail: "rahul.verma@bankflow.com" },
};

type Language = "en" | "kn" | "hi";

const LABELS: Record<Language, Record<string, string>> = {
  en: { title: "Collection Receipt", company: "BankFlow PCMS", tagline: "Payment Collection Management System", receiptNo: "Receipt No.", date: "Date", customer: "Customer", account: "Account No.", area: "Area", route: "Route", amount: "Deposit Amount", lateFee: "Late Fee", interest: "Interest", total: "Grand Total", newBalance: "New Balance", mode: "Payment Mode", agent: "Collected By", thanks: "Thank you for your payment!", duplicate: "DUPLICATE COPY" },
  kn: { title: "ಸಂಗ್ರಹ ರಶೀದಿ", company: "BankFlow PCMS", tagline: "ಪಾವತಿ ಸಂಗ್ರಹ ನಿರ್ವಹಣಾ ವ್ಯವಸ್ಥೆ", receiptNo: "ರಶೀದಿ ಸಂಖ್ಯೆ.", date: "ದಿನಾಂಕ", customer: "ಗ್ರಾಹಕ", account: "ಖಾತೆ ಸಂಖ್ಯೆ.", area: "ಪ್ರದೇಶ", route: "ಮಾರ್ಗ", amount: "ಠೇವಣಿ ಮೊತ್ತ", lateFee: "ತಡ ಶುಲ್ಕ", interest: "ಬಡ್ಡಿ", total: "ಒಟ್ಟು ಮೊತ್ತ", newBalance: "ಹೊಸ ಬಾಕಿ", mode: "ಪಾವತಿ ವಿಧಾನ", agent: "ಸಂಗ್ರಹಿಸಿದವರು", thanks: "ನಿಮ್ಮ ಪಾವತಿಗಾಗಿ ಧನ್ಯವಾದಗಳು!", duplicate: "ನಕಲು ಪ್ರತಿ" },
  hi: { title: "संग्रह रसीद", company: "BankFlow PCMS", tagline: "भुगतान संग्रह प्रबंधन प्रणाली", receiptNo: "रसीद संख्या.", date: "तारीख", customer: "ग्राहक", account: "खाता संख्या.", area: "क्षेत्र", route: "मार्ग", amount: "जमा राशि", lateFee: "विलंब शुल्क", interest: "ब्याज", total: "कुल राशि", newBalance: "नई शेष राशि", mode: "भुगतान मोड", agent: "एकत्र करने वाले", thanks: "आपके भुगतान के लिए धन्यवाद!", duplicate: "डुप्लीकेट कॉपी" },
};

function generateReceiptNo(id: string) {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `RCP-${y}${m}${day}-${id.padStart(4, "0")}${Math.floor(Math.random() * 9 + 1)}`;
}

export default function ReceiptPage() {
  const router = useRouter();
  const params = useParams();
  const id = Array.isArray(params.id) ? params.id[0] : params.id ?? "1";

  const [data, setData] = useState({
    customerName: "Priya Sharma",
    account: "PCMS-00124",
    amount: 500,
    paymentMode: "CASH",
    lateFee: 10,
    interest: 3,
    grandTotal: 513,
    newBalance: 12913,
    area: "Sector 12",
    route: "Route A",
    agentName: "Rahul Verma",
    agentEmail: "rahul.verma@bankflow.com"
  });

  const [lang, setLang] = useState<Language>("en");
  const [isDuplicate, setIsDuplicate] = useState(false);
  const [showPrinter, setShowPrinter] = useState(false);
  const [printing, setPrinting] = useState(false);
  const [sent, setSent] = useState<Set<string>>(new Set());
  const receiptNo = useRef(generateReceiptNo(id));
  const L = LABELS[lang];

  useEffect(() => {
    const agentName = localStorage.getItem("pcms_session_name") || "Rahul Verma";
    const agentEmail = localStorage.getItem("pcms_session_email") || "rahul.verma@bankflow.com";

    const loadReceipt = async () => {
      const live = await api.getReceipt(id);
      if (live) {
        setData({
          customerName: live.customerName,
          account: live.account,
          amount: live.depositTotal || live.amount,
          paymentMode: live.paymentMode,
          lateFee: live.lateFee || 0,
          interest: live.interest || 0,
          grandTotal: live.amount,
          newBalance: live.balance || 12913,
          area: "Sector 12",
          route: "Route A",
          agentName: live.agentName || agentName,
          agentEmail: agentEmail
        });
      } else {
        const records = JSON.parse(localStorage.getItem("pcms_collections_today") || "[]");
        const activeRecord = records.find((r: any) => r.customerId === id);
        const CUSTOMER_INFO: Record<string, { name: string; area: string; route: string; balance: number }> = {
          "1": { name: "Priya Sharma", area: "Sector 12", route: "Route A", balance: 12400 },
          "2": { name: "Rajesh Kumar", area: "Gandhi Nagar", route: "Route B", balance: 8750 },
          "3": { name: "Sunita Devi", area: "Sector 12", route: "Route A", balance: 5200 },
          "4": { name: "Mohan Lal", area: "Lake View Colony", route: "Route C", balance: 34100 },
        };

        if (activeRecord) {
          setData({
            customerName: activeRecord.customerName,
            account: activeRecord.account,
            amount: activeRecord.depositTotal !== undefined ? activeRecord.depositTotal : activeRecord.amount,
            paymentMode: activeRecord.paymentMode,
            lateFee: activeRecord.lateFee || 0,
            interest: activeRecord.interest || 0,
            grandTotal: activeRecord.amount,
            newBalance: (CUSTOMER_INFO[id]?.balance || 10000) + (activeRecord.depositTotal || activeRecord.amount),
            area: CUSTOMER_INFO[id]?.area || "Sector 12",
            route: CUSTOMER_INFO[id]?.route || "Route A",
            agentName: agentName,
            agentEmail: agentEmail
          });
        } else {
          const fallback = RECEIPT_DATA[id] || RECEIPT_DATA["1"];
          setData({
            ...fallback,
            agentName: agentName,
            agentEmail: agentEmail
          });
        }
      }
    };

    loadReceipt();
  }, [id]);

  const now = new Date();
  const dateStr = now.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
  const timeStr = now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" });

  const simulateSend = (method: string) => {
    setSent(prev => new Set([...prev, method]));
  };

  const simulatePrint = () => {
    setShowPrinter(true);
    setPrinting(true);
    setTimeout(() => setPrinting(false), 2500);
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
            {/* Top bar */}
            <div className={styles.topBar}>
              <button className={styles.backBtn} onClick={() => router.push("/collection")}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="20" height="20"><polyline points="15 18 9 12 15 6"/></svg>
              </button>
              <h1 className={styles.pageTitle}>{L.title}</h1>
              {/* Language Selector */}
              <div className={styles.langRow}>
                {(["en","kn","hi"] as Language[]).map(l => (
                  <button key={l} className={`${styles.langBtn} ${lang === l ? styles.langActive : ""}`} onClick={() => setLang(l)}>
                    {l === "en" ? "EN" : l === "kn" ? "ಕನ್ನಡ" : "हि"}
                  </button>
                ))}
              </div>
            </div>

            {/* Receipt Card */}
            <div className={`${styles.receiptCard} fade-in-up`}>
              {isDuplicate && <div className={styles.duplicateBanner}>{L.duplicate}</div>}

              {/* Company Header */}
              <div className={styles.receiptHeader}>
                <div className={styles.companyLogo}>B</div>
                <div className={styles.companyInfo}>
                  <p className={styles.companyName}>{L.company}</p>
                  <p className={styles.companyTagline}>{L.tagline}</p>
                </div>
              </div>

              <div className={styles.receiptDivider} />

              {/* Receipt Meta */}
              <div className={styles.metaRow}>
                <div>
                  <p className={styles.metaLabel}>{L.receiptNo}</p>
                  <p className={styles.metaValue}>{receiptNo.current}</p>
                </div>
                <div style={{ textAlign: "right" }}>
                  <p className={styles.metaLabel}>{L.date}</p>
                  <p className={styles.metaValue}>{dateStr} {timeStr}</p>
                </div>
              </div>

              <div className={styles.receiptDivider} />

              {/* Customer Info */}
              {[
                { label: L.customer, value: data.customerName },
                { label: L.account, value: data.account },
                { label: L.area, value: data.area },
                { label: L.route, value: data.route },
                { label: L.mode, value: data.paymentMode },
                { label: L.agent, value: data.agentName },
              ].map(r => (
                <div key={r.label} className={styles.infoLine}>
                  <span className={styles.infoLabel}>{r.label}</span>
                  <span className={styles.infoVal}>{r.value}</span>
                </div>
              ))}

              <div className={styles.receiptDivider} />

              {/* Amount Summary */}
              {[
                { label: L.amount, value: `₹${data.amount.toLocaleString()}`, bold: false },
                { label: L.lateFee, value: `₹${data.lateFee}`, bold: false },
                { label: L.interest, value: `₹${data.interest}`, bold: false },
              ].map(r => (
                <div key={r.label} className={styles.amtLine}>
                  <span>{r.label}</span>
                  <span>{r.value}</span>
                </div>
              ))}
              <div className={styles.grandTotalLine}>
                <span>{L.total}</span>
                <span className={styles.grandTotalVal}>₹{data.grandTotal.toLocaleString()}</span>
              </div>
              <div className={`${styles.amtLine} ${styles.balanceLine}`}>
                <span>{L.newBalance}</span>
                <span style={{ color: "#16a34a", fontWeight: 700 }}>₹{data.newBalance.toLocaleString()}</span>
              </div>

              <div className={styles.receiptDivider} />

              {/* QR Code on Receipt */}
              <div className={styles.qrSection}>
                <svg viewBox="0 0 80 80" width="72" height="72" style={{ border: "1px solid #e2e8f0", borderRadius: 8, padding: 4, background: "#fff" }}>
                  <rect x="5" y="5" width="20" height="20" fill="none" stroke="#1e293b" strokeWidth="2.5"/>
                  <rect x="9" y="9" width="12" height="12" fill="#1e293b"/>
                  <rect x="55" y="5" width="20" height="20" fill="none" stroke="#1e293b" strokeWidth="2.5"/>
                  <rect x="59" y="9" width="12" height="12" fill="#1e293b"/>
                  <rect x="5" y="55" width="20" height="20" fill="none" stroke="#1e293b" strokeWidth="2.5"/>
                  <rect x="9" y="59" width="12" height="12" fill="#1e293b"/>
                  {[32,37,42,32,37,42,32,37,42].map((x,i) => (
                    <rect key={i} x={x} y={[5,5,5,12,12,12,19,19,19][i]} width="4" height="4" fill="#1e293b"/>
                  ))}
                  {[32,37,42,32,37,42,32,37,42].map((x,i) => (
                    <rect key={`b${i}`} x={[5,5,5,12,12,12,19,19,19][i]} y={x} width="4" height="4" fill="#1e293b"/>
                  ))}
                  {[55,60,65,55,60,65,55,60,65].map((x,i) => (
                    <rect key={`c${i}`} x={x} y={[32,32,32,39,39,39,46,46,46][i]} width="4" height="4" fill="#1e293b"/>
                  ))}
                </svg>
                <div className={styles.qrInfo}>
                  <p className={styles.qrLabel}>Receipt QR</p>
                  <p className={styles.qrSub}>{receiptNo.current}</p>
                </div>
              </div>

              {/* Digital Signature */}
              <div className={styles.sigSection}>
                <div className={styles.sigBox}>
                  <svg viewBox="0 0 120 40" width="120" height="40">
                    <path d="M10 30 Q 30 10 50 25 T 90 20 T 115 28" fill="none" stroke="#1e293b" strokeWidth="2" strokeLinecap="round"/>
                  </svg>
                  <p className={styles.sigLabel}>{data.agentName}</p>
                  <p className={styles.sigSub}>Agent Signature</p>
                </div>
                <div className={styles.sigBox} style={{ textAlign: "right" }}>
                  <div className={styles.stampCircle}>
                    <span>PAID</span>
                  </div>
                </div>
              </div>

              <p className={styles.thanksMsg}>{L.thanks}</p>
            </div>

            {/* Send / Share Actions */}
            <div className={`${styles.actionsGrid} fade-in-up fade-in-up-1`}>
              {[
                { id: "whatsapp", icon: "💬", label: "WhatsApp", color: "#dcfce7", textColor: "#16a34a" },
                { id: "sms", icon: "📱", label: "SMS", color: "#dbeafe", textColor: "#2563eb" },
                { id: "email", icon: "📧", label: "Email", color: "#eff6ff", textColor: "#2563eb" },
                { id: "pdf", icon: "📄", label: "PDF", color: "#fef3c7", textColor: "#d97706" },
              ].map(a => (
                <button
                  key={a.id}
                  className={`${styles.actionBtn} ${sent.has(a.id) ? styles.actionSent : ""}`}
                  style={{ background: a.color, color: a.textColor }}
                  onClick={() => simulateSend(a.id)}
                >
                  <span className={styles.actionIcon}>{sent.has(a.id) ? "✅" : a.icon}</span>
                  <span className={styles.actionLabel}>{sent.has(a.id) ? "Sent!" : a.label}</span>
                </button>
              ))}
            </div>

            {/* Print & Duplicate Row */}
            <div className={`${styles.printRow} fade-in-up fade-in-up-2`}>
              <button className={styles.printBtn} onClick={simulatePrint}>
                🖨️ Bluetooth Print
              </button>
              <button className={`${styles.printBtn} ${styles.dupBtn}`} onClick={() => setIsDuplicate(!isDuplicate)}>
                📋 {isDuplicate ? "Hide Duplicate" : "Duplicate Print"}
              </button>
            </div>

            {/* Bluetooth Printer Modal */}
            {showPrinter && (
              <div className={`${styles.printerModal} fade-in-up`}>
                <div className={styles.printerCard}>
                  <div className={styles.printerIcon}>🖨️</div>
                  <p className={styles.printerTitle}>Bluetooth Thermal Printer</p>
                  {printing ? (
                    <>
                      <div className={styles.printerProgress}>
                        <div className={styles.printerProgressBar} />
                      </div>
                      <p className={styles.printerStatus}>Printing receipt…</p>
                    </>
                  ) : (
                    <>
                      <p className={styles.printerStatus} style={{ color: "#16a34a" }}>✅ Printed Successfully!</p>
                      <button className={styles.printerClose} onClick={() => setShowPrinter(false)}>Close</button>
                    </>
                  )}
                </div>
              </div>
            )}

            {/* Next Customer CTA */}
            <div style={{ padding: "0 16px 20px" }} className="fade-in-up">
              <button className="btn btn-primary" onClick={() => router.push("/next-customer")}>
                ➡️ Next Customer
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
