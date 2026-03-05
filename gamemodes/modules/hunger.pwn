// ============================================================================
// MODULE: hunger.pwn
// Hunger & Thirst logic: timers, decrease callbacks, pingsan trigger
// ============================================================================

stock StartHungerThirstTimers(playerid)
{
    // Kill existing timers if any (prevent duplicates)
    if(PlayerInfo[playerid][pThirstTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pThirstTimer]);
        PlayerInfo[playerid][pThirstTimer] = 0;
    }
    if(PlayerInfo[playerid][pHungerTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pHungerTimer]);
        PlayerInfo[playerid][pHungerTimer] = 0;
    }

    PlayerInfo[playerid][pThirstTimer] = SetTimerEx("OnThirstDecrease", THIRST_DECREASE_TIME, true, "d", playerid);
    PlayerInfo[playerid][pHungerTimer] = SetTimerEx("OnHungerDecrease", HUNGER_DECREASE_TIME, true, "d", playerid);
}

// --- Timer Callbacks ---

publics: OnThirstDecrease(playerid)
{
    if(!IsPlayerConnected(playerid)) return true;
    if(!PlayerInfo[playerid][pLogged]) return true;
    if(PlayerInfo[playerid][pIsDead]) return true;

    PlayerInfo[playerid][pThirst] -= THIRST_DECREASE_AMOUNT;
    if(PlayerInfo[playerid][pThirst] < 0) PlayerInfo[playerid][pThirst] = 0;

    if(PlayerInfo[playerid][pHudCreated]) UpdateThirstBar(playerid);

    if(PlayerInfo[playerid][pThirst] <= THIRST_CANT_RUN && PlayerInfo[playerid][pThirst] > 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sangat haus! Kamu tidak bisa lari. Segera minum!");
    }
    else if(PlayerInfo[playerid][pThirst] == 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sangat dehidrasi! Segera minum!");
    }
    return true;
}

publics: OnHungerDecrease(playerid)
{
    if(!IsPlayerConnected(playerid)) return true;
    if(!PlayerInfo[playerid][pLogged]) return true;
    if(PlayerInfo[playerid][pIsDead]) return true;

    PlayerInfo[playerid][pHunger] -= HUNGER_DECREASE_AMOUNT;
    if(PlayerInfo[playerid][pHunger] < 0) PlayerInfo[playerid][pHunger] = 0;

    if(PlayerInfo[playerid][pHudCreated]) UpdateHungerBar(playerid);

    // Trigger pingsan from starvation
    if(PlayerInfo[playerid][pHunger] <= HUNGER_PINGSAN)
    {
        if(!PlayerInfo[playerid][pIsDead])
        {
            PlayerInfo[playerid][pIsDead] = true;
            PlayerInfo[playerid][pDeathTick] = gettime();

            new Float:x, Float:y, Float:z, Float:angle;
            GetPlayerPos(playerid, x, y, z);
            GetPlayerFacingAngle(playerid, angle);
            PlayerInfo[playerid][pLastX] = x;
            PlayerInfo[playerid][pLastY] = y;
            PlayerInfo[playerid][pLastZ] = z;
            PlayerInfo[playerid][pLastAngle] = angle;
            PlayerInfo[playerid][pLastInterior] = GetPlayerInterior(playerid);
            PlayerInfo[playerid][pLastVW] = GetPlayerVirtualWorld(playerid);

            SetPlayerDeathState(playerid);
            PlayerInfo[playerid][pDeathTimer] = SetTimerEx("OnDeathTimerExpire", DEATH_TIME * 1000, false, "d", playerid);

            mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `is_dead` = '1', `death_tick` = '%i' WHERE `name` = '%e'",
                PlayerInfo[playerid][pDeathTick], PlayerName(playerid));
            mysql_function_query(MySQL_C1, query, false, "", "");

            SendClientFormattedMessage(playerid, COLOR_RED, "Kamu pingsan karena kelaparan! Tunggu medis atau auto respawn dalam 30 menit.");
        }
    }
    else if(PlayerInfo[playerid][pHunger] <= 30)
    {
        SendClientFormattedMessage(playerid, COLOR_YELLOW, "Kamu mulai lapar, segera makan!");
    }
    return true;
}
