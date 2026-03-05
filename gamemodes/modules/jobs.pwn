// ============================================================================
// MODULE: jobs.pwn
// Job System — Taxi, Trucker, Miner, Bus Driver, Fisherman
// ============================================================================

// ============================================================================
// DEFINES
// ============================================================================

#define JOB_NONE                0
#define JOB_TAXI                1
#define JOB_TRUCKER             2
#define JOB_MINER               3
#define JOB_BUS                 4
#define JOB_FISHERMAN           5

#define MAX_TRUCKER_COMPANIES   5
#define MAX_TRUCKER_ROUTES      30
#define MAX_FISH_MARKETS        5
#define MAX_BUS_TERMINALS       10
#define MAX_FISH_TYPES          5

#define COLOR_JOB               0xFFCC00FF  // yellow-ish
#define COLOR_JOB_INFO          0x33CC33FF  // green info

// Taxi
#define TAXI_BASE_FARE          5000        // base fare Rp 5000
#define TAXI_PER_UNIT           500         // per distance unit
#define TAXI_COMPANY_CUT        20          // 20% to company

// Miner
#define MINE_INTERVAL           15000       // 15 seconds per mining action
#define MINE_BASE_PAY           3000        // base per ore

// Fisher
#define FISH_INTERVAL           20000       // 20 seconds per cast
#define ITEM_FISHING_ROD        8           // item ID for fishing rod (will add)

// Bus
#define BUS_PASSENGER_PAY       2000        // per stop
#define BUS_MODEL               431         // Coach

// Dialog IDs (200 range taken by faction, use 220+)
#define DIALOG_JOB_CENTER       220
#define DIALOG_JOB_TRUCKER_CO   221
#define DIALOG_JOB_TRUCKER_ROUTE 222
#define DIALOG_JOB_FISH_SELL    223
#define DIALOG_JOB_CONFIRM_QUIT 224

// ============================================================================
// TRUCKER DATA
// ============================================================================

enum eTruckerCompany {
    tcID,
    tcName[48],
    tcType,
    Float:tcBaseX,
    Float:tcBaseY,
    Float:tcBaseZ,
    Float:tcBaseAngle
};
new TruckerCompanies[MAX_TRUCKER_COMPANIES][eTruckerCompany];
new TotalTruckerCompanies = 0;

enum eTruckerRoute {
    trID,
    trCompanyID,
    trRouteName[64],
    Float:trPickupX,
    Float:trPickupY,
    Float:trPickupZ,
    Float:trDeliverX,
    Float:trDeliverY,
    Float:trDeliverZ,
    trPayAmount,
    trDistBonus
};
new TruckerRoutes[MAX_TRUCKER_ROUTES][eTruckerRoute];
new TotalTruckerRoutes = 0;

// ============================================================================
// FISH MARKET DATA
// ============================================================================

enum eFishMarket {
    fmID,
    fmName[48],
    Float:fmX,
    Float:fmY,
    Float:fmZ,
    fmPrices[MAX_FISH_TYPES] // nila, mas, lele, bawal, patin
};
new FishMarkets[MAX_FISH_MARKETS][eFishMarket];
new TotalFishMarkets = 0;

new const FishNames[MAX_FISH_TYPES][16] = {
    "Ikan Nila",
    "Ikan Mas",
    "Ikan Lele",
    "Ikan Bawal",
    "Ikan Patin"
};

// ============================================================================
// PLAYER JOB DATA (runtime)
// ============================================================================

new pJobType[MAX_PLAYERS];              // JOB_* constant
new pJobCompanyID[MAX_PLAYERS];         // trucker company id
new pJobTotalEarnings[MAX_PLAYERS];
new pJobTripsCompleted[MAX_PLAYERS];

// Taxi runtime
new bool:pTaxiOnTrip[MAX_PLAYERS];     // currently has a passenger
new pTaxiPassenger[MAX_PLAYERS];        // passenger playerid
new Float:pTaxiStartX[MAX_PLAYERS];
new Float:pTaxiStartY[MAX_PLAYERS];
new Float:pTaxiStartZ[MAX_PLAYERS];
new pTaxiVehicle[MAX_PLAYERS];          // taxi vehicle ID

// Trucker runtime
new bool:pTruckerOnRoute[MAX_PLAYERS];
new pTruckerRouteIdx[MAX_PLAYERS];      // current route index
new pTruckerVehicle[MAX_PLAYERS];
new pTruckerCheckpoint[MAX_PLAYERS];    // 0=go to pickup, 1=go to deliver

// Miner runtime
new bool:pMinerMining[MAX_PLAYERS];
new pMinerTimer[MAX_PLAYERS];
new pMinerOreCount[MAX_PLAYERS];        // ores mined this session

// Bus runtime
new bool:pBusOnRoute[MAX_PLAYERS];
new pBusStopIndex[MAX_PLAYERS];
new pBusVehicle[MAX_PLAYERS];
new pBusPassengers[MAX_PLAYERS];

// Fisher runtime
new bool:pFishing[MAX_PLAYERS];
new pFishTimer[MAX_PLAYERS];
new pFishCaught[MAX_PLAYERS][MAX_FISH_TYPES]; // caught fish counts

// ============================================================================
// LOAD FUNCTIONS
// ============================================================================

stock LoadTruckerCompanies()
{
    format(query, sizeof(query), "SELECT * FROM trucker_companies ORDER BY id");
    mysql_function_query(MySQL_C1, query, true, "OnTruckerCompaniesLoaded", "");
}

publics: OnTruckerCompaniesLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalTruckerCompanies = 0;

    for(new i = 0; i < rows && i < MAX_TRUCKER_COMPANIES; i++)
    {
        TruckerCompanies[i][tcID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", TruckerCompanies[i][tcName], MySQL_C1, 48);
        TruckerCompanies[i][tcType] = cache_get_field_content_int(i, "type", MySQL_C1);
        TruckerCompanies[i][tcBaseX] = cache_get_field_content_float(i, "base_x", MySQL_C1);
        TruckerCompanies[i][tcBaseY] = cache_get_field_content_float(i, "base_y", MySQL_C1);
        TruckerCompanies[i][tcBaseZ] = cache_get_field_content_float(i, "base_z", MySQL_C1);
        TruckerCompanies[i][tcBaseAngle] = cache_get_field_content_float(i, "base_angle", MySQL_C1);
        TotalTruckerCompanies++;
    }
    printf("[Jobs] Loaded %d trucker companies.", TotalTruckerCompanies);
    return 1;
}

stock LoadTruckerRoutes()
{
    format(query, sizeof(query), "SELECT * FROM trucker_routes ORDER BY id");
    mysql_function_query(MySQL_C1, query, true, "OnTruckerRoutesLoaded", "");
}

publics: OnTruckerRoutesLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalTruckerRoutes = 0;

    for(new i = 0; i < rows && i < MAX_TRUCKER_ROUTES; i++)
    {
        TruckerRoutes[i][trID] = cache_get_field_content_int(i, "id", MySQL_C1);
        TruckerRoutes[i][trCompanyID] = cache_get_field_content_int(i, "company_id", MySQL_C1);
        cache_get_field_content(i, "route_name", TruckerRoutes[i][trRouteName], MySQL_C1, 64);
        TruckerRoutes[i][trPickupX] = cache_get_field_content_float(i, "pickup_x", MySQL_C1);
        TruckerRoutes[i][trPickupY] = cache_get_field_content_float(i, "pickup_y", MySQL_C1);
        TruckerRoutes[i][trPickupZ] = cache_get_field_content_float(i, "pickup_z", MySQL_C1);
        TruckerRoutes[i][trDeliverX] = cache_get_field_content_float(i, "deliver_x", MySQL_C1);
        TruckerRoutes[i][trDeliverY] = cache_get_field_content_float(i, "deliver_y", MySQL_C1);
        TruckerRoutes[i][trDeliverZ] = cache_get_field_content_float(i, "deliver_z", MySQL_C1);
        TruckerRoutes[i][trPayAmount] = cache_get_field_content_int(i, "pay_amount", MySQL_C1);
        TruckerRoutes[i][trDistBonus] = cache_get_field_content_int(i, "distance_bonus", MySQL_C1);
        TotalTruckerRoutes++;
    }
    printf("[Jobs] Loaded %d trucker routes.", TotalTruckerRoutes);
    return 1;
}

stock LoadFishMarkets()
{
    format(query, sizeof(query), "SELECT * FROM fish_markets ORDER BY id");
    mysql_function_query(MySQL_C1, query, true, "OnFishMarketsLoaded", "");
}

publics: OnFishMarketsLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalFishMarkets = 0;

    for(new i = 0; i < rows && i < MAX_FISH_MARKETS; i++)
    {
        FishMarkets[i][fmID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", FishMarkets[i][fmName], MySQL_C1, 48);
        FishMarkets[i][fmX] = cache_get_field_content_float(i, "pos_x", MySQL_C1);
        FishMarkets[i][fmY] = cache_get_field_content_float(i, "pos_y", MySQL_C1);
        FishMarkets[i][fmZ] = cache_get_field_content_float(i, "pos_z", MySQL_C1);
        FishMarkets[i][fmPrices][0] = cache_get_field_content_int(i, "price_ikan_nila", MySQL_C1);
        FishMarkets[i][fmPrices][1] = cache_get_field_content_int(i, "price_ikan_mas", MySQL_C1);
        FishMarkets[i][fmPrices][2] = cache_get_field_content_int(i, "price_ikan_lele", MySQL_C1);
        FishMarkets[i][fmPrices][3] = cache_get_field_content_int(i, "price_ikan_bawal", MySQL_C1);
        FishMarkets[i][fmPrices][4] = cache_get_field_content_int(i, "price_ikan_patin", MySQL_C1);
        TotalFishMarkets++;
    }
    printf("[Jobs] Loaded %d fish markets.", TotalFishMarkets);
    return 1;
}

// ============================================================================
// PLAYER JOB LOAD / SAVE
// ============================================================================

stock LoadPlayerJob(playerid)
{
    ResetPlayerJobData(playerid);
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT * FROM player_jobs WHERE player_id = '%d' LIMIT 1",
        PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnPlayerJobLoaded", "d", playerid);
}

publics: OnPlayerJobLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);
    if(!rows) return 1;

    pJobType[playerid] = cache_get_field_content_int(0, "job_type", MySQL_C1);
    pJobCompanyID[playerid] = cache_get_field_content_int(0, "company_id", MySQL_C1);
    pJobTotalEarnings[playerid] = cache_get_field_content_int(0, "total_earnings", MySQL_C1);
    pJobTripsCompleted[playerid] = cache_get_field_content_int(0, "trips_completed", MySQL_C1);

    new jobName[24];
    GetJobName(pJobType[playerid], jobName, sizeof(jobName));
    if(pJobType[playerid] > JOB_NONE)
    {
        SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
            "[Kerja] Pekerjaan: %s | Total trip: %d | Pendapatan: $%d",
            jobName, pJobTripsCompleted[playerid], pJobTotalEarnings[playerid]);
    }
    return 1;
}

stock ResetPlayerJobData(playerid)
{
    pJobType[playerid] = JOB_NONE;
    pJobCompanyID[playerid] = 0;
    pJobTotalEarnings[playerid] = 0;
    pJobTripsCompleted[playerid] = 0;

    // Taxi
    pTaxiOnTrip[playerid] = false;
    pTaxiPassenger[playerid] = INVALID_PLAYER_ID;
    pTaxiStartX[playerid] = 0.0;
    pTaxiStartY[playerid] = 0.0;
    pTaxiStartZ[playerid] = 0.0;
    pTaxiVehicle[playerid] = INVALID_VEHICLE_ID;

    // Trucker
    pTruckerOnRoute[playerid] = false;
    pTruckerRouteIdx[playerid] = -1;
    pTruckerVehicle[playerid] = INVALID_VEHICLE_ID;
    pTruckerCheckpoint[playerid] = 0;

    // Miner
    pMinerMining[playerid] = false;
    if(pMinerTimer[playerid] != 0) { KillTimer(pMinerTimer[playerid]); pMinerTimer[playerid] = 0; }
    pMinerOreCount[playerid] = 0;

    // Bus
    pBusOnRoute[playerid] = false;
    pBusStopIndex[playerid] = 0;
    pBusVehicle[playerid] = INVALID_VEHICLE_ID;
    pBusPassengers[playerid] = 0;

    // Fisher
    pFishing[playerid] = false;
    if(pFishTimer[playerid] != 0) { KillTimer(pFishTimer[playerid]); pFishTimer[playerid] = 0; }
    for(new f = 0; f < MAX_FISH_TYPES; f++) pFishCaught[playerid][f] = 0;
}

stock SavePlayerJob(playerid)
{
    if(pJobType[playerid] == JOB_NONE) return;
    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE player_jobs SET total_earnings = '%d', trips_completed = '%d' WHERE player_id = '%d'",
        pJobTotalEarnings[playerid], pJobTripsCompleted[playerid], PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, false, "", "");
}

stock GetJobName(jobType, output[], maxlen)
{
    switch(jobType)
    {
        case JOB_TAXI:      strmid(output, "Supir Taksi", 0, 12, maxlen);
        case JOB_TRUCKER:   strmid(output, "Trucker", 0, 8, maxlen);
        case JOB_MINER:     strmid(output, "Penambang", 0, 10, maxlen);
        case JOB_BUS:       strmid(output, "Supir Bus", 0, 10, maxlen);
        case JOB_FISHERMAN: strmid(output, "Nelayan", 0, 8, maxlen);
        default:            strmid(output, "Pengangguran", 0, 13, maxlen);
    }
}

// ============================================================================
// JOB CENTER COMMAND
// ============================================================================

COMMAND:kerja(playerid, params[])
{
    if(pJobType[playerid] != JOB_NONE)
    {
        new jobName[24];
        GetJobName(pJobType[playerid], jobName, sizeof(jobName));
        SendClientFormattedMessage(playerid, COLOR_JOB,
            "[Kerja] Kamu sudah bekerja sebagai %s. Gunakan /resign untuk berhenti.", jobName);
        return true;
    }

    new dialog[256];
    format(dialog, sizeof(dialog),
        "Supir Taksi\t$%d/trip\n\
Trucker\t$%d+/trip\n\
Penambang\t$%d/ore\n\
Supir Bus\t$%d/stop\n\
Nelayan\tFluktuatif",
        TAXI_BASE_FARE, 5000, MINE_BASE_PAY, BUS_PASSENGER_PAY);

    ShowPlayerDialog(playerid, DIALOG_JOB_CENTER, DIALOG_STYLE_TABLIST_HEADERS,
        "Pusat Pekerjaan", dialog, "Pilih", "Batal");
    return true;
}

COMMAND:resign(playerid, params[])
{
    if(pJobType[playerid] == JOB_NONE)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak punya pekerjaan!"), true;

    ShowPlayerDialog(playerid, DIALOG_JOB_CONFIRM_QUIT, DIALOG_STYLE_MSGBOX,
        "Konfirmasi Resign", "Apakah kamu yakin ingin berhenti dari pekerjaan ini?", "Ya", "Tidak");
    return true;
}

COMMAND:jobinfo(playerid, params[])
{
    new jobName[24];
    GetJobName(pJobType[playerid], jobName, sizeof(jobName));

    SendClientFormattedMessage(playerid, COLOR_JOB_INFO, "======= Info Pekerjaan =======");
    SendClientFormattedMessage(playerid, COLOR_JOB_INFO, "Pekerjaan: %s", jobName);
    SendClientFormattedMessage(playerid, COLOR_JOB_INFO, "Trip selesai: %d", pJobTripsCompleted[playerid]);
    SendClientFormattedMessage(playerid, COLOR_JOB_INFO, "Total pendapatan: $%d", pJobTotalEarnings[playerid]);
    SendClientFormattedMessage(playerid, COLOR_JOB_INFO, "==============================");
    return true;
}

// ============================================================================
// JOB DIALOG HANDLER
// ============================================================================

stock HandleJobDialogs(playerid, dialogid, response, listitem)
{
    switch(dialogid)
    {
        case DIALOG_JOB_CENTER:
        {
            if(!response) return 1;
            new selectedJob = listitem + 1; // JOB_TAXI=1, etc.

            if(selectedJob == JOB_TRUCKER)
            {
                // Show trucker companies
                new dlg[512];
                for(new i = 0; i < TotalTruckerCompanies; i++)
                {
                    new line[64];
                    format(line, sizeof(line), "%s\n", TruckerCompanies[i][tcName]);
                    strcat(dlg, line, sizeof(dlg));
                }
                ShowPlayerDialog(playerid, DIALOG_JOB_TRUCKER_CO, DIALOG_STYLE_LIST,
                    "Pilih Perusahaan Trucker", dlg, "Pilih", "Kembali");
                return 1;
            }

            // Direct hire for other jobs
            HirePlayerJob(playerid, selectedJob, 0);
            return 1;
        }
        case DIALOG_JOB_TRUCKER_CO:
        {
            if(!response) return cmd_kerja(playerid, ""), 1; // go back
            if(listitem >= TotalTruckerCompanies) return 1;

            HirePlayerJob(playerid, JOB_TRUCKER, TruckerCompanies[listitem][tcID]);
            return 1;
        }
        case DIALOG_JOB_CONFIRM_QUIT:
        {
            if(!response) return 1;

            // Stop any active job activity
            StopJobActivity(playerid);

            new jobName[24];
            GetJobName(pJobType[playerid], jobName, sizeof(jobName));

            // Delete from DB
            mysql_format(MySQL_C1, query, sizeof(query),
                "DELETE FROM player_jobs WHERE player_id = '%d'",
                PlayerInfo[playerid][pID]);
            mysql_function_query(MySQL_C1, query, false, "", "");

            SendClientFormattedMessage(playerid, COLOR_JOB,
                "[Kerja] Kamu telah berhenti sebagai %s.", jobName);

            pJobType[playerid] = JOB_NONE;
            pJobCompanyID[playerid] = 0;
            return 1;
        }
        case DIALOG_JOB_FISH_SELL:
        {
            if(!response) return 1;
            SellFishAtMarket(playerid, listitem);
            return 1;
        }
    }
    return 0;
}

stock HirePlayerJob(playerid, jobType, companyId)
{
    // Requirement checks
    if(jobType == JOB_TRUCKER || jobType == JOB_BUS)
    {
        if(!PlayerInfo[playerid][pHasSIMB])
        {
            SendClientFormattedMessage(playerid, COLOR_RED,
                "Kamu membutuhkan SIM B untuk pekerjaan ini!");
            return;
        }
    }
    if(jobType == JOB_TAXI)
    {
        if(!PlayerInfo[playerid][pHasSIMA])
        {
            SendClientFormattedMessage(playerid, COLOR_RED,
                "Kamu membutuhkan SIM A untuk menjadi supir taksi!");
            return;
        }
    }

    pJobType[playerid] = jobType;
    pJobCompanyID[playerid] = companyId;
    pJobTotalEarnings[playerid] = 0;
    pJobTripsCompleted[playerid] = 0;

    // Insert to DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO player_jobs (player_id, job_type, company_id) VALUES ('%d', '%d', '%d') \
ON DUPLICATE KEY UPDATE job_type = '%d', company_id = '%d'",
        PlayerInfo[playerid][pID], jobType, companyId, jobType, companyId);
    mysql_function_query(MySQL_C1, query, false, "", "");

    new jobName[24];
    GetJobName(jobType, jobName, sizeof(jobName));
    SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
        "[Kerja] Selamat! Kamu sekarang bekerja sebagai %s.", jobName);

    if(jobType == JOB_TRUCKER && companyId > 0)
    {
        for(new i = 0; i < TotalTruckerCompanies; i++)
        {
            if(TruckerCompanies[i][tcID] == companyId)
            {
                SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
                    "[Kerja] Perusahaan: %s", TruckerCompanies[i][tcName]);
                break;
            }
        }
    }

    // RP
    new rptext[80];
    format(rptext, sizeof(rptext), "* %s mendaftar sebagai %s.", PlayerInfo[playerid][pICName], jobName);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
}

stock StopJobActivity(playerid)
{
    // Stop taxi trip
    if(pTaxiOnTrip[playerid])
    {
        if(IsPlayerConnected(pTaxiPassenger[playerid]))
            SendClientFormattedMessage(pTaxiPassenger[playerid], COLOR_RED, "[Taksi] Supir berhenti beroperasi.");
        pTaxiOnTrip[playerid] = false;
        pTaxiPassenger[playerid] = INVALID_PLAYER_ID;
    }

    // Stop trucker route
    if(pTruckerOnRoute[playerid])
    {
        DisablePlayerCheckpoint(playerid);
        pTruckerOnRoute[playerid] = false;
        if(pTruckerVehicle[playerid] != INVALID_VEHICLE_ID)
        {
            DestroyVehicle(pTruckerVehicle[playerid]);
            pTruckerVehicle[playerid] = INVALID_VEHICLE_ID;
        }
    }

    // Stop mining
    if(pMinerMining[playerid])
    {
        pMinerMining[playerid] = false;
        if(pMinerTimer[playerid] != 0)
        {
            KillTimer(pMinerTimer[playerid]);
            pMinerTimer[playerid] = 0;
        }
    }

    // Stop bus route
    if(pBusOnRoute[playerid])
    {
        DisablePlayerCheckpoint(playerid);
        pBusOnRoute[playerid] = false;
        if(pBusVehicle[playerid] != INVALID_VEHICLE_ID)
        {
            DestroyVehicle(pBusVehicle[playerid]);
            pBusVehicle[playerid] = INVALID_VEHICLE_ID;
        }
    }

    // Stop fishing
    if(pFishing[playerid])
    {
        pFishing[playerid] = false;
        if(pFishTimer[playerid] != 0)
        {
            KillTimer(pFishTimer[playerid]);
            pFishTimer[playerid] = 0;
        }
        ClearAnimations(playerid);
    }
}

// ============================================================================
// TAXI SYSTEM
// ============================================================================

COMMAND:taxigo(playerid, params[])
{
    if(pJobType[playerid] != JOB_TAXI)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan supir taksi!"), true;

    if(pTaxiOnTrip[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang dalam perjalanan!"), true;

    // Check if in vehicle
    if(!IsPlayerInAnyVehicle(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu harus di dalam kendaraan!"), true;

    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Taksi] Menunggu penumpang... Penumpang bisa masuk ke kendaraan kamu.");
    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Taksi] Gunakan /taxistart saat penumpang masuk, /taxistop untuk akhiri.");

    pTaxiVehicle[playerid] = GetPlayerVehicleID(playerid);
    return true;
}

COMMAND:taxistart(playerid, params[])
{
    if(pJobType[playerid] != JOB_TAXI)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan supir taksi!"), true;

    if(pTaxiOnTrip[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Perjalanan sudah berjalan!"), true;

    if(!IsPlayerInAnyVehicle(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu harus di dalam kendaraan!"), true;

    // Find passenger in vehicle
    new vid = GetPlayerVehicleID(playerid);
    new passenger = INVALID_PLAYER_ID;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(i == playerid) continue;
        if(GetPlayerVehicleID(i) == vid)
        {
            passenger = i;
            break;
        }
    }

    if(passenger == INVALID_PLAYER_ID)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada penumpang di kendaraan!"), true;

    GetPlayerPos(playerid, pTaxiStartX[playerid], pTaxiStartY[playerid], pTaxiStartZ[playerid]);
    pTaxiOnTrip[playerid] = true;
    pTaxiPassenger[playerid] = passenger;
    pTaxiVehicle[playerid] = vid;

    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Taksi] Argo dimulai! Penumpang: %s", PlayerInfo[passenger][pICName]);
    SendClientFormattedMessage(passenger, COLOR_JOB,
        "[Taksi] Argo dimulai. Tarif dasar $%d + $%d per unit jarak.", TAXI_BASE_FARE, TAXI_PER_UNIT);

    new rptext[80];
    format(rptext, sizeof(rptext), "* %s menyalakan argo taksi.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    return true;
}

COMMAND:taxistop(playerid, params[])
{
    if(pJobType[playerid] != JOB_TAXI)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan supir taksi!"), true;

    if(!pTaxiOnTrip[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada perjalanan aktif!"), true;

    // Calculate fare
    new Float:endX, Float:endY, Float:endZ;
    GetPlayerPos(playerid, endX, endY, endZ);
    new Float:dist = floatsqroot(
        (endX - pTaxiStartX[playerid]) * (endX - pTaxiStartX[playerid]) +
        (endY - pTaxiStartY[playerid]) * (endY - pTaxiStartY[playerid])
    );

    new distUnits = floatround(dist / 50.0); // 1 unit per 50 meters
    new fare = TAXI_BASE_FARE + (distUnits * TAXI_PER_UNIT);
    new companyCut = fare * TAXI_COMPANY_CUT / 100;
    new driverPay = fare - companyCut;

    new passenger = pTaxiPassenger[playerid];

    // Pay driver
    PlayerInfo[playerid][pMoney] += driverPay;
    pJobTotalEarnings[playerid] += driverPay;
    pJobTripsCompleted[playerid]++;

    SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
        "[Taksi] Perjalanan selesai! Jarak: %.0fm | Argo: $%d | Potongan %d%%: $%d | Kamu terima: $%d",
        dist, fare, TAXI_COMPANY_CUT, companyCut, driverPay);

    if(IsPlayerConnected(passenger) && PlayerInfo[passenger][pLogged])
    {
        PlayerInfo[passenger][pMoney] -= fare;
        SendClientFormattedMessage(passenger, COLOR_JOB,
            "[Taksi] Perjalanan selesai. Total argo: $%d", fare);
    }

    pTaxiOnTrip[playerid] = false;
    pTaxiPassenger[playerid] = INVALID_PLAYER_ID;

    SavePlayerJob(playerid);

    new rptext[80];
    format(rptext, sizeof(rptext), "* %s mematikan argo taksi.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    return true;
}

// ============================================================================
// TRUCKER SYSTEM
// ============================================================================

COMMAND:truckjob(playerid, params[])
{
    if(pJobType[playerid] != JOB_TRUCKER)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan trucker!"), true;

    if(pTruckerOnRoute[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sudah dalam misi pengiriman!"), true;

    // Show routes for the player's company
    new dlg[512], count = 0;
    for(new i = 0; i < TotalTruckerRoutes; i++)
    {
        if(TruckerRoutes[i][trCompanyID] == pJobCompanyID[playerid])
        {
            new line[80];
            format(line, sizeof(line), "%s\t$%d\n",
                TruckerRoutes[i][trRouteName], TruckerRoutes[i][trPayAmount]);
            strcat(dlg, line, sizeof(dlg));
            count++;
        }
    }

    if(count == 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED,
            "Belum ada rute tersedia untuk perusahaan kamu.");
        return true;
    }

    ShowPlayerDialog(playerid, DIALOG_JOB_TRUCKER_ROUTE, DIALOG_STYLE_TABLIST_HEADERS,
        "Pilih Rute Pengiriman", dlg, "Ambil", "Batal");
    return true;
}

COMMAND:truckcancel(playerid, params[])
{
    if(!pTruckerOnRoute[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak dalam misi pengiriman!"), true;

    DisablePlayerCheckpoint(playerid);
    pTruckerOnRoute[playerid] = false;

    if(pTruckerVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(pTruckerVehicle[playerid]);
        pTruckerVehicle[playerid] = INVALID_VEHICLE_ID;
    }

    SendClientFormattedMessage(playerid, COLOR_JOB, "[Trucker] Misi pengiriman dibatalkan.");
    return true;
}

stock HandleTruckerRouteDialog(playerid, listitem)
{
    // Find the nth route for player's company
    new count = 0, routeIdx = -1;
    for(new i = 0; i < TotalTruckerRoutes; i++)
    {
        if(TruckerRoutes[i][trCompanyID] == pJobCompanyID[playerid])
        {
            if(count == listitem) { routeIdx = i; break; }
            count++;
        }
    }

    if(routeIdx == -1) return;

    pTruckerRouteIdx[playerid] = routeIdx;
    pTruckerOnRoute[playerid] = true;
    pTruckerCheckpoint[playerid] = 0; // go to pickup first

    // Spawn truck near player
    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);

    pTruckerVehicle[playerid] = CreateVehicle(515, px + 3.0, py, pz, pa, -1, -1, -1); // Roadtrain
    PutPlayerInVehicle(playerid, pTruckerVehicle[playerid], 0);

    // Set checkpoint to pickup
    SetPlayerCheckpoint(playerid,
        TruckerRoutes[routeIdx][trPickupX],
        TruckerRoutes[routeIdx][trPickupY],
        TruckerRoutes[routeIdx][trPickupZ], 5.0);

    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Trucker] Misi: %s | Bayaran: $%d",
        TruckerRoutes[routeIdx][trRouteName], TruckerRoutes[routeIdx][trPayAmount]);
    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Trucker] Pergi ke titik pengambilan barang (checkpoint merah).");
}

stock HandleTruckerCheckpoint(playerid)
{
    if(!pTruckerOnRoute[playerid]) return 0;

    new ri = pTruckerRouteIdx[playerid];
    if(ri < 0) return 0;

    if(pTruckerCheckpoint[playerid] == 0)
    {
        // Arrived at pickup
        pTruckerCheckpoint[playerid] = 1;
        DisablePlayerCheckpoint(playerid);

        // Set checkpoint to delivery
        SetPlayerCheckpoint(playerid,
            TruckerRoutes[ri][trDeliverX],
            TruckerRoutes[ri][trDeliverY],
            TruckerRoutes[ri][trDeliverZ], 5.0);

        SendClientFormattedMessage(playerid, COLOR_JOB,
            "[Trucker] Barang dimuat! Antar ke lokasi tujuan (checkpoint).");

        new rptext[80];
        format(rptext, sizeof(rptext), "* %s memuat barang ke truk.", PlayerInfo[playerid][pICName]);
        ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    }
    else
    {
        // Arrived at delivery
        DisablePlayerCheckpoint(playerid);
        pTruckerOnRoute[playerid] = false;

        new pay = TruckerRoutes[ri][trPayAmount] + TruckerRoutes[ri][trDistBonus];
        PlayerInfo[playerid][pMoney] += pay;
        pJobTotalEarnings[playerid] += pay;
        pJobTripsCompleted[playerid]++;

        SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
            "[Trucker] Pengiriman selesai! Bayaran: $%d (+bonus: $%d) = $%d",
            TruckerRoutes[ri][trPayAmount], TruckerRoutes[ri][trDistBonus], pay);

        // Destroy truck
        if(pTruckerVehicle[playerid] != INVALID_VEHICLE_ID)
        {
            RemovePlayerFromVehicle(playerid);
            DestroyVehicle(pTruckerVehicle[playerid]);
            pTruckerVehicle[playerid] = INVALID_VEHICLE_ID;
        }

        SavePlayerJob(playerid);

        new rptext[80];
        format(rptext, sizeof(rptext), "* %s selesai mengantarkan barang.", PlayerInfo[playerid][pICName]);
        ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    }
    return 1;
}

// ============================================================================
// MINER SYSTEM
// ============================================================================

// Mining spots (pre-defined coordinates)
new Float:MiningSpots[][3] = {
    {590.5, 870.2, -42.5},     // Quarry LS
    {2609.8, -2227.4, 13.3},   // Hunter Quarry (LV area)
    {-2293.5, -1610.8, 479.3}  // Mount Chilliad mine area
};

COMMAND:tambang(playerid, params[])
{
    if(pJobType[playerid] != JOB_MINER)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan penambang!"), true;

    if(pMinerMining[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang menambang!"), true;

    // Check if near a mining spot
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new bool:nearSpot = false;
    for(new i = 0; i < sizeof(MiningSpots); i++)
    {
        new Float:dist = floatsqroot(
            (px - MiningSpots[i][0]) * (px - MiningSpots[i][0]) +
            (py - MiningSpots[i][1]) * (py - MiningSpots[i][1]) +
            (pz - MiningSpots[i][2]) * (pz - MiningSpots[i][2])
        );
        if(dist < 50.0) { nearSpot = true; break; }
    }

    if(!nearSpot)
    {
        SendClientFormattedMessage(playerid, COLOR_RED,
            "Kamu harus berada di area pertambangan! Gunakan GPS untuk lokasi.");
        return true;
    }

    pMinerMining[playerid] = true;
    pMinerTimer[playerid] = SetTimerEx("OnMinerDig", MINE_INTERVAL, true, "d", playerid);

    ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.0, 1, 0, 0, 0, 0);
    SendClientFormattedMessage(playerid, COLOR_JOB, "[Tambang] Mulai menambang... (/stoptambang untuk berhenti)");

    new rptext[80];
    format(rptext, sizeof(rptext), "* %s mulai menambang.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    return true;
}

COMMAND:stoptambang(playerid, params[])
{
    if(!pMinerMining[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak sedang menambang!"), true;

    pMinerMining[playerid] = false;
    if(pMinerTimer[playerid] != 0)
    {
        KillTimer(pMinerTimer[playerid]);
        pMinerTimer[playerid] = 0;
    }
    ClearAnimations(playerid);

    // Pay for ores
    new pay = pMinerOreCount[playerid] * MINE_BASE_PAY;
    PlayerInfo[playerid][pMoney] += pay;
    pJobTotalEarnings[playerid] += pay;
    pJobTripsCompleted[playerid]++;

    SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
        "[Tambang] Selesai menambang! Ore: %d | Bayaran: $%d", pMinerOreCount[playerid], pay);

    pMinerOreCount[playerid] = 0;
    SavePlayerJob(playerid);
    return true;
}

publics: OnMinerDig(playerid)
{
    if(!pMinerMining[playerid])
    {
        KillTimer(pMinerTimer[playerid]);
        pMinerTimer[playerid] = 0;
        return 1;
    }

    pMinerOreCount[playerid]++;
    new pay = MINE_BASE_PAY + random(2000); // random bonus

    // Apply animation again
    ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.0, 1, 0, 0, 0, 0);

    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Tambang] +1 Ore digali! Total: %d ore | Estimasi: $%d",
        pMinerOreCount[playerid], pMinerOreCount[playerid] * MINE_BASE_PAY);

    #pragma unused pay
    return 1;
}

// ============================================================================
// FISHING SYSTEM (anyone with rod, but fisherman gets bonus)
// ============================================================================

COMMAND:mancing(playerid, params[])
{
    if(pFishing[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sudah memancing!"), true;

    // Check if has fishing rod in inventory
    new bool:hasRod = false;
    if(pJobType[playerid] == JOB_FISHERMAN) hasRod = true; // fisherman always has rod
    else
    {
        for(new s = 0; s < MAX_INVENTORY_SLOTS; s++)
        {
            if(PlayerInfo[playerid][pInvItems][s] == ITEM_FISHING_ROD)
            {
                hasRod = true;
                break;
            }
        }
    }

    if(!hasRod)
    {
        SendClientFormattedMessage(playerid, COLOR_RED,
            "Kamu butuh Pancing (beli di Market) atau daftar jadi Nelayan!");
        return true;
    }

    // Check if near water (simple Y check for beach areas or use Z)
    // Simplified: just check Z is near sea level
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    if(pz > 5.0 && pz < 900.0)
    {
        // Additional simplified check — allow near known water bodies
        // For now, allow anywhere below z=5 or use a flag
    }

    pFishing[playerid] = true;
    pFishTimer[playerid] = SetTimerEx("OnFishCast", FISH_INTERVAL, true, "d", playerid);

    ApplyAnimation(playerid, "CRACK", "crckdeth2", 4.0, 1, 0, 0, 0, 0);
    SendClientFormattedMessage(playerid, COLOR_JOB, "[Mancing] Memulai memancing... (/stopmancing untuk berhenti)");

    new rptext[80];
    format(rptext, sizeof(rptext), "* %s melempar kail pancing.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    return true;
}

COMMAND:stopmancing(playerid, params[])
{
    if(!pFishing[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak sedang memancing!"), true;

    pFishing[playerid] = false;
    if(pFishTimer[playerid] != 0)
    {
        KillTimer(pFishTimer[playerid]);
        pFishTimer[playerid] = 0;
    }
    ClearAnimations(playerid);

    new total = 0;
    for(new f = 0; f < MAX_FISH_TYPES; f++) total += pFishCaught[playerid][f];

    SendClientFormattedMessage(playerid, COLOR_JOB, "[Mancing] Selesai! Total ikan: %d. Jual di Pasar Ikan (/jualikan).", total);
    return true;
}

publics: OnFishCast(playerid)
{
    if(!pFishing[playerid])
    {
        KillTimer(pFishTimer[playerid]);
        pFishTimer[playerid] = 0;
        return 1;
    }

    // Random chance to catch
    new chance = random(100);
    if(chance < 30) // 30% chance no catch
    {
        SendClientFormattedMessage(playerid, COLOR_JOB, "[Mancing] Tidak ada tangkapan... mencoba lagi.");
        ApplyAnimation(playerid, "CRACK", "crckdeth2", 4.0, 1, 0, 0, 0, 0);
        return 1;
    }

    // Random fish type
    new fishType = random(MAX_FISH_TYPES);
    pFishCaught[playerid][fishType]++;

    // Fisherman job bonus: double catch chance
    if(pJobType[playerid] == JOB_FISHERMAN && random(100) < 40)
    {
        pFishCaught[playerid][fishType]++;
        SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
            "[Mancing] BONUS! Dapat 2x %s!", FishNames[fishType]);
    }
    else
    {
        SendClientFormattedMessage(playerid, COLOR_JOB,
            "[Mancing] Dapat %s!", FishNames[fishType]);
    }

    ApplyAnimation(playerid, "CRACK", "crckdeth2", 4.0, 1, 0, 0, 0, 0);

    new rptext[80];
    format(rptext, sizeof(rptext), "* %s menarik kail dan mendapat ikan.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    return 1;
}

COMMAND:jualikan(playerid, params[])
{
    // Check if near a fish market
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new marketIdx = -1;
    for(new i = 0; i < TotalFishMarkets; i++)
    {
        new Float:dist = floatsqroot(
            (px - FishMarkets[i][fmX]) * (px - FishMarkets[i][fmX]) +
            (py - FishMarkets[i][fmY]) * (py - FishMarkets[i][fmY])
        );
        if(dist < 20.0) { marketIdx = i; break; }
    }

    if(marketIdx == -1)
    {
        SendClientFormattedMessage(playerid, COLOR_RED,
            "Kamu harus berada di dekat Pasar Ikan untuk menjual!");
        return true;
    }

    // Check if has any fish
    new total = 0;
    for(new f = 0; f < MAX_FISH_TYPES; f++) total += pFishCaught[playerid][f];

    if(total == 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak punya ikan untuk dijual!");
        return true;
    }

    // Show sell dialog with current prices
    new dlg[512];
    format(dlg, sizeof(dlg), "Ikan\tJumlah\tHarga/ekor\tSubtotal\n");
    new grandTotal = 0;
    for(new f = 0; f < MAX_FISH_TYPES; f++)
    {
        if(pFishCaught[playerid][f] > 0)
        {
            new subtotal = pFishCaught[playerid][f] * FishMarkets[marketIdx][fmPrices][f];
            grandTotal += subtotal;
            new line[80];
            format(line, sizeof(line), "%s\t%d\t$%d\t$%d\n",
                FishNames[f], pFishCaught[playerid][f],
                FishMarkets[marketIdx][fmPrices][f], subtotal);
            strcat(dlg, line, sizeof(dlg));
        }
    }

    new footer[48];
    format(footer, sizeof(footer), "\n{00FF00}TOTAL: $%d", grandTotal);
    strcat(dlg, footer, sizeof(dlg));

    SetPVarInt(playerid, "FishMarketIdx", marketIdx);
    ShowPlayerDialog(playerid, DIALOG_JOB_FISH_SELL, DIALOG_STYLE_TABLIST_HEADERS,
        FishMarkets[marketIdx][fmName], dlg, "Jual Semua", "Batal");
    return true;
}

stock SellFishAtMarket(playerid, listitem)
{
    new marketIdx = GetPVarInt(playerid, "FishMarketIdx");
    if(marketIdx < 0 || marketIdx >= TotalFishMarkets) return;

    new grandTotal = 0;
    for(new f = 0; f < MAX_FISH_TYPES; f++)
    {
        grandTotal += pFishCaught[playerid][f] * FishMarkets[marketIdx][fmPrices][f];
        pFishCaught[playerid][f] = 0;
    }

    if(grandTotal <= 0) return;

    PlayerInfo[playerid][pMoney] += grandTotal;
    pJobTotalEarnings[playerid] += grandTotal;
    pJobTripsCompleted[playerid]++;

    SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
        "[Pasar Ikan] Semua ikan terjual! Total: $%d", grandTotal);

    SavePlayerJob(playerid);

    new rptext[80];
    format(rptext, sizeof(rptext), "* %s menjual ikan di pasar.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    #pragma unused listitem
}

// ============================================================================
// BUS DRIVER SYSTEM
// ============================================================================

// Pre-defined bus stops per city
new Float:BusStopsMekarPura[][3] = {
    {1207.5, -1718.2, 13.5},   // LS stop 1
    {1510.3, -1743.8, 13.5},   // LS stop 2
    {1810.2, -1877.5, 13.5},   // LS stop 3
    {2013.4, -1432.1, 13.5},   // LS stop 4
    {1207.5, -1718.2, 13.5}    // back to start
};

COMMAND:busgo(playerid, params[])
{
    if(pJobType[playerid] != JOB_BUS)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan supir bus!"), true;

    if(pBusOnRoute[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sudah dalam rute!"), true;

    // Spawn bus
    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);

    pBusVehicle[playerid] = CreateVehicle(BUS_MODEL, px + 3.0, py, pz, pa, -1, -1, -1);
    PutPlayerInVehicle(playerid, pBusVehicle[playerid], 0);

    pBusOnRoute[playerid] = true;
    pBusStopIndex[playerid] = 0;
    pBusPassengers[playerid] = 0;

    // Set first checkpoint
    SetPlayerCheckpoint(playerid,
        BusStopsMekarPura[0][0],
        BusStopsMekarPura[0][1],
        BusStopsMekarPura[0][2], 5.0);

    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Bus] Rute dimulai! Pergi ke halte pertama (checkpoint).");
    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Bus] Bayaran: $%d per halte. /busstop untuk akhiri.", BUS_PASSENGER_PAY);
    return true;
}

COMMAND:busstop(playerid, params[])
{
    if(!pBusOnRoute[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak dalam rute bus!"), true;

    DisablePlayerCheckpoint(playerid);
    pBusOnRoute[playerid] = false;

    new pay = pBusPassengers[playerid] * BUS_PASSENGER_PAY;
    PlayerInfo[playerid][pMoney] += pay;
    pJobTotalEarnings[playerid] += pay;
    pJobTripsCompleted[playerid]++;

    SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
        "[Bus] Rute selesai! Halte dilalui: %d | Bayaran: $%d", pBusPassengers[playerid], pay);

    if(pBusVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        RemovePlayerFromVehicle(playerid);
        DestroyVehicle(pBusVehicle[playerid]);
        pBusVehicle[playerid] = INVALID_VEHICLE_ID;
    }

    SavePlayerJob(playerid);
    return true;
}

stock HandleBusCheckpoint(playerid)
{
    if(!pBusOnRoute[playerid]) return 0;

    pBusPassengers[playerid]++;
    pBusStopIndex[playerid]++;

    // Check if completed route
    if(pBusStopIndex[playerid] >= sizeof(BusStopsMekarPura))
    {
        // Route complete
        DisablePlayerCheckpoint(playerid);
        pBusOnRoute[playerid] = false;

        new pay = pBusPassengers[playerid] * BUS_PASSENGER_PAY;
        PlayerInfo[playerid][pMoney] += pay;
        pJobTotalEarnings[playerid] += pay;
        pJobTripsCompleted[playerid]++;

        SendClientFormattedMessage(playerid, COLOR_JOB_INFO,
            "[Bus] Rute selesai! Total halte: %d | Bayaran: $%d",
            pBusPassengers[playerid], pay);

        if(pBusVehicle[playerid] != INVALID_VEHICLE_ID)
        {
            RemovePlayerFromVehicle(playerid);
            DestroyVehicle(pBusVehicle[playerid]);
            pBusVehicle[playerid] = INVALID_VEHICLE_ID;
        }

        SavePlayerJob(playerid);
        return 1;
    }

    // Next stop
    DisablePlayerCheckpoint(playerid);
    SetPlayerCheckpoint(playerid,
        BusStopsMekarPura[pBusStopIndex[playerid]][0],
        BusStopsMekarPura[pBusStopIndex[playerid]][1],
        BusStopsMekarPura[pBusStopIndex[playerid]][2], 5.0);

    SendClientFormattedMessage(playerid, COLOR_JOB,
        "[Bus] Halte %d/%d tercapai! +$%d | Lanjut ke halte berikutnya.",
        pBusStopIndex[playerid], sizeof(BusStopsMekarPura) - 1, BUS_PASSENGER_PAY);

    new rptext[80];
    format(rptext, sizeof(rptext), "* Bus berhenti di halte dan membuka pintu.", PlayerInfo[playerid][pICName]);
    ProxDetector(15.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    return 1;
}

// ============================================================================
// CHECKPOINT HANDLER (called from new.pwn OnPlayerEnterCheckpoint)
// ============================================================================

stock HandleJobCheckpoint(playerid)
{
    // Trucker checkpoint
    if(pTruckerOnRoute[playerid])
        return HandleTruckerCheckpoint(playerid);

    // Bus checkpoint
    if(pBusOnRoute[playerid])
        return HandleBusCheckpoint(playerid);

    return 0;
}

// ============================================================================
// FISH PRICE FLUCTUATION (called periodically)
// ============================================================================

stock FluctuateFishPrices()
{
    for(new m = 0; m < TotalFishMarkets; m++)
    {
        for(new f = 0; f < MAX_FISH_TYPES; f++)
        {
            new change = random(2001) - 1000; // -1000 to +1000
            FishMarkets[m][fmPrices][f] += change;
            if(FishMarkets[m][fmPrices][f] < 1000) FishMarkets[m][fmPrices][f] = 1000;
            if(FishMarkets[m][fmPrices][f] > 15000) FishMarkets[m][fmPrices][f] = 15000;
        }

        // Save to DB
        mysql_format(MySQL_C1, query, sizeof(query),
            "UPDATE fish_markets SET price_ikan_nila='%d', price_ikan_mas='%d', \
price_ikan_lele='%d', price_ikan_bawal='%d', price_ikan_patin='%d', \
last_price_update=NOW() WHERE id='%d'",
            FishMarkets[m][fmPrices][0], FishMarkets[m][fmPrices][1],
            FishMarkets[m][fmPrices][2], FishMarkets[m][fmPrices][3],
            FishMarkets[m][fmPrices][4], FishMarkets[m][fmID]);
        mysql_function_query(MySQL_C1, query, false, "", "");
    }
    printf("[Jobs] Fish prices fluctuated.");
}

publics: OnFishPriceFluctuate()
{
    FluctuateFishPrices();
    return 1;
}

// ============================================================================
// DISCONNECT HANDLER
// ============================================================================

stock HandleJobDisconnect(playerid)
{
    StopJobActivity(playerid);
    SavePlayerJob(playerid);
    ResetPlayerJobData(playerid);
}
