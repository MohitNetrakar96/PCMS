"use client";
import { use, useState, useRef, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import CustomerMap from "@/components/CustomerMap";
import styles from "./page.module.css";

const VISIT_STATUSES = [
  { id: "collected", label: "Collected", icon: "✓", color: "#22c55e", bg: "#dcfce7" },
  { id: "not_available", label: "Not Available", icon: "🚫", color: "#f59e0b", bg: "#fef3c7" },
  { id: "house_locked", label: "House Locked", icon: "🔒", color: "#ef4444", bg: "#fee2e2" },
  { id: "payment_tomorrow", label: "Pay Tomorrow", icon: "📅", color: "#8b5cf6", bg: "#ede9fe" },
  { id: "shifted", label: "Shifted", icon: "🚚", color: "#64748b", bg: "#f1f5f9" },
];

type CustomerData = {
  name: string;
  email: string;
  phone: string;
  account: string;
  pigmyAccountNumber: string;
  area: string;
  route: string;
  address: string;
  aadhaar: string | null;
  pan: string | null;
  kyc_status: string;
  dailyAmount: number;
  pigmyBalance: number;
  openingBalance: number;
  totalDeposits: number;
  photoUrl: string | null;
  accounts: any[];
};

const EMPTY_CUSTOMER: CustomerData = {
  name: "", email: "", phone: "", account: "", pigmyAccountNumber: "",
  area: "", route: "", address: "",
  aadhaar: null, pan: null, kyc_status: "Pending",
  dailyAmount: 0, pigmyBalance: 0, openingBalance: 0, totalDeposits: 0,
  photoUrl: null, accounts: []
};

export default function CustomerProfilePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const { notifySuccess, notifyError, notifyWarning, notifyInfo, confirmDialog } = useNotification();

  const [customer, setCustomer] = useState<CustomerData>(EMPTY_CUSTOMER);
  const [loading, setLoading] = useState(true);

  const [visitStatus, setVisitStatus] = useState("");
  const [remarks, setRemarks] = useState("");

  // GPS
  const [gpsLoading, setGpsLoading] = useState(false);
  const [gpsCoords, setGpsCoords] = useState<{ lat: number; lng: number } | null>(null);
  const [gpsError, setGpsError] = useState("");

  // Visit time (recorded when page loads)
  const [visitTime] = useState(() =>
    new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })
  );

  // Signature
  const [signed, setSigned] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const drawing = useRef(false);

  // Photo
  const [photoUrl, setPhotoUrl] = useState<string | null>(null);
  const [savingPhoto, setSavingPhoto] = useState(false);

  // Tabs
  const [activeTab, setActiveTab] = useState<"profile" | "kyc" | "pigmy">("profile");

  // Submitting
  const [submitting, setSubmitting] = useState(false);

  const [notFound, setNotFound] = useState(false);

  // ── Load customer data ──
  useEffect(() => {
    const load = async () => {
      setLoading(true);
      setNotFound(false);
      try {
        const live = await api.getCustomer(id);
        if (live) {
          const initials = live.name.split(" ").map((n: string) => n[0]).join("").substring(0, 2).toUpperCase();
          const acct = live.accounts?.[0];
          const pigmyAccNum = acct?.account_number || live.id.replace("CUST-", "PG-2026-");
          const totalDeps = live.history?.length || 0;

          setCustomer({
            name: live.name,
            email: live.email || "",
            phone: live.phone || "",
            account: `PCMS-00${live.id.replace("CUST-", "")}`,
            pigmyAccountNumber: pigmyAccNum,
            area: live.area || "",
            route: live.route || "",
            address: live.address || "",
            aadhaar: live.aadhar_number || null,
            pan: live.pan_number || null,
            kyc_status: live.kyc_status || "Pending",
            dailyAmount: acct?.daily_target || Math.round((live.opening_balance || 0) * 0.05) || 0,
            pigmyBalance: acct?.balance ?? live.opening_balance ?? 0,
            openingBalance: live.opening_balance || 0,
            totalDeposits: totalDeps,
            photoUrl: live.photo_url || null,
            accounts: live.accounts || []
          });

          if (live.photo_url) {
            setPhotoUrl(live.photo_url);
          }
        } else {
          setNotFound(true);
        }
      } catch (e: any) {
        setNotFound(true);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [id]);

  // ── GPS capture ──
  const captureGPS = useCallback(() => {
    setGpsLoading(true);
    setGpsError("");
    if (!navigator.geolocation) {
      setGpsError("GPS not supported on this device.");
      setGpsLoading(false);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setGpsCoords({ lat: pos.coords.latitude, lng: pos.coords.longitude });
        setGpsLoading(false);
        notifySuccess("GPS Captured", `Location: ${pos.coords.latitude.toFixed(4)}°N, ${pos.coords.longitude.toFixed(4)}°E`);
      },
      (err) => {
        setGpsError("Location access denied. Please allow GPS permission.");
        setGpsLoading(false);
        notifyWarning("GPS Failed", "Enable location permissions and try again.");
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }, []);

  // ── Photo capture ──
  const handlePhotoCapture = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setSavingPhoto(true);
    try {
      const reader = new FileReader();
      reader.onload = async (event) => {
        const base64 = event.target?.result as string;
        setPhotoUrl(base64);
        // Save to backend
        try {
          await api.updateCustomerPhoto(id, base64);
          notifySuccess("Photo Saved", "Customer photograph uploaded to profile.");
        } catch (e: any) {
          notifyWarning("Photo Upload", "Photo saved locally. Will sync when online.");
        }
        setSavingPhoto(false);
      };
      reader.readAsDataURL(file);
    } catch {
      setSavingPhoto(false);
    }
  };

  // ── Signature canvas ──
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

  // ── Submit visit ──
  const handleSubmitVisit = async () => {
    if (!visitStatus) {
      notifyWarning("Visit Status", "Please select a visit status before submitting.");
      return;
    }
    if (visitStatus !== "collected" && !remarks.trim()) {
      notifyWarning("Remarks Required", "Please enter remarks for this visit status.");
      return;
    }

    setSubmitting(true);
    const agentEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
    const records = JSON.parse(localStorage.getItem("pcms_collections_today") || "[]");
    const cleanRecords = records.filter((r: any) => r.customerId !== id);

    if (visitStatus === "collected") {
      // Store visit data and navigate to collect page for amount entry
      localStorage.setItem("pcms_temp_visit", JSON.stringify({
        customerId: id,
        customerName: customer.name,
        account: customer.account,
        status: "collected",
        remarks,
        signed,
        photoUrl,
        gpsCoords: gpsCoords ? `${gpsCoords.lat.toFixed(6)}, ${gpsCoords.lng.toFixed(6)}` : null,
        visitTime
      }));
      setSubmitting(false);
      router.push(`/collect/${id}`);
    } else {
      try {
        const newRecord = {
          customerId: id,
          customerName: customer.name,
          account: customer.account,
          status: visitStatus,
          amount: 0,
          paymentMode: "—",
          remarks,
          timestamp: visitTime,
          signed,
          photoUrl: !!photoUrl,
          gpsCoords: gpsCoords ? `${gpsCoords.lat.toFixed(6)}, ${gpsCoords.lng.toFixed(6)}` : null
        };
        localStorage.setItem("pcms_collections_today", JSON.stringify([...cleanRecords, newRecord]));

        await api.recordCollection({
          customerId: id,
          agentEmail,
          status: visitStatus,
          collectedAmount: 0,
          remarks,
          latitude: gpsCoords?.lat,
          longitude: gpsCoords?.lng,
          photoCaptured: photoUrl ? 1 : 0,
          signatureCaptured: signed ? 1 : 0,
        });

        notifySuccess(
          "Visit Logged",
          `${VISIT_STATUSES.find(v => v.id === visitStatus)?.label} — recorded at ${visitTime}`
        );
        router.push("/collection");
      } catch (e: any) {
        notifyError("Submit Failed", e.message || "Could not save visit. Please retry.");
      } finally {
        setSubmitting(false);
      }
    }
  };

  const kycBadgeColor = customer.kyc_status === "Verified" ? "#22c55e" : customer.kyc_status === "Rejected" ? "#ef4444" : "#f59e0b";

  if (loading) {
    return (
      <div className="app-wrapper">
        <div className="phone-frame">
          <div className="screen">
            <div className="screen-content" style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%" }}>
              <div style={{ textAlign: "center" }}>
                <div style={{ width: 40, height: 40, border: "3px solid var(--color-primary)", borderTopColor: "transparent", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto 12px" }} />
                <p style={{ color: "#64748b", fontSize: 13 }}>Loading customer…</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (notFound || !customer.name) {
    return (
      <div className="app-wrapper">
        <div className="phone-frame">
          <div className="screen">
            <div className="screen-content" style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "100%", padding: 24, textAlign: "center" }}>
              <p style={{ fontSize: 48, margin: "0 0 12px 0" }}>👤</p>
              <h3 style={{ fontSize: 18, fontWeight: 800, color: "#0f172a", marginBottom: 6 }}>Customer Not Found</h3>
              <p style={{ fontSize: 13, color: "#64748b", marginBottom: 20 }}>
                This customer does not exist or has been deleted.
              </p>
              <button
                className="btn btn-primary"
                onClick={() => router.push("/collection")}
              >
                ← Back to Collections
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="app-wrapper">
      <div className="phone-frame">
        <div className="status-bar light">
          <span>{visitTime}</span>
          <div className="status-bar__icons">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 6s4-4 11-4 11 4 11 4"/><path d="M5 10s3-3 7-3 7 3 7 3"/><path d="M9 14s1.5-1.5 3-1.5 3 1.5 3 1.5"/><circle cx="12" cy="18" r="1" fill="currentColor"/></svg>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="15" height="10" rx="2"/><path d="M22 11v2"/></svg>
          </div>
        </div>

        <div className="screen">
          <div className="screen-content">

            {/* ── Top bar ── */}
            <div className={styles.topBar}>
              <button className={styles.backBtn} onClick={() => router.back()}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="20" height="20"><polyline points="15 18 9 12 15 6"/></svg>
              </button>
              <h1 className={styles.pageTitle}>Customer Visit</h1>
              <div style={{ display: "flex", gap: 6 }}>
                {customer.phone && (
                  <a
                    href={`tel:${customer.phone}`}
                    className={styles.actionIconBtn}
                    style={{ background: "#eff6ff" }}
                    title="Call Customer"
                  >
                    <svg viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2.5" width="18" height="18"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.81 19.79 19.79 0 01.06 1.18 2 2 0 012.03 0h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L6.09 7.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z"/></svg>
                  </a>
                )}
                {customer.phone && (
                  <a
                    href={`https://wa.me/${customer.phone.replace(/\D/g, "").replace(/^0/, "91")}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    title="WhatsApp Customer"
                  >
                    💬
                  </a>
                )}
                <a
                  href={`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent((customer.address || customer.area || "Hubli") + " " + customer.name)}&travelmode=driving`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.actionIconBtn}
                  style={{ background: "#e0f2fe" }}
                  title="Navigate on Google Maps"
                >
                  <span style={{ fontSize: 16 }}>🧭</span>
                </a>
              </div>
            </div>

            {/* ── Profile Banner ── */}
            <div className={`${styles.profileBanner} fade-in-up`}>
              <div className={styles.photoContainer}>
                {photoUrl ? (
                  <img src={photoUrl} alt={customer.name} className={styles.customerPhoto} />
                ) : (
                  <div className={styles.customerPhotoCircle}>
                    {customer.name ? customer.name.split(" ").map(n => n[0]).join("").substring(0, 2).toUpperCase() : "?"}
                  </div>
                )}
                <label className={styles.cameraOverlay} title="Capture Customer Photograph">
                  {savingPhoto ? "⏳" : "📷"}
                  <input
                    type="file"
                    accept="image/*"
                    capture="environment"
                    onChange={handlePhotoCapture}
                    style={{ display: "none" }}
                  />
                </label>
              </div>
              <div className={styles.profileInfo}>
                <h2 className={styles.profileName}>{customer.name}</h2>
                {customer.phone && <p className={styles.profileEmail}>{customer.phone}</p>}
                <p className={styles.profileAcc}>{customer.account} · {customer.area}</p>
              </div>
              <div className={styles.visitTimeBadge}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="12" height="12"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                {visitTime}
              </div>
            </div>

            {/* ── Tabs ── */}
            <div className={`${styles.tabRow} fade-in-up fade-in-up-1`}>
              {(["profile", "kyc", "pigmy"] as const).map((t) => (
                <button
                  key={t}
                  className={`${styles.tabBtn} ${activeTab === t ? styles.tabActive : ""}`}
                  onClick={() => setActiveTab(t)}
                >
                  {t === "profile" ? "Profile" : t === "kyc" ? "KYC" : "Pigmy A/C"}
                </button>
              ))}
            </div>

            {/* ── Profile Tab ── */}
            {activeTab === "profile" && (
              <div className={`${styles.tabContent} fade-in-up`}>
                {[
                  { label: "Email", value: customer.email || null },
                  { label: "Phone", value: customer.phone || null },
                  { label: "Area", value: customer.area || null },
                  { label: "Route", value: customer.route || null },
                  { label: "Address", value: customer.address || null },
                ].map((r) => (
                  <div key={r.label} className={styles.infoRow}>
                    <span className={styles.infoLabel}>{r.label}</span>
                    <span className={styles.infoValue} style={{ color: r.value ? undefined : "#94a3b8", fontStyle: r.value ? "normal" : "italic" }}>
                      {r.value || "Not provided"}
                    </span>
                  </div>
                ))}

                <a
                  href={`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent((customer.address || customer.area || "Hubli") + " " + customer.name)}&travelmode=driving`}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{
                    marginTop: 10,
                    marginBottom: 10,
                    background: "linear-gradient(135deg, #2563eb, #1d4ed8)",
                    color: "#ffffff",
                    borderRadius: 10,
                    padding: "10px 16px",
                    fontSize: 13,
                    fontWeight: 700,
                    textDecoration: "none",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: 8,
                    boxShadow: "0 2px 6px rgba(37,99,235,0.25)"
                  }}
                >
                  <span>🧭 Open Turn-by-Turn GPS Navigation</span>
                </a>

                <div style={{ marginTop: 12 }}>
                  <CustomerMap
                    customerName={customer.name}
                    address={customer.address}
                    area={customer.area}
                    latitude={gpsCoords?.lat}
                    longitude={gpsCoords?.lng}
                    showNavigationButton={true}
                  />
                </div>
              </div>
            )}

            {/* ── KYC Tab ── */}
            {activeTab === "kyc" && (
              <div className={`${styles.tabContent} fade-in-up`}>
                {/* KYC Status badge */}
                <div style={{ display: "flex", justifyContent: "center", marginBottom: 10 }}>
                  <span style={{
                    padding: "4px 14px",
                    borderRadius: 100,
                    fontSize: 11,
                    fontWeight: 700,
                    background: `${kycBadgeColor}20`,
                    color: kycBadgeColor,
                    border: `1px solid ${kycBadgeColor}40`,
                  }}>
                    {customer.kyc_status === "Verified" ? "✅" : customer.kyc_status === "Rejected" ? "❌" : "⏳"} KYC {customer.kyc_status}
                  </span>
                </div>
                {[
                  { label: "Aadhaar No.", value: customer.aadhaar },
                  { label: "PAN Number", value: customer.pan },
                  { label: "Address", value: customer.address || null },
                ].map((r) => (
                  <div key={r.label} className={styles.infoRow}>
                    <span className={styles.infoLabel}>{r.label}</span>
                    <span className={styles.infoValue} style={{ color: r.value ? undefined : "#94a3b8", fontStyle: r.value ? "normal" : "italic" }}>
                      {r.value || "Not provided"}
                    </span>
                  </div>
                ))}
              </div>
            )}

            {/* ── Pigmy A/C Tab ── */}
            {activeTab === "pigmy" && (
              <div className={`${styles.tabContent} fade-in-up`}>
                <div className={styles.pigmyCard}>
                  <div className={styles.pigmyItem}>
                    <span>Account No.</span>
                    <strong style={{ fontSize: 11 }}>{customer.pigmyAccountNumber || "Not assigned"}</strong>
                  </div>
                  <div className={styles.pigmyItem}>
                    <span>Opening Balance</span>
                    <strong>{customer.openingBalance > 0 ? `₹${customer.openingBalance.toLocaleString()}` : "—"}</strong>
                  </div>
                  <div className={styles.pigmyItem}>
                    <span>Current Balance</span>
                    <strong style={{ color: "var(--color-primary)" }}>
                      {customer.pigmyBalance > 0 ? `₹${customer.pigmyBalance.toLocaleString()}` : "—"}
                    </strong>
                  </div>
                  <div className={styles.pigmyItem}>
                    <span>Daily Target</span>
                    <strong>{customer.dailyAmount > 0 ? `₹${customer.dailyAmount}` : "—"}</strong>
                  </div>
                  <div className={styles.pigmyItem}>
                    <span>Collections Logged</span>
                    <strong>{customer.totalDeposits > 0 ? `${customer.totalDeposits} entries` : "No records"}</strong>
                  </div>
                </div>
              </div>
            )}

            {/* ── GPS Location ── */}
            <div className={`${styles.section} fade-in-up fade-in-up-2`}>
              <p className={styles.sectionTitle}>📍 GPS Location</p>
              {gpsCoords ? (
                <div className={styles.gpsResult}>
                  <span>✅ {gpsCoords.lat.toFixed(5)}°N, {gpsCoords.lng.toFixed(5)}°E</span>
                </div>
              ) : (
                <button className={styles.gpsBtn} onClick={captureGPS} disabled={gpsLoading}>
                  {gpsLoading ? "Locating…" : "📍 Capture Current Location"}
                </button>
              )}
              {gpsError && <p style={{ fontSize: 11, color: "#ef4444", marginTop: 4, textAlign: "center" }}>{gpsError}</p>}
            </div>

            {/* ── Visit Status ── */}
            <div className={`${styles.section} fade-in-up fade-in-up-2`}>
              <p className={styles.sectionTitle}>📋 Visit Status</p>
              <div className={styles.statusGrid}>
                {VISIT_STATUSES.map((s) => (
                  <button
                    key={s.id}
                    className={`${styles.statusOption} ${visitStatus === s.id ? styles.statusSelected : ""}`}
                    style={visitStatus === s.id ? { borderColor: s.color, background: s.bg } : {}}
                    onClick={() => setVisitStatus(s.id)}
                  >
                    <span style={{ fontSize: 18 }}>{s.icon}</span>
                    <span className={styles.statusLabel}>{s.label}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* ── Remarks ── */}
            <div className={`${styles.section} fade-in-up fade-in-up-2`}>
              <p className={styles.sectionTitle}>
                💬 Remarks {visitStatus && visitStatus !== "collected" && <span style={{ color: "#ef4444", fontSize: 10 }}>*Required</span>}
              </p>
              <textarea
                className={styles.remarksInput}
                placeholder={visitStatus === "collected" ? "Optional remarks about this collection…" : "Describe the reason for this visit status…"}
                value={remarks}
                onChange={(e) => setRemarks(e.target.value)}
                rows={3}
              />
            </div>

            {/* ── Signature Pad ── */}
            <div className={`${styles.section} fade-in-up fade-in-up-3`}>
              <div className={styles.signatureHeader}>
                <p className={styles.sectionTitle}>✍️ Customer Signature</p>
                <button className={styles.clearBtn} onClick={clearSignature}>Clear</button>
              </div>
              <div className={styles.signaturePad}>
                <canvas
                  ref={canvasRef}
                  width={310}
                  height={100}
                  className={styles.signatureCanvas}
                  onMouseDown={startDraw}
                  onMouseMove={draw}
                  onMouseUp={stopDraw}
                  onMouseLeave={stopDraw}
                  onTouchStart={startDraw}
                  onTouchMove={(e) => { e.preventDefault(); draw(e); }}
                  onTouchEnd={stopDraw}
                />
                {!signed && <p className={styles.signaturePlaceholder}>Sign here…</p>}
              </div>
            </div>

            {/* ── Action Buttons ── */}
            <div style={{ padding: "0 16px 16px" }} className="fade-in-up">
              <button
                className="btn btn-primary"
                onClick={handleSubmitVisit}
                disabled={submitting || !visitStatus}
                style={{ opacity: !visitStatus ? 0.6 : 1 }}
              >
                {submitting
                  ? "Saving…"
                  : visitStatus === "collected"
                  ? "💰 Proceed to Collect Amount"
                  : visitStatus
                  ? `💾 Log Visit: ${VISIT_STATUSES.find(v => v.id === visitStatus)?.label}`
                  : "Select a Visit Status"}
              </button>

              <button
                type="button"
                className="btn"
                onClick={async () => {
                  const ok = await confirmDialog({
                    title: `Delete ${customer.name}?`,
                    message: "This will permanently remove the customer, all accounts, balances, and collection history from the database.",
                    confirmText: "Delete Permanently",
                    type: "danger"
                  });
                  if (!ok) return;
                  await api.deleteCustomer(id);
                  notifySuccess("Customer Deleted", `${customer.name} was permanently removed.`);
                  router.push("/collection");
                }}
                style={{ marginTop: 10, background: "#fee2e2", color: "#dc2626", border: "1px solid #fca5a5" }}
              >
                🗑️ Delete Customer Permanently
              </button>
            </div>

          </div>
        </div>
      </div>
    </div>
  );
}
