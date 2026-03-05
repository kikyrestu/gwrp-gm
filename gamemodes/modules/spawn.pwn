// ============================================================================
// MODULE: spawn.pwn
// Death/Pingsan system, revive, hospital respawn
// ============================================================================

stock HandlePlayerDeath(playerid, killerid, reason)
{
    #pragma unused killerid
    #pragma unused reason

    if(!PlayerInfo[playerid][pLogged]) return true;

    // Set player as pingsan
    PlayerInfo[playerid][pIsDead] = true;
    PlayerInfo[playerid][pDeathTick] = gettime();

    // Save death position as last position
    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);
    PlayerInfo[playerid][pLastX] = x;
    PlayerInfo[playerid][pLastY] = y;
    PlayerInfo[playerid][pLastZ] = z;
    PlayerInfo[playerid][pLastAngle] = angle;
    PlayerInfo[playerid][pLastInterior] = GetPlayerInterior(playerid);
    PlayerInfo[playerid][pLastVW] = GetPlayerVirtualWorld(playerid);

    SendClientFormattedMessage(playerid, COLOR_RED, "Kamu pingsan! Tunggu medis atau auto respawn dalam 30 menit.");

    // Start 30 min timer
    PlayerInfo[playerid][pDeathTimer] = SetTimerEx("OnDeathTimerExpire", DEATH_TIME * 1000, false, "d", playerid);

    // Save death state to DB
    mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `is_dead` = '1', `death_tick` = '%i' WHERE `name` = '%e'",
        PlayerInfo[playerid][pDeathTick], PlayerName(playerid));
    mysql_function_query(MySQL_C1, query, false, "", "");

    return true;
}

stock SetPlayerDeathState(playerid)
{
    TogglePlayerControllable(playerid, 0);
    ApplyAnimation(playerid, "CRACK", "crckdeth2", 4.1, 0, 1, 1, 1, 0, 1);

    SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan. Menunggu bantuan medis...");

    new remaining = DEATH_TIME - (gettime() - PlayerInfo[playerid][pDeathTick]);
    if(remaining > 0)
    {
        new mins = remaining / 60;
        new secs = remaining % 60;
        new msg[128];
        format(msg, sizeof(msg), "Sisa waktu sebelum auto respawn ke RS: %d menit %d detik", mins, secs);
        SendClientFormattedMessage(playerid, COLOR_YELLOW, msg);
    }
}

publics: OnDeathTimerExpire(playerid)
{
    if(!IsPlayerConnected(playerid)) return true;
    if(!PlayerInfo[playerid][pIsDead]) return true;

    RespawnAtHospital(playerid);
    return true;
}

publics: DelayedHospitalRespawn(playerid)
{
    if(!IsPlayerConnected(playerid)) return true;
    RespawnAtHospital(playerid);
    SendClientFormattedMessage(playerid, COLOR_HOSPITAL, "Kamu pingsan terlalu lama, kamu dirawat di rumah sakit.");
    return true;
}

stock RespawnAtHospital(playerid)
{
    // Find nearest hospital
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new Float:nearestDist = 999999.0;
    new nearestIdx = 0;

    for(new i = 0; i < sizeof(Hospitals); i++)
    {
        new Float:dist = floatsqroot(
            floatpower(px - Hospitals[i][0], 2.0) +
            floatpower(py - Hospitals[i][1], 2.0) +
            floatpower(pz - Hospitals[i][2], 2.0)
        );
        if(dist < nearestDist)
        {
            nearestDist = dist;
            nearestIdx = i;
        }
    }

    // Clear death state
    PlayerInfo[playerid][pIsDead] = false;
    PlayerInfo[playerid][pDeathTick] = 0;
    if(PlayerInfo[playerid][pDeathTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pDeathTimer]);
        PlayerInfo[playerid][pDeathTimer] = 0;
    }

    // Teleport to hospital
    SetPlayerPos(playerid, Hospitals[nearestIdx][0], Hospitals[nearestIdx][1], Hospitals[nearestIdx][2]);
    SetPlayerFacingAngle(playerid, Hospitals[nearestIdx][3]);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetCameraBehindPlayer(playerid);

    // HP rendah
    SetPlayerHealth(playerid, DEATH_RESPAWN_HP);

    // Restore hunger/thirst partially
    PlayerInfo[playerid][pHunger] = 50;
    PlayerInfo[playerid][pThirst] = 50;
    if(PlayerInfo[playerid][pHudCreated])
    {
        UpdateHungerBar(playerid);
        UpdateThirstBar(playerid);
    }

    // Unfreeze
    TogglePlayerControllable(playerid, 1);
    ClearAnimations(playerid);

    // Save hospital position
    PlayerInfo[playerid][pLastX] = Hospitals[nearestIdx][0];
    PlayerInfo[playerid][pLastY] = Hospitals[nearestIdx][1];
    PlayerInfo[playerid][pLastZ] = Hospitals[nearestIdx][2];
    PlayerInfo[playerid][pLastAngle] = Hospitals[nearestIdx][3];
    PlayerInfo[playerid][pLastInterior] = 0;
    PlayerInfo[playerid][pLastVW] = 0;

    // Update DB
    mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `is_dead` = '0', `death_tick` = '0' WHERE `name` = '%e'", PlayerName(playerid));
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_HOSPITAL, "Kamu telah dirawat di rumah sakit terdekat. HP kamu rendah.");
    return true;
}

stock HandleReviveKey(playerid)
{
    if(!PlayerInfo[playerid][pLogged]) return true;
    if(PlayerInfo[playerid][pIsDead]) return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan, tidak bisa menolong!"), true;

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(i == playerid) continue;
        if(!PlayerInfo[i][pIsDead]) continue;

        new Float:tx, Float:ty, Float:tz;
        GetPlayerPos(i, tx, ty, tz);

        new Float:dist = floatsqroot(
            floatpower(px - tx, 2.0) +
            floatpower(py - ty, 2.0) +
            floatpower(pz - tz, 2.0)
        );

        if(dist <= REVIVE_DISTANCE)
        {
            RevivePlayer(i, playerid);
            return true;
        }
    }
    // Tidak ada pemain pingsan — diam saja, jangan spam pesan
    // karena F/Enter dipakai buat banyak hal (masuk interior, pickup, dll)
    return true;
}

stock RevivePlayer(targetid, medid)
{
    PlayerInfo[targetid][pIsDead] = false;
    PlayerInfo[targetid][pDeathTick] = 0;
    if(PlayerInfo[targetid][pDeathTimer] != 0)
    {
        KillTimer(PlayerInfo[targetid][pDeathTimer]);
        PlayerInfo[targetid][pDeathTimer] = 0;
    }

    TogglePlayerControllable(targetid, 1);
    ClearAnimations(targetid);
    SetPlayerHealth(targetid, 50.0);

    // Restore hunger/thirst partially
    PlayerInfo[targetid][pHunger] = 30;
    PlayerInfo[targetid][pThirst] = 30;
    if(PlayerInfo[targetid][pHudCreated])
    {
        UpdateHungerBar(targetid);
        UpdateThirstBar(targetid);
    }

    mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `is_dead` = '0', `death_tick` = '0' WHERE `name` = '%e'", PlayerInfo[targetid][pName]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    new msg[128];
    format(msg, sizeof(msg), "Kamu telah dibangunkan oleh %s.", PlayerInfo[medid][pName]);
    SendClientFormattedMessage(targetid, COLOR_HOSPITAL, msg);
    format(msg, sizeof(msg), "Kamu telah membangunkan %s.", PlayerInfo[targetid][pName]);
    SendClientFormattedMessage(medid, COLOR_HOSPITAL, msg);
    return true;
}
