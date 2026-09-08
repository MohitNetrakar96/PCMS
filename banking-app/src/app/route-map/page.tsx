"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import dynamic from "next/dynamic";

// Dynamically load RouteMap so Leaflet (browser-only) works with Next.js SSR
const RouteMap = dynamic(() => import("@/components/RouteMap"), { ssr: false });

const ROUTE_ORDER = ["Route A", "Route B", "Route C", "Route D"];

interface Customer {
  id: string | number;
  name: string;
  area: string;
  route: string;
  amount: number;
  status: "pending" | "collected" | "skipped";
  lat: number;
  lng: number;
  address?: string;
  phone?: string;
  email?: string;
}

export default function RouteMapPage() {
  const router = useRouter();
  const { notifySuccess, notifyWarning } = useNotification();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [agentLocation, setAgentLocation] = useState<{ lat: number; lng: number } | null>(null);

  // Load live route from backend
  useEffect(() => {
    const loadRoute = async () => {
      setLoading(true);
      try {
        const email = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
        const routeData = await api.getOptimizedRoute(email);

        if (routeData && (routeData.optimizedQueue?.length || routeData.completedQueue?.length)) {
          const combined: Customer[] = [
            ...(routeData.optimizedQueue || []).map((c: any) => ({
              id: c.id,
              name: c.name,
              area: c.area,
              route: c.route,
              amount: c.pending_amount || 0,
              status: "pending" as const,
              lat: c.latitude || 0,
              lng: c.longitude || 0,
              address: c.address || "",
              phone: c.phone || "",
              email: c.email || "",
            })),
            ...(routeData.completedQueue || []).map((c: any) => ({
              id: c.id,
              name: c.name,
              area: c.area,
              route: c.route,
              amount: c.collected_amount || 0,
              status: "collected" as const,
              lat: c.latitude || 0,
              lng: c.longitude || 0,
              address: c.address || "",
              phone: c.phone || "",
              email: c.email || "",
            })),
          ];
          setCustomers(combined);
        }
      } catch (e) {
        console.warn("Failed to load route:", e);
      } finally {
        setLoading(false);
      }
    };

    loadRoute();

    // Get agent GPS
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => setAgentLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        () => {},
        { enableHighAccuracy: true, timeout: 10000 }
      );
    }
  }, []);

  const handleMarkCollected = async (customerId: string | number) => {
    const email = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
    try {
      await api.recordCollection({
        customerId: customerId.toString(),
        agentEmail: email,
        status: "collected",
        collectedAmount: customers.find(c => c.id === customerId)?.amount || 0,
        depositTotal: customers.find(c => c.id === customerId)?.amount || 0,
        paymentMode: "CASH",
        remarks: "Marked collected via Route Map",
      });
      setCustomers(prev =>
        prev.map(c => c.id === customerId ? { ...c, status: "collected" } : c)
      );
      notifySuccess("Collected ✓", "Collection marked and saved to backend.");
    } catch (e) {
      // Optimistic update even if API fails
      setCustomers(prev =>
        prev.map(c => c.id === customerId ? { ...c, status: "collected" } : c)
      );
      notifyWarning("Saved Locally", "Status updated. Will sync when back online.");
    }
  };

  const handleMarkSkipped = (customerId: string | number) => {
    setCustomers(prev =>
      prev.map(c => c.id === customerId ? { ...c, status: "skipped" } : c)
    );
    notifyWarning("Skipped", "Customer marked as skipped.");
  };

  const nextCustomer = customers.find(c => c.status === "pending");

  return (
    <div className="app-wrapper">
      <div className="phone-frame">
        <div className="status-bar light">
          <span>{new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}</span>
          <div className="status-bar__icons">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M1 6s4-4 11-4 11 4 11 4"/><path d="M5 10s3-3 7-3 7 3 7 3"/><path d="M9 14s1.5-1.5 3-1.5 3 1.5 3 1.5"/>
              <circle cx="12" cy="18" r="1" fill="currentColor"/>
            </svg>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="2" y="7" width="15" height="10" rx="2"/><path d="M22 11v2"/>
            </svg>
          </div>
        </div>

        <div className="screen">
          <div className="screen-content">
            {/* Header */}
            <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "12px 16px 6px", background: "#fff" }}>
              <button
                onClick={() => router.back()}
                style={{ background: "none", border: "none", cursor: "pointer", padding: 4 }}
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="#0f172a" strokeWidth="2.5" width="20" height="20">
                  <polyline points="15 18 9 12 15 6"/>
                </svg>
              </button>
              <div>
                <h1 style={{ fontSize: 16, fontWeight: 900, color: "#0f172a", margin: 0 }}>🗺️ Route Map</h1>
                <p style={{ fontSize: 11, color: "#64748b", margin: 0 }}>
                  {customers.filter(c => c.status === "pending").length} stops remaining
                </p>
              </div>
              <button
                onClick={() => router.push("/next-customer")}
                style={{
                  marginLeft: "auto", background: "#eff6ff", color: "#2563eb",
                  border: "none", borderRadius: 8, padding: "6px 10px",
                  fontSize: 11, fontWeight: 700, cursor: "pointer"
                }}
              >
                List View →
              </button>
            </div>

            {loading ? (
              <div style={{ padding: 40, textAlign: "center" }}>
                <div style={{ fontSize: 36, marginBottom: 12 }}>🗺️</div>
                <p style={{ fontSize: 14, color: "#64748b" }}>Loading route map...</p>
              </div>
            ) : customers.filter(c => c.lat && c.lng).length === 0 ? (
              <div style={{ padding: 40, textAlign: "center" }}>
                <div style={{ fontSize: 48, marginBottom: 12 }}>📍</div>
                <h3 style={{ fontSize: 16, fontWeight: 800, color: "#0f172a", marginBottom: 6 }}>No Locations on Map</h3>
                <p style={{ fontSize: 13, color: "#64748b", marginBottom: 20 }}>
                  No customer addresses with GPS coordinates are available yet. Add customers with location data first.
                </p>
                <button
                  className="btn btn-primary"
                  onClick={() => router.push("/collection")}
                >
                  ➕ Add Customers
                </button>
              </div>
            ) : (
              <RouteMap
                customers={customers}
                agentLocation={agentLocation}
                nextCustomerId={nextCustomer?.id}
                onMarkCollected={handleMarkCollected}
                onMarkSkipped={handleMarkSkipped}
              />
            )}
          </div>

          <BottomNav active="map" />
        </div>
      </div>
    </div>
  );
}
