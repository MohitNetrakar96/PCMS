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
              text: "BANKFLOW PCMS OPERATIONAL ROLES",
              bold: true,
              font: "Arial",
              size: 36,
              color: "1e3a8a",
            }),
          ],
          alignment: AlignmentType.CENTER,
          spacing: { before: 200, after: 80 },
        }),
        new Paragraph({
          children: [
            new TextRun({
              text: "Detailed Guide on User Roles, Actions, and Financial Handover Workflows",
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

        createHeading("1. Overview of PCMS Financial Operations", HeadingLevel.HEADING_1),
        createParagraph(
          "The daily micro-savings or Pigmy collection model is built on physical trust, swift digital entry, and strict financial reconciliation controls. In cooperative banking institutions, field agents collect cash daily from depositors. This cash must be logged instantly, printed, and safely integrated into the bank's main ledger."
        ),
        createParagraph(
          "BankFlow PCMS divides these responsibilities among five key operational roles. By separating collection, approval, cash handling, and auditing, the platform guarantees accountability, eliminates cash discrepancies, and seals transaction audit records."
        ),

        createHeading("2. Collection Agent Role (Field Operations)", HeadingLevel.HEADING_1),
        createParagraph(
          "The Collection Agent is the primary user operating in the field. Their tasks cover the complete client visit cycle:"
        ),
        createListItem("Checks the Collections schedule, sorts depositors by area collapse tabs, and uses the Next Route optimizer to view ETA paths and map directions.", "• Routing & Schedule:"),
        createListItem("Visits clients, logs GPS coordinates, updates client photos for KYC verification, and captures the client's signature on a touchscreen canvas.", "• KYC Visit Logging:"),
        createListItem("Logs deposits (Regular Savings, Recurring Deposits, Loan EMIs). The system checks for duplicate types, calculates late fees automatically, and can render UPI QR codes for digital transfers.", "• Transaction Entry:"),
        createListItem("Issues thermal receipts instantly in English, Kannada, or Hindi. The app simulates Bluetooth printing and lets agents share receipts via SMS or WhatsApp.", "• Thermal Receipts:"),
        createListItem("At the end of the shift, the agent reviews cumulative collections on line graphs, keys in the cash totals, requests manager OTP clearance, and hands cash to the Cashier.", "• EOD Vault Submission:"),

        createHeading("3. Branch Manager Role (Operations Approval)", HeadingLevel.HEADING_1),
        createParagraph(
          "The Branch Manager supervises field agents, manages daily schedules, and authorizes reconciliation differences:"
        ),
        createListItem("Checks dashboard active counters, verifies agent routes on lists, and monitors target collection metrics.", "• Route Monitoring:"),
        createListItem("If an agent logs a cash mismatch (e.g. short or extra cash), the manager reviews the variance report, verifies the reason, and enters an approval OTP to unlock the stepper.", "• Difference Approval:"),
        createListItem("Provides the supervisor OTP authentication code to verify cashier acceptance processes.", "• OTP Handover Clearance:"),
        createListItem("Reviews transaction logs and checks matched bank slips before bank submissions are logged.", "• Deposit Verification:"),

        createHeading("4. Cashier Role (Vault & Cash Management)", HeadingLevel.HEADING_1),
        createParagraph(
          "The Cashier is responsible for vault cash management and verifying handovers at the branch counter:"
        ),
        createListItem("Counts the physical cash handed over by the collection agent and verifies it matches the logged totals.", "• Cash Verification:"),
        createListItem("Checks the confirmation box in the handover wizard to officially log vault acceptance.", "• Cash Acceptance:"),
        createListItem("Saves the digital signature in the handover register to bind the cashier's identity to the transaction.", "• Signature Log:"),
        createListItem("Records bank reference deposit numbers and slip IDs when vault cash is deposited into the main bank accounts.", "• Bank Deposit:"),

        createHeading("5. Auditor Role (Compliance & Verification)", HeadingLevel.HEADING_1),
        createParagraph(
          "The Auditor acts as an independent compliance checkpoint, ensuring financial records are accurate:"
        ),
        createListItem("Monitors security logs, checks failed password entries, and reviews user role registrations.", "• Audit Trail Inspection:"),
        createListItem("Checks cash difference logs and OTP approvals to ensure no cashier discrepancies are bypassed.", "• Discrepancy Audits:"),
        createListItem("Verifies bank reference deposit slips against the cashier's vault counts, signing off to close and lock the daily ledger.", "• Final Sign-Off:"),

        createHeading("6. Administrator Role (System Config & Security)", HeadingLevel.HEADING_1),
        createParagraph(
          "The Administrator manages system settings, branch details, and user permissions:"
        ),
        createListItem("Registers new users, creates email accounts, and assigns specific roles to enforce security restrictions.", "• User Management:"),
        createListItem("Updates branch configurations, set bank deposit details, and configures target schedules.", "• Branch Config:"),
        createListItem("Monitors system security metrics and ensures the application runs smoothly without error.", "• Performance Tracking:"),

        createHeading("7. End-to-End Collection Lifecycle Workflow", HeadingLevel.HEADING_1),
        createParagraph(
          "Here is how a ₹500 pigmy collection flows from a merchant's hand to the bank vault:"
        ),
        createListItem("The agent uses Route Optimization to visit the merchant's shop, lock the GPS coordinates, and capture their profile photo.", "Step 1: Agent Visit"),
        createListItem("The agent enters a ₹500 Savings deposit. The merchant signs the canvas, scans the UPI QR code (or pays cash), and receives a Kannada thermal receipt.", "Step 2: Transaction Entry"),
        createListItem("At EOD, the agent enters ₹500 in the Submit Cash stepper, showing ₹500 cash in hand and updating the performance line graph.", "Step 3: Cash Submission"),
        createListItem("The cashier counts the ₹500 cash, checks the acceptance box, and logs a digital signature in the handover register.", "Step 4: Cashier Acceptance"),
        createListItem("The manager reviews the handover details and enters the OTP code to authorize the vault deposit.", "Step 5: Manager Clearance"),
        createListItem("The cashier deposits the collected cash into the branch bank account, entering reference slip number DEP-20260817-001.", "Step 6: Bank Deposit"),
        createListItem("The auditor reviews the transaction logs, matches the bank slip, and seals the audit trail to lock today's ledger.", "Step 7: Auditor Sign-Off"),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync("c:/Users/mohit/OneDrive/Desktop/PCMS/PCMS_Roles_and_Operations.docx", buffer);
  console.log("Roles and operations Word document generated successfully at C:\\Users\\mohit\\OneDrive\\Desktop\\PCMS\\PCMS_Roles_and_Operations.docx");
});
