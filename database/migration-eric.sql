-- Migrasi tambahan untuk menjalankan prototype Rasa Lokal pada database ERD Eric.
-- Target: database umkm_ayam_geprek (MariaDB 10.4 / XAMPP).
-- Tidak menghapus tabel atau data yang sudah ada.
USE umkm_ayam_geprek;

-- Kolom pendukung tampilan persediaan dan ringkasan transaksi.
ALTER TABLE bahan_baku
  ADD COLUMN IF NOT EXISTS stok_minimum DECIMAL(10,2) NOT NULL DEFAULT 0;

ALTER TABLE pesanan
  ADD COLUMN IF NOT EXISTS ringkasan VARCHAR(500) NULL,
  ADD COLUMN IF NOT EXISTS total_tagihan INT NOT NULL DEFAULT 0;

-- Modul ini merupakan tambahan untuk kebutuhan UI; tidak termasuk entitas inti ERD.
CREATE TABLE IF NOT EXISTS pembelian (
  id_pembelian BIGINT AUTO_INCREMENT PRIMARY KEY,
  tanggal DATE NOT NULL,
  id_pemasok INT NOT NULL,
  id_bahan INT NOT NULL,
  jumlah DECIMAL(10,2) NOT NULL,
  total INT NOT NULL,
  CONSTRAINT fk_pembelian_pemasok FOREIGN KEY (id_pemasok)
    REFERENCES pemasok(id_pemasok) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pembelian_bahan FOREIGN KEY (id_bahan)
    REFERENCES bahan_baku(id_bahan) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pengeluaran (
  id_pengeluaran BIGINT AUTO_INCREMENT PRIMARY KEY,
  tanggal DATE NOT NULL,
  kategori VARCHAR(60) NOT NULL,
  keterangan VARCHAR(255) NOT NULL,
  jumlah INT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
