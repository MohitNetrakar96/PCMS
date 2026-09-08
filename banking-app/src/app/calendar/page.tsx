"use client";
import { useState } from "react";
import BottomNav from "@/components/BottomNav";
import Header from "@/components/Header";
import styles from "./page.module.css";

const DAYS = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];
const MONTH_NAMES = ["January","February","March","April","May","June","July","August","September","October","November","December"];

function buildCalendar(year: number, month: number) {
  const first = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells: { day: number; currentMonth: boolean }[] = [];
  const prevDays = new Date(year, month, 0).getDate();
  for (let i = first - 1; i >= 0; i--) cells.push({ day: prevDays - i, currentMonth: false });
  for (let d = 1; d <= daysInMonth; d++) cells.push({ day: d, currentMonth: true });
  while (cells.length < 42) cells.push({ day: cells.length - daysInMonth - first + 1, currentMonth: false });
  return cells;
}

const eventDays = new Set([3, 7, 12, 15, 19, 22, 25, 28]);

const upcoming = [
  { date: "Aug 12", title: "Loan Payment", amount: -500, color: "#fee2e2" },
  { date: "Aug 15", title: "Salary Credit", amount: 5500, color: "#d1fae5" },
  { date: "Aug 19", title: "Insurance Premium", amount: -180, color: "#fef3c7" },
  { date: "Aug 22", title: "Freelance Invoice", amount: 1200, color: "#dbeafe" },
];

export default function CalendarPage() {
  const today = new Date();
  const [year, setYear] = useState(today.getFullYear());
  const [month, setMonth] = useState(today.getMonth());
  const [selectedDay, setSelectedDay] = useState(today.getDate());

  const cells = buildCalendar(year, month);

  const prevMonth = () => { if (month === 0) { setMonth(11); setYear(y => y - 1); } else setMonth(m => m - 1); };
  const nextMonth = () => { if (month === 11) { setMonth(0); setYear(y => y + 1); } else setMonth(m => m + 1); };

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
            <Header name="Alex Johnson" greeting="Payment Calendar" />

            <div className={`${styles.calCard} fade-in-up`}>
              {/* Month nav */}
              <div className={styles.monthNav}>
                <button className={styles.monthBtn} onClick={prevMonth}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="16" height="16"><polyline points="15 18 9 12 15 6"/></svg>
                </button>
                <p className={styles.monthTitle}>{MONTH_NAMES[month]} {year}</p>
                <button className={styles.monthBtn} onClick={nextMonth}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" width="16" height="16"><polyline points="9 18 15 12 9 6"/></svg>
                </button>
              </div>

              {/* Day headers */}
              <div className="calendar-grid">
                {DAYS.map((d) => <div key={d} className="cal-day-header">{d}</div>)}
              </div>

              {/* Day cells */}
              <div className="calendar-grid" style={{ marginTop: 4 }}>
                {cells.map((cell, i) => (
                  <button
                    key={i}
                    className={`cal-day ${!cell.currentMonth ? "other-month" : ""} ${cell.currentMonth && cell.day === today.getDate() && month === today.getMonth() && year === today.getFullYear() ? "today" : ""} ${cell.currentMonth && eventDays.has(cell.day) ? "has-event" : ""} ${cell.currentMonth && cell.day === selectedDay ? styles.selected : ""}`}
                    onClick={() => cell.currentMonth && setSelectedDay(cell.day)}
                    style={{ border: "none", background: "none", fontFamily: "var(--font-outfit)" }}
                  >
                    {cell.day}
                  </button>
                ))}
              </div>
            </div>

            {/* Upcoming payments */}
            <div className="section-header fade-in-up fade-in-up-1">
              <p className="section-title">Upcoming Payments</p>
              <button className="section-link">Add New</button>
            </div>
            <div className="tx-list fade-in-up fade-in-up-1" style={{ paddingBottom: 16 }}>
              {upcoming.map((ev, i) => (
                <div key={i} className="tx-item">
                  <div className={styles.eventDateBadge} style={{ background: ev.color }}>
                    <span className={styles.eventDateDay}>{ev.date.split(" ")[1]}</span>
                    <span className={styles.eventDateMonth}>{ev.date.split(" ")[0]}</span>
                  </div>
                  <div className="tx-info">
                    <p className="tx-name">{ev.title}</p>
                    <p className="tx-date">Scheduled</p>
                  </div>
                  <span className={`tx-amount ${ev.amount > 0 ? "positive" : "negative"}`}>
                    {ev.amount > 0 ? "+" : ""}${Math.abs(ev.amount).toFixed(0)}
                  </span>
                </div>
              ))}
            </div>
          </div>
          <BottomNav active="home" />
        </div>
      </div>
    </div>
  );
}
