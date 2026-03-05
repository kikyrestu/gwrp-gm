// ============================================================================
// MODULE: phone_settings.pwn
// Settings App — Displays phone info (number, kuota, about)
// ============================================================================

stock OpenPhoneSettings(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_SETTINGS;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_SETTINGS;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0x37474FDD, "~w~Setelan");
    HideAppBtns(playerid);

    // Line 0: Phone number
    new numline[48];
    format(numline, sizeof(numline), "~w~Nomor HP: ~g~%s", PlayerInfo[playerid][pPhoneNumber]);
    SetAppLine(playerid, 0, numline);

    // Line 1: Kuota
    new kuotaStr[16];
    FormatKuota(PlayerInfo[playerid][pKuota], kuotaStr, sizeof(kuotaStr));
    new kuotaline[48];
    format(kuotaline, sizeof(kuotaline), "~w~Kuota Internet: ~g~%s", kuotaStr);
    SetAppLine(playerid, 1, kuotaline);

    // Line 2: Bank account
    new bankline[48];
    if(strlen(PlayerInfo[playerid][pBankAccount]) > 0)
        format(bankline, sizeof(bankline), "~w~Rek. Bank: ~y~%s", PlayerInfo[playerid][pBankAccount]);
    else
        format(bankline, sizeof(bankline), "~w~Rek. Bank: ~r~Belum ada");
    SetAppLine(playerid, 2, bankline);

    // Line 3: IC Name
    new nameline[48];
    format(nameline, sizeof(nameline), "~w~Pemilik: ~y~%s", PlayerInfo[playerid][pICName]);
    SetAppLine(playerid, 3, nameline);

    // Line 4: About
    SetAppLine(playerid, 4, "~w~Tentang HP");

    // Hide unused lines
    HideAppLine(playerid, 5);
    HideAppLine(playerid, 6);

    ShowAppScroll(playerid, false, false);
    return 1;
}

stock HandleSettingsLineClick(playerid, lineIdx)
{
    switch(lineIdx)
    {
        case 0, 1, 2, 3: return 1; // Info only, not actionable
        case 4: // Tentang HP
        {
            SendClientFormattedMessage(playerid, 0x607D8BFF, "[Setelan] Westfield Phone v1.0 - SA-MP DL");
            if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        }
    }
    return 1;
}
