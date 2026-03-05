// ============================================================================
// MODULE: ht_radio.pwn
// HT (Handy Talky) Radio System
// - Buy HT at Market → /ht to toggle UI → /setfreq to set freq → /r to talk
// - Uses global TextDraw for radio body, PlayerTextDraw for dynamic content
// - Frequency range: 100.0 - 999.9
// ============================================================================

// ============================================================================
// GLOBAL TEXTDRAWS (Radio body — 23 elements from Radio Textdraw.txt)
// ============================================================================

new Text:HTRadioTD[HT_RADIO_TD_COUNT];

// Player-specific TextDraws for dynamic content (frequency display, status)
new PlayerText:ptdHTFreqText[MAX_PLAYERS] = {INVALID_PLAYER_TD, ...};
new PlayerText:ptdHTStatusText[MAX_PLAYERS] = {INVALID_PLAYER_TD, ...};
new PlayerText:ptdHTChannelText[MAX_PLAYERS] = {INVALID_PLAYER_TD, ...};

// ============================================================================
// CREATE / DESTROY GLOBAL TEXTDRAWS
// ============================================================================

stock CreateHTRadioTextDraws()
{
    // [0] Main body background (dark gray)
    HTRadioTD[0] = TextDrawCreate(358.000, 334.000, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[0], 111.000, 148.000);
    TextDrawAlignment(HTRadioTD[0], 1);
    TextDrawColor(HTRadioTD[0], 168430335);
    TextDrawSetShadow(HTRadioTD[0], 0);
    TextDrawSetOutline(HTRadioTD[0], 0);
    TextDrawBackgroundColor(HTRadioTD[0], 255);
    TextDrawFont(HTRadioTD[0], 4);
    TextDrawSetProportional(HTRadioTD[0], 1);

    // [1] Top-left rounded corner
    HTRadioTD[1] = TextDrawCreate(353.899, 320.000, "LD_BEAT:chit");
    TextDrawTextSize(HTRadioTD[1], 25.000, 25.000);
    TextDrawAlignment(HTRadioTD[1], 1);
    TextDrawColor(HTRadioTD[1], 168430335);
    TextDrawSetShadow(HTRadioTD[1], 0);
    TextDrawSetOutline(HTRadioTD[1], 0);
    TextDrawBackgroundColor(HTRadioTD[1], 255);
    TextDrawFont(HTRadioTD[1], 4);
    TextDrawSetProportional(HTRadioTD[1], 1);

    // [2] Top-right rounded corner
    HTRadioTD[2] = TextDrawCreate(448.000, 320.000, "LD_BEAT:chit");
    TextDrawTextSize(HTRadioTD[2], 25.100, 25.000);
    TextDrawAlignment(HTRadioTD[2], 1);
    TextDrawColor(HTRadioTD[2], 168430335);
    TextDrawSetShadow(HTRadioTD[2], 0);
    TextDrawSetOutline(HTRadioTD[2], 0);
    TextDrawBackgroundColor(HTRadioTD[2], 255);
    TextDrawFont(HTRadioTD[2], 4);
    TextDrawSetProportional(HTRadioTD[2], 1);

    // [3] Upper body panel
    HTRadioTD[3] = TextDrawCreate(367.000, 324.398, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[3], 92.000, 148.000);
    TextDrawAlignment(HTRadioTD[3], 1);
    TextDrawColor(HTRadioTD[3], 168430335);
    TextDrawSetShadow(HTRadioTD[3], 0);
    TextDrawSetOutline(HTRadioTD[3], 0);
    TextDrawBackgroundColor(HTRadioTD[3], 255);
    TextDrawFont(HTRadioTD[3], 4);
    TextDrawSetProportional(HTRadioTD[3], 1);

    // [4] Screen area (green-ish)
    HTRadioTD[4] = TextDrawCreate(367.000, 355.398, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[4], 92.000, 148.000);
    TextDrawAlignment(HTRadioTD[4], 1);
    TextDrawColor(HTRadioTD[4], 598910975);
    TextDrawSetShadow(HTRadioTD[4], 0);
    TextDrawSetOutline(HTRadioTD[4], 0);
    TextDrawBackgroundColor(HTRadioTD[4], 255);
    TextDrawFont(HTRadioTD[4], 4);
    TextDrawSetProportional(HTRadioTD[4], 1);

    // [5] Screen bottom-right corner
    HTRadioTD[5] = TextDrawCreate(435.799, 338.700, "LD_BEAT:chit");
    TextDrawTextSize(HTRadioTD[5], 28.100, 31.000);
    TextDrawAlignment(HTRadioTD[5], 1);
    TextDrawColor(HTRadioTD[5], 598910975);
    TextDrawSetShadow(HTRadioTD[5], 0);
    TextDrawSetOutline(HTRadioTD[5], 0);
    TextDrawBackgroundColor(HTRadioTD[5], 255);
    TextDrawFont(HTRadioTD[5], 4);
    TextDrawSetProportional(HTRadioTD[5], 1);

    // [6] Screen bottom-left corner
    HTRadioTD[6] = TextDrawCreate(362.199, 338.700, "LD_BEAT:chit");
    TextDrawTextSize(HTRadioTD[6], 28.100, 31.000);
    TextDrawAlignment(HTRadioTD[6], 1);
    TextDrawColor(HTRadioTD[6], 598910975);
    TextDrawSetShadow(HTRadioTD[6], 0);
    TextDrawSetOutline(HTRadioTD[6], 0);
    TextDrawBackgroundColor(HTRadioTD[6], 255);
    TextDrawFont(HTRadioTD[6], 4);
    TextDrawSetProportional(HTRadioTD[6], 1);

    // [7] Screen main area
    HTRadioTD[7] = TextDrawCreate(375.700, 343.998, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[7], 75.000, 84.000);
    TextDrawAlignment(HTRadioTD[7], 1);
    TextDrawColor(HTRadioTD[7], 598910975);
    TextDrawSetShadow(HTRadioTD[7], 0);
    TextDrawSetOutline(HTRadioTD[7], 0);
    TextDrawBackgroundColor(HTRadioTD[7], 255);
    TextDrawFont(HTRadioTD[7], 4);
    TextDrawSetProportional(HTRadioTD[7], 1);

    // [8] Antenna base
    HTRadioTD[8] = TextDrawCreate(434.000, 313.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[8], 20.000, 13.000);
    TextDrawAlignment(HTRadioTD[8], 1);
    TextDrawColor(HTRadioTD[8], 168430335);
    TextDrawSetShadow(HTRadioTD[8], 0);
    TextDrawSetOutline(HTRadioTD[8], 0);
    TextDrawBackgroundColor(HTRadioTD[8], 255);
    TextDrawFont(HTRadioTD[8], 4);
    TextDrawSetProportional(HTRadioTD[8], 1);

    // [9] Antenna base rounded
    HTRadioTD[9] = TextDrawCreate(428.997, 303.299, "LD_BEAT:chit");
    TextDrawTextSize(HTRadioTD[9], 30.100, 22.000);
    TextDrawAlignment(HTRadioTD[9], 1);
    TextDrawColor(HTRadioTD[9], 168430335);
    TextDrawSetShadow(HTRadioTD[9], 0);
    TextDrawSetOutline(HTRadioTD[9], 0);
    TextDrawBackgroundColor(HTRadioTD[9], 255);
    TextDrawFont(HTRadioTD[9], 4);
    TextDrawSetProportional(HTRadioTD[9], 1);

    // [10] Antenna shaft
    HTRadioTD[10] = TextDrawCreate(435.200, 238.399, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[10], 17.698, 76.000);
    TextDrawAlignment(HTRadioTD[10], 1);
    TextDrawColor(HTRadioTD[10], 168430335);
    TextDrawSetShadow(HTRadioTD[10], 0);
    TextDrawSetOutline(HTRadioTD[10], 0);
    TextDrawBackgroundColor(HTRadioTD[10], 255);
    TextDrawFont(HTRadioTD[10], 4);
    TextDrawSetProportional(HTRadioTD[10], 1);

    // [11] Antenna tip rounded
    HTRadioTD[11] = TextDrawCreate(430.697, 225.600, "LD_BEAT:chit");
    TextDrawTextSize(HTRadioTD[11], 26.500, 24.000);
    TextDrawAlignment(HTRadioTD[11], 1);
    TextDrawColor(HTRadioTD[11], 168430335);
    TextDrawSetShadow(HTRadioTD[11], 0);
    TextDrawSetOutline(HTRadioTD[11], 0);
    TextDrawBackgroundColor(HTRadioTD[11], 255);
    TextDrawFont(HTRadioTD[11], 4);
    TextDrawSetProportional(HTRadioTD[11], 1);

    // [12] Screen glow/shadow
    HTRadioTD[12] = TextDrawCreate(365.000, 343.000, "PARTICLE:lamp_shad_64");
    TextDrawTextSize(HTRadioTD[12], 94.000, 138.000);
    TextDrawAlignment(HTRadioTD[12], 1);
    TextDrawColor(HTRadioTD[12], -16777318);
    TextDrawSetShadow(HTRadioTD[12], 0);
    TextDrawSetOutline(HTRadioTD[12], 0);
    TextDrawBackgroundColor(HTRadioTD[12], 255);
    TextDrawFont(HTRadioTD[12], 4);
    TextDrawSetProportional(HTRadioTD[12], 1);

    // [13] Right knob base
    HTRadioTD[13] = TextDrawCreate(401.000, 308.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[13], 20.000, 18.000);
    TextDrawAlignment(HTRadioTD[13], 1);
    TextDrawColor(HTRadioTD[13], 168430335);
    TextDrawSetShadow(HTRadioTD[13], 0);
    TextDrawSetOutline(HTRadioTD[13], 0);
    TextDrawBackgroundColor(HTRadioTD[13], 255);
    TextDrawFont(HTRadioTD[13], 4);
    TextDrawSetProportional(HTRadioTD[13], 1);

    // [14] Right knob rounded
    HTRadioTD[14] = TextDrawCreate(395.997, 299.299, "LD_BEAT:chit");
    TextDrawTextSize(HTRadioTD[14], 30.100, 22.000);
    TextDrawAlignment(HTRadioTD[14], 1);
    TextDrawColor(HTRadioTD[14], 168430335);
    TextDrawSetShadow(HTRadioTD[14], 0);
    TextDrawSetOutline(HTRadioTD[14], 0);
    TextDrawBackgroundColor(HTRadioTD[14], 255);
    TextDrawFont(HTRadioTD[14], 4);
    TextDrawSetProportional(HTRadioTD[14], 1);

    // [15] Left knob base
    HTRadioTD[15] = TextDrawCreate(369.000, 319.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[15], 20.000, 13.000);
    TextDrawAlignment(HTRadioTD[15], 1);
    TextDrawColor(HTRadioTD[15], 168430335);
    TextDrawSetShadow(HTRadioTD[15], 0);
    TextDrawSetOutline(HTRadioTD[15], 0);
    TextDrawBackgroundColor(HTRadioTD[15], 255);
    TextDrawFont(HTRadioTD[15], 4);
    TextDrawSetProportional(HTRadioTD[15], 1);

    // [16] Left knob rounded
    HTRadioTD[16] = TextDrawCreate(363.997, 311.299, "LD_BEAT:chit");
    TextDrawTextSize(HTRadioTD[16], 30.100, 22.000);
    TextDrawAlignment(HTRadioTD[16], 1);
    TextDrawColor(HTRadioTD[16], 168430335);
    TextDrawSetShadow(HTRadioTD[16], 0);
    TextDrawSetOutline(HTRadioTD[16], 0);
    TextDrawBackgroundColor(HTRadioTD[16], 255);
    TextDrawFont(HTRadioTD[16], 4);
    TextDrawSetProportional(HTRadioTD[16], 1);

    // [17] PTT button
    HTRadioTD[17] = TextDrawCreate(439.000, 350.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[17], 9.000, 6.000);
    TextDrawAlignment(HTRadioTD[17], 1);
    TextDrawColor(HTRadioTD[17], -1);
    TextDrawSetShadow(HTRadioTD[17], 0);
    TextDrawSetOutline(HTRadioTD[17], 0);
    TextDrawBackgroundColor(HTRadioTD[17], 255);
    TextDrawFont(HTRadioTD[17], 4);
    TextDrawSetProportional(HTRadioTD[17], 1);

    // [18] Detail line 1
    HTRadioTD[18] = TextDrawCreate(448.200, 351.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[18], 1.600, 4.000);
    TextDrawAlignment(HTRadioTD[18], 1);
    TextDrawColor(HTRadioTD[18], -1);
    TextDrawSetShadow(HTRadioTD[18], 0);
    TextDrawSetOutline(HTRadioTD[18], 0);
    TextDrawBackgroundColor(HTRadioTD[18], 255);
    TextDrawFont(HTRadioTD[18], 4);
    TextDrawSetProportional(HTRadioTD[18], 1);

    // [19] Detail line 2
    HTRadioTD[19] = TextDrawCreate(375.200, 350.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[19], 1.600, 5.000);
    TextDrawAlignment(HTRadioTD[19], 1);
    TextDrawColor(HTRadioTD[19], -1);
    TextDrawSetShadow(HTRadioTD[19], 0);
    TextDrawSetOutline(HTRadioTD[19], 0);
    TextDrawBackgroundColor(HTRadioTD[19], 255);
    TextDrawFont(HTRadioTD[19], 4);
    TextDrawSetProportional(HTRadioTD[19], 1);

    // [20] Detail line 3
    HTRadioTD[20] = TextDrawCreate(378.200, 349.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[20], 1.600, 6.000);
    TextDrawAlignment(HTRadioTD[20], 1);
    TextDrawColor(HTRadioTD[20], -1);
    TextDrawSetShadow(HTRadioTD[20], 0);
    TextDrawSetOutline(HTRadioTD[20], 0);
    TextDrawBackgroundColor(HTRadioTD[20], 255);
    TextDrawFont(HTRadioTD[20], 4);
    TextDrawSetProportional(HTRadioTD[20], 1);

    // [21] Detail dot
    HTRadioTD[21] = TextDrawCreate(371.200, 352.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[21], 2.599, 3.000);
    TextDrawAlignment(HTRadioTD[21], 1);
    TextDrawColor(HTRadioTD[21], -1);
    TextDrawSetShadow(HTRadioTD[21], 0);
    TextDrawSetOutline(HTRadioTD[21], 0);
    TextDrawBackgroundColor(HTRadioTD[21], 255);
    TextDrawFont(HTRadioTD[21], 4);
    TextDrawSetProportional(HTRadioTD[21], 1);

    // [22] LED indicator bar
    HTRadioTD[22] = TextDrawCreate(368.000, 329.500, "LD_SPAC:white");
    TextDrawTextSize(HTRadioTD[22], 90.000, 4.000);
    TextDrawAlignment(HTRadioTD[22], 1);
    TextDrawColor(HTRadioTD[22], 421075455);
    TextDrawSetShadow(HTRadioTD[22], 0);
    TextDrawSetOutline(HTRadioTD[22], 0);
    TextDrawBackgroundColor(HTRadioTD[22], 255);
    TextDrawFont(HTRadioTD[22], 4);
    TextDrawSetProportional(HTRadioTD[22], 1);

    printf("[HT Radio] Global TextDraws loaded (%d elements).", HT_RADIO_TD_COUNT);
}

stock DestroyHTRadioTextDraws()
{
    for(new i = 0; i < HT_RADIO_TD_COUNT; i++)
    {
        if(HTRadioTD[i] != Text:INVALID_TEXT_DRAW)
        {
            TextDrawDestroy(HTRadioTD[i]);
            HTRadioTD[i] = Text:INVALID_TEXT_DRAW;
        }
    }
}

// ============================================================================
// PLAYER TEXTDRAWS (dynamic frequency + status display on radio screen)
// ============================================================================

stock CreateHTPlayerTDs(playerid)
{
    // Frequency text — centered on radio screen area
    // Screen area is roughly X: 375-450, Y: 344-428
    ptdHTFreqText[playerid] = CreatePlayerTextDraw(playerid, 413.0, 365.0, "000.0 MHz");
    PlayerTextDrawAlignment(playerid, ptdHTFreqText[playerid], 2); // center
    PlayerTextDrawFont(playerid, ptdHTFreqText[playerid], 2);
    PlayerTextDrawLetterSize(playerid, ptdHTFreqText[playerid], 0.28, 1.4);
    PlayerTextDrawColor(playerid, ptdHTFreqText[playerid], 0x00FF00FF); // green LCD
    PlayerTextDrawSetShadow(playerid, ptdHTFreqText[playerid], 0);
    PlayerTextDrawSetOutline(playerid, ptdHTFreqText[playerid], 0);
    PlayerTextDrawBackgroundColor(playerid, ptdHTFreqText[playerid], 0);

    // Status text (ON/OFF)
    ptdHTStatusText[playerid] = CreatePlayerTextDraw(playerid, 413.0, 348.0, "OFF");
    PlayerTextDrawAlignment(playerid, ptdHTStatusText[playerid], 2);
    PlayerTextDrawFont(playerid, ptdHTStatusText[playerid], 2);
    PlayerTextDrawLetterSize(playerid, ptdHTStatusText[playerid], 0.18, 0.9);
    PlayerTextDrawColor(playerid, ptdHTStatusText[playerid], 0xFF4444FF); // red = off
    PlayerTextDrawSetShadow(playerid, ptdHTStatusText[playerid], 0);
    PlayerTextDrawSetOutline(playerid, ptdHTStatusText[playerid], 0);
    PlayerTextDrawBackgroundColor(playerid, ptdHTStatusText[playerid], 0);

    // Channel label
    ptdHTChannelText[playerid] = CreatePlayerTextDraw(playerid, 413.0, 385.0, "CH: -");
    PlayerTextDrawAlignment(playerid, ptdHTChannelText[playerid], 2);
    PlayerTextDrawFont(playerid, ptdHTChannelText[playerid], 2);
    PlayerTextDrawLetterSize(playerid, ptdHTChannelText[playerid], 0.17, 0.8);
    PlayerTextDrawColor(playerid, ptdHTChannelText[playerid], 0x00FF00FF);
    PlayerTextDrawSetShadow(playerid, ptdHTChannelText[playerid], 0);
    PlayerTextDrawSetOutline(playerid, ptdHTChannelText[playerid], 0);
    PlayerTextDrawBackgroundColor(playerid, ptdHTChannelText[playerid], 0);
}

stock DestroyHTPlayerTDs(playerid)
{
    if(ptdHTFreqText[playerid] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, ptdHTFreqText[playerid]);
        ptdHTFreqText[playerid] = INVALID_PLAYER_TD;
    }
    if(ptdHTStatusText[playerid] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, ptdHTStatusText[playerid]);
        ptdHTStatusText[playerid] = INVALID_PLAYER_TD;
    }
    if(ptdHTChannelText[playerid] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, ptdHTChannelText[playerid]);
        ptdHTChannelText[playerid] = INVALID_PLAYER_TD;
    }
}

stock ResetHTRadio(playerid)
{
    PlayerInfo[playerid][pHTActive] = false;
    PlayerInfo[playerid][pHTFreq] = 0.0;
    PlayerInfo[playerid][pHTUIShown] = false;
    DestroyHTPlayerTDs(playerid);
}

// ============================================================================
// SHOW / HIDE RADIO UI
// ============================================================================

stock ShowHTRadioUI(playerid)
{
    if(PlayerInfo[playerid][pHTUIShown]) return 0;

    // Show global radio body TDs
    for(new i = 0; i < HT_RADIO_TD_COUNT; i++)
        TextDrawShowForPlayer(playerid, HTRadioTD[i]);

    // Create + show player TDs
    CreateHTPlayerTDs(playerid);
    UpdateHTDisplay(playerid);

    PlayerTextDrawShow(playerid, ptdHTFreqText[playerid]);
    PlayerTextDrawShow(playerid, ptdHTStatusText[playerid]);
    PlayerTextDrawShow(playerid, ptdHTChannelText[playerid]);

    PlayerInfo[playerid][pHTUIShown] = true;
    return 1;
}

stock HideHTRadioUI(playerid)
{
    if(!PlayerInfo[playerid][pHTUIShown]) return 0;

    // Hide global radio body TDs
    for(new i = 0; i < HT_RADIO_TD_COUNT; i++)
        TextDrawHideForPlayer(playerid, HTRadioTD[i]);

    // Destroy player TDs
    DestroyHTPlayerTDs(playerid);

    PlayerInfo[playerid][pHTUIShown] = false;
    return 1;
}

stock UpdateHTDisplay(playerid)
{
    if(!PlayerInfo[playerid][pHTUIShown]) return 0;

    // Update status
    if(PlayerInfo[playerid][pHTActive])
    {
        PlayerTextDrawSetString(playerid, ptdHTStatusText[playerid], "~g~ON");
        PlayerTextDrawColor(playerid, ptdHTStatusText[playerid], 0x00FF00FF);
    }
    else
    {
        PlayerTextDrawSetString(playerid, ptdHTStatusText[playerid], "~r~OFF");
        PlayerTextDrawColor(playerid, ptdHTStatusText[playerid], 0xFF4444FF);
    }
    PlayerTextDrawShow(playerid, ptdHTStatusText[playerid]);

    // Update frequency
    if(PlayerInfo[playerid][pHTFreq] > 0.0)
    {
        new freqStr[24];
        format(freqStr, sizeof(freqStr), "%.1f MHz", PlayerInfo[playerid][pHTFreq]);
        PlayerTextDrawSetString(playerid, ptdHTFreqText[playerid], freqStr);

        new chStr[16];
        format(chStr, sizeof(chStr), "CH: 1");
        PlayerTextDrawSetString(playerid, ptdHTChannelText[playerid], chStr);
    }
    else
    {
        PlayerTextDrawSetString(playerid, ptdHTFreqText[playerid], "--- MHz");
        PlayerTextDrawSetString(playerid, ptdHTChannelText[playerid], "CH: -");
    }
    PlayerTextDrawShow(playerid, ptdHTFreqText[playerid]);
    PlayerTextDrawShow(playerid, ptdHTChannelText[playerid]);
    return 1;
}

// ============================================================================
// HELPER: Check if player has HT Radio in inventory
// ============================================================================

stock PlayerHasHTRadio(playerid)
{
    new maxslots = GetMaxSlots(playerid);
    for(new i = 0; i < maxslots; i++)
    {
        if(PlayerInfo[playerid][pInvItems][i] == ITEM_HT_RADIO)
            return 1;
    }
    return 0;
}

// ============================================================================
// COMMANDS
// ============================================================================

// /ht — Toggle radio ON/OFF + show/hide UI
COMMAND:ht(playerid, params[])
{
    if(PlayerInfo[playerid][pIsDead])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan!"), true;

    if(!PlayerHasHTRadio(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak punya HT Radio! Beli di Market."), true;

    // Toggle
    if(PlayerInfo[playerid][pHTUIShown])
    {
        // If radio is shown, hide UI
        HideHTRadioUI(playerid);
        SendClientFormattedMessage(playerid, COLOR_RADIO, "[HT] Radio disimpan.");
    }
    else
    {
        // Show UI
        ShowHTRadioUI(playerid);
        SendClientFormattedMessage(playerid, COLOR_RADIO, "[HT] Radio ditampilkan. Gunakan /setfreq untuk atur frekuensi.");
    }
    return true;
}

// /setfreq [channel] [frequency] — Set radio frequency
COMMAND:setfreq(playerid, params[])
{
    if(PlayerInfo[playerid][pIsDead])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan!"), true;

    if(!PlayerHasHTRadio(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak punya HT Radio!"), true;

    new channel;
    new Float:freq;
    if(sscanf(params, "df", channel, freq))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setfreq [channel] [frekuensi]  Contoh: /setfreq 1 450.5"), true;

    if(channel != 1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Channel hanya tersedia: 1"), true;

    if(freq < MIN_HT_FREQ || freq > MAX_HT_FREQ)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Frekuensi harus antara %.1f - %.1f!", MIN_HT_FREQ, MAX_HT_FREQ);
        return true;
    }

    // Round to 1 decimal place
    freq = floatround(freq * 10.0, floatround_round) / 10.0;

    PlayerInfo[playerid][pHTFreq] = freq;
    PlayerInfo[playerid][pHTActive] = true;

    // Update display if UI is shown
    UpdateHTDisplay(playerid);

    // RP action
    new rptext[80];
    format(rptext, sizeof(rptext), "* %s mengatur frekuensi HT ke %.1f MHz.", PlayerInfo[playerid][pICName], freq);
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    SendClientFormattedMessage(playerid, COLOR_RADIO, "[HT] Frekuensi diatur ke %.1f MHz. Radio aktif.", freq);
    return true;
}

// /r [message] — Talk on radio
COMMAND:r(playerid, params[])
{
    if(PlayerInfo[playerid][pIsDead])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan!"), true;

    if(!PlayerHasHTRadio(playerid))
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak punya HT Radio!"), true;

    if(!PlayerInfo[playerid][pHTActive])
        return SendClientFormattedMessage(playerid, COLOR_RED, "[HT] Radio belum aktif! Gunakan /setfreq untuk mengaktifkan."), true;

    if(PlayerInfo[playerid][pHTFreq] <= 0.0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "[HT] Belum ada frekuensi yang diatur! Gunakan /setfreq."), true;

    if(!strlen(params))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /r [pesan]"), true;

    new Float:senderFreq = PlayerInfo[playerid][pHTFreq];

    // Format radio message
    new radioMsg[144];
    format(radioMsg, sizeof(radioMsg), "[Radio %.1f] %s: %s", senderFreq, PlayerInfo[playerid][pICName], params);

    // Send to all players on same frequency
    new count = 0;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(!PlayerInfo[i][pHTActive]) continue;
        if(PlayerInfo[i][pHTFreq] != senderFreq) continue;
        // Frequency match check with tolerance (floating point)
        // Already rounded to 1 decimal so direct compare is fine

        SendClientMessage(i, COLOR_RADIO, radioMsg);
        count++;
    }

    // RP action — people nearby can see player talking into radio (but NOT the message content)
    new rpaction[80];
    format(rpaction, sizeof(rpaction), "* %s berbicara ke dalam HT Radio.", PlayerInfo[playerid][pICName]);
    ProxDetector(10.0, playerid, rpaction, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    // Chat bubble with static text (not the actual message)
    SetPlayerChatBubble(playerid, "*berbicara di radio*", COLOR_RP, 10.0, 3000);
    return true;
}
