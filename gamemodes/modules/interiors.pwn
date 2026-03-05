// ============================================================================
// MODULE: interiors.pwn
// Interior entry/exit teleport system (dev-managed, loaded from DB)
// Every location (bank, police, restaurant...) uses entry/exit pickups
// ============================================================================

// ============================================================================
// LOAD FROM DB
// ============================================================================

stock LoadInteriors()
{
    mysql_function_query(MySQL_C1, "SELECT * FROM `interiors` ORDER BY `id` ASC", true, "OnInteriorsLoaded", "");
}

publics: OnInteriorsLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalInteriors = 0;
    for(new i = 0; i < rows && i < MAX_INTERIORS; i++)
    {
        InteriorData[i][intDBID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", InteriorData[i][intName], MySQL_C1, 48);
        InteriorData[i][intEntryX] = cache_get_field_content_float(i, "entry_x", MySQL_C1);
        InteriorData[i][intEntryY] = cache_get_field_content_float(i, "entry_y", MySQL_C1);
        InteriorData[i][intEntryZ] = cache_get_field_content_float(i, "entry_z", MySQL_C1);
        InteriorData[i][intEntryAngle] = cache_get_field_content_float(i, "entry_angle", MySQL_C1);
        InteriorData[i][intExitX] = cache_get_field_content_float(i, "exit_x", MySQL_C1);
        InteriorData[i][intExitY] = cache_get_field_content_float(i, "exit_y", MySQL_C1);
        InteriorData[i][intExitZ] = cache_get_field_content_float(i, "exit_z", MySQL_C1);
        InteriorData[i][intExitAngle] = cache_get_field_content_float(i, "exit_angle", MySQL_C1);
        InteriorData[i][intInterior] = cache_get_field_content_int(i, "interior_id", MySQL_C1);
        InteriorData[i][intVW] = cache_get_field_content_int(i, "vw", MySQL_C1);
        CreateInteriorWorld(i);
        TotalInteriors++;
    }
    printf("[Interior] Loaded: %d interiors.", TotalInteriors);
}

// ============================================================================
// CREATE / DESTROY WORLD OBJECTS
// ============================================================================

stock CreateInteriorWorld(idx)
{
    // Entry pickup + label (outside, real world)
    new lbl[96];
    format(lbl, sizeof(lbl), "{FFAA00}%s\n{FFFFFF}Tekan ~k~~SECONDARY_ATTACK~ untuk masuk", InteriorData[idx][intName]);
    InteriorData[idx][intEntryLabel] = Create3DTextLabel(lbl, 0xFFAA00FF, InteriorData[idx][intEntryX], InteriorData[idx][intEntryY], InteriorData[idx][intEntryZ] + 0.5, 15.0, 0);
    InteriorData[idx][intEntryPickup] = CreatePickup(1318, 23, InteriorData[idx][intEntryX], InteriorData[idx][intEntryY], InteriorData[idx][intEntryZ], -1);

    // Exit pickup + label (inside interior)
    new exitlbl[64];
    format(exitlbl, sizeof(exitlbl), "{FF6347}Keluar\n{FFFFFF}Tekan ~k~~SECONDARY_ATTACK~");
    InteriorData[idx][intExitLabel] = Create3DTextLabel(exitlbl, 0xFF6347FF, InteriorData[idx][intExitX], InteriorData[idx][intExitY], InteriorData[idx][intExitZ] + 0.5, 15.0, InteriorData[idx][intVW]);
    InteriorData[idx][intExitPickup] = CreatePickup(1318, 23, InteriorData[idx][intExitX], InteriorData[idx][intExitY], InteriorData[idx][intExitZ], InteriorData[idx][intVW]);
}

stock DestroyInteriorWorld(idx)
{
    if(InteriorData[idx][intEntryLabel] != Text3D:INVALID_3DTEXT_ID) { Delete3DTextLabel(InteriorData[idx][intEntryLabel]); InteriorData[idx][intEntryLabel] = Text3D:INVALID_3DTEXT_ID; }
    if(InteriorData[idx][intEntryPickup]) { DestroyPickup(InteriorData[idx][intEntryPickup]); InteriorData[idx][intEntryPickup] = 0; }
    if(InteriorData[idx][intExitLabel] != Text3D:INVALID_3DTEXT_ID) { Delete3DTextLabel(InteriorData[idx][intExitLabel]); InteriorData[idx][intExitLabel] = Text3D:INVALID_3DTEXT_ID; }
    if(InteriorData[idx][intExitPickup]) { DestroyPickup(InteriorData[idx][intExitPickup]); InteriorData[idx][intExitPickup] = 0; }
}

// ============================================================================
// KEY PRESS HANDLER - Enter/Exit by pressing F (SECONDARY_ATTACK)
// ============================================================================

stock HandleInteriorKeyPress(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new pint = GetPlayerInterior(playerid);
    new pvw = GetPlayerVirtualWorld(playerid);

    for(new i = 0; i < TotalInteriors; i++)
    {
        // Check entry point (outside, int=0, vw=0)
        if(pint == 0 && pvw == 0)
        {
            new Float:dist = floatsqroot((px - InteriorData[i][intEntryX]) * (px - InteriorData[i][intEntryX]) + (py - InteriorData[i][intEntryY]) * (py - InteriorData[i][intEntryY]) + (pz - InteriorData[i][intEntryZ]) * (pz - InteriorData[i][intEntryZ]));
            if(dist <= INTERIOR_RANGE)
            {
                SetPlayerPos(playerid, InteriorData[i][intExitX], InteriorData[i][intExitY], InteriorData[i][intExitZ]);
                SetPlayerFacingAngle(playerid, InteriorData[i][intExitAngle]);
                SetPlayerInterior(playerid, InteriorData[i][intInterior]);
                SetPlayerVirtualWorld(playerid, InteriorData[i][intVW]);
                SetCameraBehindPlayer(playerid);
                SendClientFormattedMessage(playerid, 0xFFAA00FF, "Kamu memasuki %s.", InteriorData[i][intName]);
                return 1;
            }
        }

        // Check exit point (inside interior)
        if(pint == InteriorData[i][intInterior] && pvw == InteriorData[i][intVW])
        {
            new Float:dist = floatsqroot((px - InteriorData[i][intExitX]) * (px - InteriorData[i][intExitX]) + (py - InteriorData[i][intExitY]) * (py - InteriorData[i][intExitY]) + (pz - InteriorData[i][intExitZ]) * (pz - InteriorData[i][intExitZ]));
            if(dist <= INTERIOR_RANGE)
            {
                SetPlayerPos(playerid, InteriorData[i][intEntryX], InteriorData[i][intEntryY], InteriorData[i][intEntryZ]);
                SetPlayerFacingAngle(playerid, InteriorData[i][intEntryAngle]);
                SetPlayerInterior(playerid, 0);
                SetPlayerVirtualWorld(playerid, 0);
                SetCameraBehindPlayer(playerid);
                SendClientFormattedMessage(playerid, 0xFF6347FF, "Kamu keluar dari %s.", InteriorData[i][intName]);
                return 1;
            }
        }
    }
    return 0;
}

// ============================================================================
// DEVELOPER COMMANDS
// ============================================================================

// Temp storage for 2-step interior creation
new TempInteriorName[MAX_PLAYERS][48];
new Float:TempInteriorEntry[MAX_PLAYERS][4]; // x, y, z, angle
new TempInteriorStep[MAX_PLAYERS]; // 0 = not creating, 1 = waiting for exit pos

COMMAND:setinterior(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TotalInteriors >= MAX_INTERIORS) return SendClientFormattedMessage(playerid, COLOR_RED, "Max interiors tercapai (%d).", MAX_INTERIORS), true;

    new iname[48];
    if(sscanf(params, "s[48]", iname)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setinterior [nama]"), true;

    // Save entry point (current pos)
    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);

    strmid(TempInteriorName[playerid], iname, 0, strlen(iname), 48);
    TempInteriorEntry[playerid][0] = px;
    TempInteriorEntry[playerid][1] = py;
    TempInteriorEntry[playerid][2] = pz;
    TempInteriorEntry[playerid][3] = pa;
    TempInteriorStep[playerid] = 1;

    SendClientFormattedMessage(playerid, 0xFFAA00FF, "[Interior] Titik masuk '%s' disimpan di posisi kamu.", iname);
    SendClientFormattedMessage(playerid, 0xFFAA00FF, "[Interior] Sekarang pergi ke dalam interior, lalu ketik /setinteriorexit");
    return true;
}

COMMAND:setinteriorexit(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TempInteriorStep[playerid] != 1) return SendClientFormattedMessage(playerid, COLOR_RED, "Gunakan /setinterior [nama] dulu untuk set titik masuk."), true;

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    new pint = GetPlayerInterior(playerid);
    new pvw = GetPlayerVirtualWorld(playerid);

    TempInteriorStep[playerid] = 0;

    mysql_format(MySQL_C1, query, sizeof(query), "INSERT INTO `interiors` (`name`,`entry_x`,`entry_y`,`entry_z`,`entry_angle`,`exit_x`,`exit_y`,`exit_z`,`exit_angle`,`interior_id`,`vw`,`created_by`,`created_at`) VALUES ('%e','%f','%f','%f','%f','%f','%f','%f','%f','%d','%d','%e','%d')", TempInteriorName[playerid], TempInteriorEntry[playerid][0], TempInteriorEntry[playerid][1], TempInteriorEntry[playerid][2], TempInteriorEntry[playerid][3], px, py, pz, pa, pint, pvw, PlayerName(playerid), gettime());
    mysql_function_query(MySQL_C1, query, true, "OnInteriorCreated", "d", playerid);
    return true;
}

publics: OnInteriorCreated(playerid)
{
    new idx = TotalInteriors;
    InteriorData[idx][intDBID] = cache_insert_id();
    strmid(InteriorData[idx][intName], TempInteriorName[playerid], 0, strlen(TempInteriorName[playerid]), 48);
    InteriorData[idx][intEntryX] = TempInteriorEntry[playerid][0];
    InteriorData[idx][intEntryY] = TempInteriorEntry[playerid][1];
    InteriorData[idx][intEntryZ] = TempInteriorEntry[playerid][2];
    InteriorData[idx][intEntryAngle] = TempInteriorEntry[playerid][3];

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    InteriorData[idx][intExitX] = px;
    InteriorData[idx][intExitY] = py;
    InteriorData[idx][intExitZ] = pz;
    InteriorData[idx][intExitAngle] = pa;
    InteriorData[idx][intInterior] = GetPlayerInterior(playerid);
    InteriorData[idx][intVW] = GetPlayerVirtualWorld(playerid);

    CreateInteriorWorld(idx);
    TotalInteriors++;

    SendClientFormattedMessage(playerid, 0x00CC00FF, "[Interior] '%s' #%d berhasil dibuat!", InteriorData[idx][intName], InteriorData[idx][intDBID]);
    TempInteriorName[playerid][0] = EOS;
    return 1;
}

COMMAND:delinterior(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    new intid;
    if(sscanf(params, "d", intid)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /delinterior [DB ID]"), true;

    new found = -1;
    for(new i = 0; i < TotalInteriors; i++)
    {
        if(InteriorData[i][intDBID] == intid) { found = i; break; }
    }
    if(found == -1) return SendClientFormattedMessage(playerid, COLOR_RED, "Interior ID %d tidak ditemukan.", intid), true;

    DestroyInteriorWorld(found);
    mysql_format(MySQL_C1, query, sizeof(query), "DELETE FROM `interiors` WHERE `id` = '%d'", intid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    // Shift array
    for(new i = found; i < TotalInteriors - 1; i++)
    {
        InteriorData[i][intDBID] = InteriorData[i+1][intDBID];
        strmid(InteriorData[i][intName], InteriorData[i+1][intName], 0, strlen(InteriorData[i+1][intName]), 48);
        InteriorData[i][intEntryX] = InteriorData[i+1][intEntryX];
        InteriorData[i][intEntryY] = InteriorData[i+1][intEntryY];
        InteriorData[i][intEntryZ] = InteriorData[i+1][intEntryZ];
        InteriorData[i][intEntryAngle] = InteriorData[i+1][intEntryAngle];
        InteriorData[i][intExitX] = InteriorData[i+1][intExitX];
        InteriorData[i][intExitY] = InteriorData[i+1][intExitY];
        InteriorData[i][intExitZ] = InteriorData[i+1][intExitZ];
        InteriorData[i][intExitAngle] = InteriorData[i+1][intExitAngle];
        InteriorData[i][intInterior] = InteriorData[i+1][intInterior];
        InteriorData[i][intVW] = InteriorData[i+1][intVW];
        InteriorData[i][intEntryPickup] = InteriorData[i+1][intEntryPickup];
        InteriorData[i][intEntryLabel] = InteriorData[i+1][intEntryLabel];
        InteriorData[i][intExitPickup] = InteriorData[i+1][intExitPickup];
        InteriorData[i][intExitLabel] = InteriorData[i+1][intExitLabel];
    }
    TotalInteriors--;
    SendClientFormattedMessage(playerid, 0x00CC00FF, "[Interior] Interior #%d berhasil dihapus.", intid);
    return true;
}

COMMAND:interiorlist(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TotalInteriors == 0) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Belum ada interior yang di-set."), true;
    SendClientFormattedMessage(playerid, 0x00CC00FF, "=== Interior Locations (%d) ===", TotalInteriors);
    for(new i = 0; i < TotalInteriors; i++)
    {
        SendClientFormattedMessage(playerid, -1, "#%d | %s | Entry: %.1f,%.1f,%.1f | Int: %d VW: %d", InteriorData[i][intDBID], InteriorData[i][intName], InteriorData[i][intEntryX], InteriorData[i][intEntryY], InteriorData[i][intEntryZ], InteriorData[i][intInterior], InteriorData[i][intVW]);
    }
    return true;
}

COMMAND:gotointerior(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    new intid;
    if(sscanf(params, "d", intid)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /gotointerior [DB ID]"), true;

    for(new i = 0; i < TotalInteriors; i++)
    {
        if(InteriorData[i][intDBID] == intid)
        {
            SetPlayerPos(playerid, InteriorData[i][intEntryX], InteriorData[i][intEntryY], InteriorData[i][intEntryZ]);
            SetPlayerFacingAngle(playerid, InteriorData[i][intEntryAngle]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            SetCameraBehindPlayer(playerid);
            SendClientFormattedMessage(playerid, 0x00CC00FF, "[Interior] Teleport ke pintu masuk '%s'.", InteriorData[i][intName]);
            return true;
        }
    }
    SendClientFormattedMessage(playerid, COLOR_RED, "Interior ID %d tidak ditemukan.", intid);
    return true;
}

// /setint and /setvw commands are in admin.pwn to avoid duplicates
