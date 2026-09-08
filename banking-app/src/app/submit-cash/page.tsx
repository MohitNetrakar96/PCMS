"use client";
import { useRef, useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import styles from "./page.module.css";

const CLOSING_BALANCE = 35125;

const DEFAULT_AUDIT_TRAIL = [
  { time: "8:12 AM", action: "Agent Login", user: "Rahul Verma", status: "ok" },
  { time: "9:05 AM", action: "Collection: Priya Sharma ₹513", user: "Rahul Verma", status: "ok" },
  { time: "10:22 AM", action: "Collection: Rajesh Kumar ₹308", user: "Rahul Verma", status: "ok" },
  { time: "11:48 AM", action: "Collection: Kavita Singh ₹762", user: "Rahul Verma", status: "ok" },
  { time: "1:30 PM", action: "Collection: Vikram Rao ₹255", user: "Rahul Verma", status: "ok" },
  { time: "2:15 PM", action: "Receipt Generated RCP-20260812-0001", user: "System", status: "ok" },
  { time: "3:00 PM", action: "Summary Submitted to Branch", user: "Rahul Verma", status: "ok" },
];

type Step = "entry" | "verify" | "manager" | "cashier" | "deposit" | "sign" | "close" | "locked";

export default function SubmitCashPage() {
  const router = useRouter();
  const { notifySuccess, notifyWarning, notifyInfo, notifyError } = useNotification();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const drawing = useRef(false);

  const [step, setStep] = useState<Step>("entry");
  const [cashEntered, setCashEntered] = useState("");
  const [bankRef, setBankRef] = useState("");
  const [managerOtp, setManagerOtp] = useState(["", "", "", ""]);
  const [signed, setSigned] = useState(false);
  const [showAudit, setShowAudit] = useState(false);
  const [locked, setLocked] = useState(false);
  const [cashierAccepted, setCashierAccepted] = useState(false);

  const [expectedCash, setExpectedCash] = useState(700);
  const [auditTrail, setAuditTrail] = useState(DEFAULT_AUDIT_TRAIL);

  useEffect(() => {
    const records = JSON.parse(localStorage.getItem("pcms_collections_today") || "[]");
    
    // Sum cash payment mode records
    const collectedCash = records
      .filter((r: any) => r.status === "collected" && r.paymentMode === "CASH")
      .reduce((sum: number, r: any) => sum + r.amount, 0);

    if (records.length > 0) {
      setExpectedCash(collectedCash);
      
      // Build dynamic audit trail
      const agentName = localStorage.getItem("pcms_session_name") || "Rahul Verma";
      const trail = [
        { time: "8:12 AM", action: "Agent Login", user: agentName, status: "ok" },
      ];
      records.forEach((r: any) => {
        trail.push({
          time: r.timestamp,
          action: `${r.status === "collected" ? "Collection" : "Visit logged"}: ${r.customerName} (₹${r.amount})`,
          user: agentName,
          status: "ok"
        });
      });
      trail.push({
        time: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
        action: "Daily Summary Submitted to Branch",
        user: agentName,
        status: "ok"
      });
      setAuditTrail(trail);
    }
  }, []);

  const cash = parseFloat(cashEntered) || 0;
  const diff = cash - expectedCash;
  const hasDiff = diff !== 0;

  const clearSignature = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    canvas.getContext("2d")?.clearRect(0, 0, canvas.width, canvas.height);
    setSigned(false);
  };

  const startDraw = (e: React.MouseEvent | React.TouchEvent) => {
    drawing.current = true;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.beginPath();
    const rect = canvas.getBoundingClientRect();
    const x = ("touches" in e ? e.touches[0].clientX : e.clientX) - rect.left;
    const y = ("touches" in e ? e.touches[0].clientY : e.clientY) - rect.top;
    ctx.moveTo(x, y);
  };

  const draw = (e: React.MouseEvent | React.TouchEvent) => {
    if (!drawing.current) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const rect = canvas.getBoundingClientRect();
    const x = ("touches" in e ? e.touches[0].clientX : e.clientX) - rect.left;
    const y = ("touches" in e ? e.touches[0].clientY : e.clientY) - rect.top;
    ctx.lineTo(x, y);
    ctx.strokeStyle = "#1e293b";
    ctx.lineWidth = 2.5;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.stroke();
    setSigned(true);
  };

  const stopDraw = () => { drawing.current = false; };

  const handleOtpChange = (val: string, i: number) => {
    const next = [...managerOtp];
    next[i] = val.slice(-1);
    setManagerOtp(next);
    if (val && i < 3) document.getElementById(`motp-${i + 1}`)?.focus();
  };

  // Step labels
  const STEPS: Step[] = ["entry", "verify", "manager", "cashier", "deposit", "sign", "close", "locked"];
  const STEP_LABELS = ["Entry", "Verify", "Approval", "Accept", "Deposit", "Sign", "Close", "Done"];
  const currentIdx = STEPS.indexOf(step);

  const renderStep = () => {
    switch (step) {
      // ── Step 1: Cash Submission Entry ──
      case "entry": return (
        <div className={`${styles.stepCard} fade-in-up`}>
          <div className={styles.stepIcon}>💼</div>
          <h2 className={styles.stepTitle}>Cash Submission Entry</h2>
          <p className={styles.stepSub}>Enter total cash collected today</p>
          <div className={styles.expectedRow}>
            <span>Expected Cash:</span>
            <strong>₹{expectedCash.toLocaleString()}</strong>
          </div>
          <div className={styles.amtBox}>
            <span className={styles.rupeeSign}>₹</span>
            <input className={styles.amtInput} type="number" placeholder="Enter cash amount" value={cashEntered} onChange={e => setCashEntered(e.target.value)} autoFocus />
          </div>
          <button className="btn btn-primary" disabled={!cashEntered} onClick={() => setStep("verify")}>
            Continue →
          </button>
        </div>
      );

      // ── Step 2: Cash Verification + Difference Report ──
      case "verify": return (
        <div className={`${styles.stepCard} fade-in-up`}>
          <div className={styles.stepIcon}>🔍</div>
          <h2 className={styles.stepTitle}>Cash Verification</h2>
          <div className={styles.verifyTable}>
            {[
              { label: "Expected Cash", value: `₹${expectedCash.toLocaleString()}`, color: "#2563eb" },
              { label: "Cash Submitted", value: `₹${cash.toLocaleString()}`, color: "#16a34a" },
              { label: "Difference", value: `${diff >= 0 ? "+" : ""}₹${diff.toLocaleString()}`, color: diff === 0 ? "#16a34a" : "#ef4444" },
            ].map(r => (
              <div key={r.label} className={styles.verifyRow}>
                <span className={styles.verifyLabel}>{r.label}</span>
                <span className={styles.verifyVal} style={{ color: r.color }}>{r.value}</span>
              </div>
            ))}
          </div>
          {hasDiff && (
            <div className={styles.diffAlert}>
              ⚠️ <strong>Cash Difference Detected!</strong><br />
              {diff > 0 ? `You have ₹${Math.abs(diff).toLocaleString()} extra cash.` : `You are short by ₹${Math.abs(diff).toLocaleString()}.`}
              <br />Please verify before proceeding.
            </div>
          )}
          {!hasDiff && <div className={styles.matchAlert}>✅ Cash matches expected amount!</div>}
          <div style={{ display: "flex", gap: 10 }}>
            <button className={styles.backBtn2} onClick={() => setStep("entry")}>← Back</button>
            <button className="btn btn-primary" onClick={async () => {
              const agentEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
              await api.submitVaultCash({ agentEmail, cashSubmitted: cash, expectedCash, auditTrail });
              if (hasDiff) {
                await api.requestManagerOtp(agentEmail, diff);
              }
              setStep("manager");
            }}>Send for Approval →</button>
          </div>
        </div>
      );

      // ── Step 3: Manager Approval ──
      case "manager": return (
        <div className={`${styles.stepCard} fade-in-up`}>
          <div className={styles.stepIcon}>👨‍💼</div>
          <h2 className={styles.stepTitle}>Manager Approval</h2>
          <p className={styles.stepSub}>Enter OTP sent to Branch Manager</p>
          <div className={styles.otpRow}>
            {managerOtp.map((v, i) => (
              <input key={i} id={`motp-${i}`} className={styles.otpBox} type="text" inputMode="numeric"
                maxLength={1} value={v} onChange={e => handleOtpChange(e.target.value, i)}
                onKeyDown={e => { if (e.key === "Backspace" && !managerOtp[i] && i > 0) document.getElementById(`motp-${i - 1}`)?.focus(); }}
              />
            ))}
          </div>
          <p className={styles.otpHint}>Manager clearance code (Enter 4 digits)</p>
          <div style={{ display: "flex", gap: 10 }}>
            <button className={styles.backBtn2} onClick={() => setStep("verify")}>← Back</button>
            <button className="btn btn-primary" disabled={managerOtp.some(v => !v)} onClick={async () => {
              const agentEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
              await api.verifyManagerOtp(agentEmail, managerOtp.join(""));
              setStep("cashier");
            }}>
              Submit Approval →
            </button>
          </div>
        </div>
      );

      // ── Step 4: Cashier Acceptance ──
      case "cashier": return (
        <div className={`${styles.stepCard} fade-in-up`}>
          <div className={styles.stepIcon}>🏦</div>
          <h2 className={styles.stepTitle}>Cashier Acceptance</h2>
          <p className={styles.stepSub}>Cashier to verify and accept the cash</p>
          <div className={styles.cashierCard}>
            <p className={styles.cashierName}>Cashier: Meena Reddy</p>
            <p className={styles.cashierEmail}>cashier@bankflow.com</p>
            <div className={styles.cashAmount}>
              <p>Cash Amount</p>
              <p className={styles.cashAmtVal}>₹{cash.toLocaleString()}</p>
            </div>
          </div>
          <label className={styles.acceptRow}>
            <input type="checkbox" checked={cashierAccepted} onChange={e => setCashierAccepted(e.target.checked)} style={{ width: 18, height: 18, accentColor: "var(--color-primary)", cursor: "pointer" }} />
            <span>I, the cashier, confirm receipt of ₹{cash.toLocaleString()}</span>
          </label>
          <div style={{ display: "flex", gap: 10 }}>
            <button className={styles.backBtn2} onClick={() => setStep("manager")}>← Back</button>
            <button className="btn btn-primary" disabled={!cashierAccepted} onClick={async () => {
              const agentEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
              await api.cashierAccept(agentEmail, "cashier_signature_accepted");
              setStep("deposit");
            }}>
              Accepted →
            </button>
          </div>
        </div>
      );

      // ── Step 5: Bank Deposit Entry ──
      case "deposit": return (
        <div className={`${styles.stepCard} fade-in-up`}>
          <div className={styles.stepIcon}>🏧</div>
          <h2 className={styles.stepTitle}>Bank Deposit Entry</h2>
          <p className={styles.stepSub}>Enter bank deposit reference</p>
          <div className={styles.depositInfo}>
            <div className={styles.depositRow}><span>Branch</span><strong>Gandhi Nagar Branch</strong></div>
            <div className={styles.depositRow}><span>Account</span><strong>PCMS-BRANCH-001</strong></div>
            <div className={styles.depositRow}><span>Deposit Amount</span><strong>₹{cash.toLocaleString()}</strong></div>
            <div className={styles.depositRow}><span>Closing Balance</span><strong style={{ color: "#16a34a" }}>₹{CLOSING_BALANCE.toLocaleString()}</strong></div>
          </div>
          <div className="form-group">
            <label className="form-label">Bank Reference / Slip No.</label>
            <input className="form-input" type="text" placeholder="e.g. DEP-2026-08-12-001" value={bankRef} onChange={e => setBankRef(e.target.value)} />
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <button className={styles.backBtn2} onClick={() => setStep("cashier")}>← Back</button>
            <button className="btn btn-primary" disabled={!bankRef} onClick={() => setStep("sign")}>Next →</button>
          </div>
        </div>
      );

      // ── Step 6: Digital Signature + Handover Register ──
      case "sign": return (
        <div className={`${styles.stepCard} fade-in-up`}>
          <div className={styles.stepIcon}>✍️</div>
          <h2 className={styles.stepTitle}>Digital Signature</h2>
          <p className={styles.stepSub}>Cash Handover Register — Sign to confirm</p>
          <div className={styles.handoverCard}>
            <div className={styles.handoverRow}><span>Date</span><strong>{new Date().toLocaleDateString("en-IN")}</strong></div>
            <div className={styles.handoverRow}><span>Agent</span><strong>Rahul Verma</strong></div>
            <div className={styles.handoverRow}><span>Amount</span><strong>₹{cash.toLocaleString()}</strong></div>
            <div className={styles.handoverRow}><span>Reference</span><strong>{bankRef}</strong></div>
          </div>
          <div className={styles.signatureHeader}>
            <p style={{ fontSize: 13, fontWeight: 700, color: "var(--color-text-primary-light)" }}>Sign Here:</p>
            <button className={styles.clearBtn} onClick={clearSignature}>Clear</button>
          </div>
          <div className={styles.signaturePad}>
            <canvas ref={canvasRef} width={300} height={90} className={styles.signatureCanvas}
              onMouseDown={startDraw} onMouseMove={draw} onMouseUp={stopDraw} onMouseLeave={stopDraw}
              onTouchStart={startDraw} onTouchMove={draw} onTouchEnd={stopDraw} />
            {!signed && <p className={styles.signaturePlaceholder}>Sign here…</p>}
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <button className={styles.backBtn2} onClick={() => setStep("deposit")}>← Back</button>
            <button className="btn btn-primary" disabled={!signed} onClick={() => setStep("close")}>Proceed →</button>
          </div>
        </div>
      );

      // ── Step 7: End of Day Closing ──
      case "close": return (
        <div className={`${styles.stepCard} fade-in-up`}>
          <div className={styles.stepIcon}>🔒</div>
          <h2 className={styles.stepTitle}>End of Day Closing</h2>
          <p className={styles.stepSub}>Review and lock daily transactions</p>
          <div className={styles.closingSummary}>
            {[
              { label: "Expected Cash", value: `₹${expectedCash.toLocaleString()}` },
              { label: "Cash Submitted", value: `₹${cash.toLocaleString()}` },
              { label: "Bank Reference", value: bankRef },
              { label: "Closing Balance", value: `₹${CLOSING_BALANCE.toLocaleString()}` },
              { label: "Status", value: "Ready to close" },
            ].map(r => (
              <div key={r.label} className={styles.closeRow}>
                <span className={styles.closeLabel}>{r.label}</span>
                <span className={styles.closeVal}>{r.value}</span>
              </div>
            ))}
          </div>
          <div className={styles.lockWarning}>
            ⚠️ <strong>Warning:</strong> Locking will prevent any further edits to today&apos;s transactions.
          </div>
          <button className={`${styles.lockBtn} ${locked ? styles.locked : ""}`}
            onClick={async () => {
              setLocked(true);
              const agentEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
              await api.bankDeposit(agentEmail, bankRef);
              notifySuccess("Vault Cash Submitted", "End of day handover locked and registered.");
              setTimeout(() => setStep("locked"), 1500);
            }}
            disabled={locked}>
            {locked ? "🔒 Locking day…" : "🔒 Close & Lock Day"}
          </button>
          <button className={styles.auditLink} onClick={() => setShowAudit(!showAudit)}>
            {showAudit ? "▲ Hide Audit Trail" : "▼ View Audit Trail"}
          </button>
          {showAudit && (
            <div className={styles.auditTrail}>
              {auditTrail.map((a, i) => (
                <div key={i} className={styles.auditRow}>
                  <div className={styles.auditDot} />
                  <div className={styles.auditInfo}>
                    <p className={styles.auditAction}>{a.action}</p>
                    <p className={styles.auditMeta}>{a.time} · {a.user}</p>
                  </div>
                  <span className={styles.auditOk}>✓</span>
                </div>
              ))}
            </div>
          )}
        </div>
      );

      // ── Step 8: Locked / Done ──
      case "locked": return (
        <div className={`${styles.stepCard} fade-in-up`} style={{ textAlign: "center" }}>
          <div style={{ fontSize: 64, marginBottom: 16 }}>🎉</div>
          <h2 className={styles.stepTitle}>Day Successfully Closed!</h2>
          <p className={styles.stepSub}>All transactions are locked and verified.</p>
          <div className={styles.closedBox}>
            <p>✅ Cash Submitted: <strong>₹{cash.toLocaleString()}</strong></p>
            <p>✅ Bank Reference: <strong>{bankRef}</strong></p>
            <p>✅ Digital Signature: <strong>Captured</strong></p>
            <p>✅ Audit Trail: <strong>Sealed</strong></p>
            <p>✅ Transactions: <strong>Locked</strong></p>
          </div>
          <button className="btn btn-primary" style={{ marginTop: 16 }} onClick={() => {
            // Empty the database for a clean start on next run
            localStorage.removeItem("pcms_collections_today");
            router.push("/dashboard");
          }}>
            Back to Dashboard
          </button>
        </div>
      );
    }
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
              <button className={styles.backBtn} onClick={() => router.back()}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="20" height="20"><polyline points="15 18 9 12 15 6"/></svg>
              </button>
              <h1 className={styles.title}>Submit Cash</h1>
              <div style={{ width: 36 }} />
            </div>

            {/* Progress Stepper */}
            <div className={styles.stepper}>
              {STEP_LABELS.map((label, i) => (
                <div key={label} className={styles.stepItem}>
                  <div className={`${styles.stepCircle} ${i <= currentIdx ? styles.stepDone : ""} ${i === currentIdx ? styles.stepCurrent : ""}`}>
                    {i < currentIdx ? "✓" : i + 1}
                  </div>
                  {i < STEP_LABELS.length - 1 && <div className={`${styles.stepLine} ${i < currentIdx ? styles.stepLineDone : ""}`} />}
                </div>
              ))}
            </div>
            <p className={styles.stepLabel}>{STEP_LABELS[currentIdx]}</p>

            {/* Step Content */}
            {renderStep()}
          </div>
        </div>
      </div>
    </div>
  );
}
