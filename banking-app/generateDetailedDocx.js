const { Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell, BorderStyle, WidthType, AlignmentType } = require("docx");
const fs = require("fs");

const createHeading = (text, level) => {
  return new Paragraph({
    text: text,
    heading: level,
    spacing: { before: 240, after: 120 },
    keepWithNext: true,
  });
};

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
              size: 38,
              color: "1e3a8a",
            }),
          ],
          alignment: AlignmentType.CENTER,
          spacing: { before: 200, after: 80 },
        }),
        new Paragraph({
          children: [
            new TextRun({
              text: "Project Specification & Component Architecture Documentation",
              italics: true,
              font: "Arial",
              size: 24,
              color: "475569",
            }),
          ],
          alignment: AlignmentType.CENTER,
          spacing: { after: 300 },
        }),

        new Paragraph({
          text: "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
          alignment: AlignmentType.CENTER,
        }),

        createHeading("1. Project Specification & Overview", HeadingLevel.HEADING_1),
        createParagraph(
          "BankFlow PCMS (Payment Collection Management System) is an enterprise-grade mobile application platform designed for micro-banking and Pigmy deposit agents, managers, cashiers, auditors, and administrators. The application acts as a real-time field ledger, tracking savings deposits and loan EMIs collected at customer doors, and automating EOD (End of Day) cash submissions to the branch vault."
        ),
        createParagraph(
          "The system is built on a Next.js 15 app router framework. It utilizes local storage state serialization to support offline collections, dynamically rendering custom user interfaces, performance analytics charts, geographical SVG navigation routes, and printed thermal receipts based on the logged-in employee role."
        ),

        createHeading("2. Folder & File Structure", HeadingLevel.HEADING_1),
        createParagraph("The repository folder structure maps to standard Next.js layouts:"),
        createListItem("Contains all global styles, layouts, page modules, routing hooks, and screen components.", "• src/app/"),
        createListItem("Reusable shared React elements including the custom bottom navigation menu (BottomNav) and page headers (Header).", "• src/components/"),
        createListItem("Holds CSS classes, themes, animations, layout borders, and card gradients.", "• src/app/globals.css"),

        createHeading("3. Reusable Shared Components", HeadingLevel.HEADING_1),
        
        createHeading("BottomNav Component (src/components/BottomNav.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Renders the persistent menu at the bottom of the viewport frame. Supports five core navigation tabs tailored to collection agents:"
        ),
        createListItem("Points to /dashboard (Role-based metrics overview).", "1. Home:"),
        createListItem("Points to /collection (Geographical area-grouped depositor tables).", "2. Collections:"),
        createListItem("Points to /cards (Active savings/loan passbook ledger carousel).", "3. Ledgers:"),
        createListItem("Points to /analytics (Dynamic rupee collection graphs and transaction feeds).", "4. Analytics:"),
        createListItem("Points to /settings (Logged-in agent profile variables).", "5. Profile:"),

        createHeading("Header Component (src/components/Header.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Renders the top banner of the application pages. Displays a greeting, the currently logged-in user's name from session storage, and an avatar card dynamically reflecting the user's role."
        ),

        createHeading("4. Pages & Component Details", HeadingLevel.HEADING_1),

        createHeading("Splash Screen (src/app/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "The welcome portal showing logo animations, application tagline details, secure feature highlights, and a 'Get Started' button forwarding directly to the credentials authorization screen."
        ),

        createHeading("Auth Screen (src/app/auth/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Provides a dynamic multi-state form for: login (Password vs OTP modes), registration (Role specification locked per email), and forgot-password reset flows. It renders a beautiful in-app Alert Modal overlay with blur effects when validation triggers (incorrect password, mismatch inputs, email exists)."
        ),

        createHeading("Dashboard (src/app/dashboard/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "The dashboard reads user roles from session storage and renders role-specific grids. Features quick-action routes, transaction tables, and a double concentric ring chart drawn on an HTML5 canvas detailing collected target progress versus remaining due amounts."
        ),

        createHeading("Collections List (src/app/collection/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Groups customer collection schedules by area. Features search inputs, area collapse controllers, sync buttons, and status indicator tags (⏳ Due, ✓ Done, 🔒 Locked, 🚫 Absent) updated instantly."
        ),

        createHeading("Customer Visit & Signature (src/app/customer/[id]/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Captures KYC visits. Integrates photo uploads, GPS coordinates lock, comments, and an interactive HTML5 signature pad canvas with drag-draw listeners for touchscreens."
        ),

        createHeading("Cash Collection (src/app/collect/[id]/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Enters deposits. Supports dynamic row arrays, late fee day multipliers, UPI QR codes, and a confirmation checker preventing duplicate payments."
        ),

        createHeading("Multilingual Receipts (src/app/receipt/[id]/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Generates thermal receipts. Supports instant toggles between English, Kannada (ಕನ್ನಡ), and Hindi (हिंदी). Animates Bluetooth printer connections."
        ),

        createHeading("Next Route Optimizer (src/app/next-customer/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Arranges customer visits by geographic path optimization. Visualizes queue metrics, Skipped / Revisit lists, ETA calculations, and active SVGs mapping coordinate paths."
        ),

        createHeading("Daily Performance Summary (src/app/daily-summary/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Provides EOD analysis. Draws a cumulative hourly collection graph on a canvas and graphs cash vs. digital payments."
        ),

        createHeading("Submit Cash Stepper (src/app/submit-cash/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "An 8-step wizard completing daily vault closure: (1) Cash entry, (2) Verification against expected totals, (3) Manager OTP approval, (4) Cashier confirmation check, (5) Bank reference slip deposit entry, (6) Digital signature confirming handover, (7) Day closing transaction locking, and (8) Sealed audit log registers."
        ),

        createHeading("Ledger Passbook Carousel (src/app/cards/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "A swipeable account passbook catalog. Loads Savings Passbooks and Loan EMIs. Displays balance amounts in Rupees, account numbers, and dynamic scrollable lists of transaction histories."
        ),

        createHeading("Settings Screen (src/app/settings/page.tsx)", HeadingLevel.HEADING_2),
        createParagraph(
          "Manages agent profile settings, updates regional preferences, and triggers session logouts."
        ),

        createHeading("5. State Sync & Offline LocalStorage Design", HeadingLevel.HEADING_1),
        createParagraph(
          "All transactions, user logins, and status updates are managed dynamically using localStorage keys. This architecture simulates offline operational readiness. The primary localStorage keys utilized are:"
        ),
        createListItem("Stores a collection agent's daily log sequence (customer, amount, timestamp, status).", "• pcms_collections_today:"),
        createListItem("Stores registered usernames, roles, and password configurations.", "• pcms_users:"),
        createListItem("Tracks active employee name, role, and email.", "• pcms_session_name / role / email:"),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync("c:/Users/mohit/OneDrive/Desktop/PCMS/Project_Details_and_Components.docx", buffer);
  console.log("Detailed Word document generated successfully at C:\\Users\\mohit\\OneDrive\\Desktop\\PCMS\\Project_Details_and_Components.docx");
});
