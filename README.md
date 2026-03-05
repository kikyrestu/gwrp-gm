# 🏙️ GWRP — GTA Westfield Roleplay Gamemode

**Server SA-MP Heavy Roleplay** berbasis [open.mp](https://open.mp) v1.5.8.3  
Platform: **open.mp** (kompatibel SA-MP 0.3.7 client)

---

## 📋 Daftar Isi

- [Tentang Project](#-tentang-project)
- [Tech Stack](#-tech-stack)
- [Fitur yang Sudah Diimplementasi](#-fitur-yang-sudah-diimplementasi)
- [Struktur Folder](#-struktur-folder)
- [Sistem Admin](#-sistem-admin)
- [Daftar Modul](#-daftar-modul)
- [Database](#-database)
- [Instalasi & Setup](#-instalasi--setup)
- [Kompilasi](#-kompilasi)
- [Kredit](#-kredit)

---

## 🎮 Tentang Project

GWRP (GTA Westfield Roleplay) adalah gamemode Heavy RP untuk server SA-MP yang berjalan di atas platform **open.mp**. Gamemode ini dibangun dengan arsitektur modular, setiap fitur dipisahkan ke file modul masing-masing untuk kemudahan maintenance dan pengembangan.

Gamemode ini dikembangkan dari base [SA-MP-0.3.7-Simple-Gamemode](https://github.com/lexjusto/SA-MP-0.3.7-Simple-Gamemode) oleh lexjusto, kemudian dikembangkan secara signifikan menjadi full Heavy RP gamemode.

---

## 🛠️ Tech Stack

| Komponen | Versi | Keterangan |
|----------|-------|------------|
| **open.mp** | v1.5.8.3079 | Server platform (pengganti SA-MP server) |
| **Pawn Compiler** | pawncc 3.10.11 | Compiler bahasa Pawn |
| **MySQL** | 8.4.3 (Laragon) | Database utama |
| **MySQL Plugin** | R39-3 (pBlueG) | Koneksi MySQL dari Pawn |
| **Streamer Plugin** | v2.9.6 (Incognito) | Dynamic objects, pickups, dll |
| **sscanf** | v2.13.8 | Parser parameter command |
| **Texture Studio** | v1.9d (Pottus) | Mapping tool (filterscript) |

---

## ✅ Fitur yang Sudah Diimplementasi

### 🔐 Sistem Akun & Autentikasi
- Registrasi & login dengan MySQL (password hashed)
- Penyimpanan data karakter persisten (HP, posisi, uang, skin, dll)
- Sistem spawn dengan pilihan lokasi

### 👤 Sistem Karakter
- **KTP (Kartu Tanda Penduduk)** — Pengurusan KTP di Mall Pelayanan dengan NPC petugas
  - Data KTP: nama lengkap, tempat lahir, alamat, status perkawinan, pekerjaan, golongan darah
  - Sistem antrian dengan limit per-mall
- **SIM (Surat Izin Mengemudi)** — Ujian SIM di SIM station
  - SIM Tipe A, B, C dengan quiz system (10 soal, passing score 7)
- **Hunger & Thirst System** — Sistem lapar dan haus yang berkurang secara berkala
- **Inventory System** — Sistem inventaris item player

### 📱 Sistem Handphone
Smartphone in-game dengan beberapa aplikasi:
- **WhatsApp** — Kirim pesan, kontak, chat history
- **Twitter** — Registrasi akun, compose tweet, timeline, komentar
- **Marketplace** — Jual beli item antar player, NPC shop
- **M-Banking** — Deposit, withdraw, transfer, riwayat transaksi, cek kuota
- **GPS** — Navigasi ke lokasi-lokasi penting
- **Notepad** — Catatan pribadi player
- **GoFood** — Pesan makanan/minuman delivery
- **Phone Call** — Panggilan telepon antar player

### 🏦 Sistem Finansial
- **Bank System** — Tabungan bank dengan bunga, deposit, withdraw, transfer
- **ATM System** — ATM tersebar di peta, bisa di-setup admin
- **Wallet System** — Uang tunai vs saldo bank
- **M-Banking** — Transaksi bank via handphone

### 🏢 Sistem Properti
- Jual beli properti (rumah, toko, dll)
- Interior custom per properti
- Lockable doors
- Admin management (create, delete, set interior)

### 🚪 Sistem Interior
- Interior dinamis yang bisa di-setup admin
- Titik masuk & keluar yang bisa dikustomisasi
- Support multiple interior ID GTA built-in

### 🏥 Sistem Rumah Sakit
- **Sistem Pingsan (Injured)** — Player pingsan saat HP habis, bukan langsung mati
- **Revive System** — Player bisa di-revive pemain lain atau oleh admin
- **Hospital Mapping** — Interior rumah sakit custom
- **Death Drop** — Sistem drop item saat mati

### 👥 Sistem Fraksi
- Pembuatan fraksi dengan HQ, budget, payday interval
- Sistem jabatan/rank dalam fraksi
- Manajemen anggota
- Budget & payday system

### 📍 Sistem Lokasi
- Lokasi teleport dinamis (bisa dibuat/hapus admin)
- Icon map untuk tiap lokasi
- Pencarian lokasi via dialog
- Tipe-tipe lokasi (publik, fraksi, dll)

### 🏪 Sistem Mall Pelayanan
- Mall Pelayanan sebagai tempat pengurusan KTP
- Setup posisi mall oleh admin (create/move/delete)
- NPC petugas di dalam mall
- Interior mall menggunakan GTA built-in interior (fix bug jatuh)
- Preview interior sebelum di-set

### 🎙️ Sistem HT Radio
- Handy Talky radio komunikasi
- Set frekuensi custom
- Komunikasi antar player di frekuensi yang sama

### 🗺️ Mapping Tools
- **Texture Studio v1.9d** — Filterscript mapping tool terintegrasi
- Akses via `/tstudio` in-game

### 🖥️ HUD System
- Custom HUD untuk menampilkan info player
- Textdraw-based interface

### ✈️ Fly Mode
- Noclip/fly mode untuk admin (`/fly`)

### 🍔 GoFood System
- Sistem pesan antar makanan
- Locker GoFood yang bisa di-setup admin
- Konfirmasi pesanan, kode pickup

---

## 📁 Struktur Folder

```
gwrp-gm/
├── gamemodes/
│   ├── new.pwn              # Main gamemode entry point
│   └── modules/             # Modul-modul terpisah
│       ├── defines.pwn      # Konstanta, define, dialog IDs
│       ├── database.pwn     # Koneksi & query MySQL
│       ├── account.pwn      # Registrasi, login, save data
│       ├── spawn.pwn        # Spawn system
│       ├── commands.pwn     # Command umum player
│       ├── admin.pwn        # Semua command admin + help
│       ├── utils.pwn        # Utility functions
│       ├── hud.pwn          # HUD textdraw
│       ├── hunger.pwn       # Hunger & thirst system
│       ├── inventory.pwn    # Inventory system
│       ├── wallet.pwn       # Wallet (uang tunai)
│       ├── bank.pwn         # Bank & ATM system
│       ├── property.pwn     # Properti system
│       ├── interiors.pwn    # Interior dinamis
│       ├── locations.pwn    # Teleport locations
│       ├── factions.pwn     # Fraksi system
│       ├── jobs.pwn         # Job system
│       ├── ktp_service.pwn  # KTP & Mall Pelayanan
│       ├── sim_service.pwn  # SIM license system
│       ├── gofood.pwn       # GoFood delivery system
│       ├── ht_radio.pwn     # HT Radio system
│       ├── flymode.pwn      # Admin fly/noclip
│       ├── hospital_mapping.pwn # Hospital interior
│       ├── phone.pwn        # Phone base system
│       ├── phone_wa.pwn     # WhatsApp
│       ├── phone_call.pwn   # Phone call
│       ├── phone_twitter.pwn # Twitter
│       ├── phone_market.pwn # Marketplace
│       ├── phone_bank.pwn   # M-Banking
│       ├── phone_gps.pwn    # GPS
│       ├── phone_notepad.pwn # Notepad
│       └── phone_settings.pwn # Phone settings
├── filterscripts/
│   └── tstudio/             # Texture Studio support files
│       └── tstudio.amx      # Texture Studio filterscript
├── include/                 # Include files (.inc)
├── models/                  # Custom model files (.dff, .txd)
├── scriptfiles/             # Server data files
│   ├── properties/          # Property data
│   └── vehicles/            # Vehicle data
├── plugins/                 # Server plugins (.dll/.so)
├── config.json              # open.mp server configuration
├── accounts.sql             # Database schema (akun)
├── migrations.sql           # Database migration scripts
└── README.md                # Dokumentasi ini
```

---

## 🛡️ Sistem Admin

Menggunakan sistem hierarki **3 level**:

| Level | Nama | Akses |
|-------|------|-------|
| **1** | **Management** | Moderasi, kick/ban/jail, freeze/mute, teleport, spawn kendaraan, pengumuman, kelola lokasi/properti/fraksi |
| **2** | **DevMap** | Semua Management + setup server (mall, bank, ATM, interior, SIM station, GoFood locker), mapping tools, fly mode, set admin |
| **3** | **Developer** | Akses penuh — sama dengan DevMap (level tertinggi) |

### Command Help In-Game
| Command | Level | Deskripsi |
|---------|-------|-----------|
| `/mhelp` | Management+ | Daftar semua perintah Management dalam dialog |
| `/dmhelp` | DevMap+ | Daftar semua perintah DevMap dalam dialog |
| `/dhelp` | Developer | Daftar perintah Developer + referensi ke level lain |

### Daftar Command Admin Lengkap

<details>
<summary><b>Management (Level 1) — 34 perintah</b></summary>

**Moderasi:**
| Command | Deskripsi |
|---------|-----------|
| `/a [pesan]` | Chat khusus admin |
| `/aduty` | Toggle mode admin duty |
| `/reports` | Melihat daftar laporan aktif |
| `/check [id]` | Melihat info detail player |
| `/spec [id]` | Spectate/mengawasi player |

**Hukuman:**
| Command | Deskripsi |
|---------|-----------|
| `/kick [id] [alasan]` | Kick player dari server |
| `/ban [id] [alasan]` | Ban player dari server |
| `/unban [nama]` | Mencabut ban player |
| `/warn [id] [alasan]` | Memberikan peringatan |
| `/mute [id]` | Toggle mute/unmute player |
| `/freeze [id]` | Toggle freeze/unfreeze player |
| `/jail [id] [menit]` | Memasukkan ke penjara |
| `/unjail [id]` | Membebaskan dari penjara |

**Utilitas:**
| Command | Deskripsi |
|---------|-----------|
| `/goto [id]` | Teleport ke posisi player |
| `/gethere [id]` | Teleport player ke posisi admin |
| `/slap [id]` | Melempar player ke atas |
| `/setskin [id] [skin]` | Mengubah skin player |
| `/setmoney [id] [jumlah]` | Mengatur uang player |
| `/sethealth [id] [hp]` | Mengatur HP player |
| `/setlevel [id] [level]` | Mengubah level player |
| `/veh [model]` | Spawn kendaraan |
| `/destroyveh` | Hancurkan kendaraan yang ditumpangi |
| `/ann [teks]` | Pengumuman global |

**Lokasi & Properti & Fraksi:**
| Command | Deskripsi |
|---------|-----------|
| `/locs` | Daftar semua lokasi |
| `/gotoloc [id]` | Teleport ke lokasi |
| `/createproperty` | Membuat properti baru |
| `/deleteproperty` | Menghapus properti |
| `/setpropinterior` | Atur interior properti |
| `/proplist` | Daftar semua properti |
| `/factions` | Daftar semua fraksi |
| `/finfo` | Info detail fraksi |
| `/createfaction` | Buat fraksi baru |
| `/deletefaction` | Hapus fraksi |
| `/fsetbudget` | Atur budget fraksi |
| `/fsethq` | Atur lokasi HQ fraksi |
| `/fsetpaydayinterval` | Atur interval payday fraksi |

</details>

<details>
<summary><b>DevMap (Level 2) — 41+ perintah</b></summary>

*Termasuk semua perintah Management, ditambah:*

**Admin & Server:**
| Command | Deskripsi |
|---------|-----------|
| `/setadmin [id] [level]` | Ubah level admin player (0-3) |
| `/serverinfo` | Statistik server |
| `/setweather [id]` | Ubah cuaca server |
| `/settime [jam]` | Ubah waktu server |

**Player Tools:**
| Command | Deskripsi |
|---------|-----------|
| `/givemoney [id] [jumlah]` | Beri uang ke player |
| `/giveitem [id] [item]` | Beri item ke player |
| `/resetplayer [id]` | Reset semua data player |
| `/setint [id] [interior]` | Ubah interior player |
| `/setvw [id] [vw]` | Ubah virtual world player |
| `/heal` | Self-heal/revive diri sendiri |

**Navigasi & Mapping:**
| Command | Deskripsi |
|---------|-----------|
| `/getpos` | Tampilkan koordinat posisi saat ini |
| `/gotopos [x] [y] [z]` | Teleport ke koordinat |
| `/fly` | Toggle mode terbang/noclip |
| `/tp` | TP ke lokasi via dialog pencarian |
| `/createloc` | Buat lokasi baru |
| `/deleteloc` | Hapus lokasi terdekat |
| `/editloc` | Edit nama lokasi |
| `/tstudio` | Buka Texture Studio (filterscript) |

**Setup Mall & KTP:**
| Command | Deskripsi |
|---------|-----------|
| `/mallsetup` | Dialog setup Mall Pelayanan |
| `/setmall` | Buat Mall Pelayanan baru |
| `/delmall` | Hapus Mall Pelayanan |
| `/movemall` | Pindahkan Mall Pelayanan |
| `/malllist` | Daftar semua Mall Pelayanan |
| `/previewinterior` | Preview interior mall |
| `/setmallinterior` | Atur interior mall |
| `/mallnpc` | Pasang NPC di mall |
| `/delmallnpc` | Hapus NPC mall |
| `/mallnpclist` | Daftar NPC di mall |

**Setup Bank & ATM:**
| Command | Deskripsi |
|---------|-----------|
| `/setatm` | Buat ATM baru |
| `/delatm` | Hapus ATM |
| `/moveatm` | Pindahkan ATM |
| `/atmlist` | Daftar semua ATM |
| `/setbank` | Buat lokasi bank baru |
| `/delbank` | Hapus lokasi bank |
| `/movebank` | Pindahkan bank |
| `/banklist` | Daftar semua bank |

**Setup Interior:**
| Command | Deskripsi |
|---------|-----------|
| `/setinterior` | Buat interior baru (set titik masuk) |
| `/setinteriorexit` | Set titik keluar interior |
| `/delinterior` | Hapus interior |
| `/interiorlist` | Daftar semua interior |
| `/gotointerior` | TP ke pintu masuk interior |

**Setup SIM & GoFood:**
| Command | Deskripsi |
|---------|-----------|
| `/setsimstation` | Buat SIM station baru |
| `/delsimstation` | Hapus SIM station |
| `/simstationlist` | Daftar semua SIM station |
| `/setlocker` | Buat locker GoFood baru |
| `/dellocker` | Hapus locker GoFood |
| `/movelocker` | Pindahkan locker GoFood |
| `/lockerlist` | Daftar semua locker GoFood |
| `/gotolocker` | TP ke locker GoFood |

</details>

---

## 📦 Daftar Modul

| Modul | File | Deskripsi |
|-------|------|-----------|
| Defines | `defines.pwn` | Konstanta, makro, dialog ID, warna |
| Database | `database.pwn` | Koneksi MySQL, tabel setup |
| Account | `account.pwn` | Register, login, save player data |
| Spawn | `spawn.pwn` | Spawn system & class selection |
| Commands | `commands.pwn` | Command umum player |
| Admin | `admin.pwn` | Semua command admin, admin chat, admin duty, help dialogs |
| Utils | `utils.pwn` | Fungsi utilitas (format, distance, dll) |
| HUD | `hud.pwn` | HUD textdraw system |
| Hunger | `hunger.pwn` | Hunger & thirst system |
| Inventory | `inventory.pwn` | Item inventory system |
| Wallet | `wallet.pwn` | Uang tunai (cash on hand) |
| Bank | `bank.pwn` | Bank & ATM system |
| Property | `property.pwn` | Properti system |
| Interiors | `interiors.pwn` | Interior dinamis |
| Locations | `locations.pwn` | Teleport locations |
| Factions | `factions.pwn` | Fraksi system |
| Jobs | `jobs.pwn` | Job system |
| KTP Service | `ktp_service.pwn` | KTP & Mall Pelayanan |
| SIM Service | `sim_service.pwn` | SIM license system |
| GoFood | `gofood.pwn` | GoFood delivery system |
| HT Radio | `ht_radio.pwn` | HT Radio system |
| Fly Mode | `flymode.pwn` | Admin fly/noclip |
| Hospital | `hospital_mapping.pwn` | Hospital interior mapping |
| Phone | `phone.pwn` | Phone base system & UI |
| Phone WA | `phone_wa.pwn` | WhatsApp messaging |
| Phone Call | `phone_call.pwn` | Phone call system |
| Phone Twitter | `phone_twitter.pwn` | Twitter social media |
| Phone Market | `phone_market.pwn` | Marketplace jual beli |
| Phone Bank | `phone_bank.pwn` | M-Banking via HP |
| Phone GPS | `phone_gps.pwn` | GPS navigasi |
| Phone Notepad | `phone_notepad.pwn` | Notepad catatan |
| Phone Settings | `phone_settings.pwn` | Pengaturan HP |

---

## 🗄️ Database

**Engine:** MySQL 8.4  
**Database:** `astawnew`

### Tabel Utama
- `accounts` — Data akun & karakter player
- `properties` — Data properti
- `interiors` — Interior dinamis
- `locations` — Lokasi teleport
- `factions` — Data fraksi
- `faction_members` — Anggota fraksi
- `atm_locations` — Posisi ATM
- `bank_locations` — Posisi bank
- `sim_stations` — Posisi SIM station
- `mall_pelayanan` — Data Mall Pelayanan
- `mall_npcs` — NPC petugas mall
- `gofood_lockers` — Locker GoFood
- `bank_transactions` — Riwayat transaksi bank
- `twitter_users` — Akun Twitter in-game
- `twitter_tweets` — Tweet & komentar
- `twitter_comments` — Komentar tweet
- `market_listings` — Listing marketplace
- `wa_contacts` — Kontak WhatsApp
- `wa_messages` — Pesan WhatsApp
- `notepad_notes` — Catatan notepad
- `inventories` — Inventori player

File migrasi: `accounts.sql`, `migrations.sql`

---

## 🚀 Instalasi & Setup

### Prasyarat
- [open.mp server](https://open.mp) v1.5.x+
- MySQL 8.x (bisa pakai [Laragon](https://laragon.org))
- Pawn compiler (pawncc 3.10.x)

### Langkah Instalasi

1. **Clone repository:**
   ```bash
   git clone https://github.com/kikyrestu/gwrp-gm.git
   cd gwrp-gm
   ```

2. **Download open.mp server:**
   - Ambil dari [open.mp releases](https://github.com/openmultiplayer/open.mp/releases)
   - Letakkan `omp-server.exe`, folder `components/` dan `bin/` di root

3. **Download plugins:**
   - [MySQL R39-3](https://github.com/pBlueG/SA-MP-MySQL/releases) → `plugins/mysql.dll`
   - [Streamer v2.9.6](https://github.com/samp-incognito/samp-streamer-plugin/releases) → `plugins/streamer.dll`
   - [sscanf v2.13.8](https://github.com/Y-Less/sscanf/releases) → `plugins/sscanf.dll`

4. **Setup database:**
   ```sql
   CREATE DATABASE astawnew;
   ```
   Import file SQL:
   ```bash
   mysql -u root astawnew < accounts.sql
   mysql -u root astawnew < migrations.sql
   ```

5. **Konfigurasi `config.json`:**
   - Sesuaikan password MySQL di `database.pwn`
   - Sesuaikan `rcon.password` di `config.json`

6. **Download compiler:**
   - [pawncc 3.10.11](https://github.com/pawn-lang/compiler/releases)
   - Letakkan di folder `compiler/`

7. **Kompilasi & jalankan:**
   ```bash
   compiler/pawnc-3.10.11-windows/bin/pawncc.exe gamemodes/new.pwn -ogamemodes/new.amx -ipawno/include -iinclude -d3
   ./omp-server.exe
   ```

---

## 🔨 Kompilasi

```powershell
# Windows (PowerShell)
.\compiler\pawnc-3.10.11-windows\bin\pawncc.exe gamemodes\new.pwn -ogamemodes\new.amx -ipawno\include -iinclude -d3
```

Output: `gamemodes/new.amx`

---

## 📝 Changelog Implementasi

### Sistem Inti
- ✅ Sistem registrasi & login MySQL
- ✅ Penyimpanan data karakter persisten
- ✅ Spawn system dengan pilihan lokasi
- ✅ Arsitektur modular (38 file modul)

### Roleplay Features
- ✅ KTP System (pengurusan di Mall Pelayanan dengan NPC)
- ✅ SIM System (ujian quiz tipe A/B/C)
- ✅ Hunger & Thirst system
- ✅ Inventory system
- ✅ Bank & ATM system
- ✅ M-Banking (via handphone)
- ✅ Property system (beli/jual/interior)
- ✅ Interior system dinamis
- ✅ Faction system (HQ, budget, payday)
- ✅ Location system (teleport dinamis)
- ✅ GoFood delivery system
- ✅ HT Radio communication
- ✅ Hospital & injured/revive system

### Smartphone System
- ✅ WhatsApp — messaging, kontak
- ✅ Twitter — tweet, comment, timeline
- ✅ Marketplace — jual beli item
- ✅ M-Banking — deposit, withdraw, transfer
- ✅ GPS — navigasi lokasi
- ✅ Notepad — catatan pribadi
- ✅ GoFood — pesan makanan
- ✅ Phone Call — panggilan telepon

### Admin System
- ✅ Hierarki 3 level: Management → DevMap → Developer
- ✅ 75+ command admin
- ✅ Help dialog per level (`/mhelp`, `/dmhelp`, `/dhelp`)
- ✅ Admin duty mode
- ✅ Admin chat (`/a`)
- ✅ Report system

### Mapping & Tools
- ✅ Texture Studio v1.9d terintegrasi
- ✅ Fly/noclip mode
- ✅ Hospital interior mapping
- ✅ Mall interior (GTA built-in, fix bug jatuh)

### Bug Fixes
- ✅ Fix mall interior jatuh (switch ke GTA built-in interior)
- ✅ Fix F/Enter spam "Tidak ada pemain pingsan"
- ✅ Fix NPC placement stuck (geser player 1.5m ke belakang)

---

## 👥 Kredit

- **Base Gamemode:** [lexjusto/SA-MP-0.3.7-Simple-Gamemode](https://github.com/lexjusto/SA-MP-0.3.7-Simple-Gamemode)
- **open.mp:** [open.mp Team](https://open.mp)
- **MySQL Plugin:** [pBlueG](https://github.com/pBlueG/SA-MP-MySQL)
- **Streamer Plugin:** [Incognito](https://github.com/samp-incognito/samp-streamer-plugin)
- **sscanf:** [Y_Less](https://github.com/Y-Less/sscanf)
- **Texture Studio:** [Pottus](https://github.com/Starter74/Texture-Studio)

---

## 📄 Lisensi

Project ini dikembangkan untuk keperluan private server. Penggunaan base gamemode tunduk pada lisensi dari repository asli.
