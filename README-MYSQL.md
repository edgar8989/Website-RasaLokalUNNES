# Rasa Lokal — integrasi dengan database ERD Eric

Proyek Next.js ini memakai database lokal MariaDB/XAMPP bernama `umkm_ayam_geprek`.

## Langkah setup (cukup satu kali)

1. Pastikan MySQL di XAMPP aktif.
2. Buka phpMyAdmin dan pilih database `umkm_ayam_geprek`.
3. Klik **Import**, pilih file `database/migration-eric.sql` dari folder proyek, lalu jalankan.
   - Migrasi ini menambahkan kolom pendukung dan dua tabel tambahan (`pembelian`, `pengeluaran`).
   - Migrasi tidak menghapus tabel atau data ERD Eric.
4. Pastikan `.env.local` di folder utama berisi konfigurasi berikut. Jika MySQL root memakai password, isi `DB_PASSWORD`.

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=umkm_ayam_geprek
```

## Menjalankan aplikasi

Di terminal VS Code, dari folder yang memiliki `package.json`:

```bash
npm install
npm run dev
```

Buka `http://localhost:3000`.

## Pemetaan database

- Data Menu -> `produk`, `kategori`
- Persediaan -> `bahan_baku`, `resep`
- Supplier -> `pemasok`
- Penjualan -> `pesanan`, `detail_pesanan`
- Pembayaran -> `pembayaran`
- Pembelian -> `pembelian` (tabel tambahan untuk modul prototype)
- Pengeluaran -> `pengeluaran` (tabel tambahan untuk modul prototype)

## Catatan

- Entitas inti ERD Eric tetap digunakan.
- `bahan_baku.stok_minimum`, `pesanan.ringkasan`, dan `pesanan.total_tagihan` adalah kolom tambahan untuk kebutuhan tampilan aplikasi.
- API sinkronisasi prototype ditujukan untuk demo satu operator. Sebelum menggunakannya dengan data operasional penting, buat backup database.
- API pembayaran mencatat pembayaran di tabel `pembayaran` dan menolak pembayaran kedua.
- Pengujian koneksi akhir tetap perlu dilakukan pada XAMPP di komputer pengguna.
