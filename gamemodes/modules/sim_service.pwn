// ============================================================================
// MODULE: sim_service.pwn
// SIM (Surat Izin Mengemudi) License system
// Player visits police station NPC, must have KTP, takes quiz, gets SIM
// Quiz: 10 multiple choice questions, need >= 70% (7/10) to pass
// SIM types: A (Mobil), B (Truk/Bus), C (Motor)
// Dev-managed station locations via /setsimstation etc.
// ============================================================================

// ============================================================================
// QUIZ QUESTIONS
// ============================================================================

enum eSIMQuiz {
    sqQuestion[128],
    sqOption1[48],
    sqOption2[48],
    sqOption3[48],
    sqCorrect // 0, 1, or 2 (index of correct answer)
};

new const SIMQuizPool[][eSIMQuiz] = {
    {"Apa arti lampu lalu lintas berwarna kuning?", "Berhenti segera", "Bersiap-siap / hati-hati", "Boleh jalan terus", 1},
    {"Batas kecepatan di area pemukiman adalah?", "60 km/jam", "30 km/jam", "80 km/jam", 1},
    {"Saat menyalip kendaraan, dari sisi mana yang benar?", "Kiri", "Kanan", "Boleh keduanya", 1},
    {"Apa yang harus dilakukan saat lampu merah?", "Klakson terus", "Berhenti di belakang garis", "Maju pelan-pelan", 1},
    {"Kapan harus menyalakan lampu sein?", "Saat akan berbelok atau pindah jalur", "Saat macet saja", "Tidak perlu", 0},
    {"Siapa yang harus didahulukan di zebra cross?", "Kendaraan", "Pejalan kaki", "Motor", 1},
    {"Apa fungsi spion pada kendaraan?", "Hiasan", "Melihat kendaraan di belakang", "Melihat ke depan", 1},
    {"Tanda dilarang parkir berbentuk apa?", "Segitiga merah", "Lingkaran merah coret", "Kotak biru", 1},
    {"Saat hujan deras, apa yang harus dilakukan?", "Gas pol", "Kurangi kecepatan, nyalakan lampu", "Matikan lampu", 1},
    {"Apa itu jalur busway?", "Jalur umum semua kendaraan", "Jalur khusus bus TransJakarta", "Jalur sepeda", 1},
    {"Batas minimum umur untuk SIM A adalah?", "15 tahun", "17 tahun", "21 tahun", 1},
    {"Apa arti rambu segitiga terbalik berwarna merah?", "Dilarang masuk", "Yield / beri jalan", "Jalan satu arah", 1},
    {"Saat malam hari, lampu apa yang wajib dinyalakan?", "Lampu hazard", "Lampu utama (headlight)", "Lampu kabin", 1},
    {"Jika rem blong, apa yang harus dilakukan?", "Loncat keluar", "Turunkan gigi, gunakan rem tangan", "Gas terus", 1},
    {"Apa tujuan sabuk pengaman?", "Gaya-gayaan", "Melindungi saat kecelakaan", "Agar tidak ditilang saja", 1},
    {"Jarak aman mengikuti kendaraan depan minimal?", "1 meter", "3 detik jarak", "Sedekat mungkin", 1},
    {"Apa yang dimaksud blind spot?", "Titik buta spion", "Lampu mati", "Ban bocor", 0},
    {"Kendaraan darurat (ambulan/pemadam) lewat, apa yang harus dilakukan?", "Klakson balik", "Minggir dan beri jalan", "Ikuti dari belakang", 1},
    {"Apa hukuman mengemudi tanpa SIM?", "Tidak ada", "Denda dan/atau kurungan", "Hanya teguran", 1},
    {"Kapan boleh menggunakan klakson?", "Saat macet untuk buru-buru", "Saat perlu memberi peringatan bahaya", "Kapan saja", 1}
};

// Player's randomized quiz indices (10 questions picked from pool)
new PlayerSIMQuizOrder[MAX_PLAYERS][SIM_QUIZ_TOTAL];

// ============================================================================
// LOAD SIM STATIONS FROM DB
// ============================================================================

stock LoadSIMStations()
{
    mysql_function_query(MySQL_C1, "SELECT * FROM `sim_stations` ORDER BY `id` ASC", true, "OnSIMStationsLoaded", "");
}

publics: OnSIMStationsLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalSIMStations = 0;
    for(new i = 0; i < rows && i < MAX_SIM_STATIONS; i++)
    {
        SIMStationData[i][simDBID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", SIMStationData[i][simName], MySQL_C1, 48);
        SIMStationData[i][simX] = cache_get_field_content_float(i, "pos_x", MySQL_C1);
        SIMStationData[i][simY] = cache_get_field_content_float(i, "pos_y", MySQL_C1);
        SIMStationData[i][simZ] = cache_get_field_content_float(i, "pos_z", MySQL_C1);
        SIMStationData[i][simAngle] = cache_get_field_content_float(i, "angle", MySQL_C1);
        SIMStationData[i][simInterior] = cache_get_field_content_int(i, "interior_id", MySQL_C1);
        SIMStationData[i][simVW] = cache_get_field_content_int(i, "vw", MySQL_C1);
        CreateSIMStationWorld(i);
        TotalSIMStations++;
    }
    printf("[SIM] SIM Stations loaded: %d locations.", TotalSIMStations);
}

stock CreateSIMStationWorld(idx)
{
    // Police NPC actor
    SIMStationData[idx][simActorID] = CreateActor(280, SIMStationData[idx][simX], SIMStationData[idx][simY], SIMStationData[idx][simZ], SIMStationData[idx][simAngle]);
    SetActorVirtualWorld(SIMStationData[idx][simActorID], SIMStationData[idx][simVW]);

    // Pickup
    SIMStationData[idx][simPickupID] = CreatePickup(1239, 23, SIMStationData[idx][simX], SIMStationData[idx][simY], SIMStationData[idx][simZ], SIMStationData[idx][simVW]);

    // 3D Label
    new lbl[128];
    format(lbl, sizeof(lbl), "{4169E1}Pelayanan SIM\n{FFFFFF}%s\n{CCCCCC}Ketik /sim", SIMStationData[idx][simName]);
    SIMStationData[idx][simLabelID] = Create3DTextLabel(lbl, 0x4169E1FF, SIMStationData[idx][simX], SIMStationData[idx][simY], SIMStationData[idx][simZ] + 0.8, 10.0, SIMStationData[idx][simVW]);
}

stock DestroySIMStationWorld(idx)
{
    if(SIMStationData[idx][simActorID] != INVALID_ACTOR_ID) { DestroyActor(SIMStationData[idx][simActorID]); SIMStationData[idx][simActorID] = INVALID_ACTOR_ID; }
    if(SIMStationData[idx][simPickupID]) { DestroyPickup(SIMStationData[idx][simPickupID]); SIMStationData[idx][simPickupID] = 0; }
    if(SIMStationData[idx][simLabelID] != Text3D:INVALID_3DTEXT_ID) { Delete3DTextLabel(SIMStationData[idx][simLabelID]); SIMStationData[idx][simLabelID] = Text3D:INVALID_3DTEXT_ID; }
}

// ============================================================================
// CHECK NEAR SIM STATION
// ============================================================================

stock IsPlayerNearSIMStation(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new pint = GetPlayerInterior(playerid);
    new pvw = GetPlayerVirtualWorld(playerid);
    for(new i = 0; i < TotalSIMStations; i++)
    {
        if(pint != SIMStationData[i][simInterior]) continue;
        if(pvw != SIMStationData[i][simVW]) continue;
        new Float:dist = floatsqroot((px - SIMStationData[i][simX]) * (px - SIMStationData[i][simX]) + (py - SIMStationData[i][simY]) * (py - SIMStationData[i][simY]) + (pz - SIMStationData[i][simZ]) * (pz - SIMStationData[i][simZ]));
        if(dist <= 3.0) return 1;
    }
    return 0;
}

// ============================================================================
// SIM COMMAND
// ============================================================================

COMMAND:sim(playerid, params[])
{
    if(!IsPlayerNearSIMStation(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak berada di dekat loket SIM!"), true;

    if(!PlayerInfo[playerid][pHasKTP])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu harus punya KTP terlebih dahulu! Buat di Mall Pelayanan Kota."), true;

    // Show SIM service options
    new menustr[256];
    menustr[0] = EOS;

    new hasA = PlayerInfo[playerid][pHasSIMA];
    new hasB = PlayerInfo[playerid][pHasSIMB];
    new hasC = PlayerInfo[playerid][pHasSIMC];

    if(hasA && hasB && hasC)
    {
        SendClientFormattedMessage(playerid, 0x4169E1FF, "[SIM] Kamu sudah memiliki semua jenis SIM (A, B, C).");
        return true;
    }

    if(!hasA) strcat(menustr, "SIM A - Mobil\n");
    if(!hasB) strcat(menustr, "SIM B - Truk / Bus\n");
    if(!hasC) strcat(menustr, "SIM C - Motor\n");

    ShowPlayerDialog(playerid, DIALOG_SIM_TYPE, DIALOG_STYLE_LIST,
        "{4169E1}Pelayanan SIM - Pilih Jenis",
        menustr, "Pilih", "Batal");
    return true;
}

// ============================================================================
// DIALOG HANDLERS
// ============================================================================

stock HandleSIMDialogs(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    if(dialogid == DIALOG_SIM_TYPE)
    {
        if(!response) return 1;

        new hasA = PlayerInfo[playerid][pHasSIMA];
        new hasB = PlayerInfo[playerid][pHasSIMB];

        // Map listitem to actual SIM type based on which ones are available
        new simtype = 0;
        new idx = 0;
        if(!hasA) { if(idx == listitem) { simtype = SIM_TYPE_A; } idx++; }
        if(!hasB) { if(idx == listitem) { simtype = SIM_TYPE_B; } idx++; }
        if(!PlayerInfo[playerid][pHasSIMC]) { if(idx == listitem) { simtype = SIM_TYPE_C; } }

        if(simtype == 0) return 1;

        PlayerInfo[playerid][pSIMQuizType] = simtype;
        PlayerInfo[playerid][pSIMQuizScore] = 0;
        PlayerInfo[playerid][pSIMQuizQuestion] = 0;

        // Randomize quiz order - pick 10 from pool
        RandomizeSIMQuiz(playerid);

        new typename[16];
        GetSIMTypeName(simtype, typename, sizeof(typename));
        SendClientFormattedMessage(playerid, 0x4169E1FF, "[SIM] Ujian tertulis %s dimulai! Jawab %d soal, minimal benar %d.", typename, SIM_QUIZ_TOTAL, SIM_QUIZ_PASS_SCORE);

        ShowNextSIMQuestion(playerid);
        return 1;
    }

    if(dialogid == DIALOG_SIM_QUIZ)
    {
        if(!response)
        {
            SendClientFormattedMessage(playerid, COLOR_RED, "[SIM] Kamu membatalkan ujian SIM.");
            return 1;
        }

        new qidx = PlayerSIMQuizOrder[playerid][PlayerInfo[playerid][pSIMQuizQuestion]];
        if(listitem == SIMQuizPool[qidx][sqCorrect])
        {
            PlayerInfo[playerid][pSIMQuizScore]++;
        }

        PlayerInfo[playerid][pSIMQuizQuestion]++;

        if(PlayerInfo[playerid][pSIMQuizQuestion] < SIM_QUIZ_TOTAL)
        {
            ShowNextSIMQuestion(playerid);
        }
        else
        {
            // Quiz finished - show result
            new score = PlayerInfo[playerid][pSIMQuizScore];
            new simtype = PlayerInfo[playerid][pSIMQuizType];
            new typename[16];
            GetSIMTypeName(simtype, typename, sizeof(typename));

            if(score >= SIM_QUIZ_PASS_SCORE)
            {
                // PASS - give SIM
                switch(simtype)
                {
                    case SIM_TYPE_A: PlayerInfo[playerid][pHasSIMA] = true;
                    case SIM_TYPE_B: PlayerInfo[playerid][pHasSIMB] = true;
                    case SIM_TYPE_C: PlayerInfo[playerid][pHasSIMC] = true;
                }

                // Generate SIM number if not exists
                if(strlen(PlayerInfo[playerid][pSIMNumber]) < 5)
                {
                    GenerateSIMNumber(playerid);
                }

                SaveSIMData(playerid);

                new msg[256];
                format(msg, sizeof(msg), "{FFFFFF}Hasil Ujian %s\n\n{00FF00}LULUS!{FFFFFF}\nSkor: %d / %d\n\nNomor SIM: %s\n\nSelamat! SIM %s kamu sudah aktif.", typename, score, SIM_QUIZ_TOTAL, PlayerInfo[playerid][pSIMNumber], typename);
                ShowPlayerDialog(playerid, DIALOG_SIM_RESULT, DIALOG_STYLE_MSGBOX, "{4169E1}Hasil Ujian SIM", msg, "OK", "");
            }
            else
            {
                // FAIL
                new msg[256];
                format(msg, sizeof(msg), "{FFFFFF}Hasil Ujian %s\n\n{FF0000}TIDAK LULUS{FFFFFF}\nSkor: %d / %d (minimal %d)\n\nCoba lagi nanti.", typename, score, SIM_QUIZ_TOTAL, SIM_QUIZ_PASS_SCORE);
                ShowPlayerDialog(playerid, DIALOG_SIM_RESULT, DIALOG_STYLE_MSGBOX, "{4169E1}Hasil Ujian SIM", msg, "OK", "");
            }
        }
        return 1;
    }

    if(dialogid == DIALOG_SIM_RESULT) return 1;

    return 0;
}

// ============================================================================
// QUIZ HELPERS
// ============================================================================

stock RandomizeSIMQuiz(playerid)
{
    new poolsize = sizeof(SIMQuizPool);
    new used[20]; // max pool size
    for(new i = 0; i < poolsize; i++) used[i] = 0;

    for(new i = 0; i < SIM_QUIZ_TOTAL; i++)
    {
        new pick;
        do {
            pick = random(poolsize);
        } while(used[pick]);
        used[pick] = 1;
        PlayerSIMQuizOrder[playerid][i] = pick;
    }
}

stock ShowNextSIMQuestion(playerid)
{
    new qnum = PlayerInfo[playerid][pSIMQuizQuestion];
    new qidx = PlayerSIMQuizOrder[playerid][qnum];

    new title[64];
    format(title, sizeof(title), "{4169E1}Ujian SIM - Soal %d/%d", qnum + 1, SIM_QUIZ_TOTAL);

    new body[256];
    format(body, sizeof(body), "{FFFFFF}%s", SIMQuizPool[qidx][sqQuestion]);

    new options[192];
    format(options, sizeof(options), "%s\n%s\n%s", SIMQuizPool[qidx][sqOption1], SIMQuizPool[qidx][sqOption2], SIMQuizPool[qidx][sqOption3]);

    ShowPlayerDialog(playerid, DIALOG_SIM_QUIZ, DIALOG_STYLE_LIST, title, options, "Jawab", "Batal");
    SendClientFormattedMessage(playerid, 0x4169E1FF, "[Soal %d] %s", qnum + 1, SIMQuizPool[qidx][sqQuestion]);
}

stock GetSIMTypeName(simtype, dest[], len)
{
    switch(simtype)
    {
        case SIM_TYPE_A: format(dest, len, "SIM A");
        case SIM_TYPE_B: format(dest, len, "SIM B");
        case SIM_TYPE_C: format(dest, len, "SIM C");
        default: format(dest, len, "SIM");
    }
}

stock GenerateSIMNumber(playerid)
{
    new num[16];
    format(num, sizeof(num), "%d%d%d%d%d%d%d%d%d%d%d%d",
        random(9) + 1, random(10), random(10), random(10),
        random(10), random(10), random(10), random(10),
        random(10), random(10), random(10), random(10));
    strmid(PlayerInfo[playerid][pSIMNumber], num, 0, strlen(num), 16);
}

stock SaveSIMData(playerid)
{
    mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `accounts` SET `has_sim_a`='%d',`has_sim_b`='%d',`has_sim_c`='%d',`sim_number`='%e' WHERE `id`='%d'", PlayerInfo[playerid][pHasSIMA], PlayerInfo[playerid][pHasSIMB], PlayerInfo[playerid][pHasSIMC], PlayerInfo[playerid][pSIMNumber], PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, false, "", "");
}

// ============================================================================
// WALLET INTEGRATION - Get SIM info string
// ============================================================================

stock GetSIMInfo(playerid, dest[], len)
{
    new simstr[256];
    simstr[0] = EOS;

    if(!PlayerInfo[playerid][pHasSIMA] && !PlayerInfo[playerid][pHasSIMB] && !PlayerInfo[playerid][pHasSIMC])
    {
        format(dest, len, "{888888}Belum memiliki SIM.");
        return;
    }

    format(simstr, sizeof(simstr), "{FFFFFF}Nomor SIM: {00FF00}%s\n", PlayerInfo[playerid][pSIMNumber]);

    new types[64];
    types[0] = EOS;
    if(PlayerInfo[playerid][pHasSIMA]) strcat(types, "A ");
    if(PlayerInfo[playerid][pHasSIMB]) strcat(types, "B ");
    if(PlayerInfo[playerid][pHasSIMC]) strcat(types, "C ");

    new line2[64];
    format(line2, sizeof(line2), "{FFFFFF}Golongan: {00FF00}%s\n", types);
    strcat(simstr, line2);

    new line3[64];
    format(line3, sizeof(line3), "{FFFFFF}Nama: {00FF00}%s\n", PlayerInfo[playerid][pKTPFullName]);
    strcat(simstr, line3);

    strmid(dest, simstr, 0, strlen(simstr), len);
}

// ============================================================================
// DEVELOPER COMMANDS
// ============================================================================

COMMAND:setsimstation(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TotalSIMStations >= MAX_SIM_STATIONS) return SendClientFormattedMessage(playerid, COLOR_RED, "Max SIM stations tercapai."), true;

    new sname[48];
    if(sscanf(params, "s[48]", sname)) format(sname, sizeof(sname), "Kantor Polisi");

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    new pint = GetPlayerInterior(playerid);
    new pvw = GetPlayerVirtualWorld(playerid);

    mysql_format(MySQL_C1, query, sizeof(query), "INSERT INTO `sim_stations` (`name`,`pos_x`,`pos_y`,`pos_z`,`angle`,`interior_id`,`vw`,`created_by`,`created_at`) VALUES ('%e','%f','%f','%f','%f','%d','%d','%e','%d')", sname, px, py, pz, pa, pint, pvw, PlayerName(playerid), gettime());
    mysql_function_query(MySQL_C1, query, true, "OnSIMStationCreated", "ds[48]", playerid, sname);
    return true;
}

publics: OnSIMStationCreated(playerid, sname[])
{
    new idx = TotalSIMStations;
    SIMStationData[idx][simDBID] = cache_insert_id();
    strmid(SIMStationData[idx][simName], sname, 0, strlen(sname), 48);
    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    SIMStationData[idx][simX] = px;
    SIMStationData[idx][simY] = py;
    SIMStationData[idx][simZ] = pz;
    SIMStationData[idx][simAngle] = pa;
    SIMStationData[idx][simInterior] = GetPlayerInterior(playerid);
    SIMStationData[idx][simVW] = GetPlayerVirtualWorld(playerid);
    CreateSIMStationWorld(idx);
    TotalSIMStations++;
    SendClientFormattedMessage(playerid, 0x00CC00FF, "[SIM] Station '%s' #%d berhasil dibuat.", sname, SIMStationData[idx][simDBID]);
    return 1;
}

COMMAND:delsimstation(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    new sid;
    if(sscanf(params, "d", sid)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /delsimstation [DB ID]"), true;

    new found = -1;
    for(new i = 0; i < TotalSIMStations; i++)
    {
        if(SIMStationData[i][simDBID] == sid) { found = i; break; }
    }
    if(found == -1) return SendClientFormattedMessage(playerid, COLOR_RED, "SIM Station ID %d tidak ditemukan.", sid), true;

    DestroySIMStationWorld(found);
    mysql_format(MySQL_C1, query, sizeof(query), "DELETE FROM `sim_stations` WHERE `id` = '%d'", sid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    for(new i = found; i < TotalSIMStations - 1; i++)
    {
        SIMStationData[i][simDBID] = SIMStationData[i+1][simDBID];
        strmid(SIMStationData[i][simName], SIMStationData[i+1][simName], 0, strlen(SIMStationData[i+1][simName]), 48);
        SIMStationData[i][simX] = SIMStationData[i+1][simX];
        SIMStationData[i][simY] = SIMStationData[i+1][simY];
        SIMStationData[i][simZ] = SIMStationData[i+1][simZ];
        SIMStationData[i][simAngle] = SIMStationData[i+1][simAngle];
        SIMStationData[i][simInterior] = SIMStationData[i+1][simInterior];
        SIMStationData[i][simVW] = SIMStationData[i+1][simVW];
        SIMStationData[i][simActorID] = SIMStationData[i+1][simActorID];
        SIMStationData[i][simPickupID] = SIMStationData[i+1][simPickupID];
        SIMStationData[i][simLabelID] = SIMStationData[i+1][simLabelID];
    }
    TotalSIMStations--;
    SendClientFormattedMessage(playerid, 0x00CC00FF, "[SIM] Station #%d berhasil dihapus.", sid);
    return true;
}

COMMAND:simstationlist(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TotalSIMStations == 0) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Belum ada SIM station yang di-set."), true;
    SendClientFormattedMessage(playerid, 0x00CC00FF, "=== SIM Stations (%d) ===", TotalSIMStations);
    for(new i = 0; i < TotalSIMStations; i++)
    {
        SendClientFormattedMessage(playerid, -1, "#%d | %s | Pos: %.1f,%.1f,%.1f | Int: %d VW: %d", SIMStationData[i][simDBID], SIMStationData[i][simName], SIMStationData[i][simX], SIMStationData[i][simY], SIMStationData[i][simZ], SIMStationData[i][simInterior], SIMStationData[i][simVW]);
    }
    return true;
}
