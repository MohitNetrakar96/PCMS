"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import AddCustomerModal from "@/components/AddCustomerModal";
import dynamic from "next/dynamic";
import styles from "./page.module.css";

const RouteMap = dynamic(() => import("@/components/RouteMap"), { ssr: false });

export default function CollectionPage() {
  const router = useRouter();
  const { notifySuccess, notifyError, confirmDialog } = useNotification();
  const [customerList, setCustomerList] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [activeArea, setActiveArea] = useState("All Areas");
  const [syncing, setSyncing] = useState(false);
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [viewMode, setViewMode] = useState<"list" | "map">("list");
  const [agentLocation, setAgentLocation] = useState<{ lat: number; lng: number } | null>(null);

  const loadCollections = async () => {
    const email = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
    const serverList = await api.getTodayCollections(email);
    if (serverList) {
      setCustomerList(serverList);
    }
  };

  useEffect(() => {
    loadCollections();
    // Grab agent GPS for map view
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => setAgentLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        () => {},
        { enableHighAccuracy: true, timeout: 10000 }
      );
    }
  }, []);

  const handleSync = async () => {
    setSyncing(true);
    try {
      const email = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
      const localRecords = JSON.parse(localStorage.getItem("pcms_collections_today") || "[]");
      await api.syncCollections(email, localRecords);
      await loadCollections();
      notifySuccess("Sync Complete", "Offline collections synced to bank server.");
    } catch (e: any) {
      notifyError("Sync Error", e.message || "Could not sync collections.");
    } finally {
      setSyncing(false);
    }
  };

  const handleDeleteCustomer = async (id: string | number, name: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const ok = await confirmDialog({
      title: `Delete ${name}?`,
      message: "This will permanently remove all accounts, balances, and collection history from the bank database.",
      confirmText: "Delete Permanently",
      type: "danger"
    });
    if (!ok) return;

    await api.deleteCustomer(id);
    await loadCollections();
    notifySuccess("Customer Deleted", `${name} was permanently removed.`);
  };

  const handleClearAllCustomers = async () => {
    const ok = await confirmDialog({
      title: "Delete All Customers?",
      message: "This will permanently wipe ALL customer records, accounts, and collection data from the database.",
      confirmText: "Wipe All Customers",
      type: "danger"
    });
    if (!ok) return;

    await api.clearAllCustomers();
    setCustomerList([]);
    notifySuccess("Database Reset", "All customer records were permanently deleted.");
  };

  const handleClearAllHistory = async () => {
    const ok = await confirmDialog({
      title: "Clear All Collections?",
      message: "This will permanently wipe all today's collection logs and transaction history.",
      confirmText: "Clear All",
      type: "danger"
    });
    if (!ok) return;

    await api.clearAllCollectionHistory();
    await loadCollections();
    notifySuccess("History Cleared", "All collection history records were permanently wiped.");
  };

  const toggleCollapse = (area: string) => {
    setCollapsed((prev) => {
      const next = new Set(prev);
      next.has(area) ? next.delete(area) : next.add(area);
      return next;
    });
  };

  const uniqueAreas = ["All Areas", ...Array.from(new Set(customerList.map((c: any) => c.area))).filter(Boolean)];

  const filtered = customerList.filter((c) => {
    const matchArea = activeArea === "All Areas" || c.area === activeArea;
    const matchSearch = (c.name || "").toLowerCase().includes(search.toLowerCase()) || (c.email || "").toLowerCase().includes(search.toLowerCase());
    return matchArea && matchSearch;
  });

  const distinctAreas = Array.from(new Set(filtered.map((c: any) => c.area))).filter(Boolean);
  const grouped = distinctAreas.reduce((acc, area) => {
    const items = filtered.filter((c) => c.area === area);
    if (items.length) acc[area] = items;
    return acc;
  }, {} as Record<string, any[]>);

  const totalPending = filtered.filter((c) => c.status === "pending").length;
  const totalCollected = filtered.filter((c) => c.status === "collected").length;
  const totalAmount = filtered.reduce((s, c) => s + (c.status === "pending" ? (c.pending_amount || c.amount || 0) : 0), 0);

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
            <div className={styles.collHeader}>
              <div>
                <h1 className={styles.collTitle}>Today&apos;s Collections</h1>
                <p className={styles.collDate}>
                  {new Date().toLocaleDateString("en-IN", { weekday: "long", day: "numeric", month: "long" })}
                </p>
              </div>
              <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
                {/* List / Map toggle */}
                <div style={{
                  display: "flex", background: "#f1f5f9", borderRadius: 10, padding: 3, gap: 2
                }}>
                  <button
                    type="button"
                    onClick={() => setViewMode("list")}
                    style={{
                      background: viewMode === "list" ? "#2563eb" : "transparent",
                      color: viewMode === "list" ? "#fff" : "#64748b",
                      border: "none", borderRadius: 8,
                      padding: "5px 10px", fontSize: 11, fontWeight: 700, cursor: "pointer",
                      transition: "all 0.15s"
                    }}
                  >
                    ☰ List
                  </button>
                  <button
                    type="button"
                    onClick={() => setViewMode("map")}
                    style={{
                      background: viewMode === "map" ? "#2563eb" : "transparent",
                      color: viewMode === "map" ? "#fff" : "#64748b",
                      border: "none", borderRadius: 8,
                      padding: "5px 10px", fontSize: 11, fontWeight: 700, cursor: "pointer",
                      transition: "all 0.15s"
                    }}
                  >
                    🗺️ Map
                  </button>
                </div>
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(true)}
                  style={{
                    background: "linear-gradient(135deg, #2563eb, #1d4ed8)",
                    color: "#ffffff",
                    border: "none",
                    borderRadius: 10,
                    padding: "8px 12px",
                    fontSize: 11,
                    fontWeight: 700,
                    cursor: "pointer",
                    display: "flex",
                    alignItems: "center",
                    gap: 4,
                    boxShadow: "0 2px 8px rgba(37,99,235,0.3)"
                  }}
                >
                  ➕ Add
                </button>
                <button
                  type="button"
                  title="Wipe All Customers"
                  onClick={handleClearAllCustomers}
                  style={{ background: "#fee2e2", color: "#dc2626", border: "none", borderRadius: 10, padding: "8px 8px", fontSize: 11, fontWeight: 700, cursor: "pointer" }}
                >
                  🗑️
                </button>
              </div>
            </div>

            {/* Summary tiles — always visible */}
            <div className={`${styles.summaryTiles} fade-in-up`}>
              <div className={styles.tile} style={{ background: "linear-gradient(135deg,#fef3c7,#fde68a)" }}>
                <p className={styles.tileNum}>{totalPending}</p>
                <p className={styles.tileLabel}>Pending</p>
              </div>
              <div className={styles.tile} style={{ background: "linear-gradient(135deg,#d1fae5,#a7f3d0)" }}>
                <p className={styles.tileNum}>{totalCollected}</p>
                <p className={styles.tileLabel}>Collected</p>
              </div>
              <div className={styles.tile} style={{ background: "linear-gradient(135deg,#dbeafe,#bfdbfe)" }}>
                <p className={styles.tileNum}>₹{totalAmount.toLocaleString()}</p>
                <p className={styles.tileLabel}>Due Today</p>
              </div>
            </div>

            {/* ── MAP VIEW ── */}
            {viewMode === "map" && (
              <div style={{ padding: "0 12px 12px" }}>
                {customerList.filter(c => c.latitude && c.longitude).length === 0 ? (
                  <div style={{ textAlign: "center", padding: "32px 16px" }}>
                    <div style={{ fontSize: 48, marginBottom: 10 }}>📍</div>
                    <h3 style={{ fontSize: 15, fontWeight: 800, color: "#0f172a", margin: "0 0 6px" }}>
                      No Locations Available
                    </h3>
                    <p style={{ fontSize: 12, color: "#64748b", margin: 0 }}>
                      Customers need GPS coordinates (latitude/longitude) to appear on the map.
                      Add customers with an address to enable map view.
                    </p>
                  </div>
                ) : (
                  <RouteMap
                    customers={customerList
                      .filter(c => c.latitude && c.longitude)
                      .map(c => ({
                        id: c.id,
                        name: c.name,
                        area: c.area || "",
                        route: c.route || "",
                        amount: c.pending_amount || c.amount || 0,
                        status: (c.status === "collected" ? "collected" : c.status === "skipped" ? "skipped" : "pending") as "pending" | "collected" | "skipped",
                        lat: c.latitude,
                        lng: c.longitude,
                        address: c.address || "",
                        phone: c.phone || "",
                      }))}
                    agentLocation={agentLocation}
                    nextCustomerId={customerList.find(c => c.status === "pending" && c.latitude && c.longitude)?.id}
                    onMarkCollected={async (id) => {
                      const email = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
                      const cust = customerList.find(c => c.id === id);
                      try {
                        await api.recordCollection({
                          customerId: id.toString(),
                          agentEmail: email,
                          status: "collected",
                          collectedAmount: cust?.pending_amount || cust?.amount || 0,
                          depositTotal: cust?.pending_amount || cust?.amount || 0,
                          paymentMode: "CASH",
                          remarks: "Marked via Map",
                        });
                      } catch (_) {}
                      setCustomerList(prev => prev.map(c => c.id === id ? { ...c, status: "collected" } : c));
                    }}
                    onMarkSkipped={(id) => {
                      setCustomerList(prev => prev.map(c => c.id === id ? { ...c, status: "skipped" } : c));
                    }}
                  />
                )}
              </div>
            )}

            {/* ── LIST VIEW ── */}
            {viewMode === "list" && (
              <>
            {/* Search */}
            <div className={`${styles.searchRow} fade-in-up fade-in-up-1`}>
              <div className={styles.searchBox}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="16" height="16" style={{ flexShrink: 0 }}>
                  <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <input className={styles.searchInput} placeholder="Search by name or email…" value={search} onChange={(e) => setSearch(e.target.value)} />
              </div>
            </div>

            {/* Area filter pills */}
            <div className={`pill-tabs fade-in-up fade-in-up-1`}>
              {uniqueAreas.map((a) => (
                <button key={a} className={`pill-tab ${activeArea === a ? "active" : ""}`} onClick={() => setActiveArea(a)}>{a}</button>
              ))}
            </div>

            {/* Grouped list */}
            {Object.entries(grouped).map(([area, list]) => (
              <div key={area} className="fade-in-up fade-in-up-2">
                {/* Area header */}
                <button className={styles.areaHeader} onClick={() => toggleCollapse(area)}>
                  <div className={styles.areaLeft}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="14" height="14"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    <span className={styles.areaName}>{area}</span>
                    <span className={styles.areaBadge}>{(list as any[]).length}</span>
                  </div>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="14" height="14">
                    <polyline points={collapsed.has(area) ? "6 9 12 15 18 9" : "18 15 12 9 6 15"} />
                  </svg>
                </button>

                {/* Customer cards */}
                {!collapsed.has(area) && (list as any[]).map((c: any) => (
                  <div key={c.id} className={styles.customerCard} onClick={() => router.push(`/customer/${c.id}`)}>
                    <div className={styles.customerAvatar} style={{ background: c.status === "collected" ? "linear-gradient(135deg,#22c55e,#16a34a)" : c.status === "pending" ? "var(--gradient-blue)" : "linear-gradient(135deg,#7c3aed,#8b5cf6)" }}>
                      {c.name.charAt(0)}
                    </div>
                    <div className={styles.customerInfo}>
                      <div className={styles.customerNameRow}>
                        <span className={styles.customerName}>{c.name}</span>
                        {c.isNew && <span className={styles.newBadge}>NEW</span>}
                      </div>
                      <span className={styles.customerEmail}>{c.email}</span>
                      <div className={styles.customerMeta}>
                        <span className={styles.routeTag}>{c.route}</span>
                        <span className={styles.balanceTag}>Bal: ₹{c.balance.toLocaleString()}</span>
                      </div>
                    </div>
                    <div className={styles.customerRight}>
                      <div style={{ display: "flex", alignItems: "center", justifyContent: "flex-end", gap: 6 }}>
                        <p className={styles.dueAmount}>₹{c.amount}</p>
                        <a
                          href={`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent((c.address || c.area || "Hubli") + " " + c.name)}&travelmode=driving`}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={(e) => e.stopPropagation()}
                          style={{
                            background: "#eff6ff",
                            color: "#2563eb",
                            border: "1px solid #bfdbfe",
                            borderRadius: 6,
                            padding: "3px 8px",
                            fontSize: 11,
                            fontWeight: 800,
                            textDecoration: "none",
                            display: "inline-flex",
                            alignItems: "center",
                            gap: 3
                          }}
                          title="Open Google Maps Driving Directions"
                        >
                          🧭 Navigate
                        </a>
                        <button
                          type="button"
                          title="Delete Customer"
                          onClick={(e) => handleDeleteCustomer(c.id, c.name, e)}
                          style={{ background: "transparent", border: "none", color: "#ef4444", fontSize: 14, cursor: "pointer", padding: "2px 4px" }}
                        >
                          🗑️
                        </button>
                      </div>
                      <span className={`${styles.statusPill} ${
                        c.status === "collected"
                          ? styles.statusCollected
                          : c.status === "pending"
                          ? styles.statusPending
                          : styles.statusOther
                      }`}>
                        {c.status === "collected"
                          ? "✓ Done"
                          : c.status === "pending"
                          ? "⏳ Due"
                          : c.status === "house_locked"
                          ? "🔒 Locked"
                          : c.status === "not_available"
                          ? "🚫 Absent"
                          : c.status === "payment_tomorrow"
                          ? "📅 Tomorrow"
                          : "🚚 Shifted"}
                      </span>
                      <p className={styles.lastPaid}>Last: {c.lastPaid}</p>
                    </div>
                  </div>
                ))}
              </div>
            ))}

            {filtered.length === 0 && (
              <div className={styles.emptyState} style={{ padding: "32px 16px", textAlign: "center" }}>
                <p style={{ fontSize: 40, margin: "0 0 8px 0" }}>👤</p>
                <p className={styles.emptyText} style={{ fontWeight: 700, color: "#0f172a", marginBottom: 4 }}>No Customers Found</p>
                <p style={{ fontSize: 12, color: "#64748b", marginBottom: 16 }}>Click below to register your first real customer!</p>
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(true)}
                  style={{
                    background: "linear-gradient(135deg, #2563eb, #1d4ed8)",
                    color: "#ffffff",
                    border: "none",
                    borderRadius: 12,
                    padding: "10px 18px",
                    fontSize: 13,
                    fontWeight: 700,
                    cursor: "pointer"
                  }}
                >
                  ➕ Add Customer Live
                </button>
              </div>
            )}

            <div style={{ height: 16 }} />
            </>
            )}
          </div>
          <BottomNav active="collection" />
        </div>
      </div>

      <AddCustomerModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onSuccess={loadCollections}
      />
    </div>
  );
}
