"use client";
import React, { useEffect, useState } from "react";
import styles from "./CustomerMap.module.css";

interface CustomerMapProps {
  customerName: string;
  address?: string;
  area?: string;
  latitude?: number;
  longitude?: number;
  phone?: string;
  height?: number | string;
  showNavigationButton?: boolean;
}

// Coordinates map for fallback areas if lat/lng are 0 or null
const AREA_COORDINATES: Record<string, { lat: number; lng: number }> = {
  "Sector 12": { lat: 12.9800, lng: 77.5500 },
  "Gandhi Nagar": { lat: 13.0030, lng: 77.5690 },
  "Lake View Colony": { lat: 12.9300, lng: 77.5800 },
  "Old Town": { lat: 12.9650, lng: 77.5920 },
};

export default function CustomerMap({
  customerName,
  address,
  area = "Sector 12",
  latitude,
  longitude,
  height = 220,
  showNavigationButton = true,
}: CustomerMapProps) {
  const [agentCoords, setAgentCoords] = useState<{ lat: number; lng: number } | null>(null);
  const [distanceKm, setDistanceKm] = useState<number | null>(null);

  // Determine target coordinates
  const fallback = AREA_COORDINATES[area] || AREA_COORDINATES["Sector 12"];
  const targetLat = latitude && latitude !== 0 ? latitude : fallback.lat;
  const targetLng = longitude && longitude !== 0 ? longitude : fallback.lng;

  // Compute Haversine Distance in KM
  const calcDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
    const R = 6371; // Radius of Earth in KM
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return Math.round(R * c * 10) / 10;
  };

  useEffect(() => {
    if (typeof window !== "undefined" && "geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const aLat = pos.coords.latitude;
          const aLng = pos.coords.longitude;
          setAgentCoords({ lat: aLat, lng: aLng });
          const dist = calcDistance(aLat, aLng, targetLat, targetLng);
          setDistanceKm(dist);
        },
        () => {
          // If GPS disabled, default distance from central hub
          setDistanceKm(1.5);
        },
        { enableHighAccuracy: true, timeout: 5000 }
      );
    }
  }, [targetLat, targetLng]);

  // OpenStreetMap embed URL
  const bboxPadding = 0.008;
  const osmEmbedUrl = `https://www.openstreetmap.org/export/embed.html?bbox=${targetLng - bboxPadding},${targetLat - bboxPadding},${targetLng + bboxPadding},${targetLat + bboxPadding}&layer=mapnik&marker=${targetLat},${targetLng}`;

  // Google Maps Driving Directions Deep Link
  const fullDestination = encodeURIComponent(address || `${customerName}, ${area}, ${targetLat},${targetLng}`);
  const googleMapsUrl = `https://www.google.com/maps/dir/?api=1&destination=${fullDestination}&travelmode=driving`;

  const estimatedMins = distanceKm ? Math.max(2, Math.round(distanceKm * 4)) : 5;

  return (
    <div className={styles.mapWrapper}>
      {/* Header */}
      <div className={styles.mapHeader}>
        <div className={styles.titleGroup}>
          <span style={{ fontSize: 16 }}>🗺️</span>
          <div>
            <h4 className={styles.title}>Customer Location &amp; Route Map</h4>
            <p className={styles.subtitle}>
              {area} · {targetLat.toFixed(4)}, {targetLng.toFixed(4)}
            </p>
          </div>
        </div>
        {distanceKm !== null && (
          <span className={styles.distanceChip}>
            📍 {distanceKm} km away (~{estimatedMins} mins)
          </span>
        )}
      </div>

      {/* Interactive OpenStreetMap Container */}
      <div className={styles.mapContainer} style={{ height: typeof height === "number" ? `${height}px` : height }}>
        <iframe
          title={`Map location for ${customerName}`}
          src={osmEmbedUrl}
          className={styles.mapIframe}
          loading="lazy"
        />

        {/* Floating Target Overlay Card */}
        <div className={styles.overlayCard}>
          <div className={styles.targetInfo}>
            <div className={styles.targetPin}>📍</div>
            <div>
              <p className={styles.targetName}>{customerName}</p>
              <p className={styles.targetAddr}>
                {address || `${area}, Main Route Stop`}
              </p>
            </div>
          </div>

          {showNavigationButton && (
            <a
              href={googleMapsUrl}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.navBtn}
            >
              <span>🧭 Navigate</span>
            </a>
          )}
        </div>
      </div>
    </div>
  );
}
