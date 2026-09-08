import type { Metadata } from "next";
import { Outfit } from "next/font/google";
import "./globals.css";

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800"],
});

export const metadata: Metadata = {
  title: "BankFlow — Modern Banking",
  description:
    "Manage your money, track transactions, exchange currencies and view analytics in one beautiful banking app.",
  keywords: ["banking", "finance", "money", "transactions", "analytics"],
};

import { NotificationProvider } from "@/context/NotificationContext";
import NotificationBar from "@/components/NotificationBar";
import NotificationDrawer from "@/components/NotificationDrawer";
import ConfirmModal from "@/components/ConfirmModal";

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${outfit.variable}`} suppressHydrationWarning>
        <NotificationProvider>
          {children}
          <NotificationBar />
          <NotificationDrawer />
          <ConfirmModal />
        </NotificationProvider>
      </body>
    </html>
  );
}
