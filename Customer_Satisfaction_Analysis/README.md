# Customer Satisfaction Analysis — End-to-End Data Analyst Workflow Documentation

*Portofolio project: analisis kepuasan pelanggan pada dataset e-commerce Olist (Brazil). Dokumentasi ini menjelaskan seluruh alur kerja seorang Data Analyst dari hulu ke hilir — mulai dari mendefinisikan masalah bisnis, membersihkan data, melakukan exploratory data analysis, hingga membangun dashboard interaktif.*

---

## BAB 1 — Business Understanding

### 1.1 Main Business Problem

> The company is experiencing a decline or fluctuation in customer satisfaction (review score) that could potentially threaten customer retention and revenue, but it is not yet clear which operational factor (delivery, product category, price, shipping costs) is the primary root cause?, so resources for improvement cannot yet be prioritized appropriately. The company could end up spending a large portion of its budget on addressing issues that are not actually the main source of the problem.

### 1.2 Business Objective

> Identify the key drivers of declining satisfaction, measure their impact on repeat purchase behavior, and ensure that future improvement decisions are data-driven, not based on assumptions or guesswork by the internal team.

### 1.3 Business Questions

| No | Business Question |
|---|---|
| 1 | Bagaimana tren review score dari tahun 2017–2018, apakah membaik, memburuk, atau stagnan? | 
| 2 | Kategori produk mana yang punya Detractor Rate tertinggi? | 
| 3 | Seberapa besar dampak delivery delay terhadap review score (apakah delay 1–3 hari beda signifikan dengan >7 hari)? | 
| 4 | Apakah customer dengan satisfaction tinggi (Promoter) punya Repeat Purchase Rate yang signifikan lebih tinggi dibanding Detractor? | 

---

## BAB 2 — Result Summary of The Project

Proyek ini menganalisis **99.441 order** dan **96.096 pelanggan unik** dari sebuah marketplace e-commerce sepanjang Januari 2017–Agustus 2018, dengan cakupan review yang sangat tinggi (98,86% dari order yang selesai punya review sample yang representatif, bukan sekadar pelanggan yang paling vokal).

Empat business questions dijawab lewat pipeline lengkap **Excel Power Query (cleaning) → MySQL (EDA, Statistical Anatomy Layer Approach) → Tableau (dashboard interaktif)**. Ringkasan temuan utama:

- **Tren review score bersifat volatile, bukan tren linear satu arah**: sempat anjlok tajam ke titik terendah 3,79 pada Maret 2018 (dari baseline normal ~4,2–4,3), lalu pulih cepat dalam 2 bulan berikutnya.
- **Kategori dengan Detractor Rate tertinggi didominasi 3 kateori produk yang bukan niche**: Fashion Pria, Furnitur Kantor, dan Audio punya detractor rate tertinggi dengan rasio (21-22%) diantara top 10 kategori produk lainnya.
- **Ada titik kritis (threshold) keterlambatan pengiriman yang tajam di kisaran 4 hari**: Detractor Rate melonjak lebih dari 2x lipat begitu keterlambatan melewati 3 hari, jauh lebih drastis dibanding lompatan dari 4-7 hari ke >7 hari.
- **Hipotesis "Promoter lebih loyal dari Detractor" terkonfirmasi arahnya, tapi lemah secara ukurannya**: selisih Repeat Purchase Rate hanya 0,20 poin persentase (3,32% vs 3,12%), jauh lebih kecil dari asumsi umum di industri.

Kesimpulan strategisnya: perbaikan customer satisfaction di perusahaan ini **tidak bisa disederhanakan jadi satu program tunggal** ("perbaiki delivery" saja, atau "naikkan kepuasan" saja), Perusahaan sebaiknya melengkapi upaya peningkatan kepuasan pelanggan dengan program loyalitas atau insentif yang lebih terarah, alih-alih berasumsi bahwa kepuasan yang tinggi saja sudah cukup untuk secara otomatis membuat pelanggan kembali.

---

## BAB 3 — Dataset Overview

### 3.1 Data Summary & Sources

Dataset ini merupakan **9 tabel relasional** yang merepresentasikan siklus transaksi e-commerce end-to-end dari pelanggan, pemesanan, item, pembayaran, hingga review. Sumber data berupa 9 file CSV yang telah melalui proses cleaning.

| Tabel | Fungsi | Total Baris (Setelah Cleaning) |
|---|---|---|
| `orders` | Central fact table — 1 baris per transaksi | 99.441 |
| `order_items` | Line-item fact — 1 baris per produk dalam sebuah order | 112.650 |
| `order_reviews` | Review pelanggan per order | ~98.376 |
| `order_payments` | Detail pembayaran per order | 103.883 |
| `customers` | Master data pelanggan | 99.441 |
| `products` | Master data produk & kategori | 32.951 |
| `sellers` | Master data penjual | 3.095 |
| `geolocation` | Referensi koordinat per kode pos | 19.015 |
| `product_category_name_translation` | Mapping nama kategori Portugis → Inggris | 73 |

**Periode data:** Januari 2017 – Agustus 2018 (20 bulan). Data 2016 secara sengaja dikeluarkan dari analisis karena volumenya terlalu kecil untuk dijadikan sample yang representatif.

### 3.2 Data Dictionary

**Tabel `orders`** (central fact table)

| Kolom | Tipe | Deskripsi |
|---|---|---|
| `order_id` | VARCHAR (PK) | Identifier unik order |
| `customer_id` | VARCHAR (FK) | Identifier pelanggan *per transaksi* |
| `order_status` | VARCHAR | Status order (`delivered`, `shipped`, `canceled`, dst.) |
| `purchase_date` | DATETIME | Waktu order dibuat |
| `approved_date` | DATETIME | Waktu pembayaran disetujui |
| `carrier_pickup_date` | DATETIME | Waktu barang diserahkan ke kurir |
| `delivered_date` | DATETIME | Waktu barang diterima pelanggan |
| `estimated_delivery_date` | DATETIME | Estimasi tanggal tiba yang dijanjikan sistem |
| `data_quality_flag` | VARCHAR | Hasil cleaning: `CLEAN`, `CARRIER_DATE_ANOMALY`, atau `DELIVERED_NO_DATE` |
| `delivery_duration_days` | INT | Selisih hari `delivered_date` − `purchase_date` |
| `delivery_delay_days` | INT | Selisih hari `delivered_date` − `estimated_delivery_date` (positif = telat) |
| `delay_bucket` | VARCHAR | Kategori keterlambatan: `On-Time`, `Late 1-3 Days`, `Late 4-7 Days`, `Late >7 Days`, `No Data` |
| `delivery_outlier_flag` | VARCHAR | Flag untuk durasi pengiriman ekstrem (>90 hari) |

**Tabel `order_reviews`**

| Kolom | Tipe | Deskripsi |
|---|---|---|
| `review_id` | VARCHAR (PK) | Identifier unik review |
| `order_id` | VARCHAR (FK) | Order yang direview |
| `review_score` | TINYINT | Rating 1–5 |
| `review_comment_title` / `review_comment_message` | TEXT | Komentar teks (opsional, banyak null secara struktural) |
| `review_creation_date` | DATETIME | Waktu review dibuat |
| `satisfaction_tier` | VARCHAR | Hasil klasifikasi: `Promoter` (skor ≥4), `Passive` (skor =3), `Detractor` (skor ≤2) — pendekatan berbasis logika NPS |

**Tabel `products`**

| Kolom | Tipe | Deskripsi |
|---|---|---|
| `product_id` | VARCHAR (PK) | Identifier unik produk |
| `product_category_name` | VARCHAR | Nama kategori (Bahasa Portugis) |
| `product_category_name_english` | VARCHAR | Nama kategori (Bahasa Inggris, hasil translasi) |
| `category_missing_flag` | VARCHAR | Flag untuk produk tanpa kategori |

**Tabel `customers`**

| Kolom | Tipe | Deskripsi |
|---|---|---|
| `customer_id` | VARCHAR (PK) | Identifier per **transaksi** — berubah setiap order baru, meski pelanggannya sama |
| `customer_unique_id` | VARCHAR | Identifier **permanen** pelanggan — dipakai untuk analisis repeat purchase |
| `customer_zip_code_prefix`, `customer_city`, `customer_state` | VARCHAR / CHAR | Data lokasi pelanggan |

> **Catatan penting:** Selisih jumlah unik `customer_id` (99.441) vs `customer_unique_id` (96.096) bukan data kotor, ini konfirmasi struktur dataset bahwa ada ±3.345 order berasal dari pelanggan yang sudah pernah order sebelumnya (repeat customer).

**Tabel `order_items`, `order_payments`, `sellers`, `geolocation`, `product_category_name_translation`** mengikuti struktur standar sesuai skema database (lihat file `Create_Database_and_Datatable.sql` di repository), masing-masing menyimpan detail item transaksi, metode pembayaran, data penjual, koordinat wilayah, dan mapping nama kategori.

---

### Data Cleaning Summary

Proses cleaning dilakukan di **Excel Power Query**, dengan prinsip utama: *flag dan investigasi anomali business-logic, mayoritas temuan justru ditangani lewat flagging, bukan penghapusan.

**10 Temuan Utama & Penanganannya**

| # | Temuan | Kategori | Tindakan |
|---|---|---|---|
| 1 | 8 order status `delivered` tapi tanggal delivery `NULL` | Genuine data integrity issue | **Flag** (`DELIVERED_NO_DATE`), tidak di-drop — jadi evidence bahwa ada masalah di source data |
| 2 | 166 order dengan `carrier_pickup_date` < `purchase_date` | Business logic violation | **Flag** (`CARRIER_DATE_ANOMALY`) — selisih terbesar hanya ±68 menit, indikasi timezone/clock drift, bukan fraud |
| 3 | Durasi pengiriman maksimum 209 hari (rata-rata 12 hari) | Valid statistical outlier | **Flag** (`EXTREME_DELIVERY_OUTLIER` untuk >90 hari), tetap dipertahankan di analisis |
| 4 | 814 `review_id` duplikat (baris identik) | Genuine duplicate | **Drop** |
| 5 | 547 order dengan >1 review record | Bukan dirty data — genuine repeat review | **Deduplicate**, ambil review paling terakhir (paling representatif) |
| 6 | 88% `review_comment_title` & 59% `review_comment_message` null | Structural, bukan dirty | **Dibiarkan null** — komentar teks memang opsional |
| 7 | 2 kategori produk tidak punya translasi Inggris | Minor gap di reference table | **Manual mapping** (`pc_gamer` → PC Gaming, dst.) |
| 8 | ~1,85% produk tanpa kategori | Minor, di bawah threshold 5% | **Flag** (`CATEGORY_UNKNOWN`) |
| 9 | 9 baris `payment_value` ≤ 0 | Perlu investigasi | 3 baris `not_defined` bernilai 0 di-**drop** (genuine garbage), 6 baris voucher bernilai 0 di-**flag** (valid, bukan garbage) |
| 10 | Jumlah unik `customer_id` ≠ `customer_unique_id` | Expected behavior | **Tidak ada tindakan** — ini konfirmasi struktur data repeat customer, bukan anomali |

**Before vs After (Row Count per Tabel)**

| Tabel | Rows Before | Rows After | Kolom Ditambahkan |
|---|---|---|---|
| `orders` | 99.441 | 99.441 | +5 kolom (delay bucket, flags, durasi, dst.) |
| `order_reviews` | 99.224 | ~98.376 | +1 kolom (`satisfaction_tier`) — turun karena drop duplikat & dedup multi-review |
| `order_items` | 112.650 | 112.650 | +2 kolom (`free_shipping_flag`, `item_total_value`) |
| `products` | 32.951 | 32.951 | +1 kolom (`category_missing_flag`), 7 kolom dimensi produk yang tidak relevan di-drop |
| `order_payments` | 103.886 | 103.883 | +1 kolom (`zero_value_payment_flag`) — turun 3 baris garbage |
| `geolocation` | 1.000.163 | 19.015 | Deduplikasi ke 1 baris per kode pos (dari rata-rata 52 koordinat/kode pos) |
| `customers`, `sellers` | Tidak berubah | Tidak berubah | Hanya standardisasi tipe data |
| `product_category_name_translation` | 71 | 73 | +2 baris manual mapping |

**Tools & Metode:** Seluruh proses cleaning dilakukan di **Microsoft Excel Power Query**, menggunakan kombinasi *Custom Column* (untuk business-logic flagging), *Table.Distinct* (deduplikasi), dan *Table.Group* (agregasi multi-review per order). Setiap tabel disimpan sebagai *Connection Only* dan digabung dalam satu *master query* sebagai input ke tahap EDA di MySQL.

---

## BAB 4 — Exploratory Data Analysis: Key/Insight Findings

EDA dilakukan menggunakan pendekatan **Statistical Anatomy Layer Approach** — sebuah metode eksplorasi data yang bergerak dari hipotesis bisnis, ke profiling, ke analisis satu-variabel, dua-variabel, lalu multi-variabel dan waktu, dan ditutup dengan validasi hipotesis berbasis data. Berikut ringkasan temuan di tiap layer.

### Layer 1 — Data Profiling & Overview

| Metrik | Nilai |
|---|---|
| Periode data | Januari 2017 – Agustus 2018 |
| Total order | 99.441 |
| Total pelanggan unik | 96.096 |
| % Order berstatus `delivered` | 97,07% |
| Review coverage (order delivered yang punya review) | 98,86% |
| Distribusi review score | 5★: 57,86% · 4★: 19,34% · 3★: 8,23% · 2★: 3,17% · 1★: 11,40% |
| Distribusi satisfaction tier | Promoter 77,20% · Passive 8,23% · Detractor 14,57% |

Distribusi review score mayoritas besar memberi rating tertinggi (5★), tapi ada kluster kedua yang cukup signifikan di rating terendah (1★, 11,4%), jauh lebih besar dari rating 2★ (3,17%). Ini pola khas review e-commerce: pelanggan puas menulis review santai, pelanggan sangat kecewa menulis review sebagai bentuk komplain — sementara yang di tengah (cukup puas) jarang repot memberi rating.

### Layer 2 — Univariate Analysis

| Metrik | Nilai |
|---|---|
| Review score — mean | 4,09 |
| Review score — median | 5,0 |
| Review score — std. dev | 1,34 |
| Durasi pengiriman — mean | 12,07 hari |
| Durasi pengiriman — median | 10 hari |
| Durasi pengiriman — Q1 / Q3 | 6 hari / 15 hari |
| Extreme outlier durasi (>90 hari) | 76 order |
| Overall On-Time Delivery (OTD) Rate | 93,20% |

Median (5,0) lebih tinggi dari mean (4,09) — mengonfirmasi distribusi *left-skewed*. Ini artinya **rata-rata (mean) sedikit understate seberapa puas mayoritas pelanggan sebenarnya**, karena ditarik ke bawah oleh minoritas yang memberi rating sangat rendah.

### Layer 3 & 4 — Bivariate, Multivariate, dan Time-Based Analysis (Jawaban Business Questions)

**BQ1 — Tren Review Score 2017–2018**

| Periode | Avg Review Score | Detractor Rate |
|---|---|---|
| Jan 2017 (baseline awal) | 4,34 | 8,26% |
| Nov 2017 (mulai turun) | 4,20 | 11,04% |
| **Mar 2018 (titik terendah)** | **3,79** | **21,69%** |
| Mei 2018 (pulih) | 4,24 | 10,91% |
| Agt 2018 (akhir periode) | 4,29 | 10,04% |

**Insight:** Bukan tren linear satu arah — ada periode krisis tajam selama ±4 bulan (Des 2017–Apr 2018) yang kemudian pulih. Kalau dilihat cuma dari rata-rata tahunan, periode krisis ini akan tersamarkan dan perlu zoom-out untuk melihat tren bulan ke bulan.

**BQ2 — Detractor Rate Tertinggi per Kategori Produk**

| Kategori | Detractor Rate | On-Time Delivery Rate | Interpretasi |
|---|---|---|---|
| Fashion Pria | 23,08% | 97,09% | Bukan masalah delivery |
| Furnitur Kantor | 21,99% | 91,96% | Bukan masalah delivery |
| Audio | 21,74% | 88,34% | **Double risk** — delivery ikut berkontribusi |
| Home Comfort | 18,56% | 90,46% | Bukan masalah delivery |
| Bed & Bath | 15,90% | 92,73% | Bukan masalah delivery |

**Insight:** Kategori dengan Detractor Rate tertinggi didominasi 3 kateori produk yang bukan niche: Fashion Pria, Furnitur Kantor, dan Audio punya detractor rate tertinggi dengan rasio (21-22%) diantara top 10 kategori produk lainnya.

**BQ3 — Dampak Delivery Delay terhadap Review Score**

| Delay Bucket | Avg Score | Gap vs On-Time | Detractor Rate |
|---|---|---|---|
| On-Time | 4,29 | — | 9,19% |
| Late 1–3 Hari | 3,29 | −1,00 | 32,08% |
| Late 4–7 Hari | 2,11 | −2,19 | 67,51% |
| Late >7 Hari | 1,70 | −2,60 | 79,30% |

**Insight:** Titik kritis (*cliff point*) ada di ambang 3–4 hari — lompatan Detractor Rate dari bucket "1–3 hari" ke "4–7 hari" (32% → 67,5%) jauh lebih drastis dibanding lompatan "4–7 hari" ke ">7 hari" (67,5% → 79,3%). Toleransi pelanggan terhadap keterlambatan nyata tapi sempit.

**BQ4 — Repeat Purchase Rate by Satisfaction Tier**

| Satisfaction Tier | Total Pelanggan Unik | Repeat Purchase Rate |
|---|---|---|
| Promoter | 72.858 | 3,32% |
| Passive | 7.647 | 3,23% |
| Detractor | 11.852 | 3,12% |

**Insight:** Arah hipotesis terkonfirmasi (Promoter > Passive > Detractor), tapi magnitude selisihnya kecil (0,20 poin persentase). Kepuasan bukan prediktor tunggal yang kuat untuk retention di dataset ini.

### Layer 5 — Data-Driven Hypothesis

| Hipotesis | Status | Evidence |
|---|---|---|
| H1: Delivery delay adalah driver utama satisfaction rendah | **Terkonfirmasi kuat** | Mayoritas kategori produk yang detractornya tinggi punya keterlambatan pengiriman yang rendah |
| H2: Promoter punya repeat purchase rate signifikan lebih tinggi dari Detractor | **Arah benar namun ukurannya kecil** | Selisih hanya 0,20pp — tidak cukup kuat untuk dijadikan strategi retention tunggal |

### Recommendations

- Set a maximum delivery delay SLA of less than four days as the primary operational target, rather than simply aiming for on-time delivery. This is the critical threshold for customer satisfaction, and logistics investments will have the greatest impact if they are focused on preventing orders from exceeding this limit.
- Implement monthly review score monitoring instead of quarterly or annual tracking, so that sharp declines like the one in March 2018 can be detected much earlier.
- Do not rely on customer satisfaction as the only retention strategy. Since its relationship with repeat purchase is weaker than expected, the company should complement satisfaction improvement efforts with more targeted loyalty programs or incentives, rather than assuming that high satisfaction alone will automatically bring customers back.

---

*Teknikal dokumentasi ini adalah bagian dari end-to-end portfolio project Customer Satisfaction Analysis. Query EDA lengkap, hasil cleaning detail, dan file dashboard interaktif serta file pendukung lainnya yang tersedia di repository GitHub terkait.*