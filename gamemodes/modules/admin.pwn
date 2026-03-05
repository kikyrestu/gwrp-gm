// ============================================================================
// MODULE: admin.pwn
// Admin system: Management(1), DevMap(2), Developer(3)
// ============================================================================

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

stock AdminLog(adminname[], action[], targetname[], detail[])
{
    new q[512];
    mysql_format(MySQL_C1, q, sizeof(q),
        "INSERT INTO `admin_logs` (`admin_name`,`action`,`target_name`,`detail`,`ts`) VALUES ('%e','%e','%e','%e','%d')",
        adminname, action, targetname, detail, gettime());
    mysql_tquery(MySQL_C1, q, "", "");
}

stock SendAdminMessage(color, msg[])
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerInfo[i][pAdmin] >= ADMIN_MANAGEMENT)
            SendClientMessage(i, color, msg);
    }
}

stock GetAdminRankName(level)
{
    new rname[16];
    switch(level)
    {
        case 1: rname = "Management";
        case 2: rname = "DevMap";
        case 3: rname = "Developer";
        default: rname = "Player";
    }
    return rname;
}

// ============================================================================
// BAN CHECK (called on login)
// ============================================================================

stock CheckPlayerBan(playerid)
{
    new ip[16];
    GetPlayerIp(playerid, ip, sizeof(ip));
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT * FROM `bans` WHERE (`name` = '%e' OR `ip` = '%e') AND (`expire_date` = 0 OR `expire_date` > %d) LIMIT 1",
        PlayerName(playerid), ip, gettime());
    mysql_function_query(MySQL_C1, query, true, "OnBanCheck", "d", playerid);
}

publics: OnBanCheck(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);
    if(rows > 0)
    {
        new reason[128], admin[24];
        cache_get_field_content(0, "reason", reason, MySQL_C1, sizeof(reason));
        cache_get_field_content(0, "admin_name", admin, MySQL_C1, sizeof(admin));

        new banmsg[256];
        format(banmsg, sizeof(banmsg),
            "{FF0000}Kamu telah di-Ban!{FFFFFF}\n\nAdmin: {FFAA00}%s\n{FFFFFF}Alasan: {FFAA00}%s\n\n{FFFFFF}Hubungi forum untuk banding.",
            admin, reason);
        ShowPlayerDialog(playerid, dNull, DIALOG_STYLE_MSGBOX, "{FF0000}BANNED", banmsg, "Tutup", "");
        PlayerKick(playerid);
        return 1;
    }
    return 0;
}

// ============================================================================
// MANAGEMENT COMMANDS
// ============================================================================

// /a [text] — admin chat
COMMAND:a(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;
    if(!strlen(params))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /a [pesan]"), true;

    new msg[144];
    format(msg, sizeof(msg), "[Admin Chat] %s (%s): %s",
        PlayerInfo[playerid][pICName], GetAdminRankName(PlayerInfo[playerid][pAdmin]), params);
    SendAdminMessage(COLOR_ADMIN, msg);
    return true;
}

// /report [playerid] [alasan]
COMMAND:report(playerid, params[])
{
    new targetid, reason[128];
    if(sscanf(params, "us[128]", targetid, reason))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /report [playerid/nama] [alasan]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    new q[512];
    mysql_format(MySQL_C1, q, sizeof(q),
        "INSERT INTO `reports` (`reporter_name`,`reporter_id`,`target_name`,`reason`,`ts`) VALUES ('%e','%d','%e','%e','%d')",
        PlayerName(playerid), playerid, PlayerName(targetid), reason, gettime());
    mysql_tquery(MySQL_C1, q, "", "");

    SendClientFormattedMessage(playerid, COLOR_REPORT, "Laporanmu tentang %s telah dikirim ke admin.", PlayerName(targetid));

    // Notify online admins
    new notify[144];
    format(notify, sizeof(notify), "[Report] %s melaporkan %s: %s",
        PlayerName(playerid), PlayerName(targetid), reason);
    SendAdminMessage(COLOR_REPORT, notify);
    return true;
}

// /reports — view active reports (admin only)
COMMAND:reports(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT * FROM `reports` WHERE `handled` = 0 ORDER BY `ts` DESC LIMIT 20");
    mysql_function_query(MySQL_C1, query, true, "OnReportsLoaded", "d", playerid);
    return true;
}

publics: OnReportsLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(rows == 0)
        return SendClientFormattedMessage(playerid, COLOR_REPORT, "Tidak ada laporan aktif.");

    new list[1024];
    list[0] = EOS;
    for(new i = 0; i < rows && i < 20; i++)
    {
        new reporter[24], target[24], reason[128], rid;
        rid = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "reporter_name", reporter, MySQL_C1, sizeof(reporter));
        cache_get_field_content(i, "target_name", target, MySQL_C1, sizeof(target));
        cache_get_field_content(i, "reason", reason, MySQL_C1, sizeof(reason));

        new line[160];
        format(line, sizeof(line), "#%d %s -> %s: %s\n", rid, reporter, target, reason);
        strcat(list, line, sizeof(list));
    }
    ShowPlayerDialog(playerid, DIALOG_REPORTS, DIALOG_STYLE_MSGBOX, "{FFAA00}Laporan Aktif", list, "Tutup", "");
    return 1;
}

// /check [playerid] — view player info
COMMAND:check(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /check [playerid/nama]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    new Float:hp;
    GetPlayerHealth(targetid, hp);
    new moneyFmt[32], bankFmt[32];
    FormatMoney(PlayerInfo[targetid][pMoney], moneyFmt, sizeof(moneyFmt));
    FormatMoney(PlayerInfo[targetid][pBank], bankFmt, sizeof(bankFmt));

    new genderStr[12];
    if(PlayerInfo[targetid][pGender] == 1) genderStr = "Laki-laki";
    else genderStr = "Perempuan";

    new mutedStr[8], jailedStr[8], frozenStr[8];
    if(PlayerInfo[targetid][pMuted]) mutedStr = "Ya"; else mutedStr = "Tidak";
    if(PlayerInfo[targetid][pJailed]) jailedStr = "Ya"; else jailedStr = "Tidak";
    if(PlayerInfo[targetid][pFrozen]) frozenStr = "Ya"; else frozenStr = "Tidak";

    new info[512], tmp[256];
    format(info, sizeof(info), "{FFFFFF}=== Info Player ===\n{AAAAAA}OOC: {FFFFFF}%s (ID: %d)\n{AAAAAA}IC Name: {FFFFFF}%s\n{AAAAAA}Umur: {FFFFFF}%d\n{AAAAAA}Gender: {FFFFFF}%s\n", PlayerName(targetid), targetid, PlayerInfo[targetid][pICName], PlayerInfo[targetid][pICAge], genderStr);
    format(tmp, sizeof(tmp), "{AAAAAA}Admin: {FFFFFF}%d (%s)\n{AAAAAA}Level: {FFFFFF}%d\n{AAAAAA}Cash: {FFFFFF}%s\n{AAAAAA}Bank: {FFFFFF}%s\n", PlayerInfo[targetid][pAdmin], GetAdminRankName(PlayerInfo[targetid][pAdmin]), PlayerInfo[targetid][pLevel], moneyFmt, bankFmt);
    strcat(info, tmp, sizeof(info));
    format(tmp, sizeof(tmp), "{AAAAAA}HP: {FFFFFF}%.0f\n{AAAAAA}Hunger: {FFFFFF}%d%%\n{AAAAAA}Thirst: {FFFFFF}%d%%\n{AAAAAA}Skin: {FFFFFF}%d\n", hp, PlayerInfo[targetid][pHunger], PlayerInfo[targetid][pThirst], PlayerInfo[targetid][pSkin]);
    strcat(info, tmp, sizeof(info));
    format(tmp, sizeof(tmp), "{AAAAAA}Muted: {FFFFFF}%s | Jailed: %s | Frozen: %s", mutedStr, jailedStr, frozenStr);
    strcat(info, tmp, sizeof(info));

    ShowPlayerDialog(playerid, dNull, DIALOG_STYLE_MSGBOX, "{FFAA00}Check Player", info, "Tutup", "");
    return true;
}

// /spec [playerid] — spectate
COMMAND:spec(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    if(PlayerInfo[playerid][pSpecMode])
    {
        // Stop spectating
        TogglePlayerSpectating(playerid, 0);
        PlayerInfo[playerid][pSpecMode] = false;
        PlayerInfo[playerid][pSpecTarget] = INVALID_PLAYER_ID;
        SendClientFormattedMessage(playerid, COLOR_ADMIN, "Berhenti spectate.");
        return true;
    }

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /spec [playerid] (tanpa param = stop)"), true;
    if(!IsPlayerConnected(targetid) || targetid == playerid)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;

    TogglePlayerSpectating(playerid, 1);
    if(IsPlayerInAnyVehicle(targetid))
        PlayerSpectateVehicle(playerid, GetPlayerVehicleID(targetid));
    else
        PlayerSpectatePlayer(playerid, targetid);

    PlayerInfo[playerid][pSpecMode] = true;
    PlayerInfo[playerid][pSpecTarget] = targetid;
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Spectating %s (ID: %d). Ketik /spec lagi untuk stop.", PlayerName(targetid), targetid);
    return true;
}

// /kick [playerid] [alasan]
COMMAND:kick(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid, reason[128];
    if(sscanf(params, "us[128]", targetid, reason))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /kick [playerid/nama] [alasan]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    new msg[144];
    format(msg, sizeof(msg), "[Admin] %s telah di-kick oleh %s. Alasan: %s",
        PlayerName(targetid), PlayerInfo[playerid][pICName], reason);
    SendClientMessageToAll(COLOR_ADMIN, msg);

    AdminLog(PlayerName(playerid), "KICK", PlayerName(targetid), reason);
    PlayerKick(targetid);
    return true;
}

// /mute [playerid] — toggle mute
COMMAND:mute(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /mute [playerid/nama]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    PlayerInfo[targetid][pMuted] = !PlayerInfo[targetid][pMuted];

    new msg[128];
    if(PlayerInfo[targetid][pMuted])
    {
        format(msg, sizeof(msg), "[Admin] %s telah di-mute oleh %s.",
            PlayerName(targetid), PlayerInfo[playerid][pICName]);
        AdminLog(PlayerName(playerid), "MUTE", PlayerName(targetid), "");
    }
    else
    {
        format(msg, sizeof(msg), "[Admin] %s telah di-unmute oleh %s.",
            PlayerName(targetid), PlayerInfo[playerid][pICName]);
        AdminLog(PlayerName(playerid), "UNMUTE", PlayerName(targetid), "");
    }
    SendClientMessageToAll(COLOR_ADMIN, msg);
    return true;
}

// /warn [playerid] [alasan]
COMMAND:warn(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid, reason[128];
    if(sscanf(params, "us[128]", targetid, reason))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /warn [playerid/nama] [alasan]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    new msg[144];
    format(msg, sizeof(msg), "[Admin] %s telah mendapat peringatan dari %s. Alasan: %s",
        PlayerName(targetid), PlayerInfo[playerid][pICName], reason);
    SendClientMessageToAll(COLOR_ADMIN, msg);
    AdminLog(PlayerName(playerid), "WARN", PlayerName(targetid), reason);
    return true;
}

// /freeze [playerid] — toggle freeze
COMMAND:freeze(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /freeze [playerid/nama]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    PlayerInfo[targetid][pFrozen] = !PlayerInfo[targetid][pFrozen];
    TogglePlayerControllable(targetid, !PlayerInfo[targetid][pFrozen]);

    new msg[128];
    if(PlayerInfo[targetid][pFrozen])
    {
        format(msg, sizeof(msg), "[Admin] %s telah di-freeze oleh %s.",
            PlayerName(targetid), PlayerInfo[playerid][pICName]);
        AdminLog(PlayerName(playerid), "FREEZE", PlayerName(targetid), "");
    }
    else
    {
        format(msg, sizeof(msg), "[Admin] %s telah di-unfreeze oleh %s.",
            PlayerName(targetid), PlayerInfo[playerid][pICName]);
        AdminLog(PlayerName(playerid), "UNFREEZE", PlayerName(targetid), "");
    }
    SendClientMessageToAll(COLOR_ADMIN, msg);
    return true;
}

// /goto [playerid]
COMMAND:goto(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /goto [playerid/nama]"), true;
    if(!IsPlayerConnected(targetid) || targetid == playerid)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;

    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(targetid, tx, ty, tz);
    SetPlayerPos(playerid, tx + 1.0, ty, tz);
    SetPlayerInterior(playerid, GetPlayerInterior(targetid));
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Teleport ke %s.", PlayerName(targetid));
    AdminLog(PlayerName(playerid), "GOTO", PlayerName(targetid), "");
    return true;
}

// /gethere [playerid]
COMMAND:gethere(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /gethere [playerid/nama]"), true;
    if(!IsPlayerConnected(targetid) || targetid == playerid)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    SetPlayerPos(targetid, px + 1.0, py, pz);
    SetPlayerInterior(targetid, GetPlayerInterior(playerid));
    SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Teleport %s ke posisimu.", PlayerName(targetid));
    SendClientFormattedMessage(targetid, COLOR_ADMIN, "Kamu di-teleport oleh admin.");
    AdminLog(PlayerName(playerid), "GETHERE", PlayerName(targetid), "");
    return true;
}

// /slap [playerid] — slap player upward
COMMAND:slap(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /slap [playerid/nama]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(targetid, px, py, pz);
    SetPlayerPos(targetid, px, py, pz + 5.0);

    new msg[128];
    format(msg, sizeof(msg), "[Admin] %s telah di-slap oleh %s.",
        PlayerName(targetid), PlayerInfo[playerid][pICName]);
    SendClientMessageToAll(COLOR_ADMIN, msg);
    AdminLog(PlayerName(playerid), "SLAP", PlayerName(targetid), "");
    return true;
}

// /jail [playerid] [menit]
COMMAND:jail(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid, minutes;
    if(sscanf(params, "ud", targetid, minutes))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /jail [playerid/nama] [menit]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;
    if(minutes < 1 || minutes > 60)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Durasi 1-60 menit!"), true;

    PlayerInfo[targetid][pJailed] = true;
    SetPlayerPos(targetid, 197.6661, 173.8179, 1003.0234);
    SetPlayerInterior(targetid, 3);
    SetPlayerVirtualWorld(targetid, targetid + 1000);
    TogglePlayerControllable(targetid, 0);

    if(PlayerInfo[targetid][pJailTimer] != 0) KillTimer(PlayerInfo[targetid][pJailTimer]);
    PlayerInfo[targetid][pJailTimer] = SetTimerEx("OnJailRelease", minutes * 60000, false, "d", targetid);

    new msg[144];
    format(msg, sizeof(msg), "[Admin] %s telah di-jail %d menit oleh %s.",
        PlayerName(targetid), minutes, PlayerInfo[playerid][pICName]);
    SendClientMessageToAll(COLOR_ADMIN, msg);

    new detail[32];
    format(detail, sizeof(detail), "%d menit", minutes);
    AdminLog(PlayerName(playerid), "JAIL", PlayerName(targetid), detail);
    return true;
}

publics: OnJailRelease(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;
    PlayerInfo[playerid][pJailed] = false;
    PlayerInfo[playerid][pJailTimer] = 0;
    TogglePlayerControllable(playerid, 1);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    // Spawn back at last city spawn
    new Float:sx, Float:sy, Float:sz, Float:sa;
    GetCitySpawn(CITY_MEKAR_PURA, 0, sx, sy, sz, sa);
    SetPlayerPos(playerid, sx, sy, sz);
    SetPlayerFacingAngle(playerid, sa);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Kamu telah dibebaskan dari jail.");
    return 1;
}

// /unjail [playerid]
COMMAND:unjail(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /unjail [playerid/nama]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;
    if(!PlayerInfo[targetid][pJailed])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak dalam jail!"), true;

    if(PlayerInfo[targetid][pJailTimer] != 0)
    {
        KillTimer(PlayerInfo[targetid][pJailTimer]);
        PlayerInfo[targetid][pJailTimer] = 0;
    }
    OnJailRelease(targetid);

    new msg[128];
    format(msg, sizeof(msg), "[Admin] %s telah di-unjail oleh %s.",
        PlayerName(targetid), PlayerInfo[playerid][pICName]);
    SendClientMessageToAll(COLOR_ADMIN, msg);
    AdminLog(PlayerName(playerid), "UNJAIL", PlayerName(targetid), "");
    return true;
}

// /setskin [playerid] [skinid]
COMMAND:setskin(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid, skinid;
    if(sscanf(params, "ud", targetid, skinid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setskin [playerid/nama] [skinid]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;
    if(skinid < 0 || skinid > 311)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Skin ID 0-311!"), true;

    SetPlayerSkin(targetid, skinid);
    PlayerInfo[targetid][pSkin] = skinid;
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Skin %s diubah ke %d.", PlayerName(targetid), skinid);

    new detail[32];
    format(detail, sizeof(detail), "Skin %d", skinid);
    AdminLog(PlayerName(playerid), "SETSKIN", PlayerName(targetid), detail);
    return true;
}

// /ban [playerid] [alasan]
COMMAND:ban(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid, reason[128];
    if(sscanf(params, "us[128]", targetid, reason))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /ban [playerid/nama] [alasan]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    new ip[16];
    GetPlayerIp(targetid, ip, sizeof(ip));

    new q[512];
    mysql_format(MySQL_C1, q, sizeof(q),
        "INSERT INTO `bans` (`name`,`ip`,`admin_name`,`reason`,`ban_date`,`expire_date`) VALUES ('%e','%e','%e','%e','%d','0')",
        PlayerName(targetid), ip, PlayerName(playerid), reason, gettime());
    mysql_tquery(MySQL_C1, q, "", "");

    new msg[144];
    format(msg, sizeof(msg), "[Admin] %s telah di-ban oleh %s. Alasan: %s",
        PlayerName(targetid), PlayerInfo[playerid][pICName], reason);
    SendClientMessageToAll(COLOR_ADMIN, msg);

    AdminLog(PlayerName(playerid), "BAN", PlayerName(targetid), reason);
    PlayerKick(targetid);
    return true;
}

// /unban [nama]
COMMAND:unban(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;
    if(!strlen(params))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /unban [nama]"), true;

    mysql_format(MySQL_C1, query, sizeof(query),
        "DELETE FROM `bans` WHERE `name` = '%e'", params);
    mysql_tquery(MySQL_C1, query, "", "");

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Ban untuk '%s' telah dicabut.", params);
    AdminLog(PlayerName(playerid), "UNBAN", params, "");
    return true;
}

// /setmoney [playerid] [jumlah]
COMMAND:setmoney(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid, amount;
    if(sscanf(params, "ud", targetid, amount))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setmoney [playerid/nama] [jumlah]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    PlayerInfo[targetid][pMoney] = amount;
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Uang %s diatur ke Rp %d.", PlayerName(targetid), amount);
    SendClientFormattedMessage(targetid, COLOR_ADMIN, "Uangmu diatur ke Rp %d oleh admin.", amount);

    new detail[32];
    format(detail, sizeof(detail), "Rp %d", amount);
    AdminLog(PlayerName(playerid), "SETMONEY", PlayerName(targetid), detail);
    return true;
}

// /sethealth [playerid] [hp]
COMMAND:sethealth(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid, Float:hp;
    if(sscanf(params, "uf", targetid, hp))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /sethealth [playerid/nama] [hp]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;
    if(hp < 0.0 || hp > 100.0) hp = 100.0;

    SetPlayerHealth(targetid, hp);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "HP %s diatur ke %.0f.", PlayerName(targetid), hp);

    new detail[32];
    format(detail, sizeof(detail), "HP %.0f", hp);
    AdminLog(PlayerName(playerid), "SETHEALTH", PlayerName(targetid), detail);
    return true;
}

// /veh [modelid] — spawn vehicle at player pos
COMMAND:veh(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new modelid;
    if(sscanf(params, "d", modelid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /veh [modelid]"), true;
    if(modelid < 400 || modelid > 611)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Model ID 400-611!"), true;

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    new vid = CreateVehicle(modelid, px + 3.0, py, pz, pa, -1, -1, -1);
    PutPlayerInVehicle(playerid, vid, 0);

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Vehicle %d spawned.", modelid);
    AdminLog(PlayerName(playerid), "VEH", "", "");
    return true;
}

// /destroyveh — destroy current vehicle
COMMAND:destroyveh(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    if(!IsPlayerInAnyVehicle(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu harus di dalam kendaraan!"), true;

    new vid = GetPlayerVehicleID(playerid);
    RemovePlayerFromVehicle(playerid);
    DestroyVehicle(vid);

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Kendaraan dihancurkan.");
    AdminLog(PlayerName(playerid), "DESTROYVEH", "", "");
    return true;
}

// /setadmin [playerid] [level]
COMMAND:setadmin(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new targetid, level;
    if(sscanf(params, "ud", targetid, level))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setadmin [playerid/nama] [level 0-3]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;
    if(level < 0 || level > 3)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Level harus 0-3!"), true;

    PlayerInfo[targetid][pAdmin] = level;

    // Save to DB immediately
    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `"TABLE_ACCOUNTS"` SET `admin_level` = '%d' WHERE `name` = '%e'",
        level, PlayerName(targetid));
    mysql_tquery(MySQL_C1, query, "", "");

    new msg[128];
    format(msg, sizeof(msg), "[Admin] %s diangkat menjadi %s (Level %d) oleh %s.",
        PlayerName(targetid), GetAdminRankName(level), level, PlayerInfo[playerid][pICName]);
    SendClientMessageToAll(COLOR_ADMIN, msg);

    new detail[32];
    format(detail, sizeof(detail), "Level %d", level);
    AdminLog(PlayerName(playerid), "SETADMIN", PlayerName(targetid), detail);
    return true;
}

// /ann [text] — global announcement
COMMAND:ann(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;
    if(!strlen(params))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /ann [pengumuman]"), true;

    new msg[144];
    format(msg, sizeof(msg), "[Pengumuman] %s", params);
    SendClientMessageToAll(COLOR_ANNOUNCE, msg);
    GameTextForAll(params, 5000, 1);
    AdminLog(PlayerName(playerid), "ANNOUNCE", "", params);
    return true;
}

// /setlevel [playerid] [level]
COMMAND:setlevel(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new targetid, level;
    if(sscanf(params, "ud", targetid, level))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setlevel [playerid/nama] [level]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;
    if(level < 1 || level > 100)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Level harus 1-100!"), true;

    PlayerInfo[targetid][pLevel] = level;
    SetPlayerScore(targetid, level);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Level %s diubah ke %d.", PlayerName(targetid), level);
    SendClientFormattedMessage(targetid, COLOR_ADMIN, "Level kamu diubah ke %d oleh admin.", level);

    new detail[32];
    format(detail, sizeof(detail), "Level %d", level);
    AdminLog(PlayerName(playerid), "SETLEVEL", PlayerName(targetid), detail);
    return true;
}

// ============================================================================
// DEVMAP / DEVELOPER COMMANDS
// ============================================================================

// /getpos — show current position coordinates
COMMAND:getpos(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    new interior = GetPlayerInterior(playerid);
    new vw = GetPlayerVirtualWorld(playerid);

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Posisi: X=%.4f Y=%.4f Z=%.4f A=%.4f", px, py, pz, pa);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Interior: %d | VW: %d", interior, vw);
    return true;
}

// /gotopos [x] [y] [z] — teleport to coordinates
COMMAND:gotopos(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new Float:tx, Float:ty, Float:tz;
    if(sscanf(params, "fff", tx, ty, tz))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /gotopos [x] [y] [z]"), true;

    SetPlayerPos(playerid, tx, ty, tz);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Teleport ke %.2f, %.2f, %.2f.", tx, ty, tz);
    return true;
}

// /setweather [id] — change server weather
COMMAND:setweather(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new weatherid;
    if(sscanf(params, "d", weatherid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setweather [0-45]"), true;
    if(weatherid < 0 || weatherid > 45)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Weather ID 0-45!"), true;

    SetWeather(weatherid);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Weather diubah ke %d.", weatherid);
    AdminLog(PlayerName(playerid), "SETWEATHER", "", "");
    return true;
}

// /settime [jam] — change server time
COMMAND:settime(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new hour;
    if(sscanf(params, "d", hour))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /settime [0-23]"), true;
    if(hour < 0 || hour > 23)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Jam 0-23!"), true;

    SetWorldTime(hour);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Waktu server diubah ke jam %d.", hour);
    AdminLog(PlayerName(playerid), "SETTIME", "", "");
    return true;
}

// /givemoney [playerid] [jumlah] — give money to player
COMMAND:givemoney(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new targetid, amount;
    if(sscanf(params, "ud", targetid, amount))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /givemoney [playerid/nama] [jumlah]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    PlayerInfo[targetid][pMoney] += amount;
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Memberikan Rp %d kepada %s. Total: Rp %d", amount, PlayerName(targetid), PlayerInfo[targetid][pMoney]);
    SendClientFormattedMessage(targetid, COLOR_ADMIN, "Kamu menerima Rp %d dari admin.", amount);

    new detail[32];
    format(detail, sizeof(detail), "Rp %d", amount);
    AdminLog(PlayerName(playerid), "GIVEMONEY", PlayerName(targetid), detail);
    return true;
}

// /giveitem [playerid] [itemid] [jumlah] — give item to player
COMMAND:giveitem(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new targetid, itemid, amount;
    if(sscanf(params, "udd", targetid, itemid, amount))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /giveitem [playerid/nama] [itemid] [jumlah]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;
    if(itemid < 1 || itemid >= MAX_ITEM_TYPES)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Item ID 1-%d!", MAX_ITEM_TYPES - 1), true;
    if(amount < 1 || amount > 99)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Jumlah 1-99!"), true;

    new idx = GetItemTableIndex(itemid);
    if(idx == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Item tidak ditemukan!"), true;

    new result = AddInventoryItem(targetid, itemid, amount);
    if(result == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Inventory %s penuh!", PlayerName(targetid)), true;

    new iname[24];
    format(iname, sizeof(iname), "%s", ItemTable[idx][itmName]);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Memberikan %dx %s kepada %s.", amount, iname, PlayerName(targetid));
    SendClientFormattedMessage(targetid, COLOR_ADMIN, "Kamu menerima %dx %s dari admin.", amount, iname);

    new detail[48];
    format(detail, sizeof(detail), "%dx %s", amount, iname);
    AdminLog(PlayerName(playerid), "GIVEITEM", PlayerName(targetid), detail);
    return true;
}

// /resetplayer [playerid] — reset all player data
COMMAND:resetplayer(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /resetplayer [playerid/nama]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    PlayerInfo[targetid][pMoney] = 0;
    PlayerInfo[targetid][pBank] = 0;
    PlayerInfo[targetid][pLevel] = 1;
    SetPlayerScore(targetid, 1);
    PlayerInfo[targetid][pHunger] = 100;
    PlayerInfo[targetid][pThirst] = 100;
    SetPlayerHealth(targetid, 100.0);

    // Clear inventory
    for(new s = 0; s < MAX_INVENTORY_SLOTS; s++)
    {
        PlayerInfo[targetid][pInvItems][s] = ITEM_NONE;
        PlayerInfo[targetid][pInvAmounts][s] = 0;
    }

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Data %s telah di-reset.", PlayerName(targetid));
    SendClientFormattedMessage(targetid, COLOR_ADMIN, "Semua data kamu telah di-reset oleh developer.");
    AdminLog(PlayerName(playerid), "RESETPLAYER", PlayerName(targetid), "");
    return true;
}

// /serverinfo — view server statistics
COMMAND:serverinfo(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new online = 0;
    for(new i = 0; i < MAX_PLAYERS; i++)
        if(IsPlayerConnected(i)) online++;

    new info[256], tmp[128];
    format(info, sizeof(info), "{FFFFFF}=== Server Info ===\n{AAAAAA}Players Online: {FFFFFF}%d / %d\n", online, GetMaxPlayers());
    format(tmp, sizeof(tmp), "{AAAAAA}Server Tick: {FFFFFF}%d\n{AAAAAA}Weather: {FFFFFF}N/A (use /setweather)\n", GetTickCount());
    strcat(info, tmp, sizeof(info));
    format(tmp, sizeof(tmp), "{AAAAAA}Gamemode: {FFFFFF}Westfield RolePlay\n{AAAAAA}Map: {FFFFFF}San Andreas");
    strcat(info, tmp, sizeof(info));
    ShowPlayerDialog(playerid, dNull, DIALOG_STYLE_MSGBOX, "{00CC00}Server Info", info, "Tutup", "");
    return true;
}

// /setint [playerid] [interior] — set player interior
COMMAND:setint(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new targetid, interior;
    if(sscanf(params, "ud", targetid, interior))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setint [playerid/nama] [interior]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    SetPlayerInterior(targetid, interior);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Interior %s diubah ke %d.", PlayerName(targetid), interior);
    return true;
}

// /setvw [playerid] [vw] — set player virtual world
COMMAND:setvw(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    new targetid, vw;
    if(sscanf(params, "ud", targetid, vw))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setvw [playerid/nama] [vw]"), true;
    if(!IsPlayerConnected(targetid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak ditemukan!"), true;

    SetPlayerVirtualWorld(targetid, vw);
    SendClientFormattedMessage(playerid, COLOR_ADMIN, "Virtual World %s diubah ke %d.", PlayerName(targetid), vw);
    return true;
}

// ============================================================================
// DEVELOPER SELF-HEAL
// ============================================================================

// /heal — developer self-heal/revive (works even while pingsan)
COMMAND:heal(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    // Clear death/pingsan state
    if(PlayerInfo[playerid][pIsDead])
    {
        PlayerInfo[playerid][pIsDead] = false;
        PlayerInfo[playerid][pDeathTick] = 0;
        if(PlayerInfo[playerid][pDeathTimer] != 0)
        {
            KillTimer(PlayerInfo[playerid][pDeathTimer]);
            PlayerInfo[playerid][pDeathTimer] = 0;
        }
        TogglePlayerControllable(playerid, 1);
        ClearAnimations(playerid);

        // Update DB
        mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `is_dead` = '0', `death_tick` = '0' WHERE `name` = '%e'", PlayerName(playerid));
        mysql_function_query(MySQL_C1, query, false, "", "");
    }

    // Full heal
    SetPlayerHealth(playerid, 100.0);
    SetPlayerArmour(playerid, 0.0);

    // Restore hunger/thirst full
    PlayerInfo[playerid][pHunger] = 100;
    PlayerInfo[playerid][pThirst] = 100;
    if(PlayerInfo[playerid][pHudCreated])
    {
        UpdateHungerBar(playerid);
        UpdateThirstBar(playerid);
    }

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "[Dev] Kamu telah di-heal. HP, hunger, thirst full.");
    return true;
}

// ============================================================================
// ADMIN DUTY
// ============================================================================

// /aduty — toggle admin duty mode
COMMAND:aduty(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    PlayerInfo[playerid][pAdminDuty] = !PlayerInfo[playerid][pAdminDuty];

    if(PlayerInfo[playerid][pAdminDuty])
    {
        SetPlayerColor(playerid, COLOR_ADMIN);
        SetPlayerHealth(playerid, 99999.0);
        SendClientFormattedMessage(playerid, COLOR_ADMIN, "Admin Duty: ON — Kamu sekarang dalam mode admin.");
        new msg[64];
        format(msg, sizeof(msg), "[Admin] %s sedang bertugas.", PlayerInfo[playerid][pICName]);
        SendAdminMessage(COLOR_ADMIN, msg);
    }
    else
    {
        SetPlayerColor(playerid, COLOR_WHITE);
        SetPlayerHealth(playerid, 100.0);
        SendClientFormattedMessage(playerid, COLOR_ADMIN, "Admin Duty: OFF — Kamu kembali ke mode normal.");
        new msg[64];
        format(msg, sizeof(msg), "[Admin] %s selesai bertugas.", PlayerInfo[playerid][pICName]);
        SendAdminMessage(COLOR_ADMIN, msg);
    }
    return true;
}

// ============================================================================
// ADMIN HELP COMMANDS
// ============================================================================

// /mhelp — Daftar command Management (Level 1)
COMMAND:mhelp(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    new helpStr[1400];
    strcat(helpStr, "{FFFFFF}=== {FFD700}PERINTAH MANAGEMENT (Level 1){FFFFFF} ===\n\n");

    strcat(helpStr, "{00BFFF}[ Moderasi ]\n");
    strcat(helpStr, "{FFFFFF}/a {AAAAAA}- Chat khusus admin\n");
    strcat(helpStr, "{FFFFFF}/aduty {AAAAAA}- Toggle mode admin duty\n");
    strcat(helpStr, "{FFFFFF}/reports {AAAAAA}- Melihat daftar laporan aktif\n");
    strcat(helpStr, "{FFFFFF}/check [id] {AAAAAA}- Melihat info detail player\n");
    strcat(helpStr, "{FFFFFF}/spec [id] {AAAAAA}- Spectate/mengawasi player\n\n");

    strcat(helpStr, "{00BFFF}[ Hukuman ]\n");
    strcat(helpStr, "{FFFFFF}/kick [id] [alasan] {AAAAAA}- Kick player\n");
    strcat(helpStr, "{FFFFFF}/ban [id] [alasan] {AAAAAA}- Ban player\n");
    strcat(helpStr, "{FFFFFF}/unban [nama] {AAAAAA}- Mencabut ban player\n");
    strcat(helpStr, "{FFFFFF}/warn [id] [alasan] {AAAAAA}- Peringatan ke player\n");
    strcat(helpStr, "{FFFFFF}/mute [id] {AAAAAA}- Toggle mute player\n");
    strcat(helpStr, "{FFFFFF}/freeze [id] {AAAAAA}- Toggle freeze player\n");
    strcat(helpStr, "{FFFFFF}/jail [id] [menit] {AAAAAA}- Penjara player\n");
    strcat(helpStr, "{FFFFFF}/unjail [id] {AAAAAA}- Bebaskan dari penjara\n\n");

    strcat(helpStr, "{00BFFF}[ Utilitas ]\n");
    strcat(helpStr, "{FFFFFF}/goto [id] {AAAAAA}- Teleport ke player\n");
    strcat(helpStr, "{FFFFFF}/gethere [id] {AAAAAA}- Teleport player ke kamu\n");
    strcat(helpStr, "{FFFFFF}/slap [id] {AAAAAA}- Lempar player ke atas\n");
    strcat(helpStr, "{FFFFFF}/setskin [id] [skin] {AAAAAA}- Ubah skin player\n");
    strcat(helpStr, "{FFFFFF}/setmoney [id] [jumlah] {AAAAAA}- Atur uang player\n");
    strcat(helpStr, "{FFFFFF}/sethealth [id] [hp] {AAAAAA}- Atur HP player\n");
    strcat(helpStr, "{FFFFFF}/setlevel [id] [level] {AAAAAA}- Ubah level player\n");
    strcat(helpStr, "{FFFFFF}/veh [model] {AAAAAA}- Spawn kendaraan\n");
    strcat(helpStr, "{FFFFFF}/destroyveh {AAAAAA}- Hancurkan kendaraan\n");
    strcat(helpStr, "{FFFFFF}/ann [teks] {AAAAAA}- Pengumuman global\n\n");

    strcat(helpStr, "{00BFFF}[ Lokasi & Properti & Fraksi ]\n");
    strcat(helpStr, "{FFFFFF}/locs {AAAAAA}- Daftar lokasi | ");
    strcat(helpStr, "{FFFFFF}/gotoloc [id] {AAAAAA}- TP ke lokasi\n");
    strcat(helpStr, "{FFFFFF}/proplist, /createproperty, /deleteproperty, /setpropinterior\n");
    strcat(helpStr, "{FFFFFF}/factions, /finfo, /createfaction, /deletefaction\n");
    strcat(helpStr, "{FFFFFF}/fsetbudget, /fsethq, /fsetpaydayinterval\n");

    ShowPlayerDialog(playerid, DIALOG_HELP_MANAGEMENT, DIALOG_STYLE_MSGBOX, "{FFD700}Management Help", helpStr, "Tutup", "");
    return true;
}

// /dmhelp — Daftar command DevMap (Level 2)
COMMAND:dmhelp(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only!"), true;

    new helpStr[2048];
    strcat(helpStr, "{FFFFFF}=== {00FF00}PERINTAH DEVMAP (Level 2){FFFFFF} ===\n");
    strcat(helpStr, "{AAAAAA}Termasuk semua perintah Management (/mhelp)\n\n");

    strcat(helpStr, "{00BFFF}[ Admin & Server ]\n");
    strcat(helpStr, "{FFFFFF}/setadmin [id] [level] {AAAAAA}- Ubah level admin\n");
    strcat(helpStr, "{FFFFFF}/serverinfo {AAAAAA}- Statistik server\n");
    strcat(helpStr, "{FFFFFF}/setweather [id] {AAAAAA}- Ubah cuaca server\n");
    strcat(helpStr, "{FFFFFF}/settime [jam] {AAAAAA}- Ubah waktu server\n\n");

    strcat(helpStr, "{00BFFF}[ Player Tools ]\n");
    strcat(helpStr, "{FFFFFF}/givemoney [id] [jumlah] {AAAAAA}- Beri uang ke player\n");
    strcat(helpStr, "{FFFFFF}/giveitem [id] [item] {AAAAAA}- Beri item ke player\n");
    strcat(helpStr, "{FFFFFF}/resetplayer [id] {AAAAAA}- Reset data player\n");
    strcat(helpStr, "{FFFFFF}/setint [id] [interior] {AAAAAA}- Ubah interior player\n");
    strcat(helpStr, "{FFFFFF}/setvw [id] [vw] {AAAAAA}- Ubah virtual world player\n");
    strcat(helpStr, "{FFFFFF}/heal {AAAAAA}- Self-heal / revive diri sendiri\n\n");

    strcat(helpStr, "{00BFFF}[ Navigasi & Mapping ]\n");
    strcat(helpStr, "{FFFFFF}/getpos {AAAAAA}- Tampilkan koordinat posisi\n");
    strcat(helpStr, "{FFFFFF}/gotopos [x] [y] [z] {AAAAAA}- TP ke koordinat\n");
    strcat(helpStr, "{FFFFFF}/fly {AAAAAA}- Toggle mode terbang/noclip\n");
    strcat(helpStr, "{FFFFFF}/tp {AAAAAA}- TP ke lokasi via dialog\n");
    strcat(helpStr, "{FFFFFF}/createloc {AAAAAA}- Buat lokasi baru\n");
    strcat(helpStr, "{FFFFFF}/deleteloc {AAAAAA}- Hapus lokasi terdekat\n");
    strcat(helpStr, "{FFFFFF}/editloc {AAAAAA}- Edit nama lokasi\n\n");

    strcat(helpStr, "{00BFFF}[ Setup Mall & KTP ]\n");
    strcat(helpStr, "{FFFFFF}/mallsetup {AAAAAA}- Dialog setup Mall Pelayanan\n");
    strcat(helpStr, "{FFFFFF}/setmall, /delmall, /movemall, /malllist\n");
    strcat(helpStr, "{FFFFFF}/previewinterior, /setmallinterior\n");
    strcat(helpStr, "{FFFFFF}/mallnpc, /delmallnpc, /mallnpclist\n\n");

    strcat(helpStr, "{00BFFF}[ Setup Bank & ATM ]\n");
    strcat(helpStr, "{FFFFFF}/setatm, /delatm, /moveatm, /atmlist\n");
    strcat(helpStr, "{FFFFFF}/setbank, /delbank, /movebank, /banklist\n\n");

    strcat(helpStr, "{00BFFF}[ Setup Interior ]\n");
    strcat(helpStr, "{FFFFFF}/setinterior, /setinteriorexit, /delinterior\n");
    strcat(helpStr, "{FFFFFF}/interiorlist, /gotointerior\n\n");

    strcat(helpStr, "{00BFFF}[ Setup SIM & GoFood ]\n");
    strcat(helpStr, "{FFFFFF}/setsimstation, /delsimstation, /simstationlist\n");
    strcat(helpStr, "{FFFFFF}/setlocker, /dellocker, /movelocker, /lockerlist, /gotolocker\n");

    ShowPlayerDialog(playerid, DIALOG_HELP_DEVMAP, DIALOG_STYLE_MSGBOX, "{00FF00}DevMap Help", helpStr, "Tutup", "");
    return true;
}

// /dhelp — Daftar command Developer (Level 3)
COMMAND:dhelp(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVELOPER)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Developer only!"), true;

    new helpStr[512];
    strcat(helpStr, "{FFFFFF}=== {FF4444}PERINTAH DEVELOPER (Level 3){FFFFFF} ===\n\n");
    strcat(helpStr, "{AAAAAA}Developer memiliki akses ke semua perintah:\n\n");
    strcat(helpStr, "{FFD700}/mhelp {FFFFFF}- Lihat perintah Management (Level 1)\n");
    strcat(helpStr, "{00FF00}/dmhelp {FFFFFF}- Lihat perintah DevMap (Level 2)\n\n");
    strcat(helpStr, "{AAAAAA}Saat ini tidak ada perintah eksklusif Developer.\n");
    strcat(helpStr, "{AAAAAA}Semua perintah DevMap juga berlaku untuk Developer.\n\n");
    strcat(helpStr, "{00BFFF}[ Mapping Tool ]\n");
    strcat(helpStr, "{FFFFFF}/tstudio {AAAAAA}- Buka Texture Studio (filterscript)\n");

    ShowPlayerDialog(playerid, DIALOG_HELP_DEVELOPER, DIALOG_STYLE_MSGBOX, "{FF4444}Developer Help", helpStr, "Tutup", "");
    return true;
}
