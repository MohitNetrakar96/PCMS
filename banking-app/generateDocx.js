const { Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell, BorderStyle, WidthType, AlignmentType } = require("docx");
const fs = require("fs");

// Helper to create heading
const createHeading = (text, level) => {
  return new Paragraph({
    text: text,
    heading: level,
    spacing: { before: 240, after: 120 },
    keepWithNext: true,
  });
};

// Helper for body paragraph
const createParagraph = (text, bold = false) => {
  return new Paragraph({
    children: [
      new TextRun({
        text: text,
        font: "Arial",
        size: 22,
        bold: bold,
      }),
    ],
    spacing: { before: 100, after: 100, line: 360 },
  });
};

// Helper for list item
const createListItem = (text, boldPrefix = "") => {
  return new Paragraph({
    children: [
      boldPrefix ? new TextRun({ text: boldPrefix + " ", bold: true, font: "Arial", size: 22 }) : null,
      new TextRun({ text: text, font: "Arial", size: 22 }),
    ].filter(Boolean),
    bullet: { level: 0 },
    spacing: { before: 60, after: 60 },
  });
};

const doc = new Document({
  sections: [
    {
      properties: {},
      children: [
        // Title
        new Paragraph({
          children: [
            new TextRun({
              text: "BANKFLOW PCMS",
              bold: true,
              font: "Arial",
              size: 40,
              color: "1e3a8a",
            }),
          ],
          alignment: AlignmentType.CENTER,
          spacing: { before: 200, after: 100 },
        }),
        new Paragraph({
          children: [
            new TextRun({
              text: "Pigmy / Payment Collection Management System",
              italics: true,
              font: "Arial",
              size: 26,
              color: "475569",
            }),
          ],
          alignment: AlignmentType.CENTER,
          spacing: { after: 400 },
        }),

        new Paragraph({
          text: "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
          alignment: AlignmentType.CENTER,
        }),

        createHeading("1. Project Executive Summary", HeadingLevel.HEADING_1),
        createParagraph(
          "BankFlow PCMS (Pigmy Collection Management System) is an enterprise-grade, mobile-responsive financial software solution designed to streamline the door-to-door micro-savings and deposit collection operations of cooperative banks, microfinance institutions, and collection agencies."
        ),
        createParagraph(
          "In many developing economies, cooperative societies use field agents who physically visit merchants, street vendors, and households to collect small daily deposit amounts (traditionally known as Pigmy Deposits). Traditionally, this process is paper-heavy, prone to reconciliation discrepancies, and highly vulnerable to manual logging errors. BankFlow PCMS automates this complete workflow from authorization to daily vault closure, logging real-time transaction updates directly on the agent's phone."
        ),

        createHeading("2. Dynamic Role-Based System Architecture", HeadingLevel.HEADING_1),
        createParagraph(
          "The system automatically adapts its metrics, transactions, and available options based on the authenticated user role. The five primary system roles are:"
        ),
        createListItem("Has full master dashboard visibility, manages system-wide branch configurations, logs security parameters, and reviews all active accounts and employee permissions.", "• Administrator:"),
        createListItem("Manages agent deployment schedules, tracks area collection stats, approves cash difference reports, verifies bank deposit slip entries, and supervises agent routes.", "• Branch Manager:"),
        createListItem("Acts as the branch cashier in charge of verifying agent cash handovers. Cashiers audit expected cash totals, sign the handover ledger, and deposit matched cash directly into the bank accounts.", "• Cashier:"),
        createListItem("The field agent carrying out collections. Collection agents use optimized daily schedules, view routes on live maps, update KYC details with customer photos, input deposits, check duplicate records, and issue multilingual thermal receipts.", "• Collection Agent:"),
        createListItem("An independent supervisor who audits transaction sequences, reviews discrepancy logs, verifies cashier acceptance stamps, and signs off on the daily closing audit trail.", "• Auditor:"),

        createHeading("3. Core Technology Stack", HeadingLevel.HEADING_1),
        createParagraph(
          "BankFlow PCMS is built utilizing modern web technologies that prioritize performance, responsiveness, and offline compatibility:"
        ),
        createListItem("Next.js 15 (React 19 Framework, utilizing App Router routing patterns).", "✔ Core Framework:"),
        createListItem("TypeScript (for static type safety and contract verification across models).", "✔ Logic & Types:"),
        createListItem("Vanilla CSS Modules (for fluid styling, interactive animations, and responsive phone layout wrapping).", "✔ UI Styling:"),
        createListItem("HTML5 LocalStorage API (for stateful client-side data storage, simulating real-time backend updates and enabling offline visit log stashing).", "✔ Storage Engine:"),
        createListItem("HTML5 Canvas API (used for rendering high-precision line performance graphs and dynamic signature capture pads).", "✔ Data Visuals:"),
        createListItem("Google Fonts (Outfit Typeface) and SVGs for interface icons and route maps.", "✔ Typography & Assets:"),

        createHeading("4. End-to-End Modules Implemented", HeadingLevel.HEADING_1),

        createHeading("Module 1 — Secure Auth & Registry", HeadingLevel.HEADING_2),
        createParagraph(
          "Allows secure login via Email/Password or Email/OTP. Features a role selector on registration that locks an email address to a single role. During login, the email database is checked, and users are automatically directed to their correct workspace. Prevents unauthorized role access."
        ),

        createHeading("Module 2 — Collapsible Collection List", HeadingLevel.HEADING_2),
        createParagraph(
          "Displays list of customers grouped by geographical areas (e.g. Sector 12, Gandhi Nagar, Lake View). Includes real-time status pills (⏳ Due, ✓ Done, 🔒 Locked, 🚫 Absent) and a sync button simulating local data update intervals."
        ),

        createHeading("Module 3 — Profile, GPS & Digital Signatures", HeadingLevel.HEADING_2),
        createParagraph(
          "The customer visit card lets agents update profile metrics, trigger GPS coordinates lock, capture KYC photos using device cameras, and collect digital signatures directly on the touchscreen."
        ),

        createHeading("Module 4 — Payment Collection & QR", HeadingLevel.HEADING_2),
        createParagraph(
          "Supports multiple deposit entries, regular savings, loan EMIs, UPI QR generation, interest calculators, and a duplicate entry check preventing duplicate collection mistakes."
        ),

        createHeading("Module 5 — Multilingual Receipts", HeadingLevel.HEADING_2),
        createParagraph(
          "Generates printable thermal receipts. Supports immediate language switching between English, Kannada (ಕನ್ನಡ), and Hindi (हिंदी). Simulates Bluetooth thermal printing and WhatsApp/SMS delivery."
        ),

        createHeading("Module 6 — Route Optimization Queue", HeadingLevel.HEADING_2),
        createParagraph(
          "Sorts customer queues based on optimized route paths (A -> B -> C -> D). Renders progress indicators, estimated arrival durations, and skipped/revisit buffers."
        ),

        createHeading("Module 7 — Daily Summaries", HeadingLevel.HEADING_2),
        createParagraph(
          "Visualizes metrics (Visited, Collected, Pending, Failed) via concentric progress charts. Renders cumulative hourly performance line graphs on a canvas and calculates cash vs digital payments."
        ),

        createHeading("Module 8 — 8-Step Cash Handover", HeadingLevel.HEADING_2),
        createParagraph(
          "An 8-step wizard completing EOD settlement: (1) Cash entry, (2) Verification against expected totals, (3) Manager OTP approval, (4) Cashier vault confirmation, (5) Bank reference deposit logs, (6) Handover digital signature, (7) Transaction lock warning, and (8) Audit trail seal."
        ),

        createHeading("5. Project Setup & Local Launch", HeadingLevel.HEADING_1),
        createParagraph(
          "To run the Next.js BankFlow PCMS application locally, run these commands in the project folder:"
        ),
        createListItem("npm install", "1. Install Dependencies:"),
        createListItem("npm run dev", "2. Launch Dev Server:"),
        createListItem("Open http://localhost:3000 in your computer's browser, or http://192.168.31.102:3000 on your mobile phone browser (same Wi-Fi).", "3. Access URL:"),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync("c:/Users/mohit/OneDrive/Desktop/PCMS/Project_Documentation.docx", buffer);
  console.log("Word document generated successfully at C:\\Users\\mohit\\OneDrive\\Desktop\\PCMS\\Project_Documentation.docx");
});
