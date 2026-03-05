# Daftar Command — Westfield Heavy RP Server

> Dokumen ini mencakup **semua command** yang sudah ada di server saat ini, serta **command yang akan dibuat** untuk 5 sistem baru (HT Radio, Phone Call, Faction, Job, Property).

---

## DAFTAR ISI

1. [Command yang Sudah Ada](#command-yang-sudah-ada)
   - [RP Commands (Player)](#rp-commands-player)
   - [Umum (Player)](#umum-player)
   - [Pelayanan Publik](#pelayanan-publik)
   - [Bank & ATM](#bank--atm)
   - [Admin Commands](#admin-commands)
   - [Dev/Setup Commands](#devsetup-commands)
2. [Command Baru — HT Radio](#1-ht-radio)
3. [Command Baru — Phone Call](#2-phone-call-witapp)
4. [Command Baru — Faction System](#3-faction-system)
5. [Command Baru — Job System](#4-job-system)
6. [Command Baru — Property System](#5-property-system)

---

## Command yang Sudah Ada

### RP Commands (Player)

| Command | Alias | Penjelasan |
|---------|-------|------------|
| `/me [aksi]` | — | Menampilkan aksi RP. Contoh: `* John Doe tersenyum.` Radius 20m. |
| `/do [narasi]` | — | Menampilkan narasi RP. Contoh: `* Hujan deras. (( John Doe ))` Radius 20m. |
| `/ame [aksi]` | — | Sama seperti `/me` tapi juga muncul teks 3D di atas kepala selama 5 detik. |
| `/s [teks]` | `/shout` | Berteriak. Pesan RP terlihat radius 40m. |
| `/w [player] [pesan]` | `/whisper` | Berbisik ke pemain di dekat (maks 3m). Pemain sekitar hanya lihat aksi bisik, bukan isi pesannya. |
| `/b [pesan]` | `/ooc` | Chat OOC (Out of Character) lokal, radius 20m. |

### Umum (Player)

| Command | Penjelasan |
|---------|------------|
| `/hp` | Buka/tutup handphone (Phone UI). Akses semua aplikasi: WitApp, Twitter, Market, M-Banking, GPS, Settings, Notepad. |
| `/inv` | Buka inventory. Lihat dan gunakan barang yang dimiliki. |
| `/dompet` | Buka/tutup dompet. Lihat kartu: KTP, Kartu Bank, SIM Kendaraan. Bisa tunjukkan ke pemain lain. |
| `/makan` | Makan (isi lapar ke 100). *Sementara — nanti diganti sistem makanan dari inventory.* |
| `/minum` | Minum (isi haus ke 100). *Sementara — nanti diganti sistem minuman dari inventory.* |
| `/cancelgps` | Batalkan navigasi GPS yang sedang aktif. |

### Pelayanan Publik

| Command | Penjelasan |
|---------|------------|
| `/layanan` | Gunakan **di dalam** Mall Pelayanan (masuk dulu tekan F di pintu masuk). Datangi loket NPC yang diinginkan, lalu ketik `/layanan`. Loket yang tersedia: **Resepsionis** (info), **Dukcapil** (KTP), **Perizinan** (segera), **Pajak** (segera), **Surat Ket.** (segera). Ada sistem antrian. |
| `/sim` | Gunakan di dekat SIM Station. Buat SIM Kendaraan (A/B/C) melalui ujian quiz. Harus punya KTP dulu. |

### Bank & ATM

| Command | Penjelasan |
|---------|------------|
| `/atm` | Gunakan di dekat ATM. Akses: cek saldo, tarik tunai, setor, transfer. |
| `/bank` | Gunakan di dekat Bank. Akses layanan bank: buka rekening, cek saldo, tarik, setor, transfer, mutasi. |

### Admin Commands

| Command | Level | Penjelasan |
|---------|-------|------------|
| `/a [pesan]` | 1 | Chat admin internal. Hanya terlihat sesama admin. |
| `/report [player] [alasan]` | 0 | Laporkan pemain. Semua pemain bisa pakai. |
| `/reports` | 1 | Lihat daftar laporan aktif. |
| `/check [player]` | 1 | Lihat informasi detail pemain (HP, uang, level, dll). |
| `/spec [player]` | 1 | Spectate/pantau pemain. Ketik `/spec` lagi untuk berhenti. |
| `/kick [player] [alasan]` | 2 | Tendang pemain dari server. |
| `/mute [player]` | 2 | Toggle mute pemain. Pemain yang di-mute tidak bisa chat. |
| `/warn [player] [alasan]` | 2 | Berikan peringatan ke pemain. |
| `/freeze [player]` | 2 | Toggle freeze pemain. Pemain tidak bisa bergerak. |
| `/goto [player]` | 2 | Teleportasi ke posisi pemain. |
| `/gethere [player]` | 2 | Tarik pemain ke posisi kamu. |
| `/slap [player]` | 2 | Lempar pemain ke atas (hukuman ringan). |
| `/jail [player] [menit]` | 3 | Penjara pemain selama X menit. |
| `/unjail [player]` | 3 | Bebaskan pemain dari penjara. |
| `/setskin [player] [skinid]` | 3 | Ubah skin pemain. |
| `/ban [player] [alasan]` | 3 | Banned pemain dari server (permanen). |
| `/unban [nama]` | 3 | Cabut ban pemain. |
| `/setmoney [player] [jumlah]` | 4 | Set uang cash pemain. |
| `/sethealth [player] [hp]` | 4 | Set HP pemain (0-100). |
| `/givemoney [player] [jumlah]` | 4 | Berikan uang ke pemain. |
| `/giveitem [player] [itemid] [jumlah]` | 4 | Berikan item ke inventory pemain. |
| `/veh [modelid]` | 4 | Spawn kendaraan di posisi kamu. |
| `/destroyveh` | 4 | Hancurkan kendaraan yang sedang dinaiki. |
| `/setadmin [player] [level]` | 5 | Set level admin pemain (0-6). |
| `/ann [pengumuman]` | 4 | Kirim pengumuman global ke seluruh server. |
| `/setlevel [player] [level]` | 5 | Set level pemain (bukan admin level). |
| `/getpos` | 3 | Tampilkan koordinat posisi saat ini (X, Y, Z, Angle). |
| `/gotopos [x] [y] [z]` | 3 | Teleportasi ke koordinat tertentu. |
| `/setweather [0-45]` | 4 | Ubah cuaca server. |
| `/settime [0-23]` | 4 | Ubah jam server. |
| `/resetplayer [player]` | 5 | Reset data pemain (hati-hati, menghapus progress). |
| `/serverinfo` | 1 | Lihat info server (player count, uptime, dll). |
| `/setint [player] [id]` | 3 | Set interior ID pemain. |
| `/setvw [player] [id]` | 3 | Set virtual world pemain. |
| `/aduty` | 1 | Toggle admin on-duty. Saat aduty aktif, nama berubah warna admin. |
| `/heal` | 6 | Self-heal untuk developer. Bisa dipakai saat pingsan. Full HP, hunger, thirst. |
| `/fly` | 6 | Toggle fly/noclip mode. WASD gerak, mouse arah. Ketik lagi untuk berhenti. |

### Dev/Setup Commands

> Command untuk setup lokasi/objek di server. Hanya untuk developer/admin level tinggi.

| Command | Penjelasan |
|---------|------------|
| `/mallsetup` | **Command utama** untuk mengelola Mall Pelayanan. Dialog menu: **Buat Mall** (pilih kota → otomatis nama), **Edit Mall** (pindah lokasi/ganti interior/kelola NPC), **Hapus Mall**. Semua lewat dialog, tanpa perlu ketik nama. |
| `/setmall [nama]` | Shortcut buat Mall Pelayanan di posisi saat ini (nama manual). Disarankan pakai `/mallsetup`. |
| `/delmall` | Shortcut hapus Mall Pelayanan terdekat (radius 8m). |
| `/movemall` | Shortcut pindahkan Mall Pelayanan terdekat ke posisi saat ini. |
| `/malllist` | Lihat daftar semua Mall Pelayanan. |
| `/setatm` | Buat ATM di posisi saat ini. |
| `/delatm` | Hapus ATM terdekat. |
| `/moveatm` | Pindahkan ATM terdekat ke posisi saat ini. |
| `/atmlist` | Lihat daftar semua ATM. |
| `/setbank [nama]` | Buat lokasi Bank di posisi saat ini. |
| `/delbank` | Hapus Bank terdekat. |
| `/movebank` | Pindahkan Bank terdekat ke posisi saat ini. |
| `/banklist` | Lihat daftar semua Bank. |
| `/setsimstation [nama]` | Buat SIM Station di posisi saat ini. |
| `/delsimstation` | Hapus SIM Station terdekat. |
| `/simstationlist` | Lihat daftar semua SIM Station. |
| `/createloc [nama]` | Buat lokasi/label baru di posisi saat ini. |
| `/deleteloc [id]` | Hapus lokasi berdasarkan ID. |
| `/editloc [id]` | Edit lokasi berdasarkan ID. |
| `/locs` | Lihat daftar semua lokasi. |
| `/gotoloc [id]` | Teleportasi ke lokasi berdasarkan ID. |
| `/tp [keyword]` | Buka dialog teleport ke SEMUA lokasi yang ada di database (Mall, ATM, Bank, Interior, SIM Station, GoFood Locker, Location, Property, Faction HQ). Opsional: filter by keyword. Contoh: `/tp mall` hanya tampilkan yang ada kata "mall". |
| `/setinterior [nama]` | Buat pintu masuk interior di posisi saat ini. |
| `/setinteriorexit` | Set titik keluar untuk interior yang baru dibuat. |
| `/delinterior` | Hapus interior terdekat. |
| `/interiorlist` | Lihat daftar semua interior. |
| `/gotointerior [id]` | Teleportasi ke interior berdasarkan ID. |
| `/setlocker [kota]` | Buat loker GoFood di posisi saat ini (kota: 1=MekarPura, 2=MadyaRaya, 3=Mojosono). |
| `/dellocker` | Hapus loker GoFood terdekat. |
| `/setmallinterior [slot]` | Shortcut konfirmasi interior Mall. Disarankan pakai `/mallsetup` > Edit > Interior. |
| `/previewinterior [slot]` | Shortcut preview interior Mall (3 opsi). Disarankan pakai `/mallsetup` > Edit > Interior. |
| `/mallnpc [slot]` | Shortcut pasang NPC di mall. Disarankan pakai `/mallsetup` > Edit > NPC. |
| `/delmallnpc` | Shortcut hapus NPC Mall terdekat (radius 3m). |
| `/mallnpclist [slot]` | Shortcut lihat NPC mall. Disarankan pakai `/mallsetup` > Edit > NPC > List. |

---

## COMMAND BARU — 5 Sistem yang Akan Dibuat

---

### 1. HT Radio

> Sistem komunikasi radio HT (Handy Talky). Beli HT di Market, atur frekuensi, bicara dengan semua pemain di frekuensi yang sama.

| Command | Penjelasan |
|---------|------------|
| `/ht` | Toggle HT on/off. Menampilkan/menyembunyikan UI radio (23 elemen TextDraw). HT harus ada di inventory. |
| `/setfreq [channel] [frekuensi]` | Atur frekuensi radio. Channel = 1 (satu frekuensi aktif). Frekuensi: 100.0 - 999.9. Contoh: `/setfreq 1 450.5` |
| `/r [pesan]` | Bicara lewat radio. Pesan terkirim ke semua pemain yang HT-nya nyala dan frekuensinya sama. |

**Setup (Admin/Dev):**

| Command | Penjelasan |
|---------|------------|
| — | Tidak ada setup command. HT dijual lewat Market (phone app) yang sudah ada. |

---

### 2. Phone Call (WitApp)

> Sistem telepon di dalam aplikasi WitApp (bukan command terpisah). Player buka WitApp → pilih kontak → "Panggil".

| Command | Penjelasan |
|---------|------------|
| — | **Tidak ada command baru.** Semua aksi lewat UI WitApp yang sudah ada. |

**Cara Kerja:**
- Buka `/hp` → WitApp → Pilih kontak → "Panggil"
- Selama telepon aktif, **semua chat otomatis jadi warna telepon** (tidak perlu command khusus)
- Pemain dalam radius <5m bisa dengar satu sisi percakapan (proximity leak)
- Potong kuota per menit. Kuota habis = tidak bisa telepon
- Auto-hangup jika disconnect/crash
- Missed call setelah 15 detik tidak diangkat
- Tutup telepon lewat UI (tombol "Tutup" di WitApp)

---

### 3. Faction System

> Sistem fraksi untuk organisasi legal (LSPD, EMS, Pemerintah) dan illegal (Gang/Mafia). Termasuk sistem on-duty, payday, presensi, sanksi, dan cuti.

#### Player Commands — Anggota Faction

| Command | Penjelasan |
|---------|------------|
| `/duty` | Toggle on-duty / off-duty. Saat off-duty, payday yang belum diklaim akan otomatis ditawarkan. |
| `/offduty` | Selesai bertugas. Wajib klaim payday saat off-duty jika ada. |
| `/frekap` | Lihat rekap presensi pribadi minggu ini (berapa kali on-duty, sisa kewajiban, dll). |
| `/fmembers` | Lihat daftar anggota fraksi yang sedang online + status duty mereka. |
| `/fchat [pesan]` atau `/f [pesan]` | Chat internal fraksi. Hanya terlihat sesama anggota fraksi. |
| `/radio [pesan]` | Chat radio fraksi (khusus legal). Mirip fchat tapi nuansa radio resmi. |
| `/cuti [hari]` | Ajukan cuti ke atasan. Contoh: `/cuti 7` untuk cuti seminggu. Harus disetujui Chief. |
| `/claimpayday` | Klaim payday yang menumpuk (jika belum diambil saat off-duty). |
| `/fstash` | Buka stash/loker fraksi (khusus illegal). Simpan/ambil barang bersama. Di lokasi HQ. |

#### Leader/Chief Commands — Pimpinan Faction

| Command | Penjelasan |
|---------|------------|
| `/finvite [player]` | Undang pemain masuk ke fraksi. |
| `/funinvite [player]` | Keluarkan anggota dari fraksi. |
| `/fsetrank [player] [rank]` | Ubah rank/jabatan anggota. |
| `/fsetgaji [rank] [gaji_pokok] [bensin] [makan] [jalan]` | Set komponen gaji per rank. Gaji Pokok + Uang Bensin + Uang Makan + Uang Jalan = Total Payday. |
| `/fsetlibur [player] [hari]` | Set jadwal libur untuk anggota tertentu. Hari: 1=Senin - 7=Minggu. Selama libur, anggota tidak bisa on-duty. |
| `/fapprovecuti [player]` | Setujui pengajuan cuti anggota. |
| `/frejectcuti [player]` | Tolak pengajuan cuti anggota. |
| `/fpresensi` | Lihat rekap presensi SEMUA anggota minggu ini. Siapa yang sudah/belum memenuhi 3x duty. |
| `/fwithdraw [jumlah]` | Tarik uang dari kas fraksi (khusus legal — fitur korupsi!). |
| `/fdeposit [jumlah]` | Setor uang ke kas fraksi. |
| `/fbalance` | Cek saldo kas fraksi. |
| `/flog` | Lihat log aktivitas fraksi (siapa duty kapan, penarikan kas, dll). |

#### Admin Commands — Setup Faction

| Command | Penjelasan |
|---------|------------|
| `/createfaction [tipe] [nama]` | Buat fraksi baru. Tipe: 1=legal, 2=illegal. Contoh: `/createfaction 1 LSPD` |
| `/deletefaction [id]` | Hapus fraksi berdasarkan ID. |
| `/fsetbudget [faction_id] [jumlah]` | Set budget/anggaran fraksi (legal). Ini uang pemerintah yang dialokasikan untuk gaji anggota. |
| `/fsetpaydayinterval [faction_id] [jam]` | Set interval payday. Contoh: setiap 8 jam on-duty = 1 payday. |
| `/factions` | Lihat daftar semua fraksi. |
| `/finfo [faction_id]` | Lihat detail fraksi (anggota, budget, saldo kas, dll). |
| `/fsethq [faction_id]` | Set lokasi HQ fraksi di posisi saat ini. |

---

### 4. Job System

> Sistem pekerjaan: Taxi, Trucker, Miner, Bus Driver, Fisherman. Masing-masing punya mekanisme unik.

#### Umum (Semua Job)

| Command | Penjelasan |
|---------|------------|
| `/jobinfo` | Lihat info pekerjaan yang sedang dimiliki (nama job, perusahaan, salary, dll). |
| `/resign` | Mengundurkan diri dari pekerjaan saat ini. Harus di kantor/NPC tempat melamar. |

#### Taxi Driver

| Command | Penjelasan |
|---------|------------|
| — | Tidak ada command khusus untuk taxi. Toggle duty lewat app **TaxiGo** di phone. |
| — | Penumpang panggil taksi lewat app **TaxiGo** atau stop taksi di jalan. **Tidak ada `/taxi`.** |

**Cara Kerja:**
- Melamar: Ke NPC interview di pool taxi → wawancara (dialog) → dapat Kartu Karyawan
- On-duty: Buka `/hp` → app TaxiGo → "Mulai Bertugas"
- Terima order: Notifikasi di TaxiGo saat ada penumpang request
- Revenue: 20% pendapatan masuk ke perusahaan taxi

#### Trucker

| Command | Penjelasan |
|---------|------------|
| `/truck` | Mulai/selesai shift trucker. Harus di area perusahaan atau dekat truk perusahaan. |
| `/loadcargo` | Muat kargo ke truk. Harus di titik loading perusahaan. |
| `/unloadcargo` | Turunkan kargo di titik tujuan (bisnis yang memesan). |

**Cara Kerja:**
- Melamar: Ke Driver Center → pilih perusahaan (PT. Nusantara Kargo, PT. Sumber Pangan, PT. Bahari Energi, PT. Cepat Kirim, PT. Batu Mulia Sejahtera) → interview → diterima
- Salary: Mingguan (otomatis masuk rekening)
- Payday: Per shift, rincian uang jalan + bensin (sama kayak faction)
- Slot: Terbatas sesuai jumlah truk perusahaan

#### Miner

| Command | Penjelasan |
|---------|------------|
| `/mine` | Mulai menambang di area tambang. Harus on-duty dan punya alat tambang. |
| `/sellore` | Jual hasil tambang. Harga fluktuatif. |

**Cara Kerja:**
- Melamar: Ke NPC tambang → interview → diterima (slot terbatas)
- On-duty: Lewat app **MineLink** di phone
- Tambang → kumpulkan ore → jual di market → harga berfluktuasi

#### Bus Driver

| Command | Penjelasan |
|---------|------------|
| `/busduty` | Mulai/selesai shift bus driver. Harus di terminal bus kota masing-masing. |
| `/busroute` | Lihat rute bus yang harus diikuti. |
| `/busstop` | Berhenti di halte (passenger naik/turun). |

**Cara Kerja:**
- Per-terminal kota: Mekar Pura (4 bus), Mojosono (3 bus), Madya Raya (2 bus)
- Slot terbatas sesuai jumlah bus

#### Fisherman

| Command | Penjelasan |
|---------|------------|
| `/fish` | Mulai memancing. Harus punya pancing (beli di Market) dan berada di tepi air. |
| `/sellfish` | Jual ikan di Fish Market. Harga berbeda per kota dan berfluktuasi. |

**Cara Kerja:**
- Tidak perlu melamar — siapa saja bisa memancing asal punya alat pancing
- Beli pancing di Market (phone app)
- 3 Fish Market: Mekar Pura, Mojosono, Madya Raya — harga per kota beda-beda
- Tidak ada app khusus

#### Mechanic (FRAKSI)

| Command | Penjelasan |
|---------|------------|
| `/repair` | Perbaiki kendaraan pemain. Harus on-duty mechanic dan dekat kendaraan target. |
| `/repairprice [harga]` | Set harga jasa reparasi. |
| `/towveh` | Derek kendaraan ke bengkel. |

**Cara Kerja:**
- Mechanic = FRAKSI (semi-legal, self-funded dari customer)
- Pakai command fraksi standar (`/duty`, `/f`, dll)
- Income dari bayaran customer, bukan gaji pemerintah

#### Admin/Dev — Setup Job

| Command | Penjelasan |
|---------|------------|
| `/createjobpoint [tipe] [nama]` | Buat titik NPC perekrutan job. Tipe: taxi/trucker/miner/bus/fishmarket. |
| `/deljobpoint [id]` | Hapus titik job. |
| `/settruckcompany [nama] [slot]` | Buat perusahaan trucker baru dengan jumlah slot. |
| `/setbusterminal [kota] [jumlah_bus]` | Set terminal bus di kota (1=MekarPura, 2=MadyaRaya, 3=Mojosono). |
| `/setfishmarket [kota]` | Buat fish market di posisi saat ini. |
| `/setminespot` | Buat spot tambang di posisi saat ini. |

---

### 5. Property System

> Sistem properti: Apartemen (sewa), Kostan (sewa murah), Gudang (beli/sewa), Tempat Usaha/Ruko (sewa), Tanah (beli investasi).

#### Player Commands

| Command | Penjelasan |
|---------|------------|
| `/property` | Lihat daftar properti yang dimiliki/disewa. |
| `/sewa` | Sewa properti. Harus di dekat pintu masuk properti yang tersedia. |
| `/bayarsewa` | Bayar tagihan sewa. Bisa juga lewat M-Banking (VA payment). |
| `/kunci` atau `/lock` | Kunci/buka kunci properti. Untuk kostan: sistem kunci fisik (bisa dicuri kalau ga dikunci!). |
| `/masukrumah` | Masuk ke dalam properti yang dimiliki/disewa. Harus di dekat pintu. |
| `/keluarrumah` | Keluar dari properti. |
| `/simpanbarang` | Simpan barang dari inventory ke storage properti. |
| `/ambilbarang` | Ambil barang dari storage properti ke inventory. |
| `/setrumah` | Set properti sebagai "Rumah Saya" di GPS. Supaya muncul di Phone GPS → Lokasi Tersimpan → Rumah Saya. |
| `/evict [player]` | (Owner kostan) Usir penyewa dari kostan milikmu. |
| `/duplikatekunci` | (Owner kostan) Buat duplikat kunci untuk penyewa baru. |
| `/bukatoko` | Buka bisnis di ruko/tempat usaha. Harus sudah punya NIB & NPWP (urus di Mall Pelayanan). |
| `/tutuptoko` | Tutup bisnis (offline, customer ga bisa beli). |
| `/setharga [item] [harga]` | (Owner bisnis) Set harga jual barang dagangannya. |
| `/ordersupply [jumlah]` | (Owner bisnis) Pesan bahan baku dari supplier. Trucker akan mengantarkan. |
| `/cekstok` | (Owner bisnis) Cek stok barang dagangan. |
| `/jualtanah [player] [harga]` | Jual tanah ke pemain lain. |
| `/belitanah` | Beli tanah yang dijual. Harus di dekat papan tanda tanah dijual. |

#### Admin/Dev — Setup Property

| Command | Penjelasan |
|---------|------------|
| `/createproperty [tipe] [nama]` | Buat properti baru. Tipe: 1=Apartemen, 2=Kostan, 3=Gudang, 4=Ruko/Biz, 5=Tanah. |
| `/delproperty [id]` | Hapus properti berdasarkan ID. |
| `/editproperty [id]` | Edit properti (harga, slot, nama, dll). |
| `/setpropertyentrance [id]` | Set pintu masuk properti di posisi saat ini. |
| `/setpropertyexit [id]` | Set pintu keluar (interior) properti. |
| `/propertylist` | Lihat daftar semua properti. |
| `/gotoproperty [id]` | Teleportasi ke properti berdasarkan ID. |
| `/setevictionoffice` | Set lokasi Kantor Penitipan Barang (tempat ambil barang setelah diusir). |
| `/setsupplier [nama]` | Buat perusahaan supplier baru untuk bisnis. |

---

## Ringkasan Jumlah Command

| Kategori | Jumlah |
|----------|--------|
| **Sudah Ada — RP** | 6 (+3 alias) |
| **Sudah Ada — Umum** | 6 |
| **Sudah Ada — Pelayanan** | 2 |
| **Sudah Ada — Bank/ATM** | 2 |
| **Sudah Ada — Admin** | 30 |
| **Sudah Ada — Dev/Setup** | 20 |
| **TOTAL SUDAH ADA** | **66** |
| | |
| **Baru — HT Radio** | 3 |
| **Baru — Phone Call** | 0 (lewat UI) |
| **Baru — Faction (Player)** | 9 |
| **Baru — Faction (Leader)** | 12 |
| **Baru — Faction (Admin)** | 7 |
| **Baru — Job (Player)** | ~15 |
| **Baru — Job (Admin)** | 6 |
| **Baru — Property (Player)** | ~16 |
| **Baru — Property (Admin)** | 9 |
| **TOTAL BARU** | **~77** |
| | |
| **GRAND TOTAL** | **~143** |

---

## Catatan Penting

- **Map Policy**: Tidak ada static marker di map. Navigasi hanya via GPS (phone app), work marker saat duty, atau serlok (share location) dari teman via WitApp.
- **Nama Kota**: Mekar Pura (LS), Madya Raya (LV), Mojosono (SF).
- **Phone Call** tidak punya command sendiri — sepenuhnya lewat UI WitApp.
- **Mechanic** = fraksi, jadi pakai command fraksi standar + command khusus repair.
- **Mall Pelayanan** menggunakan sistem interior + dynamic NPC. Player tekan **F** di pintu masuk untuk masuk, lalu datangi loket NPC dan ketik `/layanan`. Admin setup sepenuhnya via dialog: `/mallsetup` → Buat (pilih kota) → Edit (Interior/NPC) → selesai. Nama mall otomatis dari kota (Mekar Pura, Madya Raya, Mojosono). Command lama (`/setmall`, `/mallnpc`, dll) tetap ada sebagai shortcut.
- **Kuota** sudah ada di sistem (`pKuota`, stored in KB). Telepon potong dari kuota ini.
- Command baru bisa berubah/bertambah saat proses coding. Dokumen ini akan di-update.

---

*Terakhir diperbarui: 2 Maret 2026*
