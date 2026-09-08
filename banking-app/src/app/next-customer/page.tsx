"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import CustomerMap from "@/components/CustomerMap";
import styles from "./page.module.css";

const ROUTE_ORDER = ["Route A", "Route B", "Route C", "Route D"];

export default function NextCustomerPage() {
  const router = useRouter();
  const { notifySuccess, confirmDialog } = useNotification();
  const [customers, setCustomers] = useState<any[]>([]);
  const [skipped, setSkipped] = useState<Set<number>>(new Set());
  const [revisit, setRevisit] = useState<Set<number>>(new Set());
  const [showMap, setShowMap] = useState(false);
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 60000);
    
    const loadRoute = async () => {
      const email = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
      const routeData = await api.getOptimizedRoute(email);
      if (routeData && (routeData.optimizedQueue?.length || routeData.completedQueue?.length)) {
        const combined = [
          ...(routeData.optimizedQueue || []).map((c: any) => ({
            id: c.id,
            name: c.name,
            area: c.area,
            route: c.route,
            amount: c.pending_amount || 500,
            status: "pending",
            lat: c.latitude || 28.60,
            lng: c.longitude || 77.20,
            email: c.email || ""
          })),
          ...(routeData.completedQueue || []).map((c: any) => ({
            id: c.id,
            name: c.name,
            area: c.area,
            route: c.route,
            amount: c.collected_amount || 500,
            status: "collected",
            lat: c.latitude || 28.60,
            lng: c.longitude || 77.20,
            email: c.email || ""
          }))
        ];
        setCustomers(combined);
      }
    };

    loadRoute();

    return () => clearInterval(timer);
  }, []);

  const collected = customers.filter(c => c.status === "collected").length;
  const total = customers.length;
  const remaining = customers.filter(c => c.status === "pending" && !skipped.has(c.id));
  const skippedList = customers.filter(c => skipped.has(c.id));
  const revisitList = customers.filter(c => revisit.has(c.id));

  // Route-optimized pending list
  const optimizedPending = [...remaining].sort((a, b) => {
    return ROUTE_ORDER.indexOf(a.route) - ROUTE_ORDER.indexOf(b.route);
  });

  const nextCustomer = optimizedPending[0];
  const progressPct = Math.round((collected / total) * 100);

  // Estimate: 10 min per customer + travel time
  const minutesLeft = remaining.length * 12;
  const eta = new Date(currentTime.getTime() + minutesLeft * 60000);
  const etaStr = eta.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" });

  const skipCustomer = (id: number) => {
    setSkipped(prev => new Set([...prev, id]));
  };

  const markRevisit = (id: number) => {
    setRevisit(prev => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const collectCustomer = (id: number) => {
    router.push(`/customer/${id}`);
  };

  const handleDeleteStop = async (id: number | string, name: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const ok = await confirmDialog({
      title: `Remove Stop for ${name}?`,
      message: "Are you sure you want to permanently delete this route stop from the queue?",
      confirmText: "Remove Stop",
      type: "danger"
    });
    if (!ok) return;

    await api.deleteCollection(id);
    setCustomers(prev => prev.filter(c => c.id !== id));
    notifySuccess("Stop Removed", `Route stop for ${name} removed.`);
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
              <div>
                <h1 className={styles.title}>Next Customer</h1>
                <p className={styles.subtitle}>Route Optimized Schedule</p>
              </div>
              <button
                className={`${styles.mapToggle} ${styles.mapToggleActive}`}
                onClick={() => router.push("/route-map")}
              >
                🗺️ Full Map
              </button>
            </div>

            {/* Progress Bar Section */}
            <div className={`${styles.progressCard} fade-in-up`}>
              <div className={styles.progressStats}>
                <div className={styles.statItem}>
                  <p className={styles.statNum} style={{ color: "#16a34a" }}>{collected}</p>
                  <p className={styles.statLabel}>Completed</p>
                </div>
                <div className={styles.statItem}>
                  <p className={styles.statNum} style={{ color: "#f97316" }}>{remaining.length}</p>
                  <p className={styles.statLabel}>Remaining</p>
                </div>
                <div className={styles.statItem}>
                  <p className={styles.statNum} style={{ color: "#8b5cf6" }}>{skippedList.length}</p>
                  <p className={styles.statLabel}>Skipped</p>
                </div>
                <div className={styles.statItem}>
                  <p className={styles.statNum} style={{ color: "#2563eb" }}>{total}</p>
                  <p className={styles.statLabel}>Total</p>
                </div>
              </div>
              <div className={styles.progressBarBg}>
                <div className={styles.progressBarFill} style={{ width: `${progressPct}%` }} />
              </div>
              <div className={styles.progressFooter}>
                <span className={styles.progressPct}>{progressPct}% complete</span>
                <span className={styles.etaText}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="12" height="12"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  ETA {etaStr} (~{minutesLeft} min)
                </span>
              </div>
            </div>

            {/* Map View */}
            {showMap && nextCustomer && (
              <div className="fade-in-up" style={{ margin: "4px 0" }}>
                <CustomerMap
                  customerName={nextCustomer.name}
                  area={nextCustomer.area}
                  latitude={nextCustomer.lat}
                  longitude={nextCustomer.lng}
                  showNavigationButton={true}
                />
              </div>
            )}

            {/* Next Customer Card */}
            {nextCustomer ? (
              <div className={`${styles.nextCard} fade-in-up`}>
                <div className={styles.nextBadge}>⭐ NEXT — Route Optimized</div>
                <div className={styles.nextContent}>
                  <div className={styles.nextAvatar}>{nextCustomer.name.charAt(0)}</div>
                  <div className={styles.nextInfo}>
                    <p className={styles.nextName}>{nextCustomer.name}</p>
                    <p className={styles.nextEmail}>{nextCustomer.email}</p>
                    <div className={styles.nextMeta}>
                      <span className={styles.routeChip}>{nextCustomer.route}</span>
                      <span className={styles.areaChip}>{nextCustomer.area}</span>
                    </div>
                  </div>
                  <div className={styles.nextAmount}>
                    <p className={styles.dueAmt}>₹{nextCustomer.amount}</p>
                    <p className={styles.dueLabel}>Due</p>
                  </div>
                </div>
                <div className={styles.nextActions}>
                  <button className={styles.collectBtn} onClick={() => collectCustomer(nextCustomer.id)}>
                    💰 Visit & Collect
                  </button>
                  <button className={styles.skipBtn} onClick={() => skipCustomer(nextCustomer.id)}>
                    ⏭ Skip
                  </button>
                  <button
                    className={`${styles.revisitBtn} ${revisit.has(nextCustomer.id) ? styles.revisitActive : ""}`}
                    onClick={() => markRevisit(nextCustomer.id)}
                  >
                    🔄 {revisit.has(nextCustomer.id) ? "Revisit ✓" : "Revisit"}
                  </button>
                </div>
              </div>
            ) : (
              <div className={styles.allDoneCard}>
                <div className={styles.allDoneIcon}>🎉</div>
                <p className={styles.allDoneTitle}>All collections done!</p>
                <p className={styles.allDoneSub}>Great work! You have completed today&apos;s route.</p>
              </div>
            )}

            {/* Remaining List */}
            {optimizedPending.length > 1 && (
              <div className={`fade-in-up fade-in-up-1`}>
                <p className={styles.sectionTitle}>📍 Remaining Customers ({optimizedPending.length - 1})</p>
                {optimizedPending.slice(1).map((c) => (
                  <div key={c.id} className={styles.remainingCard}>
                    <div className={styles.remainingAvatar}>{c.name.charAt(0)}</div>
                    <div className={styles.remainingInfo}>
                      <p className={styles.remainingName}>{c.name}</p>
                      <div style={{ display: "flex", gap: 6, marginTop: 3 }}>
                        <span className={styles.routeChip}>{c.route}</span>
                        <span className={styles.areaChip}>{c.area}</span>
                      </div>
                    </div>
                    <div className={styles.remainingRight}>
                      <p className={styles.remainingAmt}>₹{c.amount}</p>
                      <div style={{ display: "flex", gap: 4, marginTop: 4 }}>
                        <button className={styles.tinySkipBtn} onClick={() => skipCustomer(c.id)}>Skip</button>
                        <button
                          className={`${styles.tinyRevisitBtn} ${revisit.has(c.id) ? styles.tinyRevisitActive : ""}`}
                          onClick={() => markRevisit(c.id)}
                        >🔄</button>
                        <button
                          type="button"
                          title="Delete Stop"
                          onClick={(e) => handleDeleteStop(c.id, c.name, e)}
                          style={{ background: "#fee2e2", border: "none", color: "#dc2626", borderRadius: 4, padding: "2px 5px", fontSize: 11, cursor: "pointer" }}
                        >🗑️</button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Pending Reminders */}
            {revisitList.length > 0 && (
              <div className={`${styles.reminderSection} fade-in-up fade-in-up-2`}>
                <p className={styles.sectionTitle}>⏰ Pending Revisit Reminders ({revisitList.length})</p>
                {revisitList.map(c => (
                  <div key={c.id} className={styles.reminderCard}>
                    <span className={styles.reminderDot} />
                    <span className={styles.reminderName}>{c.name}</span>
                    <span className={styles.reminderAmt}>₹{c.amount}</span>
                    <button className={styles.goBtn} onClick={() => collectCustomer(c.id)}>Go →</button>
                  </div>
                ))}
              </div>
            )}

            {/* Skipped Customers */}
            {skippedList.length > 0 && (
              <div className={`${styles.skippedSection} fade-in-up fade-in-up-2`}>
                <p className={styles.sectionTitle}>⏭ Skipped ({skippedList.length})</p>
                {skippedList.map(c => (
                  <div key={c.id} className={styles.skippedCard}>
                    <span className={styles.skippedName}>{c.name}</span>
                    <button className={styles.undoBtn} onClick={() => setSkipped(prev => { const n = new Set(prev); n.delete(c.id); return n; })}>Undo</button>
                  </div>
                ))}
              </div>
            )}

            <div style={{ height: 16 }} />
          </div>
          <BottomNav active="collection" />
        </div>
      </div>
    </div>
  );
}
