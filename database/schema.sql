-- =====================================================
-- BASIS DATA UMKM AYAM GEPREK
-- Kompatibel: MySQL 8 / MariaDB 10.4+
-- Isi: struktur tabel, data contoh, view, dan query contoh
-- =====================================================

CREATE DATABASE IF NOT EXISTS rasa_lokal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE rasa_lokal;

-- =====================================================
-- 1. STRUKTUR TABEL
-- =====================================================

CREATE TABLE kategori (
    id_kategori   INT AUTO_INCREMENT PRIMARY KEY,
    nama_kategori VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE produk (
    id_produk   INT AUTO_INCREMENT PRIMARY KEY,
    id_kategori INT NOT NULL,
    nama_produk VARCHAR(100) NOT NULL,
    harga       INT NOT NULL CHECK (harga > 0),
    tersedia    BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (id_kategori) REFERENCES kategori(id_kategori)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE pelanggan (
    id_pelanggan INT AUTO_INCREMENT PRIMARY KEY,
    nama         VARCHAR(100) NOT NULL,
    no_hp        VARCHAR(20),
    alamat       VARCHAR(200)
);

CREATE TABLE pesanan (
    id_pesanan   INT AUTO_INCREMENT PRIMARY KEY,
    id_pelanggan INT NOT NULL,
    tanggal      DATE NOT NULL,
    status       ENUM('baru','diproses','selesai','dibatalkan') NOT NULL DEFAULT 'baru',
    metode_antar ENUM('antar','ambil','makan_ditempat') NOT NULL DEFAULT 'ambil',
    FOREIGN KEY (id_pelanggan) REFERENCES pelanggan(id_pelanggan)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE detail_pesanan (
    id_detail    INT AUTO_INCREMENT PRIMARY KEY,
    id_pesanan   INT NOT NULL,
    id_produk    INT NOT NULL,
    jumlah       INT NOT NULL CHECK (jumlah > 0),
    harga_satuan INT NOT NULL,
    level_pedas  ENUM('tidak_pedas','sedang','pedas','extra_pedas') NULL,
    FOREIGN KEY (id_pesanan) REFERENCES pesanan(id_pesanan)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_produk) REFERENCES produk(id_produk)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE pembayaran (
    id_bayar   INT AUTO_INCREMENT PRIMARY KEY,
    id_pesanan INT NOT NULL UNIQUE,
    total      INT NOT NULL,
    metode     ENUM('tunai','qris','transfer') NOT NULL,
    tgl_bayar  DATE NOT NULL,
    FOREIGN KEY (id_pesanan) REFERENCES pesanan(id_pesanan)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pemasok (
    id_pemasok   INT AUTO_INCREMENT PRIMARY KEY,
    nama_pemasok VARCHAR(100) NOT NULL,
    no_hp        VARCHAR(20)
);

CREATE TABLE bahan_baku (
    id_bahan   INT AUTO_INCREMENT PRIMARY KEY,
    id_pemasok INT NOT NULL,
    nama_bahan VARCHAR(100) NOT NULL,
    satuan     VARCHAR(20) NOT NULL,
    stok       DECIMAL(10,2) NOT NULL DEFAULT 0,
    harga_beli INT NOT NULL,
    stok_minimum DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_pemasok) REFERENCES pemasok(id_pemasok)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE resep (
    id_resep     INT AUTO_INCREMENT PRIMARY KEY,
    id_produk    INT NOT NULL,
    id_bahan     INT NOT NULL,
    jumlah_pakai DECIMAL(10,3) NOT NULL,
    FOREIGN KEY (id_produk) REFERENCES produk(id_produk)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_bahan) REFERENCES bahan_baku(id_bahan)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    UNIQUE (id_produk, id_bahan)
);

-- =====================================================
-- 2. DATA CONTOH
-- =====================================================

INSERT INTO kategori (nama_kategori) VALUES
('Ayam Geprek'),
('Paket Hemat'),
('Pelengkap'),
('Minuman');

INSERT INTO produk (id_kategori, nama_produk, harga, tersedia) VALUES
(1, 'Geprek Original',          15000, TRUE),
(1, 'Geprek Keju Mozzarella',   20000, TRUE),
(1, 'Geprek Sambal Matah',      18000, TRUE),
(1, 'Geprek Telur Dadar',       18000, TRUE),
(2, 'Paket Geprek Hemat',       19000, TRUE),  -- geprek original + nasi + es teh
(2, 'Paket Geprek Keju',        24000, TRUE),  -- geprek keju + nasi + es teh
(3, 'Nasi Putih',                4000, TRUE),
(3, 'Tempe Goreng',              4000, TRUE),
(4, 'Es Teh Manis',              4000, TRUE),
(4, 'Es Jeruk',                  6000, TRUE);

INSERT INTO pelanggan (nama, no_hp, alamat) VALUES
('Siti Rahayu',    '081234567801', 'Jl. Pandanaran No. 12, Semarang'),
('Budi Santoso',   '081234567802', 'Jl. Setiabudi No. 45, Semarang'),
('Dewi Lestari',   '081234567803', 'Perum Graha Asri Blok C3, Semarang'),
('Agus Prasetyo',  '081234567804', 'Jl. Tembalang Raya No. 8, Semarang'),
('Rina Wulandari', '081234567805', 'Jl. Gajah Mada No. 21, Semarang'),
('Joko Widodo',    '081234567806', 'Jl. Kelud Raya No. 5, Semarang');

INSERT INTO pemasok (nama_pemasok, no_hp) VALUES
('UD Sumber Pangan',        '082111000001'),
('CV Ayam Segar',           '082111000002'),
('Toko Bumbu Makmur',       '082111000003'),
('Agen Minuman & Frozen',   '082111000004');

INSERT INTO bahan_baku (id_pemasok, nama_bahan, satuan, stok, harga_beli) VALUES
(2, 'Ayam potong',       'kg',    25.00,  38000),  -- 1
(1, 'Tepung bumbu',      'kg',    15.00,  25000),  -- 2
(3, 'Minyak goreng',     'liter', 30.00,  16000),  -- 3
(3, 'Cabai rawit',       'kg',     6.00,  60000),  -- 4
(3, 'Bawang putih',      'kg',     4.00,  38000),  -- 5
(1, 'Beras',             'kg',    50.00,  13000),  -- 6
(1, 'Telur ayam',        'kg',    10.00,  28000),  -- 7
(4, 'Keju mozzarella',   'kg',     3.00, 110000),  -- 8
(3, 'Serai',             'kg',     2.00,  20000),  -- 9
(1, 'Tempe papan',       'kg',     8.00,  20000),  -- 10
(4, 'Teh celup',         'pak',   10.00,  12000),  -- 11
(1, 'Gula pasir',        'kg',    20.00,  16000),  -- 12
(4, 'Jeruk peras',       'kg',     6.00,  20000);  -- 13

-- Takaran bahan per 1 porsi produk
INSERT INTO resep (id_produk, id_bahan, jumlah_pakai) VALUES
-- 1 Geprek Original
(1, 1, 0.150), (1, 2, 0.050), (1, 3, 0.060), (1, 4, 0.030), (1, 5, 0.010),
-- 2 Geprek Keju Mozzarella
(2, 1, 0.150), (2, 2, 0.050), (2, 3, 0.060), (2, 4, 0.030), (2, 5, 0.010), (2, 8, 0.050),
-- 3 Geprek Sambal Matah
(3, 1, 0.150), (3, 2, 0.050), (3, 3, 0.060), (3, 4, 0.030), (3, 5, 0.010), (3, 9, 0.010),
-- 4 Geprek Telur Dadar
(4, 1, 0.150), (4, 2, 0.050), (4, 3, 0.080), (4, 4, 0.030), (4, 5, 0.010), (4, 7, 0.060),
-- 5 Paket Geprek Hemat
(5, 1, 0.150), (5, 2, 0.050), (5, 3, 0.060), (5, 4, 0.030), (5, 6, 0.150), (5, 11, 0.005), (5, 12, 0.020),
-- 6 Paket Geprek Keju
(6, 1, 0.150), (6, 2, 0.050), (6, 3, 0.060), (6, 4, 0.030), (6, 6, 0.150), (6, 8, 0.050), (6, 11, 0.005), (6, 12, 0.020),
-- 7 Nasi Putih
(7, 6, 0.150),
-- 8 Tempe Goreng
(8, 10, 0.100), (8, 3, 0.040),
-- 9 Es Teh Manis
(9, 11, 0.005), (9, 12, 0.020),
-- 10 Es Jeruk
(10, 13, 0.150), (10, 12, 0.020);

INSERT INTO pesanan (id_pelanggan, tanggal, status, metode_antar) VALUES
(1, '2026-11-20', 'selesai',    'antar'),
(2, '2026-11-20', 'selesai',    'ambil'),
(3, '2026-11-21', 'selesai',    'antar'),
(4, '2026-11-22', 'selesai',    'makan_ditempat'),
(1, '2026-11-23', 'selesai',    'antar'),
(5, '2026-11-24', 'selesai',    'ambil'),
(6, '2026-11-25', 'diproses',   'antar'),
(2, '2026-11-25', 'dibatalkan', 'ambil');

INSERT INTO detail_pesanan (id_pesanan, id_produk, jumlah, harga_satuan, level_pedas) VALUES
-- Pesanan 1 = 46.000
(1, 1,  2, 15000, 'pedas'),
(1, 7,  2,  4000, NULL),
(1, 9,  2,  4000, NULL),
-- Pesanan 2 = 25.000
(2, 5,  1, 19000, 'sedang'),
(2, 10, 1,  6000, NULL),
-- Pesanan 3 = 56.000
(3, 2,  2, 20000, 'sedang'),
(3, 7,  2,  4000, NULL),
(3, 9,  2,  4000, NULL),
-- Pesanan 4 = 56.000
(4, 3,  1, 18000, 'extra_pedas'),
(4, 4,  1, 18000, 'pedas'),
(4, 8,  2,  4000, NULL),
(4, 10, 2,  6000, NULL),
-- Pesanan 5 = 76.000
(5, 6,  2, 24000, 'pedas'),
(5, 6,  1, 24000, 'sedang'),
(5, 8,  1,  4000, NULL),
-- Pesanan 6 = 88.000
(6, 5,  4, 19000, 'sedang'),
(6, 10, 2,  6000, NULL),
-- Pesanan 7 = 51.000 (belum dibayar)
(7, 1,  1, 15000, 'extra_pedas'),
(7, 2,  1, 20000, 'sedang'),
(7, 7,  2,  4000, NULL),
(7, 9,  2,  4000, NULL),
-- Pesanan 8 = 18.000 (dibatalkan)
(8, 4,  1, 18000, 'pedas');

INSERT INTO pembayaran (id_pesanan, total, metode, tgl_bayar) VALUES
(1, 46000, 'qris',     '2026-11-20'),
(2, 25000, 'tunai',    '2026-11-20'),
(3, 56000, 'transfer', '2026-11-21'),
(4, 56000, 'tunai',    '2026-11-22'),
(5, 76000, 'qris',     '2026-11-23'),
(6, 88000, 'qris',     '2026-11-24');

-- =====================================================
-- 3. VIEW (LAPORAN SIAP PAKAI)
-- =====================================================

-- Total tiap pesanan
CREATE VIEW v_total_pesanan AS
SELECT p.id_pesanan, pl.nama AS pelanggan, p.tanggal, p.status,
       SUM(d.jumlah * d.harga_satuan) AS total_tagihan
FROM pesanan p
JOIN pelanggan pl     ON pl.id_pelanggan = p.id_pelanggan
JOIN detail_pesanan d ON d.id_pesanan = p.id_pesanan
GROUP BY p.id_pesanan, pl.nama, p.tanggal, p.status;

-- Omzet harian (hanya pesanan yang sudah dibayar)
CREATE VIEW v_omzet_harian AS
SELECT tgl_bayar AS tanggal, COUNT(*) AS jumlah_transaksi, SUM(total) AS omzet
FROM pembayaran
GROUP BY tgl_bayar;

-- Produk terlaris
CREATE VIEW v_produk_terlaris AS
SELECT pr.nama_produk, SUM(d.jumlah) AS total_terjual,
       SUM(d.jumlah * d.harga_satuan) AS pendapatan
FROM detail_pesanan d
JOIN produk pr  ON pr.id_produk = d.id_produk
JOIN pesanan ps ON ps.id_pesanan = d.id_pesanan
WHERE ps.status <> 'dibatalkan'
GROUP BY pr.id_produk, pr.nama_produk
ORDER BY total_terjual DESC;

-- Level pedas favorit pelanggan
CREATE VIEW v_level_pedas AS
SELECT d.level_pedas, SUM(d.jumlah) AS total_porsi
FROM detail_pesanan d
JOIN pesanan ps ON ps.id_pesanan = d.id_pesanan
WHERE d.level_pedas IS NOT NULL AND ps.status <> 'dibatalkan'
GROUP BY d.level_pedas
ORDER BY total_porsi DESC;

-- Bahan baku yang stoknya menipis (kurang dari 5)
CREATE VIEW v_stok_menipis AS
SELECT b.nama_bahan, b.stok, b.satuan, p.nama_pemasok, p.no_hp
FROM bahan_baku b
JOIN pemasok p ON p.id_pemasok = b.id_pemasok
WHERE b.stok < 5;

-- HPP (biaya bahan) dan margin per produk
CREATE VIEW v_margin_produk AS
SELECT pr.nama_produk, pr.harga AS harga_jual,
       ROUND(SUM(r.jumlah_pakai * b.harga_beli)) AS hpp,
       pr.harga - ROUND(SUM(r.jumlah_pakai * b.harga_beli)) AS margin
FROM produk pr
JOIN resep r      ON r.id_produk = pr.id_produk
JOIN bahan_baku b ON b.id_bahan = r.id_bahan
GROUP BY pr.id_produk, pr.nama_produk, pr.harga;

-- =====================================================
-- 4. QUERY CONTOH
-- =====================================================

-- a) Daftar menu beserta kategorinya
-- SELECT k.nama_kategori, p.nama_produk, p.harga
-- FROM produk p JOIN kategori k ON k.id_kategori = p.id_kategori
-- ORDER BY k.id_kategori, p.id_produk;

-- b) Rincian satu pesanan (misal pesanan nomor 3)
-- SELECT pr.nama_produk, d.level_pedas, d.jumlah, d.harga_satuan,
--        d.jumlah * d.harga_satuan AS subtotal
-- FROM detail_pesanan d JOIN produk pr ON pr.id_produk = d.id_produk
-- WHERE d.id_pesanan = 3;

-- c) Pesanan yang belum dibayar
-- SELECT t.* FROM v_total_pesanan t
-- LEFT JOIN pembayaran b ON b.id_pesanan = t.id_pesanan
-- WHERE b.id_bayar IS NULL AND t.status <> 'dibatalkan';

-- d) Pelanggan paling sering memesan
-- SELECT pl.nama, COUNT(*) AS jumlah_pesanan
-- FROM pesanan ps JOIN pelanggan pl ON pl.id_pelanggan = ps.id_pelanggan
-- GROUP BY pl.id_pelanggan, pl.nama ORDER BY jumlah_pesanan DESC;

-- e) Kurangi stok bahan setelah pesanan selesai (contoh pesanan 7)
-- UPDATE bahan_baku b
-- JOIN (
--   SELECT r.id_bahan, SUM(r.jumlah_pakai * d.jumlah) AS terpakai
--   FROM detail_pesanan d JOIN resep r ON r.id_produk = d.id_produk
--   WHERE d.id_pesanan = 7 GROUP BY r.id_bahan
-- ) x ON x.id_bahan = b.id_bahan
-- SET b.stok = b.stok - x.terpakai;

-- Cek hasil view:
-- SELECT * FROM v_omzet_harian;
-- SELECT * FROM v_produk_terlaris;
-- SELECT * FROM v_level_pedas;
-- SELECT * FROM v_stok_menipis;
-- SELECT * FROM v_margin_produk;


-- Kolom tambahan untuk kebutuhan modul persediaan pada prototipe
UPDATE bahan_baku SET stok_minimum = 5 WHERE nama_bahan IN ('Ayam potong','Tepung bumbu','Cabai rawit');
UPDATE bahan_baku SET stok_minimum = 3 WHERE stok_minimum = 0;

-- Modul pembelian dan pengeluaran yang tidak terdapat pada ERD inti
CREATE TABLE pembelian (
 id_pembelian BIGINT AUTO_INCREMENT PRIMARY KEY,
 tanggal DATE NOT NULL,
 id_pemasok INT NOT NULL,
 id_bahan INT NOT NULL,
 jumlah DECIMAL(10,2) NOT NULL,
 total INT NOT NULL,
 FOREIGN KEY (id_pemasok) REFERENCES pemasok(id_pemasok) ON UPDATE CASCADE ON DELETE RESTRICT,
 FOREIGN KEY (id_bahan) REFERENCES bahan_baku(id_bahan) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE pengeluaran (
 id_pengeluaran BIGINT AUTO_INCREMENT PRIMARY KEY,
 tanggal DATE NOT NULL,
 kategori VARCHAR(60) NOT NULL,
 keterangan VARCHAR(255) NOT NULL,
 jumlah INT NOT NULL
) ENGINE=InnoDB;
