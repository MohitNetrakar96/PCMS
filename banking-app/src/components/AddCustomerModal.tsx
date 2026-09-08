"use client";
import React, { useState } from "react";
import { api } from "@/services/api";
import { useNotification } from "@/context/NotificationContext";
import styles from "./AddCustomerModal.module.css";

interface AddCustomerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export default function AddCustomerModal({ isOpen, onClose, onSuccess }: AddCustomerModalProps) {
  const { notifySuccess, notifyError } = useNotification();
  const [loading, setLoading] = useState(false);

  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [aadharNumber, setAadharNumber] = useState("");
  const [panNumber, setPanNumber] = useState("");
  const [email, setEmail] = useState("");
  const [address, setAddress] = useState("");
  const [openingBalance, setOpeningBalance] = useState("5000");

  if (!isOpen) return null;

  // Strict Phone handler: Digits only (max 10)
  const handlePhoneChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const digits = e.target.value.replace(/\D/g, "").slice(0, 10);
    setPhone(digits);
  };

  // Strict Aadhaar handler: Government format - Digits only (max 12)
  const handleAadharChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const digits = e.target.value.replace(/\D/g, "").slice(0, 12);
    setAadharNumber(digits);
  };

  // Strict PAN handler: Alphanumeric ALL CAPS (max 10)
  const handlePanChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const upperAlphaNum = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 10);
    setPanNumber(upperAlphaNum);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !phone.trim()) {
      notifyError("Validation Error", "Full Name and Phone Number are required.");
      return;
    }

    // Proceed to create customer in live database

    setLoading(true);
    try {
      const agentEmail = localStorage.getItem("pcms_session_email") || "agent@bankflow.com";
      const res = await api.createCustomer({
        name: name.trim(),
        phone: phone.trim(),
        area: "Sector 12",
        route: "Route A",
        email: email.trim(),
        address: address.trim(),
        opening_balance: parseFloat(openingBalance) || 0,
        daily_target: 500,
        aadhar_number: aadharNumber.trim() || undefined,
        pan_number: panNumber.trim() || undefined,
        agent_email: agentEmail
      });

      if (res.success) {
        notifySuccess("Customer Registered", `${name} added with Account ${res.accountNumber}!`);
        onSuccess();
        onClose();
        // Reset form
        setName("");
        setPhone("");
        setAadharNumber("");
        setPanNumber("");
        setEmail("");
        setAddress("");
        setOpeningBalance("5000");
      } else {
        notifyError("Registration Error", "Could not create customer.");
      }
    } catch (err: any) {
      notifyError("Error", err.message || "Failed to add customer.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <h3 className={styles.title}>
            <span>👤</span> Add New Customer
          </h3>
          <button type="button" className={styles.closeBtn} onClick={onClose}>
            ✕
          </button>
        </div>

        <form className={styles.form} onSubmit={handleSubmit}>
          {/* 1. Full Name */}
          <div className={styles.group}>
            <label className={styles.label}>
              Full Name <span className={styles.required}>*</span>
            </label>
            <input
              type="text"
              className={styles.input}
              placeholder="Full Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>

          {/* 2. Phone Number */}
          <div className={styles.group}>
            <label className={styles.label}>
              Phone Number <span className={styles.required}>*</span>
            </label>
            <input
              type="tel"
              inputMode="numeric"
              maxLength={10}
              className={styles.input}
              placeholder="10-digit Mobile Number"
              value={phone}
              onChange={handlePhoneChange}
              required
            />
          </div>

          {/* 3. Aadhaar Number & 4. PAN Number */}
          <div className={styles.row2}>
            <div className={styles.group}>
              <label className={styles.label}>Aadhaar Number (12 Digits)</label>
              <input
                type="text"
                inputMode="numeric"
                maxLength={12}
                className={styles.input}
                placeholder="12 Numeric Digits"
                value={aadharNumber}
                onChange={handleAadharChange}
              />
            </div>
            <div className={styles.group}>
              <label className={styles.label}>PAN Number (ALL CAPS)</label>
              <input
                type="text"
                maxLength={10}
                className={styles.input}
                placeholder="ABCDE1234F"
                value={panNumber}
                onChange={handlePanChange}
                style={{ textTransform: "uppercase" }}
              />
            </div>
          </div>

          {/* 5. Email Address */}
          <div className={styles.group}>
            <label className={styles.label}>Email Address</label>
            <input
              type="email"
              className={styles.input}
              placeholder="customer@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          {/* 6. Address */}
          <div className={styles.group}>
            <label className={styles.label}>Address</label>
            <input
              type="text"
              className={styles.input}
              placeholder="House/Shop No, Street, Landmark"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
            />
          </div>

          {/* 7. Opening Balance */}
          <div className={styles.group}>
            <label className={styles.label}>Opening Balance (₹)</label>
            <input
              type="number"
              className={styles.input}
              placeholder="5000"
              value={openingBalance}
              onChange={(e) => setOpeningBalance(e.target.value)}
            />
          </div>

          <button type="submit" className={styles.submitBtn} disabled={loading}>
            {loading ? "Registering Customer…" : "✅ Register Customer Live"}
          </button>
        </form>
      </div>
    </div>
  );
}
