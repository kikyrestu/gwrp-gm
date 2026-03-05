// ============================================================================
// MODULE: ktp_service.pwn
// KTP Service at Mall Pelayanan — DB-backed locations, dynamic NPC placement
// NPCs placed in-game by admin (/mallnpc) — unlimited per mall, stored in DB
// Admin:  /setmall, /delmall, /movemall, /malllist, /setmallinterior
//         /mallnpc, /delmallnpc, /mallnpclist
// Player: F key near Mall -> enter interior -> /layanan near Loket NPC
// ============================================================================

// ============================================================================
// DEFINES
// ============================================================================
#define MALL_VW_BASE            2000
#define MAX_MALL_NPC_TOTAL      100

// Loket types
#define LOKET_NONE              0
#define LOKET_RESEPSIONIS       1
#define LOKET_DUKCAPIL          2
#define LOKET_PERIZINAN         3
#define LOKET_PAJAK             4
#define LOKET_SURKET            5

// Dialog IDs
#define DIALOG_MALLNPC_TYPE     250
#define DIALOG_MALL_INT_SEL     251
#define DIALOG_MALL_SETUP       252
#define DIALOG_MALL_CREATE_CITY 253
#define DIALOG_MALL_EDIT_LIST   254
#define DIALOG_MALL_EDIT_MENU   255
#define DIALOG_MALL_DEL_LIST    256
#define DIALOG_MALL_DEL_CONFIRM 257
#define DIALOG_MALL_NPC_MENU    258

// City names for mall creation
#define MALL_CITY_COUNT         3
new MallCityNames[MALL_CITY_COUNT][32] = {
    "Mekar Pura",
    "Madya Raya",
    "Mojosono"
};

// ============================================================================
// ENUMS & DATA
// ============================================================================

enum eMallInfo
{
    mID,
    mName[64],
    Float:mPosX, Float:mPosY, Float:mPosZ, Float:mAngle,
    mInterior, mVW,
    Float:mIntX, Float:mIntY, Float:mIntZ, Float:mIntAngle,
    mIntInterior, mIntVW,
    mEntryActorID,
    mPickupID,
    mLabelID,
    mExitPickupID,
    mExitLabelID
};
new MallData[MAX_MALL_PELAYANAN][eMallInfo];
new MallCount = 0;
new pInsideMall[MAX_PLAYERS];

// Dynamic NPC data (loaded from DB table `mall_npcs`)
enum eMallNPC {
    mnpDBID,
    mnpMallID,
    mnpSkin,
    Float:mnpX, Float:mnpY, Float:mnpZ, Float:mnpAngle,
    mnpInterior,
    mnpVW,
    mnpLoketType,
    mnpName[32],
    mnpActorID,
    mnpLabelID
};
new MallNPCData[MAX_MALL_NPC_TOTAL][eMallNPC];
new MallNPCCount = 0;

// Temp for /mallnpc dialog
new TempNPCMallSlot[MAX_PLAYERS];

// Temp for mall setup dialogs
new TempMallCreatedSlot[MAX_PLAYERS];
new TempMallEditSlot[MAX_PLAYERS];

// Pre-defined interior options for Mall Pelayanan
#define MALL_INTERIOR_OPTIONS   3
enum eMallIntOption {
    mioName[32],
    Float:mioX, Float:mioY, Float:mioZ, Float:mioAngle,
    mioInterior
};
// Interior bawaan GTA:SA (ada lantai/dinding/langit-langit built-in, ga perlu custom objects)
new MallInteriorOpts[MALL_INTERIOR_OPTIONS][eMallIntOption] = {
    {"Kantor Pemerintahan",      386.53, 173.63, 1008.38,  180.0, 3},
    {"Balai Pelayanan",          238.66, 138.58, 1003.02,    0.0, 3},
    {"Gedung Pelayanan Modern",  246.40,  65.74, 1003.64,    0.0, 10}
};

// Queue system
new KTPQueue[MAX_MALL_PELAYANAN][MAX_KTP_QUEUE];
new KTPQueueCount[MAX_MALL_PELAYANAN];
new KTPServing[MAX_MALL_PELAYANAN];

// Temp KTP creation data
new TempKTPFullName[MAX_PLAYERS][64];
new TempKTPBirthPlace[MAX_PLAYERS][32];
new TempKTPAddress[MAX_PLAYERS][64];
new TempKTPMarital[MAX_PLAYERS][16];
new TempKTPOccupation[MAX_PLAYERS][32];
new TempKTPBlood[MAX_PLAYERS][4];
new TempKTPMall[MAX_PLAYERS];

static _ktp_msg[256];

// ============================================================================
// LOAD MALL PELAYANAN FROM DB
// ============================================================================

stock LoadMallPelayanan()
{
    mysql_function_query(MySQL_C1, "SELECT * FROM `mall_pelayanan` ORDER BY `id` ASC", true, "OnMallPelayananLoaded", "");
}

publics: OnMallPelayananLoaded()
{
    MallCount = 0;
    new rows = cache_get_row_count();
    if(rows > MAX_MALL_PELAYANAN) rows = MAX_MALL_PELAYANAN;

    for(new i = 0; i < rows; i++)
    {
        MallData[i][mID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", MallData[i][mName], MySQL_C1, 64);
        MallData[i][mPosX] = cache_get_field_content_float(i, "pos_x", MySQL_C1);
        MallData[i][mPosY] = cache_get_field_content_float(i, "pos_y", MySQL_C1);
        MallData[i][mPosZ] = cache_get_field_content_float(i, "pos_z", MySQL_C1);
        MallData[i][mAngle] = cache_get_field_content_float(i, "angle", MySQL_C1);
        MallData[i][mInterior] = cache_get_field_content_int(i, "interior", MySQL_C1);
        MallData[i][mVW] = cache_get_field_content_int(i, "vw", MySQL_C1);
        MallData[i][mIntX] = cache_get_field_content_float(i, "int_x", MySQL_C1);
        MallData[i][mIntY] = cache_get_field_content_float(i, "int_y", MySQL_C1);
        MallData[i][mIntZ] = cache_get_field_content_float(i, "int_z", MySQL_C1);
        MallData[i][mIntAngle] = cache_get_field_content_float(i, "int_angle", MySQL_C1);
        MallData[i][mIntInterior] = cache_get_field_content_int(i, "int_interior", MySQL_C1);
        MallData[i][mIntVW] = MALL_VW_BASE + MallData[i][mID];

        CreateMallWorld(i);
        MallCount++;
    }

    for(new i = 0; i < MAX_MALL_PELAYANAN; i++)
    {
        KTPServing[i] = INVALID_PLAYER_ID;
        KTPQueueCount[i] = 0;
        for(new j = 0; j < MAX_KTP_QUEUE; j++)
            KTPQueue[i][j] = INVALID_PLAYER_ID;
    }
    for(new i = 0; i < MAX_PLAYERS; i++)
        pInsideMall[i] = -1;

    printf("[KTP Service] Mall Pelayanan loaded: %d locations.", MallCount);

    // Load dynamic NPCs after malls are ready
    LoadMallNPCs();
}

// ============================================================================
// DYNAMIC NPC SYSTEM
// ============================================================================

stock LoadMallNPCs()
{
    mysql_function_query(MySQL_C1, "SELECT * FROM `mall_npcs` ORDER BY `id` ASC", true, "OnMallNPCsLoaded", "");
}

publics: OnMallNPCsLoaded()
{
    MallNPCCount = 0;
    new rows = cache_get_row_count();
    if(rows > MAX_MALL_NPC_TOTAL) rows = MAX_MALL_NPC_TOTAL;

    for(new i = 0; i < rows; i++)
    {
        MallNPCData[i][mnpDBID] = cache_get_field_content_int(i, "id", MySQL_C1);
        MallNPCData[i][mnpMallID] = cache_get_field_content_int(i, "mall_id", MySQL_C1);
        MallNPCData[i][mnpSkin] = cache_get_field_content_int(i, "skin", MySQL_C1);
        MallNPCData[i][mnpX] = cache_get_field_content_float(i, "pos_x", MySQL_C1);
        MallNPCData[i][mnpY] = cache_get_field_content_float(i, "pos_y", MySQL_C1);
        MallNPCData[i][mnpZ] = cache_get_field_content_float(i, "pos_z", MySQL_C1);
        MallNPCData[i][mnpAngle] = cache_get_field_content_float(i, "angle", MySQL_C1);
        MallNPCData[i][mnpInterior] = cache_get_field_content_int(i, "interior", MySQL_C1);
        MallNPCData[i][mnpVW] = cache_get_field_content_int(i, "vw", MySQL_C1);
        MallNPCData[i][mnpLoketType] = cache_get_field_content_int(i, "loket_type", MySQL_C1);
        cache_get_field_content(i, "name", MallNPCData[i][mnpName], MySQL_C1, 32);

        CreateSingleMallNPC(i);
        MallNPCCount++;
    }

    printf("[KTP Service] Mall NPCs loaded: %d actors.", MallNPCCount);

    printf("[KTP Service] Interior system menggunakan GTA built-in interiors (bukan custom objects).");
}

stock CreateSingleMallNPC(idx)
{
    if(idx < 0 || idx >= MAX_MALL_NPC_TOTAL) return;

    static label[128];

    MallNPCData[idx][mnpActorID] = CreateDynamicActor(MallNPCData[idx][mnpSkin],
        MallNPCData[idx][mnpX], MallNPCData[idx][mnpY], MallNPCData[idx][mnpZ],
        MallNPCData[idx][mnpAngle], .worldid = MallNPCData[idx][mnpVW],
        .interiorid = MallNPCData[idx][mnpInterior]);

    printf("[Mall NPC] idx=%d skin=%d ActorID=%d VW=%d Interior=%d pos=%.1f,%.1f,%.1f",
        idx, MallNPCData[idx][mnpSkin], MallNPCData[idx][mnpActorID],
        MallNPCData[idx][mnpVW], MallNPCData[idx][mnpInterior],
        MallNPCData[idx][mnpX], MallNPCData[idx][mnpY], MallNPCData[idx][mnpZ]);

    if(MallNPCData[idx][mnpLoketType] == LOKET_NONE)
        format(label, sizeof(label), "{AAAAAA}%s", MallNPCData[idx][mnpName]);
    else
        format(label, sizeof(label), "{FFAA00}%s\n{FFFFFF}/layanan", MallNPCData[idx][mnpName]);

    MallNPCData[idx][mnpLabelID] = _:CreateDynamic3DTextLabel(label, 0xFFAA00FF,
        MallNPCData[idx][mnpX], MallNPCData[idx][mnpY], MallNPCData[idx][mnpZ] + 1.0,
        10.0, .worldid = MallNPCData[idx][mnpVW], .interiorid = MallNPCData[idx][mnpInterior]);
}

stock DestroySingleMallNPC(idx)
{
    if(idx < 0 || idx >= MAX_MALL_NPC_TOTAL) return;

    if(MallNPCData[idx][mnpActorID] != -1)
    {
        DestroyDynamicActor(MallNPCData[idx][mnpActorID]);
        MallNPCData[idx][mnpActorID] = -1;
    }
    if(MallNPCData[idx][mnpLabelID] != -1)
    {
        DestroyDynamic3DTextLabel(Text3D:MallNPCData[idx][mnpLabelID]);
        MallNPCData[idx][mnpLabelID] = -1;
    }
}

stock DestroyMallNPCsByMallID(mallDBID)
{
    new i = 0;
    while(i < MallNPCCount)
    {
        if(MallNPCData[i][mnpMallID] == mallDBID)
        {
            DestroySingleMallNPC(i);
            for(new j = i; j < MallNPCCount - 1; j++)
                MallNPCData[j] = MallNPCData[j+1];
            MallNPCCount--;
        }
        else
            i++;
    }
}

// ============================================================================
// CREATE / DESTROY OUTDOOR WORLD OBJECTS
// ============================================================================

stock CreateMallWorld(idx)
{
    static label[128];

    MallData[idx][mEntryActorID] = -1; // No auto entry actor — admin places NPCs manually

    MallData[idx][mPickupID] = CreateDynamicPickup(1239, 1,
        MallData[idx][mPosX], MallData[idx][mPosY], MallData[idx][mPosZ],
        MallData[idx][mVW], MallData[idx][mInterior]);

    format(label, sizeof(label), "{FFAA00}%s\n{FFFFFF}Tekan ~k~~VEHICLE_ENTER_EXIT~ untuk masuk", MallData[idx][mName]);
    MallData[idx][mLabelID] = _:CreateDynamic3DTextLabel(label, 0xFFAA00FF,
        MallData[idx][mPosX], MallData[idx][mPosY], MallData[idx][mPosZ] + 0.5,
        15.0, .worldid = MallData[idx][mVW], .interiorid = MallData[idx][mInterior]);

    // Create exit door inside interior (if configured)
    MallData[idx][mExitPickupID] = -1;
    MallData[idx][mExitLabelID] = -1;
    CreateMallExitDoor(idx);
}

stock DestroyMallWorld(idx)
{
    printf("[DEBUG-DMW] DestroyMallWorld(%d) entry. ActorID=%d, PickupID=%d, LabelID=%d",
        idx, MallData[idx][mEntryActorID], MallData[idx][mPickupID], MallData[idx][mLabelID]);
    MallData[idx][mEntryActorID] = -1; // entry actor not used
    if(MallData[idx][mPickupID] != -1)
    {
        printf("[DEBUG-DMW] Destroying Pickup %d", MallData[idx][mPickupID]);
        DestroyDynamicPickup(MallData[idx][mPickupID]);
        MallData[idx][mPickupID] = -1;
    }
    if(MallData[idx][mLabelID] != -1)
    {
        printf("[DEBUG-DMW] Destroying Label %d", MallData[idx][mLabelID]);
        DestroyDynamic3DTextLabel(Text3D:MallData[idx][mLabelID]);
        MallData[idx][mLabelID] = -1;
    }
    // Destroy exit door inside interior
    DestroyMallExitDoor(idx);
    printf("[DEBUG-DMW] DestroyMallWorld(%d) done", idx);
}

// ============================================================================
// EXIT DOOR — Pickup + Label inside the mall interior
// ============================================================================

stock CreateMallExitDoor(idx)
{
    // Destroy existing exit door if any
    DestroyMallExitDoor(idx);

    // Only create if interior has been configured (non-zero position)
    if(MallData[idx][mIntX] > -1.0 && MallData[idx][mIntX] < 1.0 &&
       MallData[idx][mIntY] > -1.0 && MallData[idx][mIntY] < 1.0 &&
       MallData[idx][mIntZ] > -1.0 && MallData[idx][mIntZ] < 1.0)
        return 0;

    MallData[idx][mExitPickupID] = CreateDynamicPickup(1318, 1,
        MallData[idx][mIntX], MallData[idx][mIntY], MallData[idx][mIntZ],
        MallData[idx][mIntVW], MallData[idx][mIntInterior]);

    static exitlbl[128];
    format(exitlbl, sizeof(exitlbl), "{FF4444}Pintu Keluar\n{FFFFFF}Tekan ~k~~VEHICLE_ENTER_EXIT~ untuk keluar");
    MallData[idx][mExitLabelID] = _:CreateDynamic3DTextLabel(exitlbl, 0xFF4444FF,
        MallData[idx][mIntX], MallData[idx][mIntY], MallData[idx][mIntZ] + 0.5,
        15.0, .worldid = MallData[idx][mIntVW], .interiorid = MallData[idx][mIntInterior]);

    return 1;
}

stock DestroyMallExitDoor(idx)
{
    if(MallData[idx][mExitPickupID] != -1)
    {
        DestroyDynamicPickup(MallData[idx][mExitPickupID]);
        MallData[idx][mExitPickupID] = -1;
    }
    if(MallData[idx][mExitLabelID] != -1)
    {
        DestroyDynamic3DTextLabel(Text3D:MallData[idx][mExitLabelID]);
        MallData[idx][mExitLabelID] = -1;
    }
}

// ============================================================================
// DELETE MALL HELPER (isolated function to prevent stack corruption)
// Uses static buffers — no stack allocation for strings
// ============================================================================

stock DeleteMallInternal(playerid, mallIdx)
{
    printf("[DEBUG-DEL] DeleteMallInternal(playerid=%d, mallIdx=%d) MallCount=%d heapspace=%d",
        playerid, mallIdx, MallCount, heapspace());

    if(mallIdx < 0 || mallIdx >= MallCount) return 0;

    new dbid = MallData[mallIdx][mID];
    static delName[64];
    format(delName, sizeof(delName), "%s", MallData[mallIdx][mName]);

    printf("[DEBUG-DEL] dbid=%d, name=%s", dbid, delName);

    // 1) Clear queue & serving
    for(new q = 0; q < KTPQueueCount[mallIdx]; q++)
    {
        new pid = KTPQueue[mallIdx][q];
        if(IsPlayerConnected(pid))
            SendClientMessage(pid, COLOR_RED, "Mall Pelayanan dihapus. Antrian dibatalkan.");
    }
    KTPQueueCount[mallIdx] = 0;
    if(KTPServing[mallIdx] != INVALID_PLAYER_ID)
    {
        new pid = KTPServing[mallIdx];
        if(IsPlayerConnected(pid))
            SendClientMessage(pid, COLOR_RED, "Mall Pelayanan dihapus. Layanan dibatalkan.");
        KTPServing[mallIdx] = INVALID_PLAYER_ID;
    }

    // 2) Save entry positions BEFORE any destruction/shift
    new Float:savedX = MallData[mallIdx][mPosX];
    new Float:savedY = MallData[mallIdx][mPosY];
    new Float:savedZ = MallData[mallIdx][mPosZ];
    new savedInt = MallData[mallIdx][mInterior];
    new savedVW  = MallData[mallIdx][mVW];

    // 3) Destroy outdoor world objects
    printf("[DEBUG-DEL] DestroyMallWorld(%d)", mallIdx);
    DestroyMallWorld(mallIdx);

    // 4) Destroy all NPCs belonging to this mall
    printf("[DEBUG-DEL] DestroyMallNPCsByMallID(%d)", dbid);
    DestroyMallNPCsByMallID(dbid);

    // 5) Shift array
    printf("[DEBUG-DEL] Shifting array");
    for(new i = mallIdx; i < MallCount - 1; i++)
    {
        MallData[i] = MallData[i+1];
        for(new q = 0; q < MAX_KTP_QUEUE; q++)
            KTPQueue[i][q] = KTPQueue[i+1][q];
        KTPQueueCount[i] = KTPQueueCount[i+1];
        KTPServing[i] = KTPServing[i+1];
    }
    MallCount--;

    // 6) Clear last slot
    MallData[MallCount][mID] = 0;
    MallData[MallCount][mName][0] = EOS;
    MallData[MallCount][mEntryActorID] = -1;
    MallData[MallCount][mPickupID] = -1;
    MallData[MallCount][mLabelID] = -1;
    MallData[MallCount][mExitPickupID] = -1;
    MallData[MallCount][mExitLabelID] = -1;
    KTPServing[MallCount] = INVALID_PLAYER_ID;
    KTPQueueCount[MallCount] = 0;

    // 7) Eject players that were inside this mall
    printf("[DEBUG-DEL] Ejecting players");
    for(new p = 0; p < MAX_PLAYERS; p++)
    {
        if(pInsideMall[p] == mallIdx)
        {
            SetPlayerPos(p, savedX, savedY, savedZ);
            SetPlayerInterior(p, savedInt);
            SetPlayerVirtualWorld(p, savedVW);
            pInsideMall[p] = -1;
            SendClientMessage(p, COLOR_RED, "Mall dihapus. Kamu dipindahkan keluar.");
        }
        else if(pInsideMall[p] > mallIdx)
            pInsideMall[p]--;
    }

    // 8) DB delete (THREADED to avoid potential sync-query crash)
    printf("[DEBUG-DEL] DB delete (threaded). dbid=%d", dbid);
    static dq[128];
    format(dq, sizeof(dq), "DELETE FROM `mall_npcs` WHERE `mall_id` = '%d'", dbid);
    mysql_function_query(MySQL_C1, dq, true, "", "");
    format(dq, sizeof(dq), "DELETE FROM `mall_pelayanan` WHERE `id` = '%d'", dbid);
    mysql_function_query(MySQL_C1, dq, true, "", "");

    // 9) Success message (use manual format+SendClientMessage — SendClientFormattedMessage #emit crashes here)
    printf("[DEBUG-DEL] Sending success message. heapspace=%d", heapspace());
    static msg[128];
    format(msg, sizeof(msg), "Mall '%s' (DB:%d) berhasil dihapus.", delName, dbid);
    printf("[DEBUG-DEL] formatted msg OK");
    SendClientMessage(playerid, 0x00FF00FF, msg);
    printf("[DEBUG-DEL] DeleteMallInternal COMPLETE");
    return 1;
}

// ============================================================================
// HELPERS
// ============================================================================

stock GetNearestMallPelayanan(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    for(new i = 0; i < MallCount; i++)
    {
        new Float:dx = px - MallData[i][mPosX];
        new Float:dy = py - MallData[i][mPosY];
        new Float:dz = pz - MallData[i][mPosZ];
        new Float:dist = floatsqroot(dx*dx + dy*dy + dz*dz);
        if(dist <= 8.0) return i;
    }
    return -1;
}

stock GenerateNIK(playerid, mallIdx, nik[], size)
{
    new cityCode = 317400 + MallData[mallIdx][mID];
    new age = PlayerInfo[playerid][pICAge];
    new bYear = 2024 - age;
    new bDay = random(28) + 1;
    new bMonth = random(12) + 1;
    if(PlayerInfo[playerid][pGender] == 2) bDay += 40;
    new seq = random(9000) + 1000;
    format(nik, size, "%06d%02d%02d%02d%04d", cityCode, bDay, bMonth, bYear % 100, seq);
}

stock NotifyNewPlayerKTP(playerid)
{
    if(!PlayerInfo[playerid][pHasKTP])
    {
        SendClientMessage(playerid, COLOR_YELLOW, "=========================================");
        SendClientMessage(playerid, COLOR_YELLOW, " Kamu belum memiliki KTP!");
        SendClientMessage(playerid, COLOR_YELLOW, " Kunjungi Mall Pelayanan terdekat");
        SendClientMessage(playerid, COLOR_YELLOW, " dan tekan F untuk masuk, lalu /layanan");
        SendClientMessage(playerid, COLOR_YELLOW, "=========================================");
    }
}

// ============================================================================
// MALL ENTRY / EXIT (F KEY)
// ============================================================================

stock HandleMallKeyPress(playerid)
{
    // If player is INSIDE a mall -> check exit
    if(pInsideMall[playerid] >= 0)
    {
        new idx = pInsideMall[playerid];
        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);

        new Float:dx = px - MallData[idx][mIntX];
        new Float:dy = py - MallData[idx][mIntY];
        new Float:dz = pz - MallData[idx][mIntZ];
        new Float:dist = floatsqroot(dx*dx + dy*dy + dz*dz);
        if(dist <= 3.0)
        {
            SetPlayerPos(playerid, MallData[idx][mPosX], MallData[idx][mPosY], MallData[idx][mPosZ]);
            SetPlayerFacingAngle(playerid, MallData[idx][mAngle]);
            SetPlayerInterior(playerid, MallData[idx][mInterior]);
            SetPlayerVirtualWorld(playerid, MallData[idx][mVW]);
            SetCameraBehindPlayer(playerid);

            RemoveFromKTPQueue(playerid);
            pInsideMall[playerid] = -1;

            new rpmsg[80];
            format(rpmsg, sizeof(rpmsg), "* %s keluar dari Mall Pelayanan.", PlayerInfo[playerid][pICName]);
            ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
            GameTextForPlayer(playerid, "~w~Keluar dari ~y~Mall Pelayanan", 3000, 6);
            return 1;
        }
        return 0;
    }

    // If player is OUTSIDE -> check if near any mall outdoor entry
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    for(new i = 0; i < MallCount; i++)
    {
        if(GetPlayerInterior(playerid) != MallData[i][mInterior]) continue;
        if(GetPlayerVirtualWorld(playerid) != MallData[i][mVW]) continue;

        new Float:dx = px - MallData[i][mPosX];
        new Float:dy = py - MallData[i][mPosY];
        new Float:dz = pz - MallData[i][mPosZ];
        new Float:dist = floatsqroot(dx*dx + dy*dy + dz*dz);
        if(dist <= 3.0)
        {
            if(MallData[i][mIntX] > -1.0 && MallData[i][mIntX] < 1.0 &&
               MallData[i][mIntY] > -1.0 && MallData[i][mIntY] < 1.0 &&
               MallData[i][mIntZ] > -1.0 && MallData[i][mIntZ] < 1.0)
            {
                SendClientMessage(playerid, COLOR_RED, "Mall ini belum dikonfigurasi interiornya.");
                SendClientMessage(playerid, COLOR_YELLOW, "Admin harus set interior dulu: /setmallinterior [slot]");
                return 1;
            }

            // Teleport langsung ke interior GTA bawaan (ada lantai built-in)
            SetPlayerInterior(playerid, MallData[i][mIntInterior]);
            SetPlayerVirtualWorld(playerid, MallData[i][mIntVW]);
            SetPlayerPos(playerid, MallData[i][mIntX], MallData[i][mIntY], MallData[i][mIntZ]);
            SetPlayerFacingAngle(playerid, MallData[i][mIntAngle]);
            SetCameraBehindPlayer(playerid);

            pInsideMall[playerid] = i;

            new rpmsg[80];
            format(rpmsg, sizeof(rpmsg), "* %s memasuki Mall Pelayanan.", PlayerInfo[playerid][pICName]);
            ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

            format(_ktp_msg, sizeof(_ktp_msg), "Selamat datang di %s!", MallData[i][mName]);
            SendClientMessage(playerid, COLOR_YELLOW, _ktp_msg);
            SendClientMessage(playerid, COLOR_YELLOW, "Datangi loket yang diinginkan, lalu ketik /layanan");
            SendClientMessage(playerid, COLOR_YELLOW, "Tekan F di pintu masuk untuk keluar.");
            GameTextForPlayer(playerid, "~w~Masuk ke ~y~Mall Pelayanan", 3000, 6);
            return 1;
        }
    }
    return 0;
}

// Get which loket NPC the player is nearest to (uses dynamic NPC data)
stock GetNearestLoketType(playerid)
{
    new idx = pInsideMall[playerid];
    if(idx < 0) return -1;

    new mallDBID = MallData[idx][mID];
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new Float:bestDist = 999.0;
    new bestLoket = -1;

    for(new n = 0; n < MallNPCCount; n++)
    {
        if(MallNPCData[n][mnpMallID] != mallDBID) continue;
        if(MallNPCData[n][mnpLoketType] == LOKET_NONE) continue;
        if(MallNPCData[n][mnpActorID] == -1) continue;

        new Float:dx = px - MallNPCData[n][mnpX];
        new Float:dy = py - MallNPCData[n][mnpY];
        new Float:dz = pz - MallNPCData[n][mnpZ];
        new Float:dist = floatsqroot(dx*dx + dy*dy + dz*dz);

        if(dist < 3.0 && dist < bestDist)
        {
            bestDist = dist;
            bestLoket = MallNPCData[n][mnpLoketType];
        }
    }
    return bestLoket;
}

// ============================================================================
// QUEUE SYSTEM
// ============================================================================

stock KTPServiceNextInQueue(mall)
{
    if(mall < 0 || mall >= MallCount) return;
    KTPServing[mall] = INVALID_PLAYER_ID;

    while(KTPQueueCount[mall] > 0)
    {
        new nextPlayer = KTPQueue[mall][0];
        for(new i = 0; i < KTPQueueCount[mall] - 1; i++)
            KTPQueue[mall][i] = KTPQueue[mall][i+1];
        KTPQueue[mall][KTPQueueCount[mall] - 1] = INVALID_PLAYER_ID;
        KTPQueueCount[mall]--;

        if(IsPlayerConnected(nextPlayer) && PlayerInfo[nextPlayer][pLogged])
        {
            if(pInsideMall[nextPlayer] == mall)
            {
                KTPServing[mall] = nextPlayer;
                SendClientMessage(nextPlayer, 0x00FF00FF, "Nomor antrian kamu dipanggil! Silakan ke loket.");
                ShowKTPServiceMenu(nextPlayer);
                return;
            }
        }
    }
}

stock RemoveFromKTPQueue(playerid)
{
    for(new c = 0; c < MallCount; c++)
    {
        if(KTPServing[c] == playerid)
        {
            KTPServiceNextInQueue(c);
            return;
        }
        for(new q = 0; q < KTPQueueCount[c]; q++)
        {
            if(KTPQueue[c][q] == playerid)
            {
                for(new s = q; s < KTPQueueCount[c] - 1; s++)
                    KTPQueue[c][s] = KTPQueue[c][s+1];
                KTPQueue[c][KTPQueueCount[c] - 1] = INVALID_PLAYER_ID;
                KTPQueueCount[c]--;
                return;
            }
        }
    }
}

// ============================================================================
// MALL SETUP (all-in-one dialog)
// ============================================================================

CMD:mallsetup(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    ShowPlayerDialog(playerid, DIALOG_MALL_SETUP, DIALOG_STYLE_LIST,
        "{FFAA00}Mall Pelayanan Setup",
        "Buat Mall Baru\nEdit Mall\nHapus Mall",
        "Pilih", "Tutup");
    return 1;
}

// Helper: build mall list string for dialogs
stock BuildMallListString(dest[], size)
{
    dest[0] = EOS;
    for(new i = 0; i < MallCount; i++)
    {
        new tmp[80];
        new npcCount = 0;
        for(new n = 0; n < MallNPCCount; n++)
            if(MallNPCData[n][mnpMallID] == MallData[i][mID]) npcCount++;

        new intStatus[16];
        if(MallData[i][mIntX] != 0.0 || MallData[i][mIntY] != 0.0)
            intStatus = "{00FF00}OK";
        else
            intStatus = "{FF0000}Belum";

        format(tmp, sizeof(tmp), "[%d] %s | Interior: %s {FFFFFF}| NPC: %d", i, MallData[i][mName], intStatus, npcCount);
        strcat(dest, tmp, size);
        if(i < MallCount - 1) strcat(dest, "\n", size);
    }
}

// Helper: internal create mall (used by dialog and /setmall)
stock CreateMallInternal(playerid, mallname[])
{
    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    new interior = GetPlayerInterior(playerid);
    new vw = GetPlayerVirtualWorld(playerid);

    static q[512];
    mysql_format(MySQL_C1, q, sizeof(q), "INSERT INTO `mall_pelayanan` (`name`,`pos_x`,`pos_y`,`pos_z`,`angle`,`interior`,`vw`,`created_by`,`created_at`) VALUES ('%e','%f','%f','%f','%f','%d','%d','%e','%d')", mallname, px, py, pz, pa, interior, vw, PlayerInfo[playerid][pName], gettime());
    mysql_function_query(MySQL_C1, q, true, "OnMallCreated", "d", playerid);
}

// ============================================================================
// DEVELOPER COMMANDS: /setmall, /delmall, /movemall, /malllist (shortcuts)
// ============================================================================

CMD:setmall(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    new mallname[64];
    if(sscanf(params, "s[64]", mallname))
        return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /setmall [nama]"), 1;

    if(MallCount >= MAX_MALL_PELAYANAN)
    {
        format(_ktp_msg, sizeof(_ktp_msg), "Maksimal %d Mall Pelayanan!", MAX_MALL_PELAYANAN);
        return SendClientMessage(playerid, COLOR_RED, _ktp_msg), 1;
    }

    CreateMallInternal(playerid, mallname);
    return 1;
}

publics: OnMallCreated(playerid)
{
    new idx = MallCount;
    if(idx >= MAX_MALL_PELAYANAN) return 1;

    MallData[idx][mID] = cache_insert_id();
    GetPlayerPos(playerid, MallData[idx][mPosX], MallData[idx][mPosY], MallData[idx][mPosZ]);
    GetPlayerFacingAngle(playerid, MallData[idx][mAngle]);
    MallData[idx][mInterior] = GetPlayerInterior(playerid);
    MallData[idx][mVW] = GetPlayerVirtualWorld(playerid);

    new q[128];
    format(q, sizeof(q), "SELECT `name` FROM `mall_pelayanan` WHERE `id` = '%d'", MallData[idx][mID]);
    mysql_function_query(MySQL_C1, q, true, "OnMallNameLoaded", "d", idx);

    MallCount++;
    format(_ktp_msg, sizeof(_ktp_msg), "Mall Pelayanan berhasil dibuat! (ID: %d)", MallData[idx][mID]);
    SendClientMessage(playerid, 0x00FF00FF, _ktp_msg);

    // Show interior selection dialog
    TempMallCreatedSlot[playerid] = idx;
    new dlg[256];
    dlg[0] = EOS;
    for(new i = 0; i < MALL_INTERIOR_OPTIONS; i++)
    {
        strcat(dlg, MallInteriorOpts[i][mioName], sizeof(dlg));
        if(i < MALL_INTERIOR_OPTIONS - 1) strcat(dlg, "\n", sizeof(dlg));
    }
    ShowPlayerDialog(playerid, DIALOG_MALL_INT_SEL, DIALOG_STYLE_LIST,
        "{FFAA00}Pilih Interior Mall", dlg, "Preview", "Nanti");
    return 1;
}

publics: OnMallNameLoaded(idx)
{
    if(cache_get_row_count() > 0)
        cache_get_field_content(0, "name", MallData[idx][mName], MySQL_C1, 64);
    else
        format(MallData[idx][mName], 64, "Mall Pelayanan #%d", MallData[idx][mID]);
    CreateMallWorld(idx);
    return 1;
}

CMD:delmall(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    new mallIdx = GetNearestMallPelayanan(playerid);
    if(mallIdx == -1)
        return SendClientMessage(playerid, COLOR_RED, "Tidak ada Mall Pelayanan dalam radius 8m!"), 1;

    DeleteMallInternal(playerid, mallIdx);
    return 1;
}

CMD:movemall(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    new mallIdx = GetNearestMallPelayanan(playerid);
    if(mallIdx == -1)
        return SendClientMessage(playerid, COLOR_RED, "Tidak ada Mall Pelayanan dalam radius 8m!"), 1;

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    new interior = GetPlayerInterior(playerid);
    new vw = GetPlayerVirtualWorld(playerid);

    DestroyMallWorld(mallIdx);

    MallData[mallIdx][mPosX] = px;
    MallData[mallIdx][mPosY] = py;
    MallData[mallIdx][mPosZ] = pz;
    MallData[mallIdx][mAngle] = pa;
    MallData[mallIdx][mInterior] = interior;
    MallData[mallIdx][mVW] = vw;

    CreateMallWorld(mallIdx);

    static q_mov[256];
    mysql_format(MySQL_C1, q_mov, sizeof(q_mov), "UPDATE `mall_pelayanan` SET `pos_x`='%f', `pos_y`='%f', `pos_z`='%f', `angle`='%f', `interior`='%d', `vw`='%d' WHERE `id`='%d'", px, py, pz, pa, interior, vw, MallData[mallIdx][mID]);
    mysql_function_query(MySQL_C1, q_mov, false, "", "");

    format(_ktp_msg, sizeof(_ktp_msg), "Mall '%s' dipindahkan ke posisi kamu.", MallData[mallIdx][mName]);
    SendClientMessage(playerid, 0x00FF00FF, _ktp_msg);
    return 1;
}

CMD:malllist(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    if(MallCount == 0)
        return SendClientMessage(playerid, COLOR_YELLOW, "Belum ada Mall Pelayanan. Gunakan /setmall [nama]."), 1;

    format(_ktp_msg, sizeof(_ktp_msg), "=== Mall Pelayanan (%d) ===", MallCount);
    SendClientMessage(playerid, COLOR_YELLOW, _ktp_msg);
    for(new i = 0; i < MallCount; i++)
    {
        // Count NPCs for this mall
        new npcCount = 0;
        for(new n = 0; n < MallNPCCount; n++)
            if(MallNPCData[n][mnpMallID] == MallData[i][mID]) npcCount++;

        format(_ktp_msg, sizeof(_ktp_msg), "[%d] %s (DB:%d) - NPC: %d",
            i, MallData[i][mName], MallData[i][mID], npcCount);
        SendClientMessage(playerid, -1, _ktp_msg);

        if(MallData[i][mIntX] != 0.0 || MallData[i][mIntY] != 0.0)
        {
            format(_ktp_msg, sizeof(_ktp_msg), "    Interior: %f, %f, %f (Int:%d VW:%d)",
                MallData[i][mIntX], MallData[i][mIntY], MallData[i][mIntZ],
                MallData[i][mIntInterior], MallData[i][mIntVW]);
            SendClientMessage(playerid, -1, _ktp_msg);
        }
        else
            SendClientMessage(playerid, COLOR_RED, "    Interior: BELUM DIKONFIGURASI");
    }
    return 1;
}

// ============================================================================
// INTERIOR PREVIEW & SETUP
// ============================================================================

CMD:previewinterior(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    new mallSlot;
    if(sscanf(params, "d", mallSlot))
        return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /previewinterior [slot]  (lihat /malllist)"), 1;

    if(mallSlot < 0 || mallSlot >= MallCount)
    {
        format(_ktp_msg, sizeof(_ktp_msg), "Slot tidak valid! (0 - %d)", MallCount - 1);
        return SendClientMessage(playerid, COLOR_RED, _ktp_msg), 1;
    }

    TempMallCreatedSlot[playerid] = mallSlot;

    new dlg[256];
    dlg[0] = EOS;
    for(new i = 0; i < MALL_INTERIOR_OPTIONS; i++)
    {
        strcat(dlg, MallInteriorOpts[i][mioName], sizeof(dlg));
        if(i < MALL_INTERIOR_OPTIONS - 1) strcat(dlg, "\n", sizeof(dlg));
    }
    ShowPlayerDialog(playerid, DIALOG_MALL_INT_SEL, DIALOG_STYLE_LIST,
        "{FFAA00}Pilih Interior Mall", dlg, "Preview", "Batal");
    return 1;
}

CMD:setmallinterior(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    new mallSlot;
    if(sscanf(params, "d", mallSlot))
        return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /setmallinterior [slot]  (lihat /malllist)"), 1;

    if(mallSlot < 0 || mallSlot >= MallCount)
    {
        format(_ktp_msg, sizeof(_ktp_msg), "Slot tidak valid! (0 - %d)", MallCount - 1);
        return SendClientMessage(playerid, COLOR_RED, _ktp_msg), 1;
    }

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    new pint = GetPlayerInterior(playerid);
    new intVW = MALL_VW_BASE + MallData[mallSlot][mID];

    // Update runtime
    MallData[mallSlot][mIntX] = px;
    MallData[mallSlot][mIntY] = py;
    MallData[mallSlot][mIntZ] = pz;
    MallData[mallSlot][mIntAngle] = pa;
    MallData[mallSlot][mIntInterior] = pint;
    MallData[mallSlot][mIntVW] = intVW;

    // Save to DB
    static q[256];
    mysql_format(MySQL_C1, q, sizeof(q),
        "UPDATE `mall_pelayanan` SET `int_x`='%f',`int_y`='%f',`int_z`='%f',`int_angle`='%f',`int_interior`='%d',`int_vw`='%d' WHERE `id`='%d'",
        px, py, pz, pa, pint, intVW, MallData[mallSlot][mID]);
    mysql_function_query(MySQL_C1, q, false, "", "");

    // (Re)create exit door pickup + label at the new interior pos
    CreateMallExitDoor(mallSlot);

    static smi_msg[128];
    format(smi_msg, sizeof(smi_msg), "Interior Mall '%s' berhasil di-set di posisi kamu!", MallData[mallSlot][mName]);
    SendClientMessage(playerid, 0x00FF00FF, smi_msg);
    format(smi_msg, sizeof(smi_msg), "VW diubah ke %d. Sekarang gunakan /mallnpc %d untuk menaruh NPC.", intVW, mallSlot);
    SendClientMessage(playerid, COLOR_YELLOW, smi_msg);
    return 1;
}

// ============================================================================
// NPC PLACEMENT: /mallnpc, /delmallnpc, /mallnpclist
// ============================================================================

CMD:mallnpc(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    new mallSlot;
    if(sscanf(params, "d", mallSlot))
        return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /mallnpc [slot]  (lihat /malllist)"), 1;

    if(mallSlot < 0 || mallSlot >= MallCount)
    {
        format(_ktp_msg, sizeof(_ktp_msg), "Slot tidak valid! (0 - %d)", MallCount - 1);
        return SendClientMessage(playerid, COLOR_RED, _ktp_msg), 1;
    }

    if(MallNPCCount >= MAX_MALL_NPC_TOTAL)
    {
        format(_ktp_msg, sizeof(_ktp_msg), "Batas NPC global tercapai (%d)!", MAX_MALL_NPC_TOTAL);
        return SendClientMessage(playerid, COLOR_RED, _ktp_msg), 1;
    }

    TempNPCMallSlot[playerid] = mallSlot;

    ShowPlayerDialog(playerid, DIALOG_MALLNPC_TYPE, DIALOG_STYLE_LIST,
        "{FFAA00}Pilih Tipe NPC",
        "Satpam (Penjaga)\nResepsionis\nLoket Dukcapil (KTP)\nLoket Perizinan\nLoket Pajak\nLoket Surat Keterangan",
        "Pasang", "Batal");
    return 1;
}

publics: OnMallNPCCreated(idx)
{
    if(idx >= 0 && idx < MAX_MALL_NPC_TOTAL)
        MallNPCData[idx][mnpDBID] = cache_insert_id();
    return 1;
}

CMD:delmallnpc(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new Float:bestDist = 999.0;
    new bestIdx = -1;

    for(new n = 0; n < MallNPCCount; n++)
    {
        if(MallNPCData[n][mnpActorID] == -1) continue;
        new Float:dx = px - MallNPCData[n][mnpX];
        new Float:dy = py - MallNPCData[n][mnpY];
        new Float:dz = pz - MallNPCData[n][mnpZ];
        new Float:dist = floatsqroot(dx*dx + dy*dy + dz*dz);
        if(dist < 3.0 && dist < bestDist)
        {
            bestDist = dist;
            bestIdx = n;
        }
    }

    if(bestIdx == -1)
        return SendClientMessage(playerid, COLOR_RED, "Tidak ada NPC Mall dalam radius 3m!"), 1;

    new npcName[32], npcDBID;
    format(npcName, sizeof(npcName), "%s", MallNPCData[bestIdx][mnpName]);
    npcDBID = MallNPCData[bestIdx][mnpDBID];

    // Destroy actor & label
    DestroySingleMallNPC(bestIdx);

    // Delete from DB
    static dq[64];
    format(dq, sizeof(dq), "DELETE FROM `mall_npcs` WHERE `id` = '%d'", npcDBID);
    mysql_function_query(MySQL_C1, dq, false, "", "");

    // Shift array
    for(new j = bestIdx; j < MallNPCCount - 1; j++)
        MallNPCData[j] = MallNPCData[j+1];
    MallNPCCount--;

    format(_ktp_msg, sizeof(_ktp_msg), "NPC '%s' (DB:%d) dihapus.", npcName, npcDBID);
    SendClientMessage(playerid, 0x00FF00FF, _ktp_msg);
    return 1;
}

CMD:mallnpclist(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only!"), 1;

    new mallSlot;
    if(sscanf(params, "d", mallSlot))
        return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /mallnpclist [slot]  (lihat /malllist)"), 1;

    if(mallSlot < 0 || mallSlot >= MallCount)
        return SendClientMessage(playerid, COLOR_RED, "Slot tidak valid!"), 1;

    new mallDBID = MallData[mallSlot][mID];
    new count = 0;

    format(_ktp_msg, sizeof(_ktp_msg), "=== NPC di Mall '%s' (DB:%d) ===", MallData[mallSlot][mName], mallDBID);
    SendClientMessage(playerid, COLOR_YELLOW, _ktp_msg);

    for(new n = 0; n < MallNPCCount; n++)
    {
        if(MallNPCData[n][mnpMallID] != mallDBID) continue;

        new typeStr[20];
        switch(MallNPCData[n][mnpLoketType])
        {
            case LOKET_NONE: typeStr = "Satpam";
            case LOKET_RESEPSIONIS: typeStr = "Resepsionis";
            case LOKET_DUKCAPIL: typeStr = "Dukcapil";
            case LOKET_PERIZINAN: typeStr = "Perizinan";
            case LOKET_PAJAK: typeStr = "Pajak";
            case LOKET_SURKET: typeStr = "Surat Ket.";
            default: typeStr = "Unknown";
        }

        format(_ktp_msg, sizeof(_ktp_msg), "  [DB:%d] %s (%s) Skin:%d Pos:%f,%f,%f",
            MallNPCData[n][mnpDBID], MallNPCData[n][mnpName], typeStr,
            MallNPCData[n][mnpSkin],
            MallNPCData[n][mnpX], MallNPCData[n][mnpY], MallNPCData[n][mnpZ]);
        SendClientMessage(playerid, -1, _ktp_msg);
        count++;
    }

    if(count == 0)
    {
        format(_ktp_msg, sizeof(_ktp_msg), "  Belum ada NPC. Gunakan /mallnpc %d untuk menambah.", mallSlot);
        SendClientMessage(playerid, COLOR_RED, _ktp_msg);
    }
    else
    {
        format(_ktp_msg, sizeof(_ktp_msg), "Total: %d NPC", count);
        SendClientMessage(playerid, COLOR_YELLOW, _ktp_msg);
    }
    return 1;
}

// ============================================================================
// /layanan COMMAND
// ============================================================================

CMD:layanan(playerid, params[])
{
    new mall = pInsideMall[playerid];
    if(mall < 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Kamu harus masuk ke Mall Pelayanan terlebih dahulu! (Tekan F di pintu masuk)");
        return 1;
    }

    new loketType = GetNearestLoketType(playerid);
    if(loketType < 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Kamu tidak berada di dekat loket manapun!");
        SendClientMessage(playerid, COLOR_YELLOW, "Datangi salah satu loket pelayanan yang tersedia.");
        return 1;
    }

    // Check if already in queue or being served
    for(new c = 0; c < MallCount; c++)
    {
        if(KTPServing[c] == playerid)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Kamu sedang dilayani!");
            return 1;
        }
        for(new q = 0; q < KTPQueueCount[c]; q++)
        {
            if(KTPQueue[c][q] == playerid)
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Kamu sudah dalam antrian! Tunggu giliranmu.");
                return 1;
            }
        }
    }

    switch(loketType)
    {
        case LOKET_RESEPSIONIS:
        {
            SendClientMessage(playerid, 0xFFAA00FF, "Resepsionis: \"Selamat datang! Silakan ke loket yang sesuai kebutuhan Anda.\"");
            SendClientMessage(playerid, COLOR_YELLOW, "  Loket Dukcapil - Pembuatan KTP");
            SendClientMessage(playerid, COLOR_YELLOW, "  Loket Perizinan - NIB / Ijin Usaha");
            SendClientMessage(playerid, COLOR_YELLOW, "  Loket Pajak - NPWP / Pembayaran Pajak");
            SendClientMessage(playerid, COLOR_YELLOW, "  Loket Surat Ket. - Surat Keterangan");
            return 1;
        }
        case LOKET_DUKCAPIL:
        {
            TempKTPMall[playerid] = mall;

            new rpmsg[80];
            format(rpmsg, sizeof(rpmsg), "* %s mendekati Loket Dukcapil.", PlayerInfo[playerid][pICName]);
            ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

            if(KTPServing[mall] == INVALID_PLAYER_ID && KTPQueueCount[mall] == 0)
            {
                KTPServing[mall] = playerid;
                ShowKTPServiceMenu(playerid);
            }
            else
            {
                if(KTPQueueCount[mall] >= MAX_KTP_QUEUE)
                {
                    SendClientMessage(playerid, COLOR_RED, "Antrian penuh! Coba lagi nanti.");
                    return 1;
                }
                KTPQueue[mall][KTPQueueCount[mall]] = playerid;
                KTPQueueCount[mall]++;

                new qdlg[128];
                format(qdlg, sizeof(qdlg), "{FFFFFF}Nomor antrian kamu: {FFAA00}%d\n\n{FFFFFF}Tunggu di area loket.", KTPQueueCount[mall]);
                ShowPlayerDialog(playerid, DIALOG_KTP_QUEUE, DIALOG_STYLE_MSGBOX,
                    "{FFAA00}Antrian Pelayanan", qdlg, "OK", "Batal");
            }
            return 1;
        }
        case LOKET_PERIZINAN:
        {
            new rpmsg[80];
            format(rpmsg, sizeof(rpmsg), "* %s mendekati Loket Perizinan.", PlayerInfo[playerid][pICName]);
            ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
            SendClientMessage(playerid, 0xFFAA00FF, "Petugas: \"Maaf, layanan perizinan sedang dalam pengembangan.\"");
            return 1;
        }
        case LOKET_PAJAK:
        {
            new rpmsg[80];
            format(rpmsg, sizeof(rpmsg), "* %s mendekati Loket Pajak.", PlayerInfo[playerid][pICName]);
            ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
            SendClientMessage(playerid, 0xFFAA00FF, "Petugas: \"Maaf, layanan pajak sedang dalam pengembangan.\"");
            return 1;
        }
        case LOKET_SURKET:
        {
            new rpmsg[80];
            format(rpmsg, sizeof(rpmsg), "* %s mendekati Loket Surat Keterangan.", PlayerInfo[playerid][pICName]);
            ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
            SendClientMessage(playerid, 0xFFAA00FF, "Petugas: \"Maaf, layanan surat keterangan sedang dalam pengembangan.\"");
            return 1;
        }
    }
    return 1;
}

// ============================================================================
// SERVICE MENU
// ============================================================================

stock ShowKTPServiceMenu(playerid)
{
    new menu[128];
    menu[0] = EOS;
    strcat(menu, "Buat KTP Baru\n", sizeof(menu));
    strcat(menu, "{888888}Perpanjang KTP (Segera)\n", sizeof(menu));
    strcat(menu, "{888888}Surat Keterangan (Segera)", sizeof(menu));
    ShowPlayerDialog(playerid, DIALOG_KTP_SERVICE, DIALOG_STYLE_LIST,
        "{FFAA00}Mall Pelayanan", menu, "Pilih", "Batal");
}

// ============================================================================
// KTP CONFIRMATION DISPLAY
// ============================================================================

stock ShowKTPConfirmation(playerid)
{
    new genderStr[12];
    if(PlayerInfo[playerid][pGender] == 1) genderStr = "Laki-laki";
    else genderStr = "Perempuan";

    new dlg[512], p1[256], p2[256];
    format(p1, sizeof(p1), "{FFFFFF}Petugas: \"Cek data berikut:\"\n\n{AAAAAA}Nama Lengkap: {FFFFFF}%s\n{AAAAAA}Umur: {FFFFFF}%d tahun\n{AAAAAA}Jenis Kelamin: {FFFFFF}%s\n{AAAAAA}Tempat Lahir: {FFFFFF}%s\n",
        TempKTPFullName[playerid], PlayerInfo[playerid][pICAge], genderStr, TempKTPBirthPlace[playerid]);
    format(p2, sizeof(p2), "{AAAAAA}Alamat: {FFFFFF}%s\n{AAAAAA}Status Kawin: {FFFFFF}%s\n{AAAAAA}Pekerjaan: {FFFFFF}%s\n{AAAAAA}Gol. Darah: {FFFFFF}%s\n\n{FFFFFF}Apakah data sudah benar?",
        TempKTPAddress[playerid], TempKTPMarital[playerid], TempKTPOccupation[playerid], TempKTPBlood[playerid]);
    dlg[0] = EOS;
    strcat(dlg, p1, sizeof(dlg));
    strcat(dlg, p2, sizeof(dlg));

    ShowPlayerDialog(playerid, DIALOG_KTP_CONFIRM, DIALOG_STYLE_MSGBOX,
        "{FFAA00}Konfirmasi Data KTP", dlg, "Benar", "Ubah");
}

// ============================================================================
// FINALIZE KTP
// ============================================================================

stock FinalizeKTPCreation(playerid)
{
    new mall = TempKTPMall[playerid];
    new nik[16];
    GenerateNIK(playerid, mall, nik, sizeof(nik));

    PlayerInfo[playerid][pHasKTP] = true;
    format(PlayerInfo[playerid][pKTPNIK], 16, "%s", nik);
    format(PlayerInfo[playerid][pKTPFullName], 64, "%s", TempKTPFullName[playerid]);
    format(PlayerInfo[playerid][pBirthPlace], 32, "%s", TempKTPBirthPlace[playerid]);
    format(PlayerInfo[playerid][pAddress], 64, "%s", TempKTPAddress[playerid]);
    format(PlayerInfo[playerid][pMaritalStatus], 16, "%s", TempKTPMarital[playerid]);
    format(PlayerInfo[playerid][pOccupation], 32, "%s", TempKTPOccupation[playerid]);
    format(PlayerInfo[playerid][pBloodType], 4, "%s", TempKTPBlood[playerid]);

    static q[512];
    mysql_format(MySQL_C1, q, sizeof(q), "UPDATE `accounts` SET `has_ktp`='1', `ktp_nik`='%e', `ktp_fullname`='%e', `birth_place`='%e', `address`='%e', `marital_status`='%e', `occupation`='%e', `blood_type`='%e' WHERE `name`='%e'",
        nik, TempKTPFullName[playerid], TempKTPBirthPlace[playerid], TempKTPAddress[playerid],
        TempKTPMarital[playerid], TempKTPOccupation[playerid], TempKTPBlood[playerid], PlayerInfo[playerid][pName]);
    mysql_function_query(MySQL_C1, q, false, "", "");

    new rpmsg[96];
    format(rpmsg, sizeof(rpmsg), "* Petugas menyerahkan KTP baru kepada %s.", PlayerInfo[playerid][pICName]);
    ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    format(_ktp_msg, sizeof(_ktp_msg), "KTP berhasil dibuat! NIK: %s", nik);
    SendClientMessage(playerid, 0x00FF00FF, _ktp_msg);
    SendClientMessage(playerid, COLOR_YELLOW, "KTP tersimpan di dompet. Buka: LEFT ALT + Y.");

    KTPServiceNextInQueue(mall);
}

// ============================================================================
// DIALOG HANDLER
// ============================================================================

// ============================================================================
// MALL SETUP DIALOG HANDLER (separate function to avoid stack overflow)
// ============================================================================

stock HandleMallSetupDialogs(playerid, dialogid, response, listitem)
{
    switch(dialogid)
    {
        // === MALL SETUP: MAIN MENU ===
        case DIALOG_MALL_SETUP:
        {
            if(!response) return 1;
            switch(listitem)
            {
                case 0: // Buat Mall Baru
                {
                    if(MallCount >= MAX_MALL_PELAYANAN)
                    {
                        format(_ktp_msg, sizeof(_ktp_msg), "Maksimal %d Mall Pelayanan!", MAX_MALL_PELAYANAN);
                        SendClientMessage(playerid, COLOR_RED, _ktp_msg);
                        return 1;
                    }
                    ShowPlayerDialog(playerid, DIALOG_MALL_CREATE_CITY, DIALOG_STYLE_LIST,
                        "{FFAA00}Pilih Kota Mall",
                        "Mall Pelayanan Mekar Pura\nMall Pelayanan Madya Raya\nMall Pelayanan Mojosono",
                        "Buat", "Kembali");
                }
                case 1: // Edit Mall
                {
                    if(MallCount == 0)
                    {
                        SendClientMessage(playerid, COLOR_RED, "Belum ada mall. Buat dulu!");
                        return 1;
                    }
                    new dlg[512];
                    BuildMallListString(dlg, sizeof(dlg));
                    ShowPlayerDialog(playerid, DIALOG_MALL_EDIT_LIST, DIALOG_STYLE_LIST,
                        "{FFAA00}Pilih Mall untuk Edit", dlg, "Pilih", "Kembali");
                }
                case 2: // Hapus Mall
                {
                    if(MallCount == 0)
                    {
                        SendClientMessage(playerid, COLOR_RED, "Belum ada mall.");
                        return 1;
                    }
                    new dlg[512];
                    BuildMallListString(dlg, sizeof(dlg));
                    ShowPlayerDialog(playerid, DIALOG_MALL_DEL_LIST, DIALOG_STYLE_LIST,
                        "{FFAA00}Pilih Mall untuk Hapus", dlg, "Pilih", "Kembali");
                }
            }
            return 1;
        }

        // === CREATE: PICK CITY ===
        case DIALOG_MALL_CREATE_CITY:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_MALL_SETUP, DIALOG_STYLE_LIST,
                    "{FFAA00}Mall Pelayanan Setup",
                    "Buat Mall Baru\nEdit Mall\nHapus Mall",
                    "Pilih", "Tutup");
                return 1;
            }
            if(listitem < 0 || listitem >= MALL_CITY_COUNT) return 1;

            new mallname[64];
            format(mallname, sizeof(mallname), "Mall Pelayanan %s", MallCityNames[listitem]);
            CreateMallInternal(playerid, mallname);
            return 1;
        }

        // === INTERIOR SELECTION (preview interior GTA bawaan) ===
        case DIALOG_MALL_INT_SEL:
        {
            if(!response)
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Kamu bisa pilih interior nanti lewat /mallsetup > Edit Mall.");
                return 1;
            }
            if(listitem < 0 || listitem >= MALL_INTERIOR_OPTIONS) return 1;

            new slot = TempMallCreatedSlot[playerid];
            if(slot < 0 || slot >= MallCount) return 1;

            new intVW = MALL_VW_BASE + MallData[slot][mID];
            new Float:pvX = MallInteriorOpts[listitem][mioX];
            new Float:pvY = MallInteriorOpts[listitem][mioY];
            new Float:pvZ = MallInteriorOpts[listitem][mioZ];
            new intID = MallInteriorOpts[listitem][mioInterior];

            // Teleport langsung ke interior GTA bawaan (lantai sudah ada built-in)
            SetPlayerInterior(playerid, intID);
            SetPlayerVirtualWorld(playerid, intVW);
            SetPlayerPos(playerid, pvX, pvY, pvZ);
            SetPlayerFacingAngle(playerid, MallInteriorOpts[listitem][mioAngle]);
            SetCameraBehindPlayer(playerid);

            // Debug info
            format(_ktp_msg, sizeof(_ktp_msg), "[Preview] %s — Pos: %.1f, %.1f, %.1f | Int: %d | VW: %d",
                MallInteriorOpts[listitem][mioName], pvX, pvY, pvZ, intID, intVW);
            SendClientMessage(playerid, 0x00FF00FF, _ktp_msg);
            SendClientMessage(playerid, COLOR_YELLOW, "Jalan-jalan dulu, cek interiornya.");
            format(_ktp_msg, sizeof(_ktp_msg), "Cocok? Berdiri di pintu masuk lalu ketik: /setmallinterior %d", slot);
            SendClientMessage(playerid, COLOR_YELLOW, _ktp_msg);
            SendClientMessage(playerid, COLOR_YELLOW, "Mau ganti? /mallsetup > Edit Mall > Ganti Interior");
            return 1;
        }

        // === EDIT: PICK MALL ===
        case DIALOG_MALL_EDIT_LIST:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_MALL_SETUP, DIALOG_STYLE_LIST,
                    "{FFAA00}Mall Pelayanan Setup",
                    "Buat Mall Baru\nEdit Mall\nHapus Mall",
                    "Pilih", "Tutup");
                return 1;
            }
            if(listitem < 0 || listitem >= MallCount) return 1;

            TempMallEditSlot[playerid] = listitem;
            ShowPlayerDialog(playerid, DIALOG_MALL_EDIT_MENU, DIALOG_STYLE_LIST,
                "{FFAA00}Edit Mall",
                "Pindahkan ke Posisi Saya\nGanti Interior\nKelola NPC\nKembali",
                "Pilih", "Tutup");
            return 1;
        }

        // === EDIT: SUBMENU ===
        case DIALOG_MALL_EDIT_MENU:
        {
            if(!response)
            {
                new bdlg[512];
                BuildMallListString(bdlg, sizeof(bdlg));
                ShowPlayerDialog(playerid, DIALOG_MALL_EDIT_LIST, DIALOG_STYLE_LIST,
                    "{FFAA00}Pilih Mall untuk Edit", bdlg, "Pilih", "Kembali");
                return 1;
            }

            new slot = TempMallEditSlot[playerid];
            if(slot < 0 || slot >= MallCount) return 1;

            switch(listitem)
            {
                case 0: // Pindahkan ke posisi saya
                {
                    new Float:px, Float:py, Float:pz, Float:pa;
                    GetPlayerPos(playerid, px, py, pz);
                    GetPlayerFacingAngle(playerid, pa);
                    new interior = GetPlayerInterior(playerid);
                    new vw = GetPlayerVirtualWorld(playerid);

                    DestroyMallWorld(slot);
                    MallData[slot][mPosX] = px;
                    MallData[slot][mPosY] = py;
                    MallData[slot][mPosZ] = pz;
                    MallData[slot][mAngle] = pa;
                    MallData[slot][mInterior] = interior;
                    MallData[slot][mVW] = vw;
                    CreateMallWorld(slot);

                    new q_mov[256];
                    mysql_format(MySQL_C1, q_mov, sizeof(q_mov), "UPDATE `mall_pelayanan` SET `pos_x`='%f', `pos_y`='%f', `pos_z`='%f', `angle`='%f', `interior`='%d', `vw`='%d' WHERE `id`='%d'", px, py, pz, pa, interior, vw, MallData[slot][mID]);
                    mysql_function_query(MySQL_C1, q_mov, false, "", "");

                    format(_ktp_msg, sizeof(_ktp_msg), "Mall '%s' dipindahkan ke posisi kamu.", MallData[slot][mName]);
                    SendClientMessage(playerid, 0x00FF00FF, _ktp_msg);
                }
                case 1: // Ganti Interior
                {
                    TempMallCreatedSlot[playerid] = slot;
                    new dlg[256];
                    dlg[0] = EOS;
                    for(new i = 0; i < MALL_INTERIOR_OPTIONS; i++)
                    {
                        strcat(dlg, MallInteriorOpts[i][mioName], sizeof(dlg));
                        if(i < MALL_INTERIOR_OPTIONS - 1) strcat(dlg, "\n", sizeof(dlg));
                    }
                    ShowPlayerDialog(playerid, DIALOG_MALL_INT_SEL, DIALOG_STYLE_LIST,
                        "{FFAA00}Pilih Interior Mall", dlg, "Preview", "Kembali");
                }
                case 2: // Kelola NPC
                {
                    TempNPCMallSlot[playerid] = slot;
                    ShowPlayerDialog(playerid, DIALOG_MALL_NPC_MENU, DIALOG_STYLE_LIST,
                        "{FFAA00}Kelola NPC Mall",
                        "Pasang NPC Baru (di posisi saya)\nHapus NPC Terdekat (3m)\nLihat Daftar NPC\nKembali",
                        "Pilih", "Tutup");
                }
                case 3: // Kembali
                {
                    new dlg[512];
                    BuildMallListString(dlg, sizeof(dlg));
                    ShowPlayerDialog(playerid, DIALOG_MALL_EDIT_LIST, DIALOG_STYLE_LIST,
                        "{FFAA00}Pilih Mall untuk Edit", dlg, "Pilih", "Kembali");
                }
            }
            return 1;
        }

        // === NPC SUBMENU ===
        case DIALOG_MALL_NPC_MENU:
        {
            if(!response)
            {
                new es2 = TempNPCMallSlot[playerid];
                if(es2 >= 0 && es2 < MallCount)
                {
                    TempMallEditSlot[playerid] = es2;
                    ShowPlayerDialog(playerid, DIALOG_MALL_EDIT_MENU, DIALOG_STYLE_LIST,
                        "{FFAA00}Edit Mall",
                        "Pindahkan ke Posisi Saya\nGanti Interior\nKelola NPC\nKembali",
                        "Pilih", "Tutup");
                }
                return 1;
            }

            new slot = TempNPCMallSlot[playerid];
            if(slot < 0 || slot >= MallCount) return 1;

            switch(listitem)
            {
                case 0: // Pasang NPC Baru
                {
                    if(MallNPCCount >= MAX_MALL_NPC_TOTAL)
                    {
                        format(_ktp_msg, sizeof(_ktp_msg), "Batas NPC global tercapai (%d)!", MAX_MALL_NPC_TOTAL);
                        SendClientMessage(playerid, COLOR_RED, _ktp_msg);
                        return 1;
                    }
                    ShowPlayerDialog(playerid, DIALOG_MALLNPC_TYPE, DIALOG_STYLE_LIST,
                        "{FFAA00}Pilih Tipe NPC",
                        "Satpam (Penjaga)\nResepsionis\nLoket Dukcapil (KTP)\nLoket Perizinan\nLoket Pajak\nLoket Surat Keterangan",
                        "Pasang", "Kembali");
                }
                case 1: // Hapus NPC Terdekat
                {
                    new Float:px, Float:py, Float:pz;
                    GetPlayerPos(playerid, px, py, pz);
                    new Float:bestDist = 999.0;
                    new bestIdx = -1;
                    for(new n = 0; n < MallNPCCount; n++)
                    {
                        if(MallNPCData[n][mnpActorID] == -1) continue;
                        new Float:dx = px - MallNPCData[n][mnpX];
                        new Float:dy = py - MallNPCData[n][mnpY];
                        new Float:dz = pz - MallNPCData[n][mnpZ];
                        new Float:dist = floatsqroot(dx*dx + dy*dy + dz*dz);
                        if(dist < 3.0 && dist < bestDist)
                        {
                            bestDist = dist;
                            bestIdx = n;
                        }
                    }
                    if(bestIdx == -1)
                    {
                        SendClientMessage(playerid, COLOR_RED, "Tidak ada NPC dalam radius 3m!");
                    }
                    else
                    {
                        new npcName[32], npcDBID;
                        format(npcName, sizeof(npcName), "%s", MallNPCData[bestIdx][mnpName]);
                        npcDBID = MallNPCData[bestIdx][mnpDBID];
                        DestroySingleMallNPC(bestIdx);
                        new dq_npc[80];
                        format(dq_npc, sizeof(dq_npc), "DELETE FROM `mall_npcs` WHERE `id` = '%d'", npcDBID);
                        mysql_function_query(MySQL_C1, dq_npc, false, "", "");
                        for(new j = bestIdx; j < MallNPCCount - 1; j++)
                            MallNPCData[j] = MallNPCData[j+1];
                        MallNPCCount--;
                        format(_ktp_msg, sizeof(_ktp_msg), "NPC '%s' dihapus.", npcName);
                        SendClientMessage(playerid, 0x00FF00FF, _ktp_msg);
                    }
                    ShowPlayerDialog(playerid, DIALOG_MALL_NPC_MENU, DIALOG_STYLE_LIST,
                        "{FFAA00}Kelola NPC Mall",
                        "Pasang NPC Baru (di posisi saya)\nHapus NPC Terdekat (3m)\nLihat Daftar NPC\nKembali",
                        "Pilih", "Tutup");
                }
                case 2: // Lihat Daftar NPC
                {
                    new mallDBID = MallData[slot][mID];
                    new count = 0;
                    format(_ktp_msg, sizeof(_ktp_msg), "=== NPC di '%s' ===", MallData[slot][mName]);
                    SendClientMessage(playerid, COLOR_YELLOW, _ktp_msg);
                    for(new n = 0; n < MallNPCCount; n++)
                    {
                        if(MallNPCData[n][mnpMallID] != mallDBID) continue;
                        new typeStr[20];
                        switch(MallNPCData[n][mnpLoketType])
                        {
                            case LOKET_NONE: typeStr = "Satpam";
                            case LOKET_RESEPSIONIS: typeStr = "Resepsionis";
                            case LOKET_DUKCAPIL: typeStr = "Dukcapil";
                            case LOKET_PERIZINAN: typeStr = "Perizinan";
                            case LOKET_PAJAK: typeStr = "Pajak";
                            case LOKET_SURKET: typeStr = "Surat Ket.";
                            default: typeStr = "Unknown";
                        }
                        format(_ktp_msg, sizeof(_ktp_msg), "  [DB:%d] %s (%s) Skin:%d",
                            MallNPCData[n][mnpDBID], MallNPCData[n][mnpName], typeStr, MallNPCData[n][mnpSkin]);
                        SendClientMessage(playerid, -1, _ktp_msg);
                        count++;
                    }
                    if(count == 0)
                        SendClientMessage(playerid, COLOR_RED, "  Belum ada NPC.");
                    else
                    {
                        format(_ktp_msg, sizeof(_ktp_msg), "  Total: %d NPC", count);
                        SendClientMessage(playerid, COLOR_YELLOW, _ktp_msg);
                    }
                    ShowPlayerDialog(playerid, DIALOG_MALL_NPC_MENU, DIALOG_STYLE_LIST,
                        "{FFAA00}Kelola NPC Mall",
                        "Pasang NPC Baru (di posisi saya)\nHapus NPC Terdekat (3m)\nLihat Daftar NPC\nKembali",
                        "Pilih", "Tutup");
                }
                case 3: // Kembali ke Edit Menu
                {
                    TempMallEditSlot[playerid] = slot;
                    ShowPlayerDialog(playerid, DIALOG_MALL_EDIT_MENU, DIALOG_STYLE_LIST,
                        "{FFAA00}Edit Mall",
                        "Pindahkan ke Posisi Saya\nGanti Interior\nKelola NPC\nKembali",
                        "Pilih", "Tutup");
                }
            }
            return 1;
        }

        // === DELETE: PICK MALL ===
        case DIALOG_MALL_DEL_LIST:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_MALL_SETUP, DIALOG_STYLE_LIST,
                    "{FFAA00}Mall Pelayanan Setup",
                    "Buat Mall Baru\nEdit Mall\nHapus Mall",
                    "Pilih", "Tutup");
                return 1;
            }
            if(listitem < 0 || listitem >= MallCount) return 1;

            TempMallEditSlot[playerid] = listitem;
            new dlg[256];
            format(dlg, sizeof(dlg), "{FFFFFF}Yakin mau hapus:\n\n{FFAA00}%s{FFFFFF} (DB:%d)\n\nSemua NPC di mall ini juga akan dihapus.",
                MallData[listitem][mName], MallData[listitem][mID]);
            ShowPlayerDialog(playerid, DIALOG_MALL_DEL_CONFIRM, DIALOG_STYLE_MSGBOX,
                "{FF0000}Konfirmasi Hapus Mall", dlg, "Hapus", "Batal");
            return 1;
        }

        // === DELETE: CONFIRM ===
        case DIALOG_MALL_DEL_CONFIRM:
        {
            if(!response)
            {
                new dlg[512];
                BuildMallListString(dlg, sizeof(dlg));
                ShowPlayerDialog(playerid, DIALOG_MALL_DEL_LIST, DIALOG_STYLE_LIST,
                    "{FFAA00}Pilih Mall untuk Hapus", dlg, "Pilih", "Kembali");
                return 1;
            }

            new mallIdx = TempMallEditSlot[playerid];
            DeleteMallInternal(playerid, mallIdx);
            return 1;
        }

        // === NPC PLACEMENT DIALOG ===
        case DIALOG_MALLNPC_TYPE:
        {
            if(!response)
            {
                new es = TempNPCMallSlot[playerid];
                if(es >= 0 && es < MallCount)
                {
                    TempMallEditSlot[playerid] = es;
                    ShowPlayerDialog(playerid, DIALOG_MALL_NPC_MENU, DIALOG_STYLE_LIST,
                        "{FFAA00}Mall NPC - Menu",
                        "Pasang NPC Baru\nHapus NPC\nList NPC\nKembali",
                        "Pilih", "Tutup");
                }
                return 1;
            }

            new slot = TempNPCMallSlot[playerid];
            if(slot < 0 || slot >= MallCount) return 1;

            if(MallNPCCount >= MAX_MALL_NPC_TOTAL)
            {
                format(_ktp_msg, sizeof(_ktp_msg), "Batas NPC tercapai (%d)!", MAX_MALL_NPC_TOTAL);
                SendClientMessage(playerid, COLOR_RED, _ktp_msg);
                return 1;
            }

            printf("[DEBUG-NPC] Step 1: slot=%d, MallCount=%d, MallNPCCount=%d", slot, MallCount, MallNPCCount);

            new loketType, skin, npcName[32];
            switch(listitem)
            {
                case 0: { loketType = LOKET_NONE;        skin = 71;  format(npcName, 32, "Satpam"); }
                case 1: { loketType = LOKET_RESEPSIONIS;  skin = 211; format(npcName, 32, "Resepsionis"); }
                case 2: { loketType = LOKET_DUKCAPIL;     skin = 61;  format(npcName, 32, "Loket Dukcapil"); }
                case 3: { loketType = LOKET_PERIZINAN;    skin = 17;  format(npcName, 32, "Loket Perizinan"); }
                case 4: { loketType = LOKET_PAJAK;        skin = 28;  format(npcName, 32, "Loket Pajak"); }
                case 5: { loketType = LOKET_SURKET;       skin = 147; format(npcName, 32, "Loket Surat Ket."); }
                default: return 1;
            }

            new Float:px, Float:py, Float:pz, Float:pa;
            GetPlayerPos(playerid, px, py, pz);
            GetPlayerFacingAngle(playerid, pa);
            new pint = GetPlayerInterior(playerid);
            new pvw = GetPlayerVirtualWorld(playerid);
            new mallDBID = MallData[slot][mID];

            printf("[DEBUG-NPC] Step 2: mallDBID=%d, skin=%d, loket=%d", mallDBID, skin, loketType);

            new ni = MallNPCCount;
            MallNPCData[ni][mnpMallID] = mallDBID;
            MallNPCData[ni][mnpSkin] = skin;
            MallNPCData[ni][mnpX] = px;
            MallNPCData[ni][mnpY] = py;
            MallNPCData[ni][mnpZ] = pz;
            MallNPCData[ni][mnpAngle] = pa;
            MallNPCData[ni][mnpInterior] = pint;
            MallNPCData[ni][mnpVW] = pvw;
            MallNPCData[ni][mnpLoketType] = loketType;
            format(MallNPCData[ni][mnpName], 32, "%s", npcName);

            printf("[DEBUG-NPC] Step 3: CreateSingleMallNPC(%d)", ni);
            CreateSingleMallNPC(ni);
            MallNPCCount++;

            // Geser player mundur 1.5m supaya tidak stuck di collision actor
            new Float:backX, Float:backY;
            backX = px + (1.5 * floatsin(-pa, degrees));
            backY = py + (1.5 * floatcos(-pa, degrees));
            SetPlayerPos(playerid, backX, backY, pz);
            SetPlayerFacingAngle(playerid, pa);
            SetCameraBehindPlayer(playerid);

            printf("[DEBUG-NPC] Step 4: Saving to DB");
            new q_ins[512];
            mysql_format(MySQL_C1, q_ins, sizeof(q_ins),
                "INSERT INTO `mall_npcs` (`mall_id`,`skin`,`pos_x`,`pos_y`,`pos_z`,`angle`,`interior`,`vw`,`loket_type`,`name`) VALUES ('%d','%d','%f','%f','%f','%f','%d','%d','%d','%e')",
                mallDBID, skin, px, py, pz, pa, pint, pvw, loketType, npcName);
            mysql_function_query(MySQL_C1, q_ins, true, "OnMallNPCCreated", "d", ni);

            printf("[DEBUG-NPC] Step 5: Sending messages + showing NPC menu");
            format(_ktp_msg, sizeof(_ktp_msg), "NPC '%s' berhasil dipasang di Mall '%s'!", npcName, MallData[slot][mName]);
            SendClientMessage(playerid, 0x00FF00FF, _ktp_msg);
            SendClientMessage(playerid, COLOR_YELLOW, "Gunakan /mallsetup > Edit > NPC untuk kelola NPC lainnya.");
            TempMallEditSlot[playerid] = slot;
            ShowPlayerDialog(playerid, DIALOG_MALL_NPC_MENU, DIALOG_STYLE_LIST,
                "{FFAA00}Mall NPC - Menu",
                "Pasang NPC Baru\nHapus NPC\nList NPC\nKembali",
                "Pilih", "Tutup");
            printf("[DEBUG-NPC] Step 6: NPC placement complete");
            return 1;
        }
    }
    return 0;
}

// ============================================================================
// KTP DIALOG HANDLER
// ============================================================================

stock HandleKTPDialogs(playerid, dialogid, response, listitem, inputtext[])
{
    // Mall setup dialogs → separate function (to avoid stack overflow)
    if(dialogid >= DIALOG_MALLNPC_TYPE && dialogid <= DIALOG_MALL_NPC_MENU)
        return HandleMallSetupDialogs(playerid, dialogid, response, listitem);

    switch(dialogid)
    {
        // === KTP FLOW DIALOGS ===
        case DIALOG_KTP_SERVICE:
        {
            if(!response)
            {
                KTPServiceNextInQueue(TempKTPMall[playerid]);
                return 1;
            }
            if(listitem == 0)
            {
                if(PlayerInfo[playerid][pHasKTP])
                {
                    SendClientMessage(playerid, COLOR_YELLOW, "Kamu sudah memiliki KTP.");
                    KTPServiceNextInQueue(TempKTPMall[playerid]);
                    return 1;
                }
                ShowPlayerDialog(playerid, DIALOG_KTP_FULLNAME, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Nama Lengkap",
                    "{FFFFFF}Petugas: \"Silakan masukkan nama lengkap Anda.\"\n\n{AAAAAA}Masukkan nama lengkap (sesuai akte lahir):",
                    "Lanjut", "Batal");
            }
            else
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Layanan ini belum tersedia.");
                ShowKTPServiceMenu(playerid);
            }
            return 1;
        }
        case DIALOG_KTP_QUEUE:
        {
            if(!response)
            {
                RemoveFromKTPQueue(playerid);
                SendClientMessage(playerid, COLOR_YELLOW, "Kamu keluar dari antrian.");
            }
            return 1;
        }
        case DIALOG_KTP_FULLNAME:
        {
            if(!response)
            {
                KTPServiceNextInQueue(TempKTPMall[playerid]);
                return 1;
            }
            if(strlen(inputtext) < 3 || strlen(inputtext) > 60)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_FULLNAME, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Nama Lengkap",
                    "{FF0000}Harus 3-60 karakter!\n\n{FFFFFF}Petugas: \"Silakan masukkan nama lengkap Anda.\"\n\n{AAAAAA}Masukkan nama lengkap (sesuai akte lahir):",
                    "Lanjut", "Batal");
                return 1;
            }
            format(TempKTPFullName[playerid], 64, "%s", inputtext);
            ShowPlayerDialog(playerid, DIALOG_KTP_BIRTHPLACE, DIALOG_STYLE_INPUT,
                "{FFAA00}Buat KTP - Tempat Lahir",
                "{FFFFFF}Petugas: \"Silakan isi tempat lahir Anda.\"\n\n{AAAAAA}Masukkan kota/kabupaten tempat lahir:",
                "Lanjut", "Kembali");
            return 1;
        }
        case DIALOG_KTP_BIRTHPLACE:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_FULLNAME, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Nama Lengkap",
                    "{FFFFFF}Petugas: \"Silakan masukkan nama lengkap Anda.\"\n\n{AAAAAA}Masukkan nama lengkap (sesuai akte lahir):",
                    "Lanjut", "Batal");
                return 1;
            }
            if(strlen(inputtext) < 3 || strlen(inputtext) > 30)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_BIRTHPLACE, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Tempat Lahir",
                    "{FF0000}Harus 3-30 karakter!\n\n{FFFFFF}Petugas: \"Silakan isi tempat lahir Anda.\"\n\n{AAAAAA}Masukkan kota/kabupaten tempat lahir:",
                    "Lanjut", "Kembali");
                return 1;
            }
            format(TempKTPBirthPlace[playerid], 32, "%s", inputtext);
            ShowPlayerDialog(playerid, DIALOG_KTP_ADDRESS, DIALOG_STYLE_INPUT,
                "{FFAA00}Buat KTP - Alamat",
                "{FFFFFF}Petugas: \"Masukkan alamat tempat tinggal Anda.\"\n\n{AAAAAA}Masukkan alamat lengkap:",
                "Lanjut", "Kembali");
            return 1;
        }
        case DIALOG_KTP_ADDRESS:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_BIRTHPLACE, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Tempat Lahir",
                    "{FFFFFF}Petugas: \"Silakan isi tempat lahir Anda.\"\n\n{AAAAAA}Masukkan kota/kabupaten tempat lahir:",
                    "Lanjut", "Kembali");
                return 1;
            }
            if(strlen(inputtext) < 5 || strlen(inputtext) > 60)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_ADDRESS, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Alamat",
                    "{FF0000}Harus 5-60 karakter!\n\n{FFFFFF}Petugas: \"Masukkan alamat tempat tinggal Anda.\"\n\n{AAAAAA}Masukkan alamat lengkap:",
                    "Lanjut", "Kembali");
                return 1;
            }
            format(TempKTPAddress[playerid], 64, "%s", inputtext);
            ShowPlayerDialog(playerid, DIALOG_KTP_MARITAL, DIALOG_STYLE_LIST,
                "{FFAA00}Buat KTP - Status Perkawinan",
                "Belum Kawin\nKawin\nCerai Hidup\nCerai Mati",
                "Pilih", "Kembali");
            return 1;
        }
        case DIALOG_KTP_MARITAL:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_ADDRESS, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Alamat",
                    "{FFFFFF}Petugas: \"Masukkan alamat tempat tinggal Anda.\"\n\n{AAAAAA}Masukkan alamat lengkap:",
                    "Lanjut", "Kembali");
                return 1;
            }
            switch(listitem)
            {
                case 0: format(TempKTPMarital[playerid], 16, "Belum Kawin");
                case 1: format(TempKTPMarital[playerid], 16, "Kawin");
                case 2: format(TempKTPMarital[playerid], 16, "Cerai Hidup");
                case 3: format(TempKTPMarital[playerid], 16, "Cerai Mati");
            }
            ShowPlayerDialog(playerid, DIALOG_KTP_OCCUPATION, DIALOG_STYLE_INPUT,
                "{FFAA00}Buat KTP - Pekerjaan",
                "{FFFFFF}Petugas: \"Apa pekerjaan Anda saat ini?\"\n\n{AAAAAA}Masukkan pekerjaan:",
                "Lanjut", "Kembali");
            return 1;
        }
        case DIALOG_KTP_OCCUPATION:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_MARITAL, DIALOG_STYLE_LIST,
                    "{FFAA00}Buat KTP - Status Perkawinan",
                    "Belum Kawin\nKawin\nCerai Hidup\nCerai Mati",
                    "Pilih", "Kembali");
                return 1;
            }
            if(strlen(inputtext) < 3 || strlen(inputtext) > 30)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_OCCUPATION, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Pekerjaan",
                    "{FF0000}Harus 3-30 karakter!\n\n{FFFFFF}Petugas: \"Apa pekerjaan Anda saat ini?\"\n\n{AAAAAA}Masukkan pekerjaan:",
                    "Lanjut", "Kembali");
                return 1;
            }
            format(TempKTPOccupation[playerid], 32, "%s", inputtext);
            ShowPlayerDialog(playerid, DIALOG_KTP_BLOOD, DIALOG_STYLE_LIST,
                "{FFAA00}Buat KTP - Golongan Darah",
                "A\nB\nAB\nO",
                "Pilih", "Kembali");
            return 1;
        }
        case DIALOG_KTP_BLOOD:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_OCCUPATION, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Pekerjaan",
                    "{FFFFFF}Petugas: \"Apa pekerjaan Anda saat ini?\"\n\n{AAAAAA}Masukkan pekerjaan:",
                    "Lanjut", "Kembali");
                return 1;
            }
            switch(listitem)
            {
                case 0: format(TempKTPBlood[playerid], 4, "A");
                case 1: format(TempKTPBlood[playerid], 4, "B");
                case 2: format(TempKTPBlood[playerid], 4, "AB");
                case 3: format(TempKTPBlood[playerid], 4, "O");
            }
            ShowKTPConfirmation(playerid);
            return 1;
        }
        case DIALOG_KTP_CONFIRM:
        {
            if(!response)
            {
                ShowPlayerDialog(playerid, DIALOG_KTP_FULLNAME, DIALOG_STYLE_INPUT,
                    "{FFAA00}Buat KTP - Nama Lengkap",
                    "{FFFFFF}Petugas: \"Silakan isi ulang data.\"\n\n{AAAAAA}Masukkan nama lengkap (sesuai akte lahir):",
                    "Lanjut", "Batal");
                return 1;
            }
            FinalizeKTPCreation(playerid);
            return 1;
        }
    }
    return 0;
}
