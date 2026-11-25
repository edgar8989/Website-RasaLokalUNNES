import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'Rasa Lokal | Sistem Informasi Manajemen', description: 'Sistem informasi penjualan, persediaan, dan keuangan Rasa Lokal UNNES.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="id"><body>{children}</body></html>; }
