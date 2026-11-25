# SIM Rasa Lokal UNNES

Prototipe Sistem Informasi Manajemen untuk pencatatan penjualan, persediaan, pembelian, pengeluaran, supplier, dan laporan sederhana.

## Kebutuhan
- Node.js versi LTS (disarankan Node.js 20 atau lebih baru)
- npm

## Menjalankan project

```bash
npm install
npm run dev
```

Buka http://localhost:3000.

## Fitur prototipe
- Dashboard ringkasan penjualan, transaksi, pengeluaran, dan stok minimum.
- Pencatatan transaksi penjualan dengan status pembayaran.
- Pengelolaan data menu.
- Pengelolaan bahan baku dan penyesuaian stok simulasi.
- Pencatatan pembelian yang menambah stok bahan baku.
- Pencatatan pengeluaran operasional.
- Pengelolaan supplier.
- Laporan ringkas dan ekspor data penjualan ke CSV.
- Data demo disimpan pada localStorage browser.

## Catatan akademik dan batasan
Ini adalah prototipe frontend untuk demonstrasi. Data tersimpan di browser yang digunakan (localStorage), belum menggunakan server/database bersama, belum ada autentikasi/otorisasi nyata, dan transaksi penjualan belum mengurangi bahan baku otomatis karena resep/BOM tiap menu belum didefinisikan dan diverifikasi dengan organisasi. Angka dan nama data awal adalah data contoh, bukan catatan transaksi asli Rasa Lokal.
