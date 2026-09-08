"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import { api } from "@/services/api";

export default function DatabaseViewerPage() {
  const router = useRouter();
  const [data, setData] = useState<{ dbPath: string; timestamp: string; tables: Record<string, any[]> } | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTable, setActiveTable] = useState<string>("customers");
  const [search, setSearch] = useState("");
  const [viewMode, setViewMode] = useState<"table" | "json">("table");

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await api.getDatabaseTables();
      if (res && res.tables) {
        setData(res);
      }
    } catch (e) {
      console.error("Failed to load DB tables:", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const tableNames = data?.tables ? Object.keys(data.tables) : [];
  const currentRows = data?.tables?.[activeTable] || [];

  const filteredRows = currentRows.filter((row) => {
    if (!search.trim()) return true;
    const str = JSON.stringify(row).toLowerCase();
    return str.includes(search.toLowerCase());
  });

  const columns = currentRows.length > 0 ? Object.keys(currentRows[0]) : [];

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
          <div className="screen-content" style={{ paddingBottom: 80 }}>
            {/* Header */}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 16px", background: "#fff", borderBottom: "1px solid #e2e8f0" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <button onClick={() => router.back()} style={{ background: "none", border: "none", cursor: "pointer", padding: 4 }}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="#0f172a" strokeWidth="2.5" width="20" height="20">
                    <polyline points="15 18 9 12 15 6"/>
                  </svg>
                </button>
                <div>
                  <h1 style={{ fontSize: 16, fontWeight: 900, color: "#0f172a", margin: 0 }}>🗄️ Database Inspector</h1>
                  <p style={{ fontSize: 11, color: "#64748b", margin: 0 }}>SQLite Live Database (`backend/pcms.db`)</p>
                </div>
              </div>
              <button
                onClick={loadData}
                style={{ marginLeft: "auto", background: "#eff6ff", color: "#2563eb", border: "none", borderRadius: 8, padding: "6px 12px", fontSize: 11, fontWeight: 700, cursor: "pointer" }}
              >
                🔄 Refresh
              </button>
            </div>

            {loading ? (
              <div style={{ padding: 40, textAlign: "center" }}>
                <div style={{ fontSize: 36, marginBottom: 12 }}>⚡</div>
                <p style={{ fontSize: 14, color: "#64748b" }}>Querying SQLite database...</p>
              </div>
            ) : (
              <div style={{ padding: 12 }}>
                {/* Table selector pills */}
                <div style={{ display: "flex", gap: 6, overflowX: "auto", paddingBottom: 8, marginBottom: 10 }}>
                  {tableNames.map((t) => {
                    const count = data?.tables[t]?.length || 0;
                    const isActive = activeTable === t;
                    return (
                      <button
                        key={t}
                        onClick={() => setActiveTable(t)}
                        style={{
                          background: isActive ? "linear-gradient(135deg,#2563eb,#1d4ed8)" : "#f1f5f9",
                          color: isActive ? "#ffffff" : "#475569",
                          border: "none",
                          borderRadius: 20,
                          padding: "6px 14px",
                          fontSize: 11,
                          fontWeight: 700,
                          cursor: "pointer",
                          whiteSpace: "nowrap",
                          display: "flex",
                          alignItems: "center",
                          gap: 6
                        }}
                      >
                        <span>{t}</span>
                        <span style={{
                          background: isActive ? "rgba(255,255,255,0.25)" : "#cbd5e1",
                          color: isActive ? "#fff" : "#0f172a",
                          borderRadius: 10,
                          padding: "1px 6px",
                          fontSize: 10,
                          fontWeight: 900
                        }}>
                          {count}
                        </span>
                      </button>
                    );
                  })}
                </div>

                {/* Toolbar */}
                <div style={{ display: "flex", gap: 8, marginBottom: 12, alignItems: "center" }}>
                  <input
                    type="text"
                    placeholder={`Search in ${activeTable}…`}
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    style={{
                      flex: 1,
                      padding: "8px 12px",
                      borderRadius: 10,
                      border: "1px solid #cbd5e1",
                      fontSize: 12,
                      background: "#fff"
                    }}
                  />
                  <div style={{ display: "flex", background: "#e2e8f0", borderRadius: 8, padding: 2 }}>
                    <button
                      onClick={() => setViewMode("table")}
                      style={{
                        background: viewMode === "table" ? "#fff" : "transparent",
                        color: viewMode === "table" ? "#0f172a" : "#64748b",
                        border: "none", borderRadius: 6, padding: "4px 8px", fontSize: 11, fontWeight: 700, cursor: "pointer"
                      }}
                    >
                      📊 Grid
                    </button>
                    <button
                      onClick={() => setViewMode("json")}
                      style={{
                        background: viewMode === "json" ? "#fff" : "transparent",
                        color: viewMode === "json" ? "#0f172a" : "#64748b",
                        border: "none", borderRadius: 6, padding: "4px 8px", fontSize: 11, fontWeight: 700, cursor: "pointer"
                      }}
                    >
                      {`{ } JSON`}
                    </button>
                  </div>
                </div>

                {/* Data View */}
                {viewMode === "json" ? (
                  <pre style={{
                    background: "#0f172a", color: "#38bdf8", padding: 12, borderRadius: 12,
                    fontSize: 11, overflowX: "auto", maxHeight: 400, fontFamily: "monospace"
                  }}>
                    {JSON.stringify(filteredRows, null, 2)}
                  </pre>
                ) : filteredRows.length === 0 ? (
                  <div style={{ textAlign: "center", padding: "40px 16px", background: "#f8fafc", borderRadius: 12, border: "1px solid #e2e8f0" }}>
                    <div style={{ fontSize: 32, marginBottom: 8 }}>📭</div>
                    <p style={{ fontSize: 13, fontWeight: 700, color: "#0f172a", margin: "0 0 4px" }}>
                      No records found in table `{activeTable}`
                    </p>
                    <p style={{ fontSize: 11, color: "#64748b", margin: 0 }}>
                      {search ? "Try clearing search filter." : "This database table is currently empty."}
                    </p>
                  </div>
                ) : (
                  <div style={{ overflowX: "auto", border: "1px solid #e2e8f0", borderRadius: 12, background: "#fff" }}>
                    <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 11, textWrap: "nowrap" }}>
                      <thead>
                        <tr style={{ background: "#f1f5f9", borderBottom: "1px solid #cbd5e1" }}>
                          {columns.map((col) => (
                            <th key={col} style={{ padding: "8px 10px", textAlign: "left", fontWeight: 800, color: "#475569" }}>
                              {col}
                            </th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {filteredRows.map((row, idx) => (
                          <tr key={idx} style={{ borderBottom: "1px solid #f1f5f9", background: idx % 2 === 0 ? "#ffffff" : "#f8fafc" }}>
                            {columns.map((col) => {
                              const val = row[col];
                              return (
                                <td key={col} style={{ padding: "8px 10px", color: "#1e293b", maxWidth: 180, overflow: "hidden", textOverflow: "ellipsis" }}>
                                  {val === null || val === undefined ? (
                                    <span style={{ color: "#cbd5e1", fontStyle: "italic" }}>null</span>
                                  ) : typeof val === "object" ? (
                                    JSON.stringify(val)
                                  ) : String(val)}
                                </td>
                              );
                            })}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}
          </div>
          <BottomNav active="settings" />
        </div>
      </div>
    </div>
  );
}
