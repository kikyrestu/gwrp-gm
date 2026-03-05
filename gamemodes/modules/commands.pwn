// ============================================================================
// MODULE: commands.pwn
// All player commands (zcmd)
// ============================================================================

COMMAND:mymenu(playerid, params[])
{
    SendClientFormattedMessage(playerid, -1, "Ini adalah perintah test.");
    return true;
}

COMMAND:minum(playerid, params[])
{
    if(PlayerInfo[playerid][pIsDead]) return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan!"), true;
    PlayerInfo[playerid][pThirst] = 100;
    if(PlayerInfo[playerid][pHudCreated]) UpdateThirstBar(playerid);
    SendClientFormattedMessage(playerid, 0x33CCFFFF, "Kamu telah minum. Rasa haus teratasi.");
    return true;
}

COMMAND:makan(playerid, params[])
{
    if(PlayerInfo[playerid][pIsDead]) return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan!"), true;
    PlayerInfo[playerid][pHunger] = 100;
    if(PlayerInfo[playerid][pHudCreated]) UpdateHungerBar(playerid);
    SendClientFormattedMessage(playerid, 0x33FF33FF, "Kamu telah makan. Rasa lapar teratasi.");
    return true;
}

COMMAND:cancelgps(playerid, params[])
{
    if(!PlayerInfo[playerid][pGPSActive])
        return SendClientFormattedMessage(playerid, COLOR_RED, "GPS tidak aktif!"), true;
    SendClientFormattedMessage(playerid, 0xF44336FF, "[GPS] Navigasi dibatalkan.");
    StopGPSTracking(playerid);
    return true;
}

COMMAND:dompet(playerid, params[])
{
    if(PlayerInfo[playerid][pIsDead]) return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan!"), true;
    if(PlayerInfo[playerid][pWalletOpen])
        CloseWallet(playerid);
    else
        OpenWallet(playerid);
    return true;
}

// ============================================================================
// RP COMMANDS
// ============================================================================

// /me [action] — "* John Doe [action]"
COMMAND:me(playerid, params[])
{
    if(!strlen(params)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /me [aksi]"), true;
    new rptext[144];
    format(rptext, sizeof(rptext), "* %s %s", PlayerInfo[playerid][pICName], params);
    ProxDetector(20.0, playerid, rptext, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
    return true;
}

// /do [narration] — "* [narration] (( John Doe ))"
COMMAND:do(playerid, params[])
{
    if(!strlen(params)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /do [narasi]"), true;
    new rptext[144];
    format(rptext, sizeof(rptext), "* %s (( %s ))", params, PlayerInfo[playerid][pICName]);
    ProxDetector(20.0, playerid, rptext, COLOR_DO, COLOR_DO, COLOR_DO, COLOR_DO, COLOR_DO);
    return true;
}

// /ame [action] — same as /me + 3D text above head for ~5 seconds
COMMAND:ame(playerid, params[])
{
    if(!strlen(params)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /ame [aksi]"), true;

    // Chat message (same as /me)
    new rptext[144];
    format(rptext, sizeof(rptext), "* %s %s", PlayerInfo[playerid][pICName], params);
    ProxDetector(20.0, playerid, rptext, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);

    // Destroy old AME label if exists
    if(PlayerInfo[playerid][pAMETimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pAMETimer]);
        PlayerInfo[playerid][pAMETimer] = 0;
    }
    if(PlayerInfo[playerid][pAMELabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(PlayerInfo[playerid][pAMELabel]);
        PlayerInfo[playerid][pAMELabel] = Text3D:INVALID_3DTEXT_ID;
    }

    // Create 3D text label above player head
    new labeltext[144];
    format(labeltext, sizeof(labeltext), "%s", rptext);
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    PlayerInfo[playerid][pAMELabel] = Create3DTextLabel(labeltext, COLOR_ME, px, py, pz + 0.35, 20.0, 0, 1);
    Attach3DTextLabelToPlayer(PlayerInfo[playerid][pAMELabel], playerid, 0.0, 0.0, 0.35);

    // Auto-delete after 5 seconds
    PlayerInfo[playerid][pAMETimer] = SetTimerEx("OnAMEExpire", 5000, false, "d", playerid);
    return true;
}

publics: OnAMEExpire(playerid)
{
    if(PlayerInfo[playerid][pAMELabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(PlayerInfo[playerid][pAMELabel]);
        PlayerInfo[playerid][pAMELabel] = Text3D:INVALID_3DTEXT_ID;
    }
    PlayerInfo[playerid][pAMETimer] = 0;
    return 1;
}

// /s [text] or /shout [text] — "John Doe berteriak: [text]!!"  radius 40m
COMMAND:s(playerid, params[])
{
    if(!strlen(params)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /s [teks]"), true;
    new shouttext[144];
    format(shouttext, sizeof(shouttext), "%s berteriak: %s!!", PlayerInfo[playerid][pICName], params);
    ProxDetector(40.0, playerid, shouttext, COLOR_SHOUT, COLOR_SHOUT, COLOR_SHOUT, COLOR_SHOUT, COLOR_SHOUT);
    SetPlayerChatBubble(playerid, params, COLOR_SHOUT, 40.0, 5000);
    return true;
}
COMMAND:shout(playerid, params[]) return cmd_s(playerid, params);

// /w [playerid] [text] — whisper, only sender + target within 3m see it
COMMAND:w(playerid, params[])
{
    new targetid, wtext[128];
    if(sscanf(params, "us[128]", targetid, wtext))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /w [playerid/nama] [pesan]"), true;

    if(!IsPlayerConnected(targetid) || targetid == playerid)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), true;

    // Check distance (max 3m)
    new Float:px, Float:py, Float:pz, Float:tx, Float:ty, Float:tz;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerPos(targetid, tx, ty, tz);
    new Float:dist = floatsqroot((px-tx)*(px-tx) + (py-ty)*(py-ty) + (pz-tz)*(pz-tz));

    if(dist > 3.0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Orang tersebut terlalu jauh untuk berbisik!"), true;

    new whispertext[144];
    format(whispertext, sizeof(whispertext), "%s berbisik kepada %s: %s",
        PlayerInfo[playerid][pICName], PlayerInfo[targetid][pICName], wtext);
    SendClientMessage(playerid, COLOR_WHISPER, whispertext);
    SendClientMessage(targetid, COLOR_WHISPER, whispertext);

    // Nearby players see the action (but NOT the content)
    new rpaction[80];
    format(rpaction, sizeof(rpaction), "* %s berbisik kepada %s.", PlayerInfo[playerid][pICName], PlayerInfo[targetid][pICName]);
    ProxDetector(10.0, playerid, rpaction, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
    return true;
}
COMMAND:whisper(playerid, params[]) return cmd_w(playerid, params);

// /b [text] — OOC local chat (out of character, radius 20m)
COMMAND:b(playerid, params[])
{
    if(!strlen(params)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /b [pesan OOC]"), true;
    new ooctext[144];
    format(ooctext, sizeof(ooctext), "(( %s(%d): %s ))", PlayerName(playerid), playerid, params);
    ProxDetector(20.0, playerid, ooctext, COLOR_OOC, COLOR_OOC, COLOR_OOC, COLOR_OOC, COLOR_OOC);
    return true;
}
COMMAND:ooc(playerid, params[]) return cmd_b(playerid, params);
