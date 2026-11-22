import type { Metadata } from "next";
import { Literata, Archivo } from "next/font/google";
import "./globals.css";

const literata = Literata({
  subsets: ["latin"],
  variable: "--font-literata",
  display: "swap",
});

const archivo = Archivo({
  subsets: ["latin"],
  variable: "--font-archivo",
  display: "swap",
});

export const metadata: Metadata = {
  title: "SenEdu — Le programme sénégalais, chapitre par chapitre",
  description:
    "Fiches de cours et annales corrigées pour le BFEM, le bac et les concours des grandes écoles.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr" className={`${literata.variable} ${archivo.variable}`}>
      <body>{children}</body>
    </html>
  );
}
