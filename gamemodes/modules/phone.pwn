// ============================================================================
// MODULE: phone.pwn
// Core phone system: Slim Android-style UI with in-phone TextDraw content
// Key: N (KEY_NO) to toggle phone
// All app content rendered inside phone frame via TextDraws
// ============================================================================

stock GeneratePhoneNumber(output[], maxlen)
{
    new num = 80000000 + random(19999999);
    format(output, maxlen, "08%d", num);
}

stock GenerateBankAccountNumber(output[], maxlen)
{
    new p1 = 10000 + random(89999);
    new p2 = 10000 + random(89999);
    format(output, maxlen, "%d%d", p1, p2);
}

stock FormatKuota(kuota_kb, output[], maxlen)
{
    if(kuota_kb >= 1048576)
        format(output, maxlen, "%.1fGB", float(kuota_kb) / 1048576.0);
    else if(kuota_kb >= 1024)
        format(output, maxlen, "%dMB", kuota_kb / 1024);
    else
        format(output, maxlen, "%dKB", kuota_kb);
}

stock UseKuota(playerid, amount)
{
    if(PlayerInfo[playerid][pKuota] < amount)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kuota internet habis! Beli kuota di M-Bank.");
        return 0;
    }
    PlayerInfo[playerid][pKuota] -= amount;
    UpdatePhoneStatusBar(playerid);
    return 1;
}

stock UpdatePhoneStatusBar(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return;
    if(PlayerInfo[playerid][ptdPhoneStatusTxt] == INVALID_PLAYER_TD) return;

    new hour, minute, second;
    gettime(hour, minute, second);
    new kuotaStr[16];
    FormatKuota(PlayerInfo[playerid][pKuota], kuotaStr, sizeof(kuotaStr));
    new statusTxt[64];
    format(statusTxt, sizeof(statusTxt), "III %02d:%02d  4G  %s", hour, minute, kuotaStr);
    PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdPhoneStatusTxt], statusTxt);
}

publics: OnKuotaBrowseTick(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) { StopKuotaTimer(playerid); return 1; }
    if(PlayerInfo[playerid][pPhoneScreen] == PHONE_SCREEN_HOME) { StopKuotaTimer(playerid); return 1; }

    if(PlayerInfo[playerid][pKuota] < KUOTA_BROWSE_AMOUNT)
    {
        PlayerInfo[playerid][pKuota] = 0;
        UpdatePhoneStatusBar(playerid);
        SendClientFormattedMessage(playerid, COLOR_RED, "Kuota habis! Beli kuota di M-Bank.");
        ShowHomeScreen(playerid);
        StopKuotaTimer(playerid);
        return 1;
    }

    PlayerInfo[playerid][pKuota] -= KUOTA_BROWSE_AMOUNT;
    UpdatePhoneStatusBar(playerid);
    return 1;
}

stock StartKuotaTimer(playerid)
{
    if(PlayerInfo[playerid][pKuotaTimer] != 0) return;
    PlayerInfo[playerid][pKuotaTimer] = SetTimerEx("OnKuotaBrowseTick", KUOTA_BROWSE_INTERVAL, true, "d", playerid);
}

stock StopKuotaTimer(playerid)
{
    if(PlayerInfo[playerid][pKuotaTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pKuotaTimer]);
        PlayerInfo[playerid][pKuotaTimer] = 0;
    }
}

// ============================================================================
// OPEN PHONE — Create all TextDraws (home + app content, app TDs hidden)
// ============================================================================

stock OpenPhone(playerid)
{
    if(!PlayerInfo[playerid][pLogged] || PlayerInfo[playerid][pIsDead]) return 0;
    if(PlayerInfo[playerid][pInvOpen]) return 0;
    if(PlayerInfo[playerid][pPhoneOpen]) { ClosePhone(playerid); return 0; }

    PlayerInfo[playerid][pPhoneOpen] = true;
    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_NONE;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_HOME;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    new Float:centerX = PHONE_FRAME_X + PHONE_FRAME_W / 2.0;

    // ---- 1. PHONE FRAME (outer body) ----
    PlayerInfo[playerid][ptdPhoneFrame] = CreatePlayerTextDraw(playerid, PHONE_FRAME_X, PHONE_FRAME_Y, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneFrame], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneFrame], PHONE_COLOR_FRAME);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneFrame], PHONE_FRAME_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneFrame], 0.0, 29.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneFrame], 0);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneFrame], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneFrame]);

    // ---- 2. SPEAKER GRILL ----
    PlayerInfo[playerid][ptdPhoneSpeaker] = CreatePlayerTextDraw(playerid, centerX, PHONE_FRAME_Y + 3.0, "______");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneSpeaker], 1);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneSpeaker], 0.10, 0.3);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneSpeaker], 0x444444FF);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneSpeaker], 2);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneSpeaker], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneSpeaker], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneSpeaker]);

    // ---- 3. NOTCH / CAMERA ----
    PlayerInfo[playerid][ptdPhoneNotch] = CreatePlayerTextDraw(playerid, centerX + 18.0, PHONE_FRAME_Y + 3.0, "o");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneNotch], 1);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneNotch], 0.10, 0.4);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneNotch], 0x333333FF);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneNotch], 2);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneNotch], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneNotch], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneNotch]);

    // ---- 4. INNER SCREEN (dark bg) ----
    PlayerInfo[playerid][ptdPhoneBG] = CreatePlayerTextDraw(playerid, PHONE_X, PHONE_Y, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneBG], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneBG], PHONE_COLOR_BG);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneBG], PHONE_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneBG], 0.0, 26.7);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneBG], 0);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneBG], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneBG]);

    // ---- 5. STATUS BAR ----
    PlayerInfo[playerid][ptdPhoneStatus] = CreatePlayerTextDraw(playerid, PHONE_X, PHONE_Y, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneStatus], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneStatus], PHONE_COLOR_STATUS);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneStatus], PHONE_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneStatus], 0.0, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneStatus], 0);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneStatus], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneStatus]);

    new hour, minute, second;
    gettime(hour, minute, second);
    new kuotaStr[16];
    FormatKuota(PlayerInfo[playerid][pKuota], kuotaStr, sizeof(kuotaStr));
    new statusTxt[64];
    format(statusTxt, sizeof(statusTxt), "III %02d:%02d  4G  %s", hour, minute, kuotaStr);
    PlayerInfo[playerid][ptdPhoneStatusTxt] = CreatePlayerTextDraw(playerid, PHONE_X + 3.0, PHONE_Y + 1.0, statusTxt);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneStatusTxt], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneStatusTxt], 0.11, 0.7);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneStatusTxt], 0xAAAAAAFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneStatusTxt], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneStatusTxt], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneStatusTxt]);

    // ---- 6. WALLPAPER (home screen only) ----
    new Float:wpY = PHONE_Y + PHONE_STATUS_H;
    PlayerInfo[playerid][ptdPhoneWallpaper] = CreatePlayerTextDraw(playerid, PHONE_X, wpY, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneWallpaper], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneWallpaper], PHONE_COLOR_WALLPAPER);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneWallpaper], PHONE_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneWallpaper], 0.0, 23.6);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneWallpaper], 0);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneWallpaper], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneWallpaper]);

    // ---- 7. CLOCK + PHONE NUMBER (compact) ----
    new titlestr[64];
    new Float:titleCX = PHONE_X + PHONE_W / 2.0;
    format(titlestr, sizeof(titlestr), "%02d:%02d~n~~w~%s", hour, minute, PlayerInfo[playerid][pPhoneNumber]);
    PlayerInfo[playerid][ptdPhoneTitle] = CreatePlayerTextDraw(playerid, titleCX, PHONE_Y + 16.0, titlestr);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneTitle], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneTitle], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneTitle], 0.24, 1.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneTitle], PHONE_COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneTitle], 1);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneTitle], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneTitle]);

    // ---- 8. APP GRID (2x4) — Uniform colored boxes ----
    // Grid layout: 2 columns, 4 rows
    // Col1: left=502, right=542 (width=40), center=522
    // Col2: left=558, right=598 (width=40), center=578
    new Float:col1L = PHONE_X + 8.0;    // 502
    new Float:col1R = col1L + 40.0;     // 542
    new Float:col2L = col1R + 16.0;     // 558
    new Float:col2R = col2L + 40.0;     // 598
    new Float:col1C = col1L + 20.0;     // 522
    new Float:col2C = col2L + 20.0;     // 578

    new Float:row1Y = PHONE_Y + 48.0;
    new Float:row2Y = row1Y + 42.0;
    new Float:row3Y = row2Y + 42.0;
    new Float:row4Y = row3Y + 42.0;
    new Float:iconLH = 2.2;          // Box height via LetterSize Y (smaller for 4 rows)
    new Float:lblOff = 26.0;         // Label offset below icon

    // --- App 1: WitApp (green) ---
    PlayerInfo[playerid][ptdPhoneApp1] = CreatePlayerTextDraw(playerid, col1L, row1Y, "W");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp1], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp1], 1);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneApp1], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneApp1], 0x25D36688);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneApp1], col1R, 12.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp1], 0.32, iconLH);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp1], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp1], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneApp1], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp1]);

    PlayerInfo[playerid][ptdPhoneApp1Lbl] = CreatePlayerTextDraw(playerid, col1C, row1Y + lblOff, "WitApp");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl], 0.13, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl]);

    // --- App 2: Wittiter (blue) ---
    PlayerInfo[playerid][ptdPhoneApp2] = CreatePlayerTextDraw(playerid, col2L, row1Y, "WT");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp2], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp2], 1);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneApp2], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneApp2], 0x1DA1F288);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneApp2], col2R, 12.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp2], 0.32, iconLH);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp2], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp2], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneApp2], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp2]);

    PlayerInfo[playerid][ptdPhoneApp2Lbl] = CreatePlayerTextDraw(playerid, col2C, row1Y + lblOff, "Wittiter");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl], 0.13, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl]);

    // --- App 3: Market (orange) ---
    PlayerInfo[playerid][ptdPhoneApp3] = CreatePlayerTextDraw(playerid, col1L, row2Y, "MP");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp3], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp3], 1);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneApp3], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneApp3], 0xFF980088);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneApp3], col1R, 12.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp3], 0.32, iconLH);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp3], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp3], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneApp3], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp3]);

    PlayerInfo[playerid][ptdPhoneApp3Lbl] = CreatePlayerTextDraw(playerid, col1C, row2Y + lblOff, "Market");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl], 0.13, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl]);

    // --- App 4: M-Bank (purple) ---
    PlayerInfo[playerid][ptdPhoneApp4] = CreatePlayerTextDraw(playerid, col2L, row2Y, "MB");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp4], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp4], 1);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneApp4], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneApp4], 0x7C4DFF88);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneApp4], col2R, 12.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp4], 0.32, iconLH);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp4], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp4], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneApp4], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp4]);

    PlayerInfo[playerid][ptdPhoneApp4Lbl] = CreatePlayerTextDraw(playerid, col2C, row2Y + lblOff, "M-Bank");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl], 0.13, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl]);

    // --- App 5: GPS (red) ---
    PlayerInfo[playerid][ptdPhoneApp5] = CreatePlayerTextDraw(playerid, col1L, row3Y, "GPS");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp5], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp5], 1);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneApp5], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneApp5], 0xF4433688);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneApp5], col1R, 12.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp5], 0.32, iconLH);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp5], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp5], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneApp5], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp5]);

    PlayerInfo[playerid][ptdPhoneApp5Lbl] = CreatePlayerTextDraw(playerid, col1C, row3Y + lblOff, "GPS");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl], 0.13, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl]);

    // --- App 6: Settings (gray) ---
    PlayerInfo[playerid][ptdPhoneApp6] = CreatePlayerTextDraw(playerid, col2L, row3Y, "SET");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp6], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp6], 1);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneApp6], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneApp6], 0x607D8B88);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneApp6], col2R, 12.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp6], 0.32, iconLH);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp6], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp6], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneApp6], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp6]);

    PlayerInfo[playerid][ptdPhoneApp6Lbl] = CreatePlayerTextDraw(playerid, col2C, row3Y + lblOff, "Setelan");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl], 0.13, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl]);

    // --- App 7: Notepad (yellow) ---
    PlayerInfo[playerid][ptdPhoneApp7] = CreatePlayerTextDraw(playerid, col1L, row4Y, "NP");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp7], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp7], 1);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneApp7], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneApp7], 0xFFC10788);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneApp7], col1R, 12.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp7], 0.32, iconLH);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp7], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp7], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneApp7], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp7]);

    PlayerInfo[playerid][ptdPhoneApp7Lbl] = CreatePlayerTextDraw(playerid, col1C, row4Y + lblOff, "Notepad");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl], 0.13, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl]);

    // --- App 8: (empty/future) ---
    PlayerInfo[playerid][ptdPhoneApp8] = CreatePlayerTextDraw(playerid, col2L, row4Y, " ");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp8], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp8], 1);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneApp8], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneApp8], 0x33333388);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneApp8], col2R, 12.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp8], 0.32, iconLH);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp8], 0x666666FF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp8], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp8]);

    PlayerInfo[playerid][ptdPhoneApp8Lbl] = CreatePlayerTextDraw(playerid, col2C, row4Y + lblOff, " ");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl], 0.13, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl]);

    // --- Badge TDs (WA=1, Twitter=2) — small red circle at top-right of icon ---
    PlayerInfo[playerid][ptdBadge1] = CreatePlayerTextDraw(playerid, col1R - 2.0, row1Y - 2.0, " ");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdBadge1], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdBadge1], 2);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdBadge1], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdBadge1], 0xFF2222EE);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdBadge1], col1R + 6.0, 8.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdBadge1], 0.12, 0.6);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdBadge1], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdBadge1], 0);
    if(PlayerInfo[playerid][pBadgeWA] > 0)
    {
        new bstr[4];
        format(bstr, sizeof(bstr), "%d", PlayerInfo[playerid][pBadgeWA]);
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdBadge1], bstr);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdBadge1]);
    }

    PlayerInfo[playerid][ptdBadge2] = CreatePlayerTextDraw(playerid, col2R - 2.0, row1Y - 2.0, " ");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdBadge2], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdBadge2], 2);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdBadge2], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdBadge2], 0xFF2222EE);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdBadge2], col2R + 6.0, 8.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdBadge2], 0.12, 0.6);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdBadge2], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdBadge2], 0);
    if(PlayerInfo[playerid][pBadgeTW] > 0)
    {
        new bstr[4];
        format(bstr, sizeof(bstr), "%d", PlayerInfo[playerid][pBadgeTW]);
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdBadge2], bstr);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdBadge2]);
    }

    // ---- 9. BOTTOM NAV BAR ----
    new Float:navY = PHONE_Y + PHONE_H - PHONE_NAV_H;
    PlayerInfo[playerid][ptdPhoneNav] = CreatePlayerTextDraw(playerid, PHONE_X, navY, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdPhoneNav], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdPhoneNav], PHONE_COLOR_NAV);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneNav], PHONE_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneNav], 0.0, 1.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneNav], 0);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneNav], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneNav]);

    // ---- 10. NAV BUTTONS: Back | Home | Recent ----
    new Float:navBtnY = navY + 1.0;
    new Float:navThird = PHONE_W / 3.0;

    PlayerInfo[playerid][ptdPhoneBack] = CreatePlayerTextDraw(playerid, PHONE_X + navThird / 2.0, navBtnY, "~w~<");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneBack], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneBack], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneBack], 0.22, 1.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneBack], 0x888888FF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneBack], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneBack], 0);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneBack], 12.0, 30.0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneBack], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneBack]);

    PlayerInfo[playerid][ptdPhoneHome] = CreatePlayerTextDraw(playerid, PHONE_X + PHONE_W / 2.0, navBtnY, "~w~O");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneHome], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneHome], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneHome], 0.22, 1.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneHome], 0x888888FF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneHome], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneHome], 0);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneHome], 12.0, 30.0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneHome], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneHome]);

    PlayerInfo[playerid][ptdPhoneRecent] = CreatePlayerTextDraw(playerid, PHONE_X + PHONE_W - navThird / 2.0, navBtnY, "~w~=");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdPhoneRecent], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdPhoneRecent], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdPhoneRecent], 0.22, 1.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdPhoneRecent], 0x888888FF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdPhoneRecent], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdPhoneRecent], 0);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdPhoneRecent], 12.0, 30.0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdPhoneRecent], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneRecent]);

    // ---- 11. APP CONTENT TDs (created hidden) ----
    CreateAppContentTDs(playerid);

    SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    return 1;
}

// ============================================================================
// CREATE APP CONTENT TDs (hidden initially)
// ============================================================================

stock CreateAppContentTDs(playerid)
{
    PlayerInfo[playerid][ptdAppHeader] = CreatePlayerTextDraw(playerid, PHONE_X, PHONE_APP_HDR_Y, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdAppHeader], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdAppHeader], PHONE_COLOR_HEADER);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdAppHeader], PHONE_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdAppHeader], 0.0, 1.4);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdAppHeader], 0);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdAppHeader], 0);

    PlayerInfo[playerid][ptdAppTitle] = CreatePlayerTextDraw(playerid, PHONE_X + 4.0, PHONE_APP_HDR_Y + 2.0, "App");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdAppTitle], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdAppTitle], 0.19, 1.1);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdAppTitle], PHONE_COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdAppTitle], 0);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdAppTitle], 0);

    for(new i = 0; i < MAX_APP_LINES; i++)
    {
        new Float:lineY = PHONE_APP_LINE_START + (PHONE_APP_LINE_GAP * float(i));
        PhoneAppLines[playerid][i] = CreatePlayerTextDraw(playerid, PHONE_X + 2.0, lineY, " ");
        PlayerTextDrawUseBox(playerid, PhoneAppLines[playerid][i], 1);
        PlayerTextDrawBoxColor(playerid, PhoneAppLines[playerid][i], PHONE_COLOR_LINE_BG);
        PlayerTextDrawTextSize(playerid, PhoneAppLines[playerid][i], PHONE_X_END - 2.0, 12.0);
        PlayerTextDrawFont(playerid, PhoneAppLines[playerid][i], 2);
        PlayerTextDrawLetterSize(playerid, PhoneAppLines[playerid][i], 0.16, 1.5);
        PlayerTextDrawColor(playerid, PhoneAppLines[playerid][i], PHONE_COLOR_TEXT);
        PlayerTextDrawSetShadow(playerid, PhoneAppLines[playerid][i], 0);
        PlayerTextDrawSetOutline(playerid, PhoneAppLines[playerid][i], 0);
        PlayerTextDrawSetSelectable(playerid, PhoneAppLines[playerid][i], 1);
    }

    PlayerInfo[playerid][ptdAppScrollUp] = CreatePlayerTextDraw(playerid, PHONE_X_END - 14.0, PHONE_APP_HDR_Y + 2.0, "~w~^");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdAppScrollUp], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdAppScrollUp], 0.18, 1.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdAppScrollUp], 0x888888FF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdAppScrollUp], 0);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdAppScrollUp], 10.0, 14.0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdAppScrollUp], 1);

    new Float:scrollDnY = PHONE_APP_LINE_START + (PHONE_APP_LINE_GAP * float(MAX_APP_LINES)) + 2.0;
    PlayerInfo[playerid][ptdAppScrollDn] = CreatePlayerTextDraw(playerid, PHONE_X_END - 14.0, scrollDnY, "~w~v");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdAppScrollDn], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdAppScrollDn], 0.18, 1.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdAppScrollDn], 0x888888FF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdAppScrollDn], 0);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdAppScrollDn], 10.0, 14.0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdAppScrollDn], 1);

    new Float:btnW = PHONE_W / 2.0 - 4.0;
    PlayerInfo[playerid][ptdAppBtn1] = CreatePlayerTextDraw(playerid, PHONE_X + 2.0, PHONE_APP_BTN_Y, "Btn1");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdAppBtn1], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdAppBtn1], 0x333333CC);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdAppBtn1], PHONE_X + 2.0 + btnW, 10.0);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdAppBtn1], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdAppBtn1], 0.16, 1.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdAppBtn1], PHONE_COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdAppBtn1], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdAppBtn1], 1);

    PlayerInfo[playerid][ptdAppBtn2] = CreatePlayerTextDraw(playerid, PHONE_X + PHONE_W / 2.0 + 2.0, PHONE_APP_BTN_Y, "Btn2");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdAppBtn2], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdAppBtn2], 0x333333CC);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdAppBtn2], PHONE_X_END - 2.0, 10.0);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdAppBtn2], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdAppBtn2], 0.16, 1.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdAppBtn2], PHONE_COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdAppBtn2], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdAppBtn2], 1);
}

// ============================================================================
// SHOW/HIDE SCREENS
// ============================================================================

stock ShowHomeScreen(playerid)
{
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_HOME;
    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_NONE;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    StopKuotaTimer(playerid);

    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneWallpaper]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneTitle]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp1]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp2]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp3]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp4]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp5]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp6]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp7]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp8]);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl]);

    // Show badges if > 0
    if(PlayerInfo[playerid][pBadgeWA] > 0)
    {
        new bstr[4];
        format(bstr, sizeof(bstr), "%d", PlayerInfo[playerid][pBadgeWA]);
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdBadge1], bstr);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdBadge1]);
    }
    else PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdBadge1]);

    if(PlayerInfo[playerid][pBadgeTW] > 0)
    {
        new bstr[4];
        format(bstr, sizeof(bstr), "%d", PlayerInfo[playerid][pBadgeTW]);
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdBadge2], bstr);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdBadge2]);
    }
    else PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdBadge2]);

    HideAllAppContent(playerid);
}

stock HideHomeElements(playerid)
{
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneWallpaper]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneTitle]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp1]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp2]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp3]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp4]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp5]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp6]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp7]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp8]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdBadge1]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdBadge2]);
}

stock HideAllAppContent(playerid)
{
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppHeader]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppTitle]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppScrollUp]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppScrollDn]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppBtn1]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppBtn2]);
    for(new i = 0; i < MAX_APP_LINES; i++)
        PlayerTextDrawHide(playerid, PhoneAppLines[playerid][i]);
}

// ============================================================================
// APP SCREEN FRAMEWORK
// ============================================================================

stock ShowAppScreen(playerid, headerColor, title[])
{
    HideHomeElements(playerid);
    HideAllAppContent(playerid);

    StartKuotaTimer(playerid);

    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdAppHeader], headerColor);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdAppHeader]);

    PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdAppTitle], title);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdAppTitle]);
}

stock SetAppLine(playerid, lineIdx, text[])
{
    if(lineIdx < 0 || lineIdx >= MAX_APP_LINES) return;
    PlayerTextDrawSetString(playerid, PhoneAppLines[playerid][lineIdx], text);
    PlayerTextDrawShow(playerid, PhoneAppLines[playerid][lineIdx]);
}

stock HideAppLine(playerid, lineIdx)
{
    if(lineIdx < 0 || lineIdx >= MAX_APP_LINES) return;
    PlayerTextDrawHide(playerid, PhoneAppLines[playerid][lineIdx]);
}

stock ShowAppScroll(playerid, showUp, showDown)
{
    if(showUp) PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdAppScrollUp]);
    else PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppScrollUp]);

    if(showDown) PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdAppScrollDn]);
    else PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppScrollDn]);
}

stock ShowAppBtn(playerid, btnIdx, text[])
{
    if(btnIdx == 1)
    {
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdAppBtn1], text);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdAppBtn1]);
    }
    else if(btnIdx == 2)
    {
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdAppBtn2], text);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdAppBtn2]);
    }
}

stock HideAppBtns(playerid)
{
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppBtn1]);
    PlayerTextDrawHide(playerid, PlayerInfo[playerid][ptdAppBtn2]);
}

// ============================================================================
// CLOSE PHONE
// ============================================================================

stock ClosePhone(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    StopKuotaTimer(playerid);

    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneFrame]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneBG]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneStatus]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneStatusTxt]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneWallpaper]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneTitle]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp1]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp1Lbl]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp2]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp2Lbl]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp3]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp3Lbl]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp4]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp4Lbl]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp5]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp5Lbl]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp6]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp6Lbl]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp7]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp7Lbl]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp8]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneApp8Lbl]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdBadge1]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdBadge2]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneNav]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneBack]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneHome]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneRecent]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneSpeaker]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdPhoneNotch]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdAppHeader]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdAppTitle]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdAppScrollUp]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdAppScrollDn]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdAppBtn1]);
    DestroyPhoneTD(playerid, PlayerInfo[playerid][ptdAppBtn2]);

    for(new i = 0; i < MAX_APP_LINES; i++)
    {
        if(PhoneAppLines[playerid][i] != INVALID_PLAYER_TD)
        {
            PlayerTextDrawDestroy(playerid, PhoneAppLines[playerid][i]);
            PhoneAppLines[playerid][i] = INVALID_PLAYER_TD;
        }
    }

    ResetPhoneTDs(playerid);
    PlayerInfo[playerid][pPhoneOpen] = false;
    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_NONE;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_HOME;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    CancelSelectTextDraw(playerid);
    return 1;
}

stock DestroyPhoneTD(playerid, &PlayerText:td)
{
    if(td != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, td);
        td = INVALID_PLAYER_TD;
    }
}

stock ResetPhoneTDs(playerid)
{
    PlayerInfo[playerid][ptdPhoneFrame] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneBG] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneStatus] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneStatusTxt] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneWallpaper] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneTitle] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp1] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp1Lbl] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp2] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp2Lbl] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp3] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp3Lbl] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp4] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp4Lbl] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp5] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp5Lbl] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp6] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp6Lbl] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp7] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp7Lbl] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp8] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneApp8Lbl] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdBadge1] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdBadge2] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneNav] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneBack] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneHome] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneRecent] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneSpeaker] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdPhoneNotch] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdAppHeader] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdAppTitle] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdAppScrollUp] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdAppScrollDn] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdAppBtn1] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdAppBtn2] = INVALID_PLAYER_TD;
    for(new i = 0; i < MAX_APP_LINES; i++)
        PhoneAppLines[playerid][i] = INVALID_PLAYER_TD;
}

// ============================================================================
// INPUT HANDLERS
// ============================================================================

stock HandlePhoneKey(playerid)
{
    if(!PlayerInfo[playerid][pLogged] || PlayerInfo[playerid][pIsDead]) return 0;
    if(PlayerInfo[playerid][pInvOpen]) return 0;
    if(PlayerInfo[playerid][pPhoneOpen])
    {
        new rpmsg[80];
        format(rpmsg, sizeof(rpmsg), "* %s menyimpan handphonenya.", PlayerInfo[playerid][pICName]);
        ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
        ClosePhone(playerid);
    }
    else
    {
        new rpmsg[80];
        format(rpmsg, sizeof(rpmsg), "* %s mengeluarkan handphonenya.", PlayerInfo[playerid][pICName]);
        ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
        OpenPhone(playerid);
    }
    return 1;
}

stock HandlePhoneClick(playerid, PlayerText:playertextid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    // Nav buttons
    if(playertextid == PlayerInfo[playerid][ptdPhoneBack])
        return PhoneGoBack(playerid);
    if(playertextid == PlayerInfo[playerid][ptdPhoneHome])
        return PhoneGoHome(playerid);
    if(playertextid == PlayerInfo[playerid][ptdPhoneRecent])
        return 1;

    // Home screen — app icons
    if(PlayerInfo[playerid][pPhoneScreen] == PHONE_SCREEN_HOME)
    {
        if(playertextid == PlayerInfo[playerid][ptdPhoneApp1])
            return OpenPhoneWA(playerid);
        if(playertextid == PlayerInfo[playerid][ptdPhoneApp2])
            return OpenPhoneTwitter(playerid);
        if(playertextid == PlayerInfo[playerid][ptdPhoneApp3])
            return OpenPhoneMarket(playerid);
        if(playertextid == PlayerInfo[playerid][ptdPhoneApp4])
            return OpenPhoneMBank(playerid);
        if(playertextid == PlayerInfo[playerid][ptdPhoneApp5])
            return OpenPhoneGPS(playerid);
        if(playertextid == PlayerInfo[playerid][ptdPhoneApp6])
            return OpenPhoneSettings(playerid);
        if(playertextid == PlayerInfo[playerid][ptdPhoneApp7])
            return OpenPhoneNotepad(playerid);
        return 0;
    }

    // In-app content lines
    for(new i = 0; i < MAX_APP_LINES; i++)
    {
        if(playertextid == PhoneAppLines[playerid][i])
            return HandleAppLineClick(playerid, i);
    }

    // Scroll & action buttons
    if(playertextid == PlayerInfo[playerid][ptdAppScrollUp])
        return HandleAppScrollUp(playerid);
    if(playertextid == PlayerInfo[playerid][ptdAppScrollDn])
        return HandleAppScrollDown(playerid);
    if(playertextid == PlayerInfo[playerid][ptdAppBtn1])
        return HandleAppBtn1Click(playerid);
    if(playertextid == PlayerInfo[playerid][ptdAppBtn2])
        return HandleAppBtn2Click(playerid);

    return 0;
}

stock HandlePhoneEsc(playerid)
{
    if(PlayerInfo[playerid][pPhoneOpen])
    {
        ClosePhone(playerid);
        return 1;
    }
    return 0;
}

// ============================================================================
// NAVIGATION
// ============================================================================

stock PhoneGoHome(playerid)
{
    ShowHomeScreen(playerid);
    SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    return 1;
}

stock PhoneGoBack(playerid)
{
    switch(PlayerInfo[playerid][pPhoneScreen])
    {
        case PHONE_SCREEN_HOME:
            ClosePhone(playerid);
        case PHONE_SCREEN_WA_MAIN, PHONE_SCREEN_TW_MAIN,
             PHONE_SCREEN_MK_MAIN, PHONE_SCREEN_MB_MAIN,
             PHONE_SCREEN_GPS_MAIN, PHONE_SCREEN_SETTINGS,
             PHONE_SCREEN_NOTEPAD, PHONE_SCREEN_TW_REGISTER:
            PhoneGoHome(playerid);
        case PHONE_SCREEN_WA_CHAT:
            OpenPhoneWA(playerid);
        case PHONE_SCREEN_TW_TL:
            OpenPhoneTwitter(playerid);
        case PHONE_SCREEN_TW_DETAIL:
            ShowTwitterTimelineScreen(playerid);
        case PHONE_SCREEN_NOTE_VIEW:
            OpenPhoneNotepad(playerid);
        case PHONE_SCREEN_MK_BROWSE, PHONE_SCREEN_MK_SELL, PHONE_SCREEN_MK_NPC, PHONE_SCREEN_MK_GOFOOD:
            OpenPhoneMarket(playerid);
        case PHONE_SCREEN_MK_GOFOOD_CART:
            ShowGoFoodScreen(playerid);
        case PHONE_SCREEN_MB_HISTORY:
            OpenPhoneMBank(playerid);
        default:
            PhoneGoHome(playerid);
    }
    return 1;
}

// ============================================================================
// APP LINE CLICK DISPATCH
// ============================================================================

stock HandleAppLineClick(playerid, lineIdx)
{
    switch(PlayerInfo[playerid][pPhoneScreen])
    {
        case PHONE_SCREEN_WA_MAIN: return HandleWALineClick(playerid, lineIdx);
        case PHONE_SCREEN_TW_MAIN: return HandleTwitterLineClick(playerid, lineIdx);
        case PHONE_SCREEN_TW_REGISTER: return HandleTwitterRegLineClick(playerid, lineIdx);
        case PHONE_SCREEN_TW_TL: return HandleTimelineLineClick(playerid, lineIdx);
        case PHONE_SCREEN_MK_MAIN: return HandleMarketLineClick(playerid, lineIdx);
        case PHONE_SCREEN_MK_BROWSE: return HandleMarketBrowseLineClick(playerid, lineIdx);
        case PHONE_SCREEN_MK_SELL: return HandleMarketSellLineClick(playerid, lineIdx);
        case PHONE_SCREEN_MK_NPC: return HandleMarketNPCLineClick(playerid, lineIdx);
        case PHONE_SCREEN_MK_GOFOOD: return HandleGoFoodLineClick(playerid, lineIdx);
        case PHONE_SCREEN_MK_GOFOOD_CART: return HandleGoFoodCartClick(playerid, lineIdx);
        case PHONE_SCREEN_MB_MAIN: return HandleMBankLineClick(playerid, lineIdx);
        case PHONE_SCREEN_GPS_MAIN: return HandleGPSLineClick(playerid, lineIdx);
        case PHONE_SCREEN_SETTINGS: return HandleSettingsLineClick(playerid, lineIdx);
        case PHONE_SCREEN_NOTEPAD: return HandleNotepadLineClick(playerid, lineIdx);
        case PHONE_SCREEN_TW_DETAIL: return 1;
        case PHONE_SCREEN_NOTE_VIEW: return 1;
    }
    return 0;
}

stock HandleAppScrollUp(playerid)
{
    if(PlayerInfo[playerid][pPhoneScrollPos] > 0)
    {
        PlayerInfo[playerid][pPhoneScrollPos]--;
        RefreshCurrentScreen(playerid);
    }
    return 1;
}

stock HandleAppScrollDown(playerid)
{
    PlayerInfo[playerid][pPhoneScrollPos]++;
    RefreshCurrentScreen(playerid);
    return 1;
}

stock HandleAppBtn1Click(playerid)
{
    switch(PlayerInfo[playerid][pPhoneScreen])
    {
        case PHONE_SCREEN_TW_MAIN:
        {
            ShowPlayerDialog(playerid, DIALOG_PHONE_TW_COMPOSE, DIALOG_STYLE_INPUT,
                "{1DA1F2}Wittiter - Post",
                "{FFFFFF}Tulis tweet kamu (maks 140 karakter):",
                "Post", "Batal");
        }
        case PHONE_SCREEN_WA_MAIN:
        {
            ShowWAAddContact(playerid);
        }
        case PHONE_SCREEN_WA_CHAT:
        {
            ShowPlayerDialog(playerid, DIALOG_PHONE_WA_SEND, DIALOG_STYLE_INPUT,
                "{25D366}WitApp - Kirim Pesan",
                "{FFFFFF}Ketik pesan:",
                "Kirim", "Batal");
        }
        case PHONE_SCREEN_NOTEPAD:
        {
            // New note
            PlayerInfo[playerid][pNotepadEditID] = -1;
            ShowPlayerDialog(playerid, DIALOG_PHONE_NOTEPAD_TITLE, DIALOG_STYLE_INPUT,
                "{FFC107}Notepad - Judul",
                "{FFFFFF}Masukkan judul catatan:",
                "Lanjut", "Batal");
        }
        case PHONE_SCREEN_TW_TL:
        {
            ShowPlayerDialog(playerid, DIALOG_PHONE_TW_COMPOSE, DIALOG_STYLE_INPUT,
                "{1DA1F2}Wittiter - Post",
                "{FFFFFF}Tulis tweet kamu (maks 140 karakter):",
                "Post", "Batal");
        }
        case PHONE_SCREEN_TW_DETAIL:
        {
            ShowPlayerDialog(playerid, DIALOG_PHONE_TW_COMMENT, DIALOG_STYLE_INPUT,
                "{1DA1F2}Wittiter - Komentar",
                "{FFFFFF}Tulis komentar (maks 100 karakter):",
                "Kirim", "Batal");
        }
    }
    return 1;
}

stock HandleAppBtn2Click(playerid)
{
    switch(PlayerInfo[playerid][pPhoneScreen])
    {
        case PHONE_SCREEN_WA_MAIN:
        {
            // Profil: show own phone number
            new msg[80];
            format(msg, sizeof(msg), "{25D366}[WitApp] {FFFFFF}Nomor HP kamu: {00FF00}%s", PlayerInfo[playerid][pPhoneNumber]);
            SendClientMessage(playerid, -1, msg);
            if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        }
        case PHONE_SCREEN_WA_CHAT:
        {
            // Panggil contact
            StartPhoneCall(playerid);
            if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        }
        case PHONE_SCREEN_NOTEPAD, PHONE_SCREEN_NOTE_VIEW:
        {
            HandleNotepadDelete(playerid);
        }
    }
    return 1;
}

// ============================================================================
// REFRESH CURRENT SCREEN (after scroll)
// ============================================================================

stock RefreshCurrentScreen(playerid)
{
    switch(PlayerInfo[playerid][pPhoneScreen])
    {
        case PHONE_SCREEN_WA_MAIN: ShowWAContactsList(playerid);
        case PHONE_SCREEN_WA_CHAT: RefreshWAChat(playerid);
        case PHONE_SCREEN_TW_TL: RefreshTwitterTL(playerid);
        case PHONE_SCREEN_MK_BROWSE: RefreshMarketBrowse(playerid);
        case PHONE_SCREEN_MK_SELL: ShowMarketSellList(playerid);
        case PHONE_SCREEN_MK_NPC: ShowNPCShopList(playerid);
        case PHONE_SCREEN_MK_GOFOOD: ShowGoFoodList(playerid);
        case PHONE_SCREEN_MK_GOFOOD_CART: ShowGoFoodCartScreen(playerid);
        case PHONE_SCREEN_MB_HISTORY: RefreshBankHistory(playerid);
        case PHONE_SCREEN_GPS_MAIN: RefreshGPSList(playerid);
        case PHONE_SCREEN_NOTEPAD: RefreshNotepadList(playerid);
    }
}

// ============================================================================
// TOAST NOTIFICATION SYSTEM
// ============================================================================

stock ShowPhoneToast(playerid, text[], color = 0x333333DD)
{
    // Kill existing toast
    if(PlayerInfo[playerid][pToastTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pToastTimer]);
        PlayerInfo[playerid][pToastTimer] = 0;
    }

    if(PlayerInfo[playerid][ptdToast] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdToast]);
        PlayerInfo[playerid][ptdToast] = INVALID_PLAYER_TD;
    }

    // Create toast at top-center of screen
    PlayerInfo[playerid][ptdToast] = CreatePlayerTextDraw(playerid, 320.0, 10.0, text);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdToast], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdToast], 2);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdToast], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdToast], color);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdToast], 20.0, 260.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdToast], 0.2, 1.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdToast], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdToast], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdToast]);

    PlayerInfo[playerid][pToastTimer] = SetTimerEx("OnToastExpire", 4000, false, "d", playerid);
}

publics: OnToastExpire(playerid)
{
    if(PlayerInfo[playerid][ptdToast] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdToast]);
        PlayerInfo[playerid][ptdToast] = INVALID_PLAYER_TD;
    }
    PlayerInfo[playerid][pToastTimer] = 0;
}

// ============================================================================
// BADGE SYSTEM
// ============================================================================

stock UpdateBadge(playerid, appIdx, count)
{
    if(appIdx == 1) PlayerInfo[playerid][pBadgeWA] = count;
    else if(appIdx == 2) PlayerInfo[playerid][pBadgeTW] = count;

    // If phone is open on home screen, refresh badge visual
    if(PlayerInfo[playerid][pPhoneOpen] && PlayerInfo[playerid][pPhoneScreen] == PHONE_SCREEN_HOME)
    {
        new PlayerText:badge = INVALID_PLAYER_TD;
        if(appIdx == 1) badge = PlayerInfo[playerid][ptdBadge1];
        else if(appIdx == 2) badge = PlayerInfo[playerid][ptdBadge2];

        if(badge != INVALID_PLAYER_TD)
        {
            if(count > 0)
            {
                new bstr[4];
                format(bstr, sizeof(bstr), "%d", count);
                PlayerTextDrawSetString(playerid, badge, bstr);
                PlayerTextDrawShow(playerid, badge);
            }
            else
            {
                PlayerTextDrawHide(playerid, badge);
            }
        }
    }
}

// ============================================================================
// GPS DISTANCE TRACKING + ARROW NAVIGATION
// ============================================================================

stock StartGPSTracking(playerid, Float:x, Float:y, Float:z, locName[])
{
    // Stop any existing tracking first
    if(PlayerInfo[playerid][pGPSActive]) StopGPSTracking(playerid);

    PlayerInfo[playerid][pGPSTargetX] = x;
    PlayerInfo[playerid][pGPSTargetY] = y;
    PlayerInfo[playerid][pGPSTargetZ] = z;
    strmid(PlayerInfo[playerid][pGPSTargetName], locName, 0, strlen(locName), 32);
    PlayerInfo[playerid][pGPSActive] = true;

    // Set map icon (red marker) at destination — icon 0 = white square, 32 = radar_centre, 19 = destination
    SetPlayerMapIcon(playerid, 99, x, y, z, 19, 0xFF0000FF, MAPICON_GLOBAL);
    PlayerInfo[playerid][pGPSMapIconID] = 99;

    // Create distance TD on screen (bottom-left above radar)
    if(PlayerInfo[playerid][ptdGPSDistance] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdGPSDistance]);

    PlayerInfo[playerid][ptdGPSDistance] = CreatePlayerTextDraw(playerid, 85.0, 300.0, "~r~GPS: ~w~...");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdGPSDistance], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdGPSDistance], 0.22, 1.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdGPSDistance], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdGPSDistance], 1);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdGPSDistance], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdGPSDistance]);

    // Create arrow TD — sprite directional arrow (ld_beat)
    if(PlayerInfo[playerid][ptdGPSArrow] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdGPSArrow]);

    PlayerInfo[playerid][ptdGPSArrow] = CreatePlayerTextDraw(playerid, 305.0, 355.0, "ld_beat:up");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdGPSArrow], 4); // Sprite font
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdGPSArrow], 30.0, 30.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdGPSArrow], 0xFF4444FF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdGPSArrow], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdGPSArrow]);

    // Start update timer
    if(PlayerInfo[playerid][pGPSTimer] != 0) KillTimer(PlayerInfo[playerid][pGPSTimer]);
    PlayerInfo[playerid][pGPSTimer] = SetTimerEx("OnGPSDistanceUpdate", GPS_UPDATE_INTERVAL, true, "d", playerid);
    OnGPSDistanceUpdate(playerid); // immediate first update
}

stock StopGPSTracking(playerid)
{
    PlayerInfo[playerid][pGPSActive] = false;
    if(PlayerInfo[playerid][pGPSTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pGPSTimer]);
        PlayerInfo[playerid][pGPSTimer] = 0;
    }
    if(PlayerInfo[playerid][ptdGPSDistance] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdGPSDistance]);
        PlayerInfo[playerid][ptdGPSDistance] = INVALID_PLAYER_TD;
    }
    if(PlayerInfo[playerid][ptdGPSArrow] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdGPSArrow]);
        PlayerInfo[playerid][ptdGPSArrow] = INVALID_PLAYER_TD;
    }
    RemovePlayerMapIcon(playerid, PlayerInfo[playerid][pGPSMapIconID]);
}

publics: OnGPSDistanceUpdate(playerid)
{
    if(!PlayerInfo[playerid][pGPSActive]) { StopGPSTracking(playerid); return 1; }
    if(!IsPlayerConnected(playerid)) return 1;

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new Float:dx = PlayerInfo[playerid][pGPSTargetX] - px;
    new Float:dy = PlayerInfo[playerid][pGPSTargetY] - py;
    new Float:dist = floatsqroot(dx*dx + dy*dy);

    // Auto-arrive if very close
    if(dist < 5.0)
    {
        HandleGPSCheckpointReached(playerid);
        return 1;
    }

    // Update distance text
    new gpstxt[64];
    if(dist >= 1000.0)
        format(gpstxt, sizeof(gpstxt), "~r~GPS: ~w~%s ~y~%.1fkm", PlayerInfo[playerid][pGPSTargetName], dist / 1000.0);
    else
        format(gpstxt, sizeof(gpstxt), "~r~GPS: ~w~%s ~y~%dm", PlayerInfo[playerid][pGPSTargetName], floatround(dist));

    if(PlayerInfo[playerid][ptdGPSDistance] != INVALID_PLAYER_TD)
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdGPSDistance], gpstxt);

    // Update arrow direction relative to player heading
    new Float:angle = atan2(dy, dx); // math angle: 0=East(+X), 90=North(+Y), CCW
    angle = angle - 90.0; // convert to SA-MP heading: 0=North, 90=West, CCW
    if(angle < 0.0) angle += 360.0;
    if(angle >= 360.0) angle -= 360.0;

    new Float:heading;
    GetPlayerFacingAngle(playerid, heading);

    new Float:relAngle = angle - heading;
    if(relAngle < 0.0) relAngle += 360.0;
    if(relAngle >= 360.0) relAngle -= 360.0;

    // Choose sprite based on relative angle (4 cardinal directions)
    // SA-MP CCW: 0=forward, 90=left, 180=back, 270=right
    new spriteStr[20];
    if(relAngle >= 315.0 || relAngle < 45.0)
        spriteStr = "ld_beat:up";       // Forward
    else if(relAngle >= 45.0 && relAngle < 135.0)
        spriteStr = "ld_beat:left";     // Left
    else if(relAngle >= 135.0 && relAngle < 225.0)
        spriteStr = "ld_beat:down";     // Backward
    else
        spriteStr = "ld_beat:right";    // Right

    // Recreate sprite TD with correct directional arrow
    if(PlayerInfo[playerid][ptdGPSArrow] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdGPSArrow]);
        PlayerInfo[playerid][ptdGPSArrow] = INVALID_PLAYER_TD;
    }
    PlayerInfo[playerid][ptdGPSArrow] = CreatePlayerTextDraw(playerid, 305.0, 355.0, spriteStr);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdGPSArrow], 4);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdGPSArrow], 30.0, 30.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdGPSArrow], 0xFF4444FF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdGPSArrow], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdGPSArrow]);

    return 1;
}

stock HandleGPSCheckpointReached(playerid)
{
    if(!PlayerInfo[playerid][pGPSActive]) return 0;

    new msg[64];
    format(msg, sizeof(msg), "[GPS] Kamu sudah sampai di %s!", PlayerInfo[playerid][pGPSTargetName]);
    SendClientFormattedMessage(playerid, 0xF44336FF, msg);
    ShowPhoneToast(playerid, "~g~Sampai di tujuan!", 0x4CAF50DD);
    StopGPSTracking(playerid);
    return 1;
}

// ============================================================================
// COMMAND
// ============================================================================

COMMAND:hp(playerid, params[])
{
    HandlePhoneKey(playerid);
    return true;
}
