// ============================================================================
// MODULE: factions.pwn
// Faction System — Legal (9-rank, gov salary) + Illegal (5-rank, self-funded)
// Features: duty, payday (breakdown), presensi, sanksi, cuti, faction chat
// ============================================================================

// ============================================================================
// DEFINES
// ============================================================================

#define MAX_FACTIONS            20
#define MAX_FACTION_RANKS       9
#define MAX_FACTION_MEMBERS_LOAD 50
#define FACTION_TYPE_LEGAL      1
#define FACTION_TYPE_ILLEGAL    2
#define COLOR_FACTION_CHAT      0xAAD4FFFF  // faction chat color
#define COLOR_FACTION_RADIO     0x6EB5FFFF  // faction radio color
#define COLOR_FACTION_INFO      0x33AA33FF  // faction info green
#define DUTY_SHIFT_SECONDS      28800       // 8 hours = 28800 seconds
#define MIN_DUTY_PER_WEEK       3           // minimum 3x on-duty per week
#define MAX_WARNINGS            3           // 3 warnings = auto-kick
#define PAYDAY_CHECK_INTERVAL   60000       // check duty time every 60 seconds

// Dialog IDs for faction
#define DIALOG_FACTION_CREATE_TYPE  200
#define DIALOG_FACTION_CREATE_NAME  201
#define DIALOG_FACTION_SETGAJI      202
#define DIALOG_FACTION_CUTI         203

// ============================================================================
// FACTION DATA (loaded from DB)
// ============================================================================

enum eFactionData {
    fID,
    fName[48],
    fType,                  // 1=legal, 2=illegal
    fBudget,                // government budget
    fBalance,               // treasury
    Float:fHQX,
    Float:fHQY,
    Float:fHQZ,
    Float:fHQAngle,
    fHQInterior,
    fHQVW,
    fPaydayInterval         // hours per payday
};
new FactionData[MAX_FACTIONS][eFactionData];
new TotalFactions = 0;

// Rank data per faction (in-memory)
enum eFactionRank {
    frFactionIdx,           // index into FactionData
    frLevel,
    frName[32],
    frSalaryBase,
    frSalaryFuel,
    frSalaryFood,
    frSalaryTravel
};
new FactionRanks[MAX_FACTIONS][MAX_FACTION_RANKS][eFactionRank];
new FactionRankCount[MAX_FACTIONS];

// Player faction data (per-player, runtime)
new pFactionID[MAX_PLAYERS];            // faction DB id (0 = none)
new pFactionIdx[MAX_PLAYERS];           // index into FactionData array (-1 = none)
new pFactionRank[MAX_PLAYERS];          // rank level (1-9)
new pFactionWarnings[MAX_PLAYERS];      // current warnings
new pFactionDutyCount[MAX_PLAYERS];     // times on-duty this week
new bool:pOnDuty[MAX_PLAYERS];          // currently on duty
new pDutyStartTick[MAX_PLAYERS];        // GetTickCount when duty started
new pDutyAccumulated[MAX_PLAYERS];      // accumulated duty seconds this session
new pPaydayPending[MAX_PLAYERS];        // unclaimed payday stacks
new pPaydayAmount[MAX_PLAYERS];         // total unclaimed money
new pCutiDays[MAX_PLAYERS];             // remaining cuti days
new pCutiApproved[MAX_PLAYERS];         // cuti approved flag
new pDayOff[MAX_PLAYERS];              // scheduled day off (0=none, 1-7)
new pDutyTimer[MAX_PLAYERS];           // timer for duty time check

// Temp vars for admin create faction
new pTempFactionType[MAX_PLAYERS];

// ============================================================================
// LOAD FACTIONS FROM DB
// ============================================================================

stock LoadFactions()
{
    format(query, sizeof(query), "SELECT * FROM `factions` ORDER BY id");
    mysql_function_query(MySQL_C1, query, true, "OnFactionsLoaded", "");
}

publics: OnFactionsLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalFactions = 0;

    for(new i = 0; i < rows && i < MAX_FACTIONS; i++)
    {
        FactionData[i][fID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", FactionData[i][fName], MySQL_C1, 48);
        FactionData[i][fType] = cache_get_field_content_int(i, "type", MySQL_C1);
        FactionData[i][fBudget] = cache_get_field_content_int(i, "budget", MySQL_C1);
        FactionData[i][fBalance] = cache_get_field_content_int(i, "balance", MySQL_C1);
        FactionData[i][fHQX] = cache_get_field_content_float(i, "hq_x", MySQL_C1);
        FactionData[i][fHQY] = cache_get_field_content_float(i, "hq_y", MySQL_C1);
        FactionData[i][fHQZ] = cache_get_field_content_float(i, "hq_z", MySQL_C1);
        FactionData[i][fHQAngle] = cache_get_field_content_float(i, "hq_angle", MySQL_C1);
        FactionData[i][fHQInterior] = cache_get_field_content_int(i, "hq_interior", MySQL_C1);
        FactionData[i][fHQVW] = cache_get_field_content_int(i, "hq_vw", MySQL_C1);
        FactionData[i][fPaydayInterval] = cache_get_field_content_int(i, "payday_interval", MySQL_C1);
        if(FactionData[i][fPaydayInterval] <= 0) FactionData[i][fPaydayInterval] = 8;
        TotalFactions++;
    }

    // Load ranks for each faction
    for(new i = 0; i < TotalFactions; i++)
        LoadFactionRanks(i);

    printf("[Faction] Loaded: %d factions.", TotalFactions);
    return 1;
}

stock LoadFactionRanks(factionIdx)
{
    FactionRankCount[factionIdx] = 0;
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT * FROM `faction_ranks` WHERE `faction_id` = '%d' ORDER BY rank_level",
        FactionData[factionIdx][fID]);
    mysql_function_query(MySQL_C1, query, true, "OnFactionRanksLoaded", "d", factionIdx);
}

publics: OnFactionRanksLoaded(factionIdx)
{
    new rows, fields;
    cache_get_data(rows, fields);
    FactionRankCount[factionIdx] = 0;

    for(new i = 0; i < rows && i < MAX_FACTION_RANKS; i++)
    {
        FactionRanks[factionIdx][i][frFactionIdx] = factionIdx;
        FactionRanks[factionIdx][i][frLevel] = cache_get_field_content_int(i, "rank_level", MySQL_C1);
        cache_get_field_content(i, "rank_name", FactionRanks[factionIdx][i][frName], MySQL_C1, 32);
        FactionRanks[factionIdx][i][frSalaryBase] = cache_get_field_content_int(i, "salary_base", MySQL_C1);
        FactionRanks[factionIdx][i][frSalaryFuel] = cache_get_field_content_int(i, "salary_fuel", MySQL_C1);
        FactionRanks[factionIdx][i][frSalaryFood] = cache_get_field_content_int(i, "salary_food", MySQL_C1);
        FactionRanks[factionIdx][i][frSalaryTravel] = cache_get_field_content_int(i, "salary_travel", MySQL_C1);
        FactionRankCount[factionIdx]++;
    }
    return 1;
}

// ============================================================================
// LOAD PLAYER FACTION DATA (called after login)
// ============================================================================

stock LoadPlayerFaction(playerid)
{
    pFactionID[playerid] = 0;
    pFactionIdx[playerid] = -1;
    pFactionRank[playerid] = 0;
    pFactionWarnings[playerid] = 0;
    pFactionDutyCount[playerid] = 0;
    pOnDuty[playerid] = false;
    pDutyStartTick[playerid] = 0;
    pDutyAccumulated[playerid] = 0;
    pPaydayPending[playerid] = 0;
    pPaydayAmount[playerid] = 0;
    pCutiDays[playerid] = 0;
    pCutiApproved[playerid] = 0;
    pDayOff[playerid] = 0;
    pDutyTimer[playerid] = 0;

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT * FROM `faction_members` WHERE `player_id` = '%d' LIMIT 1",
        PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnPlayerFactionLoaded", "d", playerid);
}

publics: OnPlayerFactionLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(!rows) return 1; // not in a faction

    pFactionID[playerid] = cache_get_field_content_int(0, "faction_id", MySQL_C1);
    pFactionRank[playerid] = cache_get_field_content_int(0, "rank_level", MySQL_C1);
    pFactionWarnings[playerid] = cache_get_field_content_int(0, "warnings", MySQL_C1);
    pFactionDutyCount[playerid] = cache_get_field_content_int(0, "duty_count_week", MySQL_C1);
    pPaydayPending[playerid] = cache_get_field_content_int(0, "payday_pending", MySQL_C1);
    pPaydayAmount[playerid] = cache_get_field_content_int(0, "payday_amount", MySQL_C1);
    pCutiDays[playerid] = cache_get_field_content_int(0, "cuti_days", MySQL_C1);
    pCutiApproved[playerid] = cache_get_field_content_int(0, "cuti_approved", MySQL_C1);
    pDayOff[playerid] = cache_get_field_content_int(0, "day_off", MySQL_C1);

    // Find faction index
    pFactionIdx[playerid] = GetFactionIndex(pFactionID[playerid]);

    if(pFactionIdx[playerid] != -1)
    {
        new rname[32];
        GetPlayerRankName(playerid, rname, sizeof(rname));
        SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
            "[Fraksi] %s | Jabatan: %s (Rank %d)",
            FactionData[pFactionIdx[playerid]][fName], rname, pFactionRank[playerid]);

        if(pPaydayPending[playerid] > 0)
        {
            SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
                "[Fraksi] Kamu punya %d payday belum diklaim (Total: $%d). Gunakan /claimpayday.",
                pPaydayPending[playerid], pPaydayAmount[playerid]);
        }
    }
    return 1;
}

stock ResetPlayerFaction(playerid)
{
    if(pOnDuty[playerid]) EndDuty(playerid, false);
    pFactionID[playerid] = 0;
    pFactionIdx[playerid] = -1;
    pFactionRank[playerid] = 0;
    pFactionWarnings[playerid] = 0;
    pFactionDutyCount[playerid] = 0;
    pOnDuty[playerid] = false;
    pDutyStartTick[playerid] = 0;
    pDutyAccumulated[playerid] = 0;
    pPaydayPending[playerid] = 0;
    pPaydayAmount[playerid] = 0;
    pCutiDays[playerid] = 0;
    pCutiApproved[playerid] = 0;
    pDayOff[playerid] = 0;
    if(pDutyTimer[playerid] != 0)
    {
        KillTimer(pDutyTimer[playerid]);
        pDutyTimer[playerid] = 0;
    }
}

// ============================================================================
// UTILITY
// ============================================================================

stock GetFactionIndex(factionDbId)
{
    for(new i = 0; i < TotalFactions; i++)
        if(FactionData[i][fID] == factionDbId) return i;
    return -1;
}

stock GetPlayerRankName(playerid, output[], maxlen)
{
    new fi = pFactionIdx[playerid];
    new rl = pFactionRank[playerid];
    output[0] = EOS;
    if(fi < 0 || fi >= TotalFactions) return;
    for(new i = 0; i < FactionRankCount[fi]; i++)
    {
        if(FactionRanks[fi][i][frLevel] == rl)
        {
            strmid(output, FactionRanks[fi][i][frName], 0, strlen(FactionRanks[fi][i][frName]), maxlen);
            return;
        }
    }
    format(output, maxlen, "Rank %d", rl);
}

stock GetRankSalaryTotal(factionIdx, rankLevel)
{
    for(new i = 0; i < FactionRankCount[factionIdx]; i++)
    {
        if(FactionRanks[factionIdx][i][frLevel] == rankLevel)
        {
            return FactionRanks[factionIdx][i][frSalaryBase] +
                   FactionRanks[factionIdx][i][frSalaryFuel] +
                   FactionRanks[factionIdx][i][frSalaryFood] +
                   FactionRanks[factionIdx][i][frSalaryTravel];
        }
    }
    return 0;
}

stock GetRankData(factionIdx, rankLevel, &base, &fuel, &food, &travel)
{
    base = 0; fuel = 0; food = 0; travel = 0;
    for(new i = 0; i < FactionRankCount[factionIdx]; i++)
    {
        if(FactionRanks[factionIdx][i][frLevel] == rankLevel)
        {
            base = FactionRanks[factionIdx][i][frSalaryBase];
            fuel = FactionRanks[factionIdx][i][frSalaryFuel];
            food = FactionRanks[factionIdx][i][frSalaryFood];
            travel = FactionRanks[factionIdx][i][frSalaryTravel];
            return 1;
        }
    }
    return 0;
}

stock IsLeader(playerid)
{
    new fi = pFactionIdx[playerid];
    if(fi < 0) return 0;
    new maxRank = (FactionData[fi][fType] == FACTION_TYPE_LEGAL) ? 9 : 5;
    return (pFactionRank[playerid] >= maxRank - 1) ? 1 : 0; // top 2 ranks = leader
}

stock IsChief(playerid)
{
    new fi = pFactionIdx[playerid];
    if(fi < 0) return 0;
    new maxRank = (FactionData[fi][fType] == FACTION_TYPE_LEGAL) ? 9 : 5;
    return (pFactionRank[playerid] == maxRank) ? 1 : 0;
}

stock FactionLog(factionId, playerName[], action[])
{
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `faction_logs` (`faction_id`, `player_name`, `action`) VALUES ('%d', '%e', '%e')",
        factionId, playerName, action);
    mysql_function_query(MySQL_C1, query, false, "", "");
}

stock SendFactionMessage(factionDbId, color, msg[])
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(pFactionID[i] != factionDbId) continue;
        SendClientMessage(i, color, msg);
    }
}

stock SavePlayerFactionData(playerid)
{
    if(pFactionID[playerid] <= 0) return;
    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `faction_members` SET `rank_level` = '%d', `warnings` = '%d', \
`duty_count_week` = '%d', `payday_pending` = '%d', `payday_amount` = '%d', \
`cuti_days` = '%d', `cuti_approved` = '%d', `day_off` = '%d' \
WHERE `player_id` = '%d'",
        pFactionRank[playerid], pFactionWarnings[playerid],
        pFactionDutyCount[playerid], pPaydayPending[playerid], pPaydayAmount[playerid],
        pCutiDays[playerid], pCutiApproved[playerid], pDayOff[playerid],
        PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, false, "", "");
}

// ============================================================================
// DUTY SYSTEM
// ============================================================================

stock StartDuty(playerid)
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), 0;
    if(pOnDuty[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sudah on-duty!"), 0;

    pOnDuty[playerid] = true;
    pDutyStartTick[playerid] = GetTickCount();
    pFactionDutyCount[playerid]++;

    // Start duty timer (check every 60s for payday)
    pDutyTimer[playerid] = SetTimerEx("OnDutyCheck", PAYDAY_CHECK_INTERVAL, true, "d", playerid);

    new fi = pFactionIdx[playerid];
    new rname[32];
    GetPlayerRankName(playerid, rname, sizeof(rname));

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Kamu sekarang ON-DUTY sebagai %s.", rname);

    // Notify faction members
    new msg[128];
    format(msg, sizeof(msg), "[Fraksi] %s (%s) sekarang on-duty.", PlayerInfo[playerid][pICName], rname);
    SendFactionMessage(pFactionID[playerid], COLOR_FACTION_CHAT, msg);

    // Log
    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], "On-duty");

    // RP
    new rptext[80];
    format(rptext, sizeof(rptext), "* %s memulai tugasnya.", PlayerInfo[playerid][pICName]);
    ProxDetector(15.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    return 1;
    #pragma unused fi
}

stock EndDuty(playerid, bool:showMessage = true)
{
    if(!pOnDuty[playerid]) return 0;

    // Calculate duty time
    new dutyMs = GetTickCount() - pDutyStartTick[playerid];
    new dutySecs = dutyMs / 1000;
    pDutyAccumulated[playerid] += dutySecs;

    // Kill timer
    if(pDutyTimer[playerid] != 0)
    {
        KillTimer(pDutyTimer[playerid]);
        pDutyTimer[playerid] = 0;
    }

    pOnDuty[playerid] = false;
    pDutyStartTick[playerid] = 0;

    // Check if accumulated enough for a payday
    new fi = pFactionIdx[playerid];
    if(fi >= 0)
    {
        new payInterval = FactionData[fi][fPaydayInterval] * 3600; // hours to seconds
        while(pDutyAccumulated[playerid] >= payInterval)
        {
            pDutyAccumulated[playerid] -= payInterval;
            // Award payday
            new totalSalary = GetRankSalaryTotal(fi, pFactionRank[playerid]);
            if(totalSalary > 0 && FactionData[fi][fType] == FACTION_TYPE_LEGAL)
            {
                pPaydayPending[playerid]++;
                pPaydayAmount[playerid] += totalSalary;
            }
        }
    }

    if(showMessage)
    {
        new hours = dutySecs / 3600;
        new mins = (dutySecs % 3600) / 60;

        SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
            "[Fraksi] Off-duty. Lama bertugas: %d jam %d menit.", hours, mins);

        if(pPaydayPending[playerid] > 0)
        {
            SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
                "[Fraksi] Payday tersedia: %d kali (Total: $%d). Gunakan /claimpayday.",
                pPaydayPending[playerid], pPaydayAmount[playerid]);
        }

        // Notify faction
        new msg[128];
        format(msg, sizeof(msg), "[Fraksi] %s sekarang off-duty.", PlayerInfo[playerid][pICName]);
        SendFactionMessage(pFactionID[playerid], COLOR_FACTION_CHAT, msg);

        // Log
        new logmsg[64];
        format(logmsg, sizeof(logmsg), "Off-duty (%d jam %d menit)", hours, mins);
        FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], logmsg);

        // RP
        new rptext[80];
        format(rptext, sizeof(rptext), "* %s selesai bertugas.", PlayerInfo[playerid][pICName]);
        ProxDetector(15.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    }

    SavePlayerFactionData(playerid);
    return 1;
}

publics: OnDutyCheck(playerid)
{
    if(!pOnDuty[playerid])
    {
        if(pDutyTimer[playerid] != 0)
        {
            KillTimer(pDutyTimer[playerid]);
            pDutyTimer[playerid] = 0;
        }
        return 1;
    }

    // Check accumulated time for payday calculation (live)
    new dutyMs = GetTickCount() - pDutyStartTick[playerid];
    new totalSecs = pDutyAccumulated[playerid] + (dutyMs / 1000);

    new fi = pFactionIdx[playerid];
    if(fi < 0) return 1;

    new payInterval = FactionData[fi][fPaydayInterval] * 3600;
    if(totalSecs >= payInterval)
    {
        // Notify that payday will be available when off-duty
        SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
            "[Fraksi] Kamu sudah memenuhi %d jam bertugas. Payday akan tersedia saat off-duty.",
            FactionData[fi][fPaydayInterval]);
    }
    return 1;
}

// ============================================================================
// COMMANDS — Player (Anggota)
// ============================================================================

COMMAND:duty(playerid, params[])
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), true;

    if(pOnDuty[playerid])
        EndDuty(playerid);
    else
        StartDuty(playerid);
    return true;
}

COMMAND:offduty(playerid, params[])
{
    if(!pOnDuty[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak sedang on-duty!"), true;
    EndDuty(playerid);
    return true;
}

COMMAND:f(playerid, params[])
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), true;
    if(!strlen(params))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /f [pesan]"), true;

    new rname[32];
    GetPlayerRankName(playerid, rname, sizeof(rname));

    new msg[144];
    format(msg, sizeof(msg), "[Fraksi] %s (%s): %s", PlayerInfo[playerid][pICName], rname, params);
    SendFactionMessage(pFactionID[playerid], COLOR_FACTION_CHAT, msg);
    return true;
}

COMMAND:fchat(playerid, params[]) return cmd_f(playerid, params);

COMMAND:radio(playerid, params[])
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), true;

    new fi = pFactionIdx[playerid];
    if(FactionData[fi][fType] != FACTION_TYPE_LEGAL)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Hanya fraksi legal yang punya radio!"), true;

    if(!strlen(params))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /radio [pesan]"), true;

    new rname[32];
    GetPlayerRankName(playerid, rname, sizeof(rname));

    new msg[144];
    format(msg, sizeof(msg), "** [Radio] %s (%s): %s **", PlayerInfo[playerid][pICName], rname, params);
    SendFactionMessage(pFactionID[playerid], COLOR_FACTION_RADIO, msg);

    // RP
    new rptext[80];
    format(rptext, sizeof(rptext), "* %s berbicara ke radio.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    return true;
}

COMMAND:frekap(playerid, params[])
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), true;

    new fi = pFactionIdx[playerid];
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "======= Rekap Presensi Minggu Ini =======");
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Fraksi: %s", FactionData[fi][fName]);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "On-duty minggu ini: %d/%d kali", pFactionDutyCount[playerid], MIN_DUTY_PER_WEEK);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Warnings: %d/%d", pFactionWarnings[playerid], MAX_WARNINGS);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Payday pending: %d (Total: $%d)", pPaydayPending[playerid], pPaydayAmount[playerid]);

    if(pOnDuty[playerid])
    {
        new dutyMs = GetTickCount() - pDutyStartTick[playerid];
        new dutySecs = dutyMs / 1000;
        SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Sedang bertugas: %d menit", dutySecs / 60);
    }
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "=========================================");
    return true;
}

COMMAND:fmembers(playerid, params[])
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), true;

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "======= Anggota Fraksi Online =======");
    new count = 0;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(pFactionID[i] != pFactionID[playerid]) continue;

        new rname[32];
        GetPlayerRankName(i, rname, sizeof(rname));
        new status[16] = "Off-duty";
        if(pOnDuty[i]) status = "ON-DUTY";

        SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
            "  %s - %s (Rank %d) [%s]",
            PlayerInfo[i][pICName], rname, pFactionRank[i], status);
        count++;
    }
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Total online: %d", count);
    return true;
}

COMMAND:claimpayday(playerid, params[])
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), true;

    if(pPaydayPending[playerid] <= 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada payday yang bisa diklaim!"), true;

    if(pOnDuty[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu harus off-duty dulu untuk klaim payday!"), true;

    new fi = pFactionIdx[playerid];
    new amount = pPaydayAmount[playerid];
    new stacks = pPaydayPending[playerid];

    // Show breakdown
    new base, fuel, food, travel;
    GetRankData(fi, pFactionRank[playerid], base, fuel, food, travel);

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "======= PAYDAY CLAIMED (%d shift) =======", stacks);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Gaji Pokok  : $%d x %d = $%d", base, stacks, base * stacks);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Uang Bensin : $%d x %d = $%d", fuel, stacks, fuel * stacks);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Uang Makan  : $%d x %d = $%d", food, stacks, food * stacks);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Uang Jalan  : $%d x %d = $%d", travel, stacks, travel * stacks);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "TOTAL       : $%d", amount);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "=========================================");

    // Give money to bank
    PlayerInfo[playerid][pBank] += amount;
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] $%d telah ditransfer ke rekening bank kamu.", amount);

    pPaydayPending[playerid] = 0;
    pPaydayAmount[playerid] = 0;
    SavePlayerFactionData(playerid);

    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], "Claimed payday");
    return true;
}

COMMAND:cuti(playerid, params[])
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), true;

    new days;
    if(sscanf(params, "d", days))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /cuti [hari] — Contoh: /cuti 7"), true;

    if(days < 1 || days > 30)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Cuti harus antara 1-30 hari!"), true;

    pCutiDays[playerid] = days;
    pCutiApproved[playerid] = 0; // pending
    SavePlayerFactionData(playerid);

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Pengajuan cuti %d hari telah dikirim. Menunggu persetujuan Chief.", days);

    // Notify leaders
    new msg[128];
    format(msg, sizeof(msg), "[Fraksi] %s mengajukan cuti %d hari. Gunakan /fapprovecuti atau /frejectcuti.",
        PlayerInfo[playerid][pICName], days);
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(pFactionID[i] != pFactionID[playerid]) continue;
        if(!IsChief(i)) continue;
        SendClientMessage(i, COLOR_FACTION_INFO, msg);
    }

    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], "Mengajukan cuti");
    return true;
}

// ============================================================================
// COMMANDS — Leader/Chief
// ============================================================================

COMMAND:finvite(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsLeader(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan pemimpin fraksi!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /finvite [playerid]"), true;
    if(!IsPlayerConnected(targetid) || !PlayerInfo[targetid][pLogged])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;
    if(pFactionID[targetid] > 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player sudah di fraksi lain!"), true;

    new fi = pFactionIdx[playerid];

    // Insert into DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `faction_members` (`faction_id`, `player_id`, `player_name`, `rank_level`) \
VALUES ('%d', '%d', '%e', '1')",
        pFactionID[playerid], PlayerInfo[targetid][pID], PlayerInfo[targetid][pICName]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    // Set runtime data
    pFactionID[targetid] = pFactionID[playerid];
    pFactionIdx[targetid] = fi;
    pFactionRank[targetid] = 1;
    pFactionWarnings[targetid] = 0;
    pFactionDutyCount[targetid] = 0;

    SendClientFormattedMessage(targetid, COLOR_FACTION_INFO,
        "[Fraksi] Kamu telah bergabung dengan %s!", FactionData[fi][fName]);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] %s telah diundang ke fraksi.", PlayerInfo[targetid][pICName]);

    new msg[128];
    format(msg, sizeof(msg), "[Fraksi] %s bergabung ke fraksi.", PlayerInfo[targetid][pICName]);
    SendFactionMessage(pFactionID[playerid], COLOR_FACTION_CHAT, msg);
    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], "Invite member");
    return true;
}

COMMAND:funinvite(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsLeader(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan pemimpin fraksi!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /funinvite [playerid]"), true;
    if(!IsPlayerConnected(targetid) || !PlayerInfo[targetid][pLogged])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;
    if(pFactionID[targetid] != pFactionID[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak di fraksi yang sama!"), true;

    // Remove from DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "DELETE FROM `faction_members` WHERE `player_id` = '%d'",
        PlayerInfo[targetid][pID]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(targetid, COLOR_RED,
        "[Fraksi] Kamu telah dikeluarkan dari %s.", FactionData[pFactionIdx[playerid]][fName]);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] %s telah dikeluarkan.", PlayerInfo[targetid][pICName]);

    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], "Uninvite member");
    ResetPlayerFaction(targetid);
    return true;
}

COMMAND:fsetrank(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsLeader(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan pemimpin fraksi!"), true;

    new targetid, rank;
    if(sscanf(params, "ud", targetid, rank))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fsetrank [playerid] [rank]"), true;
    if(!IsPlayerConnected(targetid) || !PlayerInfo[targetid][pLogged])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;
    if(pFactionID[targetid] != pFactionID[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak di fraksi yang sama!"), true;

    new fi = pFactionIdx[playerid];
    new maxRank = (FactionData[fi][fType] == FACTION_TYPE_LEGAL) ? 9 : 5;
    if(rank < 1 || rank > maxRank)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Rank harus antara 1-%d!", maxRank), true;

    pFactionRank[targetid] = rank;
    SavePlayerFactionData(targetid);

    new rname[32];
    GetPlayerRankName(targetid, rname, sizeof(rname));

    SendClientFormattedMessage(targetid, COLOR_FACTION_INFO,
        "[Fraksi] Jabatan kamu diubah menjadi: %s (Rank %d)", rname, rank);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] %s diubah ke rank %d (%s).", PlayerInfo[targetid][pICName], rank, rname);

    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], "Set rank member");
    return true;
}

COMMAND:fsetgaji(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsChief(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Hanya Chief yang bisa mengatur gaji!"), true;

    new rank, base, fuel, food, travel;
    if(sscanf(params, "ddddd", rank, base, fuel, food, travel))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fsetgaji [rank] [gaji_pokok] [bensin] [makan] [jalan]"), true;

    new fi = pFactionIdx[playerid];
    new maxRank = (FactionData[fi][fType] == FACTION_TYPE_LEGAL) ? 9 : 5;
    if(rank < 1 || rank > maxRank)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Rank harus antara 1-%d!", maxRank), true;

    // Update DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `faction_ranks` (`faction_id`, `rank_level`, `rank_name`, `salary_base`, `salary_fuel`, `salary_food`, `salary_travel`) \
VALUES ('%d', '%d', 'Rank %d', '%d', '%d', '%d', '%d') \
ON DUPLICATE KEY UPDATE `salary_base` = '%d', `salary_fuel` = '%d', `salary_food` = '%d', `salary_travel` = '%d'",
        pFactionID[playerid], rank, rank, base, fuel, food, travel,
        base, fuel, food, travel);
    mysql_function_query(MySQL_C1, query, false, "", "");

    // Update in-memory
    for(new i = 0; i < FactionRankCount[fi]; i++)
    {
        if(FactionRanks[fi][i][frLevel] == rank)
        {
            FactionRanks[fi][i][frSalaryBase] = base;
            FactionRanks[fi][i][frSalaryFuel] = fuel;
            FactionRanks[fi][i][frSalaryFood] = food;
            FactionRanks[fi][i][frSalaryTravel] = travel;
            break;
        }
    }

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Gaji rank %d diatur: Pokok=$%d + Bensin=$%d + Makan=$%d + Jalan=$%d = Total $%d",
        rank, base, fuel, food, travel, base+fuel+food+travel);

    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], "Set salary rank");
    return true;
}

COMMAND:fsetlibur(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsChief(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Hanya Chief yang bisa mengatur jadwal libur!"), true;

    new targetid, day;
    if(sscanf(params, "ud", targetid, day))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fsetlibur [playerid] [hari 1-7] (1=Senin, 7=Minggu, 0=hapus)"), true;
    if(!IsPlayerConnected(targetid) || !PlayerInfo[targetid][pLogged])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;
    if(pFactionID[targetid] != pFactionID[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak di fraksi yang sama!"), true;
    if(day < 0 || day > 7)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Hari harus 0-7! (0=hapus, 1=Senin, 7=Minggu)"), true;

    pDayOff[targetid] = day;
    SavePlayerFactionData(targetid);

    new dayNames[][] = {"Tidak ada", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"};
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Jadwal libur %s diatur ke: %s", PlayerInfo[targetid][pICName], dayNames[day]);
    SendClientFormattedMessage(targetid, COLOR_FACTION_INFO,
        "[Fraksi] Jadwal libur kamu diatur ke: %s", dayNames[day]);
    return true;
}

COMMAND:fapprovecuti(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsChief(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Hanya Chief yang bisa approve cuti!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fapprovecuti [playerid]"), true;
    if(!IsPlayerConnected(targetid) || !PlayerInfo[targetid][pLogged])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;
    if(pFactionID[targetid] != pFactionID[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak di fraksi yang sama!"), true;
    if(pCutiDays[targetid] <= 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak mengajukan cuti!"), true;

    pCutiApproved[targetid] = 1;
    SavePlayerFactionData(targetid);

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Cuti %s selama %d hari disetujui.", PlayerInfo[targetid][pICName], pCutiDays[targetid]);
    SendClientFormattedMessage(targetid, COLOR_FACTION_INFO,
        "[Fraksi] Pengajuan cuti kamu selama %d hari telah DISETUJUI.", pCutiDays[targetid]);

    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], "Approved cuti");
    return true;
}

COMMAND:frejectcuti(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsChief(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Hanya Chief yang bisa reject cuti!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /frejectcuti [playerid]"), true;
    if(!IsPlayerConnected(targetid) || !PlayerInfo[targetid][pLogged])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;
    if(pFactionID[targetid] != pFactionID[playerid])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak di fraksi yang sama!"), true;

    pCutiDays[targetid] = 0;
    pCutiApproved[targetid] = 0;
    SavePlayerFactionData(targetid);

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Cuti %s ditolak.", PlayerInfo[targetid][pICName]);
    SendClientFormattedMessage(targetid, COLOR_RED,
        "[Fraksi] Pengajuan cuti kamu DITOLAK.");
    return true;
}

COMMAND:fpresensi(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsLeader(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan pemimpin fraksi!"), true;

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "======= Rekap Presensi Fraksi =======");
    // Query all members of this faction
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT player_name, rank_level, duty_count_week, warnings, cuti_approved, day_off \
FROM `faction_members` WHERE `faction_id` = '%d' ORDER BY rank_level DESC",
        pFactionID[playerid]);
    mysql_function_query(MySQL_C1, query, true, "OnFactionPresensiLoaded", "d", playerid);
    return true;
}

publics: OnFactionPresensiLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    for(new i = 0; i < rows; i++)
    {
        new name[32], rl, dc, warns, cuti, dayoff;
        cache_get_field_content(i, "player_name", name, MySQL_C1, 32);
        rl = cache_get_field_content_int(i, "rank_level", MySQL_C1);
        dc = cache_get_field_content_int(i, "duty_count_week", MySQL_C1);
        warns = cache_get_field_content_int(i, "warnings", MySQL_C1);
        cuti = cache_get_field_content_int(i, "cuti_approved", MySQL_C1);
        dayoff = cache_get_field_content_int(i, "day_off", MySQL_C1);

        new status[16] = "OK";
        if(dc < MIN_DUTY_PER_WEEK) status = "{FF0000}KURANG";
        if(cuti) status = "{FFFF00}CUTI";

        SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
            "  R%d %s — Duty: %d/%d [%s] Warn: %d Off: %d",
            rl, name, dc, MIN_DUTY_PER_WEEK, status, warns, dayoff);
    }
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Total anggota: %d", rows);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "=====================================");
    return 1;
}

COMMAND:fwithdraw(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsLeader(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan pemimpin fraksi!"), true;

    new amount;
    if(sscanf(params, "d", amount))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fwithdraw [jumlah]"), true;

    new fi = pFactionIdx[playerid];
    if(amount <= 0 || amount > FactionData[fi][fBalance])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Jumlah tidak valid! Saldo kas: $%d", FactionData[fi][fBalance]), true;

    FactionData[fi][fBalance] -= amount;
    PlayerInfo[playerid][pMoney] += amount;

    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `factions` SET `balance` = '%d' WHERE `id` = '%d'",
        FactionData[fi][fBalance], FactionData[fi][fID]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Penarikan $%d dari kas fraksi. Sisa: $%d", amount, FactionData[fi][fBalance]);

    new logmsg[64];
    format(logmsg, sizeof(logmsg), "Withdraw $%d from faction balance", amount);
    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], logmsg);
    return true;
}

COMMAND:fdeposit(playerid, params[])
{
    if(pFactionIdx[playerid] < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan anggota fraksi!"), true;

    new amount;
    if(sscanf(params, "d", amount))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fdeposit [jumlah]"), true;

    if(amount <= 0 || amount > PlayerInfo[playerid][pMoney])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Uang tidak cukup!"), true;

    new fi = pFactionIdx[playerid];
    FactionData[fi][fBalance] += amount;
    PlayerInfo[playerid][pMoney] -= amount;

    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `factions` SET `balance` = '%d' WHERE `id` = '%d'",
        FactionData[fi][fBalance], FactionData[fi][fID]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Setor $%d ke kas fraksi. Saldo kas: $%d", amount, FactionData[fi][fBalance]);

    new logmsg[64];
    format(logmsg, sizeof(logmsg), "Deposit $%d to faction balance", amount);
    FactionLog(pFactionID[playerid], PlayerInfo[playerid][pICName], logmsg);
    return true;
}

COMMAND:fbalance(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsLeader(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan pemimpin fraksi!"), true;

    new fi = pFactionIdx[playerid];
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Fraksi] Saldo kas %s: $%d | Budget pemerintah: $%d",
        FactionData[fi][fName], FactionData[fi][fBalance], FactionData[fi][fBudget]);
    return true;
}

COMMAND:flog(playerid, params[])
{
    if(pFactionIdx[playerid] < 0 || !IsLeader(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan pemimpin fraksi!"), true;

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT player_name, action, created_at FROM `faction_logs` WHERE `faction_id` = '%d' ORDER BY id DESC LIMIT 15",
        pFactionID[playerid]);
    mysql_function_query(MySQL_C1, query, true, "OnFactionLogLoaded", "d", playerid);
    return true;
}

publics: OnFactionLogLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "======= Log Fraksi (15 terakhir) =======");
    for(new i = 0; i < rows; i++)
    {
        new name[32], action[128], ts[20];
        cache_get_field_content(i, "player_name", name, MySQL_C1, 32);
        cache_get_field_content(i, "action", action, MySQL_C1, 128);
        cache_get_field_content(i, "created_at", ts, MySQL_C1, 20);

        SendClientFormattedMessage(playerid, -1, "  [%s] %s: %s", ts, name, action);
    }
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "=========================================");
    return 1;
}

// ============================================================================
// ADMIN COMMANDS
// ============================================================================

COMMAND:createfaction(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new type, name[48];
    if(sscanf(params, "ds[48]", type, name))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /createfaction [tipe 1=legal/2=illegal] [nama]"), true;

    if(type != 1 && type != 2)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tipe harus 1 (legal) atau 2 (illegal)!"), true;

    if(TotalFactions >= MAX_FACTIONS)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Fraksi penuh! Maksimum %d.", MAX_FACTIONS), true;

    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `factions` (`name`, `type`) VALUES ('%e', '%d')",
        name, type);
    mysql_function_query(MySQL_C1, query, true, "OnFactionCreated", "dds", playerid, type, name);
    return true;
}

publics: OnFactionCreated(playerid, type, name[])
{
    new insertId = cache_insert_id();
    if(insertId <= 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Gagal membuat fraksi!");
        return 1;
    }

    // Add to runtime
    new idx = TotalFactions;
    FactionData[idx][fID] = insertId;
    strmid(FactionData[idx][fName], name, 0, strlen(name), 48);
    FactionData[idx][fType] = type;
    FactionData[idx][fBudget] = 0;
    FactionData[idx][fBalance] = 0;
    FactionData[idx][fPaydayInterval] = 8;
    FactionRankCount[idx] = 0;
    TotalFactions++;

    // Create default ranks
    new maxRank = (type == FACTION_TYPE_LEGAL) ? 9 : 5;
    for(new r = 1; r <= maxRank; r++)
    {
        mysql_format(MySQL_C1, query, sizeof(query),
            "INSERT INTO `faction_ranks` (`faction_id`, `rank_level`, `rank_name`) VALUES ('%d', '%d', 'Rank %d')",
            insertId, r, r);
        mysql_function_query(MySQL_C1, query, false, "", "");
    }

    // Reload ranks for this faction
    LoadFactionRanks(idx);

    new typeStr[12];
    if(type == 1) typeStr = "Legal";
    else typeStr = "Illegal";

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Admin] Fraksi '%s' (ID: %d, Tipe: %s) berhasil dibuat! %d rank default ditambahkan.",
        name, insertId, typeStr, maxRank);
    return 1;
}

COMMAND:deletefaction(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new fid;
    if(sscanf(params, "d", fid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /deletefaction [faction_id]"), true;

    new fi = GetFactionIndex(fid);
    if(fi == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Fraksi tidak ditemukan!"), true;

    // Remove all online members
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(pFactionID[i] == fid)
            ResetPlayerFaction(i);
    }

    // Delete from DB (cascade will delete ranks, members, logs)
    mysql_format(MySQL_C1, query, sizeof(query),
        "DELETE FROM `factions` WHERE `id` = '%d'", fid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Admin] Fraksi '%s' (ID: %d) telah dihapus.", FactionData[fi][fName], fid);

    // Reload factions
    LoadFactions();
    return true;
}

COMMAND:fsetbudget(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new fid, amount;
    if(sscanf(params, "dd", fid, amount))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fsetbudget [faction_id] [jumlah]"), true;

    new fi = GetFactionIndex(fid);
    if(fi == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Fraksi tidak ditemukan!"), true;

    FactionData[fi][fBudget] = amount;
    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `factions` SET `budget` = '%d' WHERE `id` = '%d'", amount, fid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Admin] Budget fraksi '%s' diatur ke $%d.", FactionData[fi][fName], amount);
    return true;
}

COMMAND:factions(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "======= Daftar Fraksi =======");
    for(new i = 0; i < TotalFactions; i++)
    {
        new typeStr[12];
        if(FactionData[i][fType] == 1) typeStr = "Legal";
        else typeStr = "Illegal";

        SendClientFormattedMessage(playerid, -1, "  [%d] %s (%s) | Kas: $%d | Budget: $%d",
            FactionData[i][fID], FactionData[i][fName], typeStr,
            FactionData[i][fBalance], FactionData[i][fBudget]);
    }
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "Total: %d fraksi.", TotalFactions);
    return true;
}

COMMAND:finfo(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    new fid;
    if(sscanf(params, "d", fid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /finfo [faction_id]"), true;

    new fi = GetFactionIndex(fid);
    if(fi == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Fraksi tidak ditemukan!"), true;

    new typeStr[12];
    if(FactionData[fi][fType] == 1) typeStr = "Legal";
    else typeStr = "Illegal";

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "======= Info Fraksi =======");
    SendClientFormattedMessage(playerid, -1, "Nama: %s (ID: %d)", FactionData[fi][fName], FactionData[fi][fID]);
    SendClientFormattedMessage(playerid, -1, "Tipe: %s | Payday Interval: %d jam", typeStr, FactionData[fi][fPaydayInterval]);
    SendClientFormattedMessage(playerid, -1, "Kas: $%d | Budget: $%d", FactionData[fi][fBalance], FactionData[fi][fBudget]);

    // Show ranks
    for(new r = 0; r < FactionRankCount[fi]; r++)
    {
        new total = FactionRanks[fi][r][frSalaryBase] + FactionRanks[fi][r][frSalaryFuel]
                  + FactionRanks[fi][r][frSalaryFood] + FactionRanks[fi][r][frSalaryTravel];
        SendClientFormattedMessage(playerid, -1, "  Rank %d: %s — Gaji: $%d ($%d+$%d+$%d+$%d)",
            FactionRanks[fi][r][frLevel], FactionRanks[fi][r][frName], total,
            FactionRanks[fi][r][frSalaryBase], FactionRanks[fi][r][frSalaryFuel],
            FactionRanks[fi][r][frSalaryFood], FactionRanks[fi][r][frSalaryTravel]);
    }

    // Online count
    new online = 0;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(pFactionID[i] == fid) online++;
    }
    SendClientFormattedMessage(playerid, -1, "Online: %d anggota", online);
    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO, "===========================");
    return true;
}

COMMAND:fsethq(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new fid;
    if(sscanf(params, "d", fid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fsethq [faction_id]"), true;

    new fi = GetFactionIndex(fid);
    if(fi == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Fraksi tidak ditemukan!"), true;

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    new interior = GetPlayerInterior(playerid);
    new vw = GetPlayerVirtualWorld(playerid);

    FactionData[fi][fHQX] = x;
    FactionData[fi][fHQY] = y;
    FactionData[fi][fHQZ] = z;
    FactionData[fi][fHQAngle] = a;
    FactionData[fi][fHQInterior] = interior;
    FactionData[fi][fHQVW] = vw;

    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `factions` SET `hq_x` = '%f', `hq_y` = '%f', `hq_z` = '%f', \
`hq_angle` = '%f', `hq_interior` = '%d', `hq_vw` = '%d' WHERE `id` = '%d'",
        x, y, z, a, interior, vw, fid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Admin] HQ fraksi '%s' diatur di posisi saat ini.", FactionData[fi][fName]);
    return true;
}

COMMAND:fsetpaydayinterval(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new fid, hours;
    if(sscanf(params, "dd", fid, hours))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /fsetpaydayinterval [faction_id] [jam]"), true;

    new fi = GetFactionIndex(fid);
    if(fi == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Fraksi tidak ditemukan!"), true;

    if(hours < 1 || hours > 24)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Interval harus 1-24 jam!"), true;

    FactionData[fi][fPaydayInterval] = hours;
    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `factions` SET `payday_interval` = '%d' WHERE `id` = '%d'", hours, fid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_FACTION_INFO,
        "[Admin] Interval payday '%s' diatur ke %d jam.", FactionData[fi][fName], hours);
    return true;
}
