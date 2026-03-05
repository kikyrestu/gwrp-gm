// ============================================================================
// MODULE: locations.pwn
// Dynamic location system — developer can create/delete/edit places
// Restaurants, apartments, shops, etc with pickup + 3D label + map icon
// ============================================================================

enum eLocInfo {
    locID,
    locName[64],
    locType[32],
    Float:locX,
    Float:locY,
    Float:locZ,
    locInterior,
    locVW,
    locIconID,
    locLabelColor,
    locCreatedBy[24],
    // Runtime handles
    locPickupID,
    Text3D:locLabelID,
    locMapIconID
};

new LocationData[MAX_LOCATIONS][eLocInfo];
new TotalLocations = 0;

// Temp data for creation flow
new TempLocName[MAX_PLAYERS][64];
new TempLocType[MAX_PLAYERS][32];
new TempLocIcon[MAX_PLAYERS];

// Teleport dialog: store source type + index per entry (aggregated from all DB)
#define MAX_TP_ENTRIES  100

// TP source types
#define TP_SRC_MALL         0
#define TP_SRC_ATM          1
#define TP_SRC_BANK         2
#define TP_SRC_INTERIOR     3
#define TP_SRC_SIM          4
#define TP_SRC_LOCKER       5
#define TP_SRC_LOCATION     6
#define TP_SRC_PROPERTY     7
#define TP_SRC_FACTION      8

new TpSrcType[MAX_PLAYERS][MAX_TP_ENTRIES];   // source type
new TpSrcIdx[MAX_PLAYERS][MAX_TP_ENTRIES];    // index into that source array
new TpEntryCount[MAX_PLAYERS];

// ============================================================================
// LOAD ALL LOCATIONS FROM DB
// ============================================================================

stock LoadLocations()
{
    mysql_function_query(MySQL_C1, "SELECT * FROM `locations` ORDER BY `id` ASC", true, "OnLocationsLoaded", "");
}

publics: OnLocationsLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);

    TotalLocations = 0;

    for(new i = 0; i < rows && i < MAX_LOCATIONS; i++)
    {
        LocationData[i][locID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", LocationData[i][locName], MySQL_C1, 64);
        cache_get_field_content(i, "type", LocationData[i][locType], MySQL_C1, 32);
        LocationData[i][locX] = cache_get_field_content_float(i, "pos_x", MySQL_C1);
        LocationData[i][locY] = cache_get_field_content_float(i, "pos_y", MySQL_C1);
        LocationData[i][locZ] = cache_get_field_content_float(i, "pos_z", MySQL_C1);
        LocationData[i][locInterior] = cache_get_field_content_int(i, "interior", MySQL_C1);
        LocationData[i][locVW] = cache_get_field_content_int(i, "vw", MySQL_C1);
        LocationData[i][locIconID] = cache_get_field_content_int(i, "icon_id", MySQL_C1);
        LocationData[i][locLabelColor] = cache_get_field_content_int(i, "label_color", MySQL_C1);
        cache_get_field_content(i, "created_by", LocationData[i][locCreatedBy], MySQL_C1, 24);

        CreateLocationWorld(i);
        TotalLocations++;
    }
    printf("-> Locations loaded: %d places.", TotalLocations);
    return 1;
}

// ============================================================================
// CREATE IN-WORLD OBJECTS (pickup, label, mapicon)
// ============================================================================

stock CreateLocationWorld(idx)
{
    // Pickup (green house icon=1273, info=1239, dollar=1274, heart=1240)
    new pickupModel = 1239; // default info icon
    LocationData[idx][locPickupID] = CreateDynamicPickup(pickupModel, 1,
        LocationData[idx][locX], LocationData[idx][locY], LocationData[idx][locZ],
        LocationData[idx][locVW], LocationData[idx][locInterior], -1, 30.0);

    // 3D Text Label above pickup
    new labelText[128];
    format(labelText, sizeof(labelText), "{FFFFFF}%s\n{AAAAAA}[%s]", LocationData[idx][locName], LocationData[idx][locType]);

    new labelColor = 0x33AA33FF; // default green
    if(LocationData[idx][locLabelColor] != 0)
        labelColor = LocationData[idx][locLabelColor];

    LocationData[idx][locLabelID] = CreateDynamic3DTextLabel(labelText, labelColor,
        LocationData[idx][locX], LocationData[idx][locY], LocationData[idx][locZ] + 0.7,
        20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1,
        LocationData[idx][locVW], LocationData[idx][locInterior], -1, 20.0);

    // Map icon (if set)
    if(LocationData[idx][locIconID] > 0)
    {
        LocationData[idx][locMapIconID] = CreateDynamicMapIcon(
            LocationData[idx][locX], LocationData[idx][locY], LocationData[idx][locZ],
            LocationData[idx][locIconID], 0, LocationData[idx][locVW],
            LocationData[idx][locInterior], -1, 200.0, MAPICON_LOCAL);
    }
    else
    {
        LocationData[idx][locMapIconID] = -1;
    }
}

// ============================================================================
// DESTROY IN-WORLD OBJECTS
// ============================================================================

stock DestroyLocationWorld(idx)
{
    if(IsValidDynamicPickup(LocationData[idx][locPickupID]))
        DestroyDynamicPickup(LocationData[idx][locPickupID]);
    if(IsValidDynamic3DTextLabel(LocationData[idx][locLabelID]))
        DestroyDynamic3DTextLabel(LocationData[idx][locLabelID]);
    if(LocationData[idx][locMapIconID] != -1 && IsValidDynamicMapIcon(LocationData[idx][locMapIconID]))
        DestroyDynamicMapIcon(LocationData[idx][locMapIconID]);
}

// ============================================================================
// FIND NEAREST LOCATION
// ============================================================================

stock GetNearestLocation(playerid, Float:maxdist = 5.0)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new Float:mindist = maxdist, nearest = -1;

    for(new i = 0; i < TotalLocations; i++)
    {
        new Float:dist = floatsqroot(
            (px - LocationData[i][locX]) * (px - LocationData[i][locX]) +
            (py - LocationData[i][locY]) * (py - LocationData[i][locY]) +
            (pz - LocationData[i][locZ]) * (pz - LocationData[i][locZ])
        );
        if(dist < mindist)
        {
            mindist = dist;
            nearest = i;
        }
    }
    return nearest;
}

// ============================================================================
// DEVELOPER COMMANDS
// ============================================================================

// /createloc — start location creation flow
COMMAND:createloc(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    ShowPlayerDialog(playerid, DIALOG_LOC_TYPE, DIALOG_STYLE_LIST,
        "{00CC00}Buat Lokasi — Pilih Tipe",
        "Restoran\nApartemen\nToko\nBengkel\nKantor\nRumah Sakit\nKantor Polisi\nGym\nBar/Club\nPom Bensin\nUmum",
        "Pilih", "Batal");
    return true;
}

// /deleteloc — delete nearest location
COMMAND:deleteloc(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new idx = GetNearestLocation(playerid, 10.0);
    if(idx == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada lokasi dalam radius 10m!"), true;

    // Destroy world objects
    DestroyLocationWorld(idx);

    // Delete from DB
    new q[128];
    mysql_format(MySQL_C1, q, sizeof(q), "DELETE FROM `locations` WHERE `id` = '%d'", LocationData[idx][locID]);
    mysql_tquery(MySQL_C1, q, "", "");

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Lokasi '%s' (ID: %d) telah dihapus.", LocationData[idx][locName], LocationData[idx][locID]);
    AdminLog(PlayerName(playerid), "DELETELOC", LocationData[idx][locName], "");

    // Shift array
    for(new i = idx; i < TotalLocations - 1; i++)
    {
        LocationData[i] = LocationData[i + 1];
    }
    TotalLocations--;
    return true;
}

// /editloc — edit nearest location name
COMMAND:editloc(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new idx = GetNearestLocation(playerid, 10.0);
    if(idx == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada lokasi dalam radius 10m!"), true;

    // Store which location we're editing
    TempLocIcon[playerid] = idx;

    new current[128];
    format(current, sizeof(current), "Lokasi saat ini: %s\nMasukkan nama baru:", LocationData[idx][locName]);
    ShowPlayerDialog(playerid, DIALOG_LOC_NAME + 10, DIALOG_STYLE_INPUT,
        "{FFAA00}Edit Nama Lokasi", current, "Simpan", "Batal");
    return true;
}

// /locs — list all locations
COMMAND:locs(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    if(TotalLocations == 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Belum ada lokasi yang dibuat."), true;

    new list[1024];
    list[0] = EOS;
    for(new i = 0; i < TotalLocations && i < 30; i++)
    {
        new line[80];
        format(line, sizeof(line), "#%d [%s] %s (%.1f, %.1f, %.1f)\n",
            LocationData[i][locID], LocationData[i][locType], LocationData[i][locName],
            LocationData[i][locX], LocationData[i][locY], LocationData[i][locZ]);
        strcat(list, line, sizeof(list));
    }
    ShowPlayerDialog(playerid, dNull, DIALOG_STYLE_MSGBOX, "{00CC00}Daftar Lokasi", list, "Tutup", "");
    return true;
}

// Helper: add an entry to the TP dialog list for a player
static stock TpAddEntry(playerid, list[], listsize, type, idx, name[], category[], interior, vw)
{
    if(TpEntryCount[playerid] >= MAX_TP_ENTRIES) return 0;

    new line[128];
    if(interior > 0 || vw > 0)
        format(line, sizeof(line), "{FFFFFF}%s {AAAAAA}[%s] {888888}(Int:%d VW:%d)\n", name, category, interior, vw);
    else
        format(line, sizeof(line), "{FFFFFF}%s {AAAAAA}[%s]\n", name, category);

    // Check if we'd exceed dialog buffer
    if(strlen(list) + strlen(line) >= listsize - 1) return 0;

    strcat(list, line, listsize);
    TpSrcType[playerid][TpEntryCount[playerid]] = type;
    TpSrcIdx[playerid][TpEntryCount[playerid]]  = idx;
    TpEntryCount[playerid]++;
    return 1;
}

// /tp [keyword] — teleport ke lokasi dari SEMUA database via dialog (Developer only)
COMMAND:tp(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new list[4000];
    list[0] = EOS;
    TpEntryCount[playerid] = 0;

    new keyword[32];
    new bool:hasFilter = !sscanf(params, "s[32]", keyword);

    new tmpname[64];

    // 1) Mall Pelayanan
    for(new i = 0; i < MallCount; i++)
    {
        if(hasFilter && strfind(MallData[i][mName], keyword, true) == -1
                     && strfind("Mall", keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_MALL, i, MallData[i][mName], "Mall Pelayanan", 0, 0);
    }

    // 2) ATM
    for(new i = 0; i < TotalATMs; i++)
    {
        format(tmpname, sizeof(tmpname), "ATM #%d", ATMData[i][atmDBID]);
        if(hasFilter && strfind(tmpname, keyword, true) == -1
                     && strfind("ATM", keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_ATM, i, tmpname, "ATM", 0, 0);
    }

    // 3) Bank
    for(new i = 0; i < TotalBanks; i++)
    {
        if(hasFilter && strfind(BankData[i][bnkName], keyword, true) == -1
                     && strfind("Bank", keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_BANK, i, BankData[i][bnkName], "Bank", 0, 0);
    }

    // 4) Interior
    for(new i = 0; i < TotalInteriors; i++)
    {
        if(hasFilter && strfind(InteriorData[i][intName], keyword, true) == -1
                     && strfind("Interior", keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_INTERIOR, i, InteriorData[i][intName], "Interior",
            InteriorData[i][intInterior], InteriorData[i][intVW]);
    }

    // 5) SIM Station
    for(new i = 0; i < TotalSIMStations; i++)
    {
        if(hasFilter && strfind(SIMStationData[i][simName], keyword, true) == -1
                     && strfind("SIM", keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_SIM, i, SIMStationData[i][simName], "SIM Station",
            SIMStationData[i][simInterior], SIMStationData[i][simVW]);
    }

    // 6) GoFood Locker
    for(new i = 0; i < TotalLockers; i++)
    {
        new citynames[3][16] = {"MekarPura", "MadyaRaya", "Mojosono"};
        new cidx = LockerData[i][lkCity] - 1;
        if(cidx < 0 || cidx > 2) cidx = 0;
        format(tmpname, sizeof(tmpname), "Locker GoFood %s #%d", citynames[cidx], LockerData[i][lkDBID]);
        if(hasFilter && strfind(tmpname, keyword, true) == -1
                     && strfind("GoFood", keyword, true) == -1
                     && strfind("Locker", keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_LOCKER, i, tmpname, "GoFood Locker", 0, 0);
    }

    // 7) Location (tabel locations)
    for(new i = 0; i < TotalLocations; i++)
    {
        if(hasFilter && strfind(LocationData[i][locName], keyword, true) == -1
                     && strfind(LocationData[i][locType], keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_LOCATION, i, LocationData[i][locName], LocationData[i][locType],
            LocationData[i][locInterior], LocationData[i][locVW]);
    }

    // 8) Property
    for(new i = 0; i < TotalProperties; i++)
    {
        if(hasFilter && strfind(PropertyData[i][propName], keyword, true) == -1
                     && strfind("Property", keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_PROPERTY, i, PropertyData[i][propName], "Property",
            PropertyData[i][propInterior], PropertyData[i][propVW]);
    }

    // 9) Faction HQ
    for(new i = 0; i < TotalFactions; i++)
    {
        format(tmpname, sizeof(tmpname), "HQ %s", FactionData[i][fName]);
        if(hasFilter && strfind(FactionData[i][fName], keyword, true) == -1
                     && strfind("Faction", keyword, true) == -1
                     && strfind("HQ", keyword, true) == -1) continue;
        TpAddEntry(playerid, list, sizeof(list), TP_SRC_FACTION, i, tmpname, "Faction HQ",
            FactionData[i][fHQInterior], FactionData[i][fHQVW]);
    }

    // Check results
    if(TpEntryCount[playerid] == 0)
    {
        if(hasFilter)
            return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada lokasi yang cocok dengan '%s'.", keyword), true;
        else
            return SendClientFormattedMessage(playerid, COLOR_RED, "Belum ada lokasi di database. Setup dulu (setmall/setatm/setbank/dll)."), true;
    }

    new title[64];
    format(title, sizeof(title), "{00CC00}Teleport — %d Lokasi", TpEntryCount[playerid]);
    ShowPlayerDialog(playerid, DIALOG_LOC_LIST, DIALOG_STYLE_LIST, title, list, "Teleport", "Batal");
    return true;
}

// /gotoloc [id] — teleport to location by DB id
COMMAND:gotoloc(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new locid;
    if(sscanf(params, "d", locid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /gotoloc [id lokasi]"), true;

    for(new i = 0; i < TotalLocations; i++)
    {
        if(LocationData[i][locID] == locid)
        {
            SetPlayerPos(playerid, LocationData[i][locX], LocationData[i][locY], LocationData[i][locZ]);
            SetPlayerInterior(playerid, LocationData[i][locInterior]);
            SetPlayerVirtualWorld(playerid, LocationData[i][locVW]);
            SendClientFormattedMessage(playerid, COLOR_ADMIN, "Teleport ke lokasi '%s'.", LocationData[i][locName]);
            return true;
        }
    }
    SendClientFormattedMessage(playerid, COLOR_RED, "Lokasi ID %d tidak ditemukan!", locid);
    return true;
}

// ============================================================================
// DIALOG HANDLERS
// ============================================================================

stock HandleLocationDialogs(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_LOC_TYPE:
        {
            if(!response) return 1;
            switch(listitem)
            {
                case 0: TempLocType[playerid] = "Restoran";
                case 1: TempLocType[playerid] = "Apartemen";
                case 2: TempLocType[playerid] = "Toko";
                case 3: TempLocType[playerid] = "Bengkel";
                case 4: TempLocType[playerid] = "Kantor";
                case 5: TempLocType[playerid] = "Rumah Sakit";
                case 6: TempLocType[playerid] = "Kantor Polisi";
                case 7: TempLocType[playerid] = "Gym";
                case 8: TempLocType[playerid] = "Bar/Club";
                case 9: TempLocType[playerid] = "Pom Bensin";
                default: TempLocType[playerid] = "Umum";
            }
            ShowPlayerDialog(playerid, DIALOG_LOC_NAME, DIALOG_STYLE_INPUT,
                "{00CC00}Buat Lokasi — Nama",
                "Masukkan nama lokasi (contoh: Restoran Nasi Padang):",
                "Lanjut", "Batal");
            return 1;
        }
        case DIALOG_LOC_NAME:
        {
            if(!response) return 1;
            if(strlen(inputtext) < 3 || strlen(inputtext) > 60)
            {
                SendClientFormattedMessage(playerid, COLOR_RED, "Nama harus 3-60 karakter!");
                ShowPlayerDialog(playerid, DIALOG_LOC_NAME, DIALOG_STYLE_INPUT,
                    "{00CC00}Buat Lokasi — Nama",
                    "Masukkan nama lokasi (contoh: Restoran Nasi Padang):",
                    "Lanjut", "Batal");
                return 1;
            }
            format(TempLocName[playerid], 64, "%s", inputtext);

            ShowPlayerDialog(playerid, DIALOG_LOC_ICON, DIALOG_STYLE_LIST,
                "{00CC00}Buat Lokasi — Map Icon",
                "Tanpa Icon\nRestoran (10)\nBar (11)\nBurger (45)\nBensin (55)\nRumah (31)\nRumah Sakit (22)\nPolisi (30)\nGym (54)\nToko (6)\nModista (45)\nKantor (36)",
                "Buat!", "Batal");
            return 1;
        }
        case DIALOG_LOC_ICON:
        {
            if(!response) return 1;
            switch(listitem)
            {
                case 0: TempLocIcon[playerid] = 0;
                case 1: TempLocIcon[playerid] = 10;
                case 2: TempLocIcon[playerid] = 11;
                case 3: TempLocIcon[playerid] = 45;
                case 4: TempLocIcon[playerid] = 55;
                case 5: TempLocIcon[playerid] = 31;
                case 6: TempLocIcon[playerid] = 22;
                case 7: TempLocIcon[playerid] = 30;
                case 8: TempLocIcon[playerid] = 54;
                case 9: TempLocIcon[playerid] = 6;
                case 10: TempLocIcon[playerid] = 45;
                case 11: TempLocIcon[playerid] = 36;
                default: TempLocIcon[playerid] = 0;
            }
            // Create the location at player's current position
            FinalizeCreateLocation(playerid);
            return 1;
        }
        // Teleport dialog (aggregated from all DB sources)
        case DIALOG_LOC_LIST:
        {
            if(!response) return 1;
            if(listitem < 0 || listitem >= TpEntryCount[playerid]) return 1;

            new srctype = TpSrcType[playerid][listitem];
            new srcidx  = TpSrcIdx[playerid][listitem];

            // Cancel fly mode if active
            if(FlyData[playerid][flyCamMode] == FLY_CAM_FLY)
                StopFlyMode(playerid);

            new Float:tx, Float:ty, Float:tz, tint = 0, tvw = 0;
            new tname[64];

            switch(srctype)
            {
                case TP_SRC_MALL:
                {
                    tx = MallData[srcidx][mPosX]; ty = MallData[srcidx][mPosY]; tz = MallData[srcidx][mPosZ];
                    format(tname, sizeof(tname), "%s", MallData[srcidx][mName]);
                }
                case TP_SRC_ATM:
                {
                    tx = ATMData[srcidx][atmX]; ty = ATMData[srcidx][atmY]; tz = ATMData[srcidx][atmZ];
                    format(tname, sizeof(tname), "ATM #%d", ATMData[srcidx][atmDBID]);
                }
                case TP_SRC_BANK:
                {
                    tx = BankData[srcidx][bnkX]; ty = BankData[srcidx][bnkY]; tz = BankData[srcidx][bnkZ];
                    format(tname, sizeof(tname), "%s", BankData[srcidx][bnkName]);
                }
                case TP_SRC_INTERIOR:
                {
                    tx = InteriorData[srcidx][intEntryX]; ty = InteriorData[srcidx][intEntryY]; tz = InteriorData[srcidx][intEntryZ];
                    tint = InteriorData[srcidx][intInterior]; tvw = InteriorData[srcidx][intVW];
                    format(tname, sizeof(tname), "%s", InteriorData[srcidx][intName]);
                }
                case TP_SRC_SIM:
                {
                    tx = SIMStationData[srcidx][simX]; ty = SIMStationData[srcidx][simY]; tz = SIMStationData[srcidx][simZ];
                    tint = SIMStationData[srcidx][simInterior]; tvw = SIMStationData[srcidx][simVW];
                    format(tname, sizeof(tname), "%s", SIMStationData[srcidx][simName]);
                }
                case TP_SRC_LOCKER:
                {
                    tx = LockerData[srcidx][lkX]; ty = LockerData[srcidx][lkY]; tz = LockerData[srcidx][lkZ];
                    format(tname, sizeof(tname), "GoFood Locker #%d", LockerData[srcidx][lkDBID]);
                }
                case TP_SRC_LOCATION:
                {
                    tx = LocationData[srcidx][locX]; ty = LocationData[srcidx][locY]; tz = LocationData[srcidx][locZ];
                    tint = LocationData[srcidx][locInterior]; tvw = LocationData[srcidx][locVW];
                    format(tname, sizeof(tname), "%s", LocationData[srcidx][locName]);
                }
                case TP_SRC_PROPERTY:
                {
                    tx = PropertyData[srcidx][propEntryX]; ty = PropertyData[srcidx][propEntryY]; tz = PropertyData[srcidx][propEntryZ];
                    tint = PropertyData[srcidx][propInterior]; tvw = PropertyData[srcidx][propVW];
                    format(tname, sizeof(tname), "%s", PropertyData[srcidx][propName]);
                }
                case TP_SRC_FACTION:
                {
                    tx = FactionData[srcidx][fHQX]; ty = FactionData[srcidx][fHQY]; tz = FactionData[srcidx][fHQZ];
                    tint = FactionData[srcidx][fHQInterior]; tvw = FactionData[srcidx][fHQVW];
                    format(tname, sizeof(tname), "HQ %s", FactionData[srcidx][fName]);
                }
                default: return 1;
            }

            SetPlayerPos(playerid, tx, ty, tz);
            SetPlayerInterior(playerid, tint);
            SetPlayerVirtualWorld(playerid, tvw);
            SetCameraBehindPlayer(playerid);

            SendClientFormattedMessage(playerid, COLOR_ADMIN, "[Teleport] Kamu teleport ke '%s'.", tname);
            AdminLog(PlayerName(playerid), "TELEPORT", tname, "");
            return 1;
        }
        // Edit location name dialog (DIALOG_LOC_NAME + 10 = 141)
        case 141:
        {
            if(!response) return 1;
            if(strlen(inputtext) < 3 || strlen(inputtext) > 60)
                return SendClientFormattedMessage(playerid, COLOR_RED, "Nama harus 3-60 karakter!"), 1;

            new idx = TempLocIcon[playerid]; // stored edit index
            if(idx < 0 || idx >= TotalLocations) return 1;

            format(LocationData[idx][locName], 64, "%s", inputtext);

            // Update DB
            new q[256];
            mysql_format(MySQL_C1, q, sizeof(q), "UPDATE `locations` SET `name` = '%e' WHERE `id` = '%d'", inputtext, LocationData[idx][locID]);
            mysql_tquery(MySQL_C1, q, "", "");

            // Rebuild label
            if(IsValidDynamic3DTextLabel(LocationData[idx][locLabelID]))
                DestroyDynamic3DTextLabel(LocationData[idx][locLabelID]);

            new labelText[128];
            format(labelText, sizeof(labelText), "{FFFFFF}%s\n{AAAAAA}[%s]", LocationData[idx][locName], LocationData[idx][locType]);
            LocationData[idx][locLabelID] = CreateDynamic3DTextLabel(labelText, 0x33AA33FF,
                LocationData[idx][locX], LocationData[idx][locY], LocationData[idx][locZ] + 0.7,
                20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1,
                LocationData[idx][locVW], LocationData[idx][locInterior], -1, 20.0);

            SendClientFormattedMessage(playerid, COLOR_ADMIN, "Nama lokasi diubah ke '%s'.", inputtext);
            return 1;
        }
    }
    return 0;
}

// ============================================================================
// FINALIZE CREATION
// ============================================================================

stock FinalizeCreateLocation(playerid)
{
    if(TotalLocations >= MAX_LOCATIONS)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Batas maksimum lokasi tercapai (%d)!", MAX_LOCATIONS);

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new interior = GetPlayerInterior(playerid);
    new vw = GetPlayerVirtualWorld(playerid);

    // Save to DB
    new q[512];
    mysql_format(MySQL_C1, q, sizeof(q),
        "INSERT INTO `locations` (`name`,`type`,`pos_x`,`pos_y`,`pos_z`,`interior`,`vw`,`icon_id`,`label_color`,`created_by`,`created_at`) VALUES ('%e','%e','%f','%f','%f','%d','%d','%d','0','%e','%d')",
        TempLocName[playerid], TempLocType[playerid], px, py, pz, interior, vw, TempLocIcon[playerid], PlayerName(playerid), gettime());
    mysql_function_query(MySQL_C1, q, true, "OnLocationCreated", "d", playerid);
    return 1;
}

publics: OnLocationCreated(playerid)
{
    new idx = TotalLocations;
    LocationData[idx][locID] = cache_insert_id();

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    format(LocationData[idx][locName], 64, "%s", TempLocName[playerid]);
    format(LocationData[idx][locType], 32, "%s", TempLocType[playerid]);
    LocationData[idx][locX] = px;
    LocationData[idx][locY] = py;
    LocationData[idx][locZ] = pz;
    LocationData[idx][locInterior] = GetPlayerInterior(playerid);
    LocationData[idx][locVW] = GetPlayerVirtualWorld(playerid);
    LocationData[idx][locIconID] = TempLocIcon[playerid];
    LocationData[idx][locLabelColor] = 0;
    format(LocationData[idx][locCreatedBy], 24, "%s", PlayerName(playerid));

    CreateLocationWorld(idx);
    TotalLocations++;

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Lokasi '%s' [%s] berhasil dibuat! (ID: %d)", LocationData[idx][locName], LocationData[idx][locType], LocationData[idx][locID]);
    AdminLog(PlayerName(playerid), "CREATELOC", LocationData[idx][locName], LocationData[idx][locType]);
    return 1;
}
