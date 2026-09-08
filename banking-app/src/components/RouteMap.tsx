"use client";

import { useEffect, useRef, useState } from "react";
import styles from "./RouteMap.module.css";

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
}

interface RouteMapProps {
  customers: Customer[];
  agentLocation?: { lat: number; lng: number } | null;
  nextCustomerId?: string | number | null;
  onNavigate?: (customer: Customer) => void;
  onMarkCollected?: (customerId: string | number) => void;
  onMarkSkipped?: (customerId: string | number) => void;
}

// Haversine distance in KM
function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 10) / 10;
}

// Nearest-neighbor route ordering
function orderByNearestNeighbor(customers: Customer[], agentLat: number, agentLng: number): Customer[] {
  const pending = customers.filter(c => c.status === "pending");
  const done = customers.filter(c => c.status !== "pending");
  const unvisited = [...pending];
  const ordered: Customer[] = [];
  let curLat = agentLat;
  let curLng = agentLng;

  while (unvisited.length > 0) {
    let nearestIdx = 0;
    let minDist = Infinity;
    for (let i = 0; i < unvisited.length; i++) {
      const d = haversineKm(curLat, curLng, unvisited[i].lat, unvisited[i].lng);
      if (d < minDist) { minDist = d; nearestIdx = i; }
    }
    const [next] = unvisited.splice(nearestIdx, 1);
    ordered.push(next);
    curLat = next.lat;
    curLng = next.lng;
  }

  return [...ordered, ...done];
}

// Open Google Maps turn-by-turn navigation
function openNavigation(lat: number, lng: number, label: string) {
  const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
  if (isMobile) {
    // Try Google Maps app deep link first, fallback to web
    window.open(`https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}&travelmode=driving`, "_blank");
  } else {
    window.open(`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(label + " " + lat + "," + lng)}&travelmode=driving`, "_blank");
  }
}

const PIN_COLORS = {
  pending: "#ef4444",
  collected: "#22c55e",
  skipped: "#94a3b8",
  next: "#2563eb",
  agent: "#7c3aed",
};

export default function RouteMap({
  customers,
  agentLocation,
  nextCustomerId,
  onNavigate,
  onMarkCollected,
  onMarkSkipped,
}: RouteMapProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const leafletMapRef = useRef<any>(null);
  const markersRef = useRef<any[]>([]);
  const polylineRef = useRef<any>(null);
  const agentMarkerRef = useRef<any>(null);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [agentCoords, setAgentCoords] = useState<{ lat: number; lng: number } | null>(agentLocation || null);
  const [orderedRoute, setOrderedRoute] = useState<Customer[]>([]);
  const [mapLoaded, setMapLoaded] = useState(false);

  // Get agent GPS if not provided
  useEffect(() => {
    if (agentLocation) { setAgentCoords(agentLocation); return; }
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => setAgentCoords({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        () => {
          // Fallback: use centroid of all customer locations
          const validCustomers = customers.filter(c => c.lat && c.lng);
          if (validCustomers.length > 0) {
            const avgLat = validCustomers.reduce((s, c) => s + c.lat, 0) / validCustomers.length;
            const avgLng = validCustomers.reduce((s, c) => s + c.lng, 0) / validCustomers.length;
            setAgentCoords({ lat: avgLat, lng: avgLng });
          }
        },
        { enableHighAccuracy: true, timeout: 8000 }
      );
    }
  }, [agentLocation, customers]);

  // Compute nearest-neighbor route when agent or customers change
  useEffect(() => {
    if (!agentCoords || customers.length === 0) return;
    const valid = customers.filter(c => c.lat && c.lng);
    const ordered = orderByNearestNeighbor(valid, agentCoords.lat, agentCoords.lng);
    setOrderedRoute(ordered);
  }, [agentCoords, customers]);

  // Initialize Leaflet map
  useEffect(() => {
    if (!mapRef.current || leafletMapRef.current) return;

    const initMap = async () => {
      const L = (await import("leaflet")).default;
      // Leaflet CSS is added via next.config or globals.css
      // We inject it dynamically to avoid SSR issues
      if (!document.querySelector('link[href*="leaflet"]')) {
        const link = document.createElement("link");
        link.rel = "stylesheet";
        link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
        document.head.appendChild(link);
      }

      const centerLat = agentCoords?.lat || customers[0]?.lat || 12.97;
      const centerLng = agentCoords?.lng || customers[0]?.lng || 77.59;

      const map = L.map(mapRef.current!, {
        center: [centerLat, centerLng],
        zoom: 14,
        zoomControl: true,
      });

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        maxZoom: 19,
      }).addTo(map);

      leafletMapRef.current = map;
      setMapLoaded(true);
    };

    initMap();

    return () => {
      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }
    };
  }, []);

  // Draw markers and route polyline whenever map is loaded or data changes
  useEffect(() => {
    if (!mapLoaded || !leafletMapRef.current) return;

    const L: any = (window as any).L || require("leaflet");
    const map = leafletMapRef.current;

    // Clear existing markers
    markersRef.current.forEach(m => m.remove());
    markersRef.current = [];
    if (polylineRef.current) { polylineRef.current.remove(); polylineRef.current = null; }
    if (agentMarkerRef.current) { agentMarkerRef.current.remove(); agentMarkerRef.current = null; }

    const createSvgIcon = (color: string, label: string, isNext: boolean) => {
      const size = isNext ? 36 : 28;
      const svg = `
        <svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size + 8}" viewBox="0 0 36 44">
          ${isNext ? `<circle cx="18" cy="18" r="17" fill="${color}22" stroke="${color}" stroke-width="2" stroke-dasharray="4 2"/>` : ""}
          <circle cx="18" cy="18" r="${isNext ? 13 : 11}" fill="${color}" stroke="#fff" stroke-width="2.5"/>
          <polygon points="14,28 18,38 22,28" fill="${color}"/>
          <text x="18" y="23" text-anchor="middle" fill="white" font-size="${isNext ? 11 : 9}" font-weight="bold" font-family="Arial">${label}</text>
        </svg>`;
      return {
        html: svg,
        className: "custom-leaflet-icon",
        iconSize: [size, size + 8],
        iconAnchor: [size / 2, size + 8],
        popupAnchor: [0, -(size + 8)],
      };
    };

    const validCustomers = customers.filter(c => c.lat && c.lng);
    const routeLatLngs: [number, number][] = [];

    if (agentCoords) {
      routeLatLngs.push([agentCoords.lat, agentCoords.lng]);
    }

    const pendingList = validCustomers.filter(c => c.status === "pending");
    const nextId = pendingList[0]?.id;
    const nextNextId = pendingList[1]?.id;

    // Draw markers for each customer
    validCustomers.forEach((customer) => {
      const isNext = customer.id === nextId;
      const isNextNext = customer.id === nextNextId;
      const color =
        customer.status === "collected" ? PIN_COLORS.collected :
        customer.status === "skipped" ? PIN_COLORS.skipped :
        isNext ? PIN_COLORS.next :
        isNextNext ? "#f97316" : PIN_COLORS.pending;

      const shortLabel = customer.name.substring(0, 2).toUpperCase();
      const divIcon = L.divIcon(createSvgIcon(color, shortLabel, isNext));

      const marker = L.marker([customer.lat, customer.lng], { icon: divIcon })
        .addTo(map)
        .bindPopup(
          `<div style="min-width:160px;padding:4px;">
            <strong style="font-size:13px">${customer.name}</strong><br/>
            <span style="font-size:11px;color:#64748b">${customer.area} · ${customer.route}</span><br/>
            <span style="font-size:12px;font-weight:bold;color:#16a34a">₹${customer.amount} due</span><br/>
            <span style="font-size:10px;background:${color}22;color:${color};padding:2px 8px;border-radius:100px;font-weight:bold">${customer.status.toUpperCase()}</span>
            ${customer.status === "pending" ? `
              <div style="margin-top:8px;display:flex;gap:6px;">
                <a href="https://www.google.com/maps/dir/?api=1&destination=${customer.lat},${customer.lng}&travelmode=driving"
                   target="_blank"
                   style="flex:1;text-align:center;background:#2563eb;color:#fff;padding:5px;border-radius:6px;font-size:11px;font-weight:bold;text-decoration:none">
                  🧭 Navigate
                </a>
              </div>` : ""}
          </div>`,
          { maxWidth: 220 }
        )
        .on("click", () => setSelectedCustomer(customer));

      markersRef.current.push(marker);

      if (customer.status === "pending") {
        routeLatLngs.push([customer.lat, customer.lng]);
      }
    });

    // Draw agent position marker
    if (agentCoords) {
      const agentSvg = `
        <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
          <circle cx="18" cy="18" r="16" fill="#7c3aed" stroke="#fff" stroke-width="3"/>
          <circle cx="18" cy="18" r="6" fill="#fff"/>
          <circle cx="18" cy="18" r="24" fill="none" stroke="#7c3aed" stroke-width="1.5" opacity="0.3"/>
        </svg>`;
      const agentIcon = L.divIcon({
        html: agentSvg,
        className: "agent-location-icon",
        iconSize: [36, 36],
        iconAnchor: [18, 18],
        popupAnchor: [0, -18],
      });
      agentMarkerRef.current = L.marker([agentCoords.lat, agentCoords.lng], { icon: agentIcon })
        .addTo(map)
        .bindPopup(`<strong>📍 Your Location</strong><br/><span style="font-size:11px;color:#7c3aed">Collection Agent</span>`);
    }

    // Draw dashed route polyline
    if (routeLatLngs.length > 1) {
      polylineRef.current = L.polyline(routeLatLngs, {
        color: "#2563eb",
        weight: 3,
        opacity: 0.7,
        dashArray: "8, 6",
      }).addTo(map);
    }

    // Auto-fit bounds to show everything
    const allPoints: [number, number][] = [];
    if (agentCoords) allPoints.push([agentCoords.lat, agentCoords.lng]);
    validCustomers.forEach(c => allPoints.push([c.lat, c.lng]));
    if (allPoints.length > 1) {
      map.fitBounds(L.latLngBounds(allPoints), { padding: [30, 30] });
    }
  }, [mapLoaded, customers, agentCoords, nextCustomerId]);

  const pendingStops = orderedRoute.filter(c => c.status === "pending");
  const nextStop = pendingStops[0] || null;
  const nextNextStop = pendingStops[1] || null;
  const pendingCount = customers.filter(c => c.status === "pending").length;
  const collectedCount = customers.filter(c => c.status === "collected").length;

  return (
    <div className={styles.mapWrapper}>
      {/* Stats Bar */}
      <div className={styles.statsBar}>
        <div className={styles.stat}>
          <span className={styles.statVal} style={{ color: "#2563eb" }}>{customers.length}</span>
          <span className={styles.statLabel}>Total</span>
        </div>
        <div className={styles.stat}>
          <span className={styles.statVal} style={{ color: "#ef4444" }}>{pendingCount}</span>
          <span className={styles.statLabel}>Pending</span>
        </div>
        <div className={styles.stat}>
          <span className={styles.statVal} style={{ color: "#22c55e" }}>{collectedCount}</span>
          <span className={styles.statLabel}>Collected</span>
        </div>
        <div className={styles.stat}>
          <span className={styles.statVal} style={{ color: "#94a3b8" }}>{customers.filter(c => c.status === "skipped").length}</span>
          <span className={styles.statLabel}>Skipped</span>
        </div>
      </div>

      {/* Map Canvas */}
      <div ref={mapRef} className={styles.leafletMap} />

      {/* Legend */}
      <div className={styles.legend}>
        <div className={styles.legendItem}><span className={styles.legendDot} style={{ background: "#2563eb" }} />Next</div>
        <div className={styles.legendItem}><span className={styles.legendDot} style={{ background: "#f97316" }} />Next Next</div>
        <div className={styles.legendItem}><span className={styles.legendDot} style={{ background: "#ef4444" }} />Pending</div>
        <div className={styles.legendItem}><span className={styles.legendDot} style={{ background: "#22c55e" }} />Collected</div>
        <div className={styles.legendItem}><span className={styles.legendDot} style={{ background: "#7c3aed" }} />You</div>
      </div>

      {/* Next Stop Floating Panel */}
      {nextStop && (
        <div className={styles.floatingPanel}>
          <div className={styles.panelHeader}>
            <span className={styles.nextBadge}>⭐ NEXT CUSTOMER (#1)</span>
            {agentCoords && nextStop.lat && nextStop.lng && (
              <span className={styles.distLabel}>
                📍 {haversineKm(agentCoords.lat, agentCoords.lng, nextStop.lat, nextStop.lng)} km away
              </span>
            )}
          </div>
          <p className={styles.panelName}>{nextStop.name}</p>
          <p className={styles.panelArea}>{nextStop.area} · {nextStop.route} · ₹{nextStop.amount} due</p>
          <div className={styles.panelActions}>
            <a
              href={`https://www.google.com/maps/dir/?api=1&destination=${nextStop.lat},${nextStop.lng}&travelmode=driving`}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.btnNav}
            >
              🧭 Navigate
            </a>
            {onMarkCollected && (
              <button className={styles.btnCollect} onClick={() => onMarkCollected(nextStop.id)}>
                ✓ Collected
              </button>
            )}
            {onMarkSkipped && (
              <button className={styles.btnSkip} onClick={() => onMarkSkipped(nextStop.id)}>
                ⏭ Skip
              </button>
            )}
          </div>
        </div>
      )}

      {/* Next Next Stop Preview Banner */}
      {nextNextStop && (
        <div style={{
          background: "#fff7ed",
          borderTop: "1px solid #ffedd5",
          padding: "10px 16px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between"
        }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
              <span style={{
                background: "#f97316", color: "#fff", fontSize: 9, fontWeight: 900,
                padding: "2px 6px", borderRadius: 10, textTransform: "uppercase"
              }}>
                📍 NEXT NEXT CUSTOMER (#2)
              </span>
              {agentCoords && nextNextStop.lat && nextNextStop.lng && (
                <span style={{ fontSize: 11, color: "#c2410c", fontWeight: 700 }}>
                  {haversineKm(agentCoords.lat, agentCoords.lng, nextNextStop.lat, nextNextStop.lng)} km
                </span>
              )}
            </div>
            <p style={{ margin: "3px 0 0", fontSize: 13, fontWeight: 800, color: "#9a3412" }}>
              {nextNextStop.name} <span style={{ fontWeight: 500, fontSize: 11, color: "#ea580c" }}>({nextNextStop.area})</span>
            </p>
          </div>
          <button
            onClick={() => {
              setSelectedCustomer(nextNextStop);
              if (leafletMapRef.current && nextNextStop.lat && nextNextStop.lng) {
                leafletMapRef.current.setView([nextNextStop.lat, nextNextStop.lng], 16);
              }
            }}
            style={{
              background: "#ffedd5", color: "#c2410c", border: "1px solid #fed7aa",
              borderRadius: 8, padding: "6px 10px", fontSize: 11, fontWeight: 800, cursor: "pointer"
            }}
          >
            🎯 Focus Pin
          </button>
        </div>
      )}

      {/* Ordered Route Queue */}
      {orderedRoute.length > 0 && (
        <div className={styles.routeList}>
          <p className={styles.routeListTitle}>📋 Optimized Route Order</p>
          {orderedRoute.map((c, idx) => (
            <div
              key={c.id}
              className={`${styles.routeItem} ${c.status !== "pending" ? styles.routeItemDone : ""}`}
              onClick={() => {
                setSelectedCustomer(c);
                if (leafletMapRef.current && c.lat && c.lng) {
                  leafletMapRef.current.setView([c.lat, c.lng], 16);
                }
              }}
            >
              <span className={styles.routeIndex}>#{idx + 1}</span>
              <div className={styles.routeInfo}>
                <span className={styles.routeName}>{c.name}</span>
                <span className={styles.routeArea}>{c.area}</span>
              </div>
              <div className={styles.routeRight}>
                <span className={styles.routeAmt}>₹{c.amount}</span>
                <span className={styles.routeStatus} style={{
                  color: c.status === "collected" ? "#22c55e" : c.status === "skipped" ? "#94a3b8" : "#ef4444"
                }}>
                  {c.status === "collected" ? "✓" : c.status === "skipped" ? "⏭" : "●"}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
