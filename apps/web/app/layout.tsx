import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/providers";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Synqo",
  description: "Tasks. Synced. Shared.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-[#0D0D0E] text-white overflow-x-hidden min-h-screen`}>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
