// ============================================================================
// MODULE: phone_gps.pwn
// GPS App — Shows list of locations, sets checkpoint on selection
// ============================================================================

stock OpenPhoneGPS(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    if(!UseKuota(playerid, KUOTA_PER_ACTION))
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kuota habis! Beli kuota di M-Bank.");
        return 0;
    }

    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_GPS;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_GPS_MAIN;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0xB71C1CDD, "~r~GPS");
    HideAppBtns(playerid);

    new totalLocs = sizeof(GPSLocations);
    new maxShow = 7;
    if(totalLocs < maxShow) maxShow = totalLocs;

    for(new i = 0; i < maxShow; i++)
    {
        new line[64];
        format(line, sizeof(line), "~r~> ~w~%s", GPSLocations[i][gpsName]);
        SetAppLine(playerid, i, line);
    }
    for(new i = maxShow; i < 7; i++)
    {
        HideAppLine(playerid, i);
    }

    new canDown = (totalLocs > 7) ? true : false;
    ShowAppScroll(playerid, false, canDown);
    return 1;
}

stock RefreshGPSList(playerid)
{
    new scrollPos = PlayerInfo[playerid][pPhoneScrollPos];
    new totalLocs = sizeof(GPSLocations);

    for(new i = 0; i < 7; i++)
    {
        new idx = scrollPos + i;
        if(idx < totalLocs)
        {
            new line[64];
            format(line, sizeof(line), "~r~> ~w~%s", GPSLocations[idx][gpsName]);
            SetAppLine(playerid, i, line);
        }
        else
        {
            HideAppLine(playerid, i);
        }
    }

    new canUp = (scrollPos > 0) ? true : false;
    new canDown = (scrollPos + 7 < totalLocs) ? true : false;
    ShowAppScroll(playerid, canUp, canDown);
}

stock HandleGPSLineClick(playerid, lineIdx)
{
    new scrollPos = PlayerInfo[playerid][pPhoneScrollPos];
    new locIdx = scrollPos + lineIdx;
    new totalLocs = sizeof(GPSLocations);

    if(locIdx < 0 || locIdx >= totalLocs) return 1;

    // Use GPS tracking system with distance display
    new locname[32];
    strmid(locname, GPSLocations[locIdx][gpsName], 0, strlen(GPSLocations[locIdx][gpsName]), 32);
    StartGPSTracking(playerid,
        GPSLocations[locIdx][gpsX],
        GPSLocations[locIdx][gpsY],
        GPSLocations[locIdx][gpsZ],
        locname);

    SendClientFormattedMessage(playerid, 0xF44336FF, "[GPS] Menuju %s... Ikuti arah panah di layar.", GPSLocations[locIdx][gpsName]);

    // Auto RP
    new rpmsg[80];
    format(rpmsg, sizeof(rpmsg), "* %s melihat GPS di handphonenya.", PlayerInfo[playerid][pICName]);
    ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    // Close phone after setting GPS
    ClosePhone(playerid);
    return 1;
}
