// ============================================================================
// MODULE: phone_call.pwn
// Phone Call System (via WitApp)
// - Open WitApp → select contact → "Panggil" button
// - During call: ALL player chat becomes phone-color (intercepted in OnPlayerText)
// - Nearby players (<5m) hear one side of the conversation (proximity leak)
// - Costs kuota per 30 seconds
// - Auto hangup on disconnect, missed call after 15 seconds
// ============================================================================

// ============================================================================
// DEFINES
// ============================================================================

#define CALL_STATE_NONE         0
#define CALL_STATE_CALLING      1   // ringing, waiting for answer
#define CALL_STATE_ACTIVE       2   // both parties connected
#define CALL_RING_TIMEOUT       15000   // 15 seconds to answer
#define CALL_KUOTA_INTERVAL     30000   // deduct kuota every 30 seconds
#define CALL_KUOTA_COST         10240   // 10 MB per 30s
#define COLOR_PHONE_CHAT        0x8ED1FCFF  // light blue phone chat
#define COLOR_PHONE_LEAK        0x6B9EC3AA  // proximity leak color (faded)

// ============================================================================
// PLAYER CALL DATA
// ============================================================================

new pCallState[MAX_PLAYERS];        // CALL_STATE_*
new pCallPartner[MAX_PLAYERS];      // playerid of partner (-1 = none)
new pCallTimer[MAX_PLAYERS];        // ring timeout OR kuota timer
new pCallKuotaTimer[MAX_PLAYERS];   // kuota drain timer during active call

// ============================================================================
// INIT / RESET
// ============================================================================

stock ResetCallData(playerid)
{
    pCallState[playerid] = CALL_STATE_NONE;
    pCallPartner[playerid] = -1;
    if(pCallTimer[playerid] != 0)
    {
        KillTimer(pCallTimer[playerid]);
        pCallTimer[playerid] = 0;
    }
    if(pCallKuotaTimer[playerid] != 0)
    {
        KillTimer(pCallKuotaTimer[playerid]);
        pCallKuotaTimer[playerid] = 0;
    }
}

// ============================================================================
// START CALL (from WitApp chat view — Btn2 "Panggil")
// ============================================================================

stock StartPhoneCall(playerid)
{
    // Validate caller state
    if(pCallState[playerid] != CALL_STATE_NONE)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang dalam panggilan!"), 0;

    // Must have contact selected in WA chat
    new contactIdx = PlayerInfo[playerid][pPhoneChatContact];
    if(contactIdx < 0 || contactIdx >= PlayerInfo[playerid][pPhoneContactCount])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada kontak yang dipilih!"), 0;

    new targetDbId = PlayerInfo[playerid][pPhoneContacts][contactIdx];

    // Check kuota
    if(PlayerInfo[playerid][pKuota] < CALL_KUOTA_COST)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kuota tidak cukup untuk menelepon! Beli kuota di toko."), 0;

    // Find target player online
    new targetPid = -1;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(PlayerInfo[i][pID] == targetDbId)
        {
            targetPid = i;
            break;
        }
    }

    if(targetPid == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "[WitApp] Kontak sedang offline. Panggilan gagal."), 0;

    if(targetPid == playerid)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak bisa menelepon diri sendiri!"), 0;

    // Check if target is already in a call
    if(pCallState[targetPid] != CALL_STATE_NONE)
        return SendClientFormattedMessage(playerid, COLOR_RED, "[WitApp] Kontak sedang sibuk (dalam panggilan lain)."), 0;

    // Start calling
    pCallState[playerid] = CALL_STATE_CALLING;
    pCallPartner[playerid] = targetPid;
    pCallState[targetPid] = CALL_STATE_CALLING;
    pCallPartner[targetPid] = playerid;

    // Notify both
    SendClientFormattedMessage(playerid, COLOR_PHONE_CHAT,
        "[WitApp] Menelepon %s... Menunggu jawaban.",
        PhoneContactNames[playerid][contactIdx]);

    // Find caller name in target's contacts (or use IC name)
    new callerName[32];
    new found = 0;
    for(new i = 0; i < PlayerInfo[targetPid][pPhoneContactCount]; i++)
    {
        if(PlayerInfo[targetPid][pPhoneContacts][i] == PlayerInfo[playerid][pID])
        {
            strmid(callerName, PhoneContactNames[targetPid][i], 0, strlen(PhoneContactNames[targetPid][i]), 32);
            found = 1;
            break;
        }
    }
    if(!found) strmid(callerName, PlayerInfo[playerid][pPhoneNumber], 0, strlen(PlayerInfo[playerid][pPhoneNumber]), 32);

    SendClientFormattedMessage(targetPid, COLOR_PHONE_CHAT,
        "[WitApp] Panggilan masuk dari %s. Ketik /angkat untuk menjawab atau /tolak untuk menolak.",
        callerName);

    // RP action
    new rptext[80];
    format(rptext, sizeof(rptext), "* %s menelepon seseorang via handphone.", PlayerInfo[playerid][pICName]);
    ProxDetector(15.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    // Ring timeout — missed call after 15 seconds
    pCallTimer[playerid] = SetTimerEx("OnCallRingTimeout", CALL_RING_TIMEOUT, false, "dd", playerid, targetPid);

    return 1;
}

// ============================================================================
// RING TIMEOUT — Missed call
// ============================================================================

publics: OnCallRingTimeout(callerid, targetid)
{
    // Only trigger if still in CALLING state
    if(pCallState[callerid] != CALL_STATE_CALLING) return 1;
    if(pCallPartner[callerid] != targetid) return 1;

    SendClientFormattedMessage(callerid, COLOR_PHONE_CHAT,
        "[WitApp] Tidak ada jawaban. Panggilan terputus.");
    SendClientFormattedMessage(targetid, COLOR_PHONE_CHAT,
        "[WitApp] Panggilan tidak terjawab.");

    // Reset both
    ResetCallData(callerid);
    ResetCallData(targetid);
    return 1;
}

// ============================================================================
// ANSWER / REJECT
// ============================================================================

COMMAND:angkat(playerid, params[])
{
    if(pCallState[playerid] != CALL_STATE_CALLING)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada panggilan masuk!"), true;

    new callerid = pCallPartner[playerid];
    if(callerid == -1 || !IsPlayerConnected(callerid))
    {
        ResetCallData(playerid);
        return SendClientFormattedMessage(playerid, COLOR_RED, "Penelepon sudah tidak tersedia."), true;
    }

    // Kill ring timeout timer
    if(pCallTimer[callerid] != 0)
    {
        KillTimer(pCallTimer[callerid]);
        pCallTimer[callerid] = 0;
    }

    // Set both to ACTIVE
    pCallState[playerid] = CALL_STATE_ACTIVE;
    pCallState[callerid] = CALL_STATE_ACTIVE;

    SendClientFormattedMessage(playerid, COLOR_PHONE_CHAT,
        "[WitApp] Panggilan tersambung. Bicara langsung di chat. Ketik /tutup untuk mengakhiri.");
    SendClientFormattedMessage(callerid, COLOR_PHONE_CHAT,
        "[WitApp] Panggilan dijawab! Bicara langsung di chat. Ketik /tutup untuk mengakhiri.");

    // RP action
    new rptext[80];
    format(rptext, sizeof(rptext), "* %s mengangkat telepon.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    // Start kuota drain for caller
    pCallKuotaTimer[callerid] = SetTimerEx("OnCallKuotaDrain", CALL_KUOTA_INTERVAL, true, "d", callerid);

    return true;
}

COMMAND:tolak(playerid, params[])
{
    if(pCallState[playerid] != CALL_STATE_CALLING)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Tidak ada panggilan masuk!"), true;

    new callerid = pCallPartner[playerid];

    SendClientFormattedMessage(playerid, COLOR_PHONE_CHAT,
        "[WitApp] Panggilan ditolak.");

    if(callerid != -1 && IsPlayerConnected(callerid))
    {
        SendClientFormattedMessage(callerid, COLOR_PHONE_CHAT,
            "[WitApp] Panggilan ditolak oleh penerima.");
    }

    // RP
    new rptext[80];
    format(rptext, sizeof(rptext), "* %s menolak panggilan telepon.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    ResetCallData(playerid);
    if(callerid != -1 && IsPlayerConnected(callerid))
        ResetCallData(callerid);

    return true;
}

// ============================================================================
// HANGUP
// ============================================================================

COMMAND:tutup(playerid, params[])
{
    if(pCallState[playerid] == CALL_STATE_NONE)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak sedang dalam panggilan!"), true;

    new partnerid = pCallPartner[playerid];

    SendClientFormattedMessage(playerid, COLOR_PHONE_CHAT,
        "[WitApp] Panggilan diakhiri.");

    if(partnerid != -1 && IsPlayerConnected(partnerid))
    {
        SendClientFormattedMessage(partnerid, COLOR_PHONE_CHAT,
            "[WitApp] Panggilan diakhiri oleh lawan bicara.");
        ResetCallData(partnerid);
    }

    // RP
    new rptext[80];
    format(rptext, sizeof(rptext), "* %s menutup telepon.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    ResetCallData(playerid);
    return true;
}

// ============================================================================
// KUOTA DRAIN (every 30s during active call)
// ============================================================================

publics: OnCallKuotaDrain(playerid)
{
    if(pCallState[playerid] != CALL_STATE_ACTIVE)
    {
        if(pCallKuotaTimer[playerid] != 0)
        {
            KillTimer(pCallKuotaTimer[playerid]);
            pCallKuotaTimer[playerid] = 0;
        }
        return 1;
    }

    // Deduct kuota
    PlayerInfo[playerid][pKuota] -= CALL_KUOTA_COST;
    if(PlayerInfo[playerid][pPhoneOpen])
        UpdatePhoneStatusBar(playerid);

    // If kuota runs out, auto hangup
    if(PlayerInfo[playerid][pKuota] <= 0)
    {
        PlayerInfo[playerid][pKuota] = 0;
        SendClientFormattedMessage(playerid, COLOR_RED, "[WitApp] Kuota habis! Panggilan terputus.");

        new partnerid = pCallPartner[playerid];
        if(partnerid != -1 && IsPlayerConnected(partnerid))
        {
            SendClientFormattedMessage(partnerid, COLOR_PHONE_CHAT,
                "[WitApp] Panggilan terputus (kuota lawan habis).");
            ResetCallData(partnerid);
        }
        ResetCallData(playerid);
    }
    return 1;
}

// ============================================================================
// DISCONNECT HANDLER — Auto hangup
// ============================================================================

stock HandleCallDisconnect(playerid)
{
    if(pCallState[playerid] == CALL_STATE_NONE) return;

    new partnerid = pCallPartner[playerid];
    if(partnerid != -1 && IsPlayerConnected(partnerid))
    {
        SendClientFormattedMessage(partnerid, COLOR_PHONE_CHAT,
            "[WitApp] Panggilan terputus (lawan bicara disconnect).");
        ResetCallData(partnerid);
    }
    ResetCallData(playerid);
}

// ============================================================================
// CHAT INTERCEPT — Called from OnPlayerText
// Returns 1 if call is active (message handled), 0 if normal chat
// ============================================================================

stock HandleCallChat(playerid, text[])
{
    if(pCallState[playerid] != CALL_STATE_ACTIVE) return 0;

    new partnerid = pCallPartner[playerid];
    if(partnerid == -1 || !IsPlayerConnected(partnerid))
    {
        // Partner gone, end call
        SendClientFormattedMessage(playerid, COLOR_PHONE_CHAT,
            "[WitApp] Panggilan terputus.");
        ResetCallData(playerid);
        return 1;
    }

    // Format phone chat message
    new chatmsg[144];
    format(chatmsg, sizeof(chatmsg), "[Telepon] %s: %s", PlayerInfo[playerid][pICName], text);

    // Send to both parties (full message)
    SendClientMessage(playerid, COLOR_PHONE_CHAT, chatmsg);
    SendClientMessage(partnerid, COLOR_PHONE_CHAT, chatmsg);

    // Proximity leak — nearby players (<5m) hear one side
    // They see something like "* [speaker] berbicara di telepon: [partial]"
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(i == playerid || i == partnerid) continue;

        new Float:tx, Float:ty, Float:tz;
        GetPlayerPos(i, tx, ty, tz);
        new Float:dist = floatsqroot((px-tx)*(px-tx) + (py-ty)*(py-ty) + (pz-tz)*(pz-tz));

        if(dist <= 5.0)
        {
            // Nearby player hears one side
            new leakmsg[144];
            format(leakmsg, sizeof(leakmsg), "* %s (telepon): %s", PlayerInfo[playerid][pICName], text);
            SendClientMessage(i, COLOR_PHONE_LEAK, leakmsg);
        }
    }

    // Chat bubble for RP (people see player is talking on phone)
    SetPlayerChatBubble(playerid, "*sedang menelepon*", COLOR_RP, 10.0, 3000);

    return 1; // message handled, block normal chat
}

// ============================================================================
// UTILITY: Check if player is in active call
// ============================================================================

stock IsPlayerInCall(playerid)
{
    return (pCallState[playerid] == CALL_STATE_ACTIVE) ? 1 : 0;
}

stock IsPlayerCalling(playerid)
{
    return (pCallState[playerid] != CALL_STATE_NONE) ? 1 : 0;
}
