"use client";
import { useRouter } from "next/navigation";

const navItems = [
  {
    id: "home", label: "Home", path: "/dashboard",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill={active ? "var(--color-primary)" : "none"} stroke={active ? "var(--color-primary)" : "var(--color-text-secondary-light)"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" /><polyline points="9 22 9 12 15 12 15 22" />
      </svg>
    ),
  },
  {
    id: "collection", label: "Collections", path: "/collection",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill="none" stroke={active ? "var(--color-primary)" : "var(--color-text-secondary-light)"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/>
      </svg>
    ),
  },
  {
    id: "analytics", label: "Analytics", path: "/analytics",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill="none" stroke={active ? "var(--color-primary)" : "var(--color-text-secondary-light)"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" />
      </svg>
    ),
  },
  {
    id: "map", label: "Map", path: "/route-map",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill="none" stroke={active ? "var(--color-primary)" : "var(--color-text-secondary-light)"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
        <circle cx="12" cy="10" r="3"/>
      </svg>
    ),
  },
  {
    id: "cards", label: "Ledgers", path: "/cards",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill="none" stroke={active ? "var(--color-primary)" : "var(--color-text-secondary-light)"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
      </svg>
    ),
  },
  {
    id: "settings", label: "Profile", path: "/settings",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill={active ? "var(--color-primary)" : "none"} stroke={active ? "var(--color-primary)" : "var(--color-text-secondary-light)"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" /><circle cx="12" cy="7" r="4" />
      </svg>
    ),
  },
];

interface BottomNavProps {
  active: string;
  dark?: boolean;
}

export default function BottomNav({ active, dark = false }: BottomNavProps) {
  const router = useRouter();

  return (
    <nav className={`bottom-nav ${dark ? "dark" : ""}`}>
      {navItems.map((item) => {
        const isActive = item.id === active;
        return (
          <button
            key={item.id}
            className={`nav-item ${isActive ? "active" : ""} ${dark ? "dark" : ""}`}
            onClick={() => router.push(item.path)}
            aria-label={item.label}
          >
            {item.icon(isActive)}
            <span>{item.label}</span>
          </button>
        );
      })}
    </nav>
  );
}
