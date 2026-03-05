// ============================================================================
// MODULE: utils.pwn
// Utility functions: chat, kick, anim, proximity, formatted message, money
// ============================================================================

stock PlayerClearChat(playerid, size) for(new s; s < size; s++) SendClientFormattedMessage(playerid, -1, " ");

stock PlayerKick(i) return SetTimerEx("KickFix", 250, false, "d", i);
publics: KickFix(i)
{
    SendClientFormattedMessage(i, -1, "Untuk keluar dari game gunakan perintah /q(uit)");
    Kick(i);
    return true;
}

stock PlayerUpdateMoney(playerid)
{
    // Always hide default $ HUD — we use custom Rp TextDraw
    if(GetPlayerMoney(playerid) != 0)
    {
        ResetPlayerMoney(playerid);
    }
    return true;
}

stock ApplyAnim(playerid,name[],anim[],Float:speed,p,p2,p3,p4,p5,p6 = 0)
{
    if(!IsPlayerInAnyVehicle(playerid)) ApplyAnimation(playerid,name,anim,speed,p,p2,p3,p4,p5,p6);
    return true;
}
publics: ClearAnim(playerid) return ApplyAnimation(playerid, "CARRY", "crry_prtial",4.0,0,0,0,0,0,1);

stock ProxDetector(Float:radi, playerid, string[],col1,col2,col3,col4,col5)
{
    new Float:posx, Float:posy, Float:posz;
    new Float:oldposx, Float:oldposy, Float:oldposz;
    new Float:tempposx, Float:tempposy, Float:tempposz;
    GetPlayerPos(playerid, oldposx, oldposy, oldposz);
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            GetPlayerPos(i, posx, posy, posz);
            tempposx = (oldposx -posx);
            tempposy = (oldposy -posy);
            tempposz = (oldposz -posz);
            if(GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i))
            {
                if (((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16))) SendClientMessage(i, col1, string);
                else if (((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8)))SendClientMessage(i, col2, string);
                else if (((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4)))SendClientMessage(i, col3, string);
                else if (((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2)))SendClientMessage(i, col4, string);
                else if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)))SendClientMessage(i, col5, string);
            }
        }
    }
    return 1;
}

// ============================================================================
// FORMATTED MESSAGE
// ============================================================================

SendClientFormattedMessage(playerid, color, fstring[], {Float, _}:...)
{
    static const
        STATIC_ARGS = 3;
    new
        n = (numargs() - STATIC_ARGS) * BYTES_PER_CELL;
    if (n)
    {
        new
            message[144],
            arg_start,
            arg_end;
        #emit CONST.alt        fstring
        #emit LCTRL          5
        #emit ADD
        #emit STOR.S.pri        arg_start

        #emit LOAD.S.alt        n
        #emit ADD
        #emit STOR.S.pri        arg_end
        do
        {
            #emit LOAD.I
            #emit PUSH.pri
            arg_end -= BYTES_PER_CELL;
            #emit LOAD.S.pri      arg_end
        }
        while (arg_end > arg_start);

        #emit PUSH.S          fstring
        #emit PUSH.C          128
        #emit PUSH.ADR         message

        n += BYTES_PER_CELL * 3;
        #emit PUSH.S          n
        #emit SYSREQ.C         format

        n += BYTES_PER_CELL;
        #emit LCTRL          4
        #emit LOAD.S.alt        n
        #emit ADD
        #emit SCTRL          4

        return SendClientMessage(playerid, color, message);
    }
    else
    {
        return SendClientMessage(playerid, color, fstring);
    }
}

stock GetCitySpawn(city, spawntype, &Float:x, &Float:y, &Float:z, &Float:angle)
{
    if(spawntype < 0 || spawntype > 2) spawntype = 0;
    switch(city)
    {
        case CITY_MEKAR_PURA:
        {
            x = SpawnMekarPura[spawntype][0];
            y = SpawnMekarPura[spawntype][1];
            z = SpawnMekarPura[spawntype][2];
            angle = SpawnMekarPura[spawntype][3];
        }
        case CITY_MADYA_RAYA:
        {
            x = SpawnMadyaRaya[spawntype][0];
            y = SpawnMadyaRaya[spawntype][1];
            z = SpawnMadyaRaya[spawntype][2];
            angle = SpawnMadyaRaya[spawntype][3];
        }
        case CITY_MOJOSONO:
        {
            x = SpawnMojosono[spawntype][0];
            y = SpawnMojosono[spawntype][1];
            z = SpawnMojosono[spawntype][2];
            angle = SpawnMojosono[spawntype][3];
        }
        default:
        {
            x = SpawnMekarPura[spawntype][0];
            y = SpawnMekarPura[spawntype][1];
            z = SpawnMekarPura[spawntype][2];
            angle = SpawnMekarPura[spawntype][3];
        }
    }
}

stock ShowMaleSkinDialog(playerid)
{
    new skinlist[512];
    for(new i = 0; i < sizeof(MaleSkins); i++)
    {
        new tmp[32];
        format(tmp, sizeof(tmp), "Skin Laki-laki #%d (ID: %d)\n", i+1, MaleSkins[i]);
        strcat(skinlist, tmp);
    }
    ShowPlayerDialog(playerid, dRegSkinMale, DIALOG_STYLE_LIST, "{FFFFFF}Registrasi - Pilih Skin", skinlist, "Pilih", "Batal");
}

stock ShowFemaleSkinDialog(playerid)
{
    new skinlist[512];
    for(new i = 0; i < sizeof(FemaleSkins); i++)
    {
        new tmp[32];
        format(tmp, sizeof(tmp), "Skin Perempuan #%d (ID: %d)\n", i+1, FemaleSkins[i]);
        strcat(skinlist, tmp);
    }
    ShowPlayerDialog(playerid, dRegSkinFemale, DIALOG_STYLE_LIST, "{FFFFFF}Registrasi - Pilih Skin", skinlist, "Pilih", "Batal");
}

stock ShowCityDialog(playerid)
{
    ShowPlayerDialog(playerid, dRegCity, DIALOG_STYLE_LIST, "{FFFFFF}Registrasi - Pilih Kota Spawn",
        "Mekar Pura (Los Santos)\nMadya Raya (Las Venturas)\nMojosono (San Fierro)",
        "Pilih", "Batal");
}

stock ShowSpawnLocationDialog(playerid)
{
    new cityname[32];
    switch(TempInfo[playerid][pRegCity])
    {
        case CITY_MEKAR_PURA: format(cityname, sizeof(cityname), "Mekar Pura");
        case CITY_MADYA_RAYA: format(cityname, sizeof(cityname), "Madya Raya");
        case CITY_MOJOSONO: format(cityname, sizeof(cityname), "Mojosono");
        default: format(cityname, sizeof(cityname), "Mekar Pura");
    }
    new liststr[256];
    format(liststr, sizeof(liststr), "Terminal Bus %s\nBandara %s\nStasiun Kereta %s", cityname, cityname, cityname);
    ShowPlayerDialog(playerid, dRegSpawn, DIALOG_STYLE_LIST, "{FFFFFF}Registrasi - Lokasi Spawn", liststr, "Pilih", "Kembali");
}

stock ResetPlayerInfo(playerid)
{
    PlayerInfo[playerid][pLogged] = false;
    PlayerInfo[playerid][pID] = INVALID_PLAYER_DATA;
    PlayerInfo[playerid][pName][0] = EOS;
    PlayerInfo[playerid][pICName][0] = EOS;
    PlayerInfo[playerid][pICAge] = 0;
    PlayerInfo[playerid][pRegDate] = INVALID_PLAYER_DATA;
    PlayerInfo[playerid][pRegIP][0] = EOS;
    PlayerInfo[playerid][pLastDate] = INVALID_PLAYER_DATA;
    PlayerInfo[playerid][pLastIP][0] = EOS;
    PlayerInfo[playerid][pRegistered] = INVALID_PLAYER_DATA;
    PlayerInfo[playerid][pGender] = INVALID_PLAYER_DATA;
    PlayerInfo[playerid][pLevel] = INVALID_PLAYER_DATA;
    PlayerInfo[playerid][pMoney] = INVALID_PLAYER_DATA;
    PlayerInfo[playerid][pSkin] = INVALID_PLAYER_DATA;
    PlayerInfo[playerid][pLastX] = 0.0;
    PlayerInfo[playerid][pLastY] = 0.0;
    PlayerInfo[playerid][pLastZ] = 0.0;
    PlayerInfo[playerid][pLastAngle] = 0.0;
    PlayerInfo[playerid][pLastInterior] = 0;
    PlayerInfo[playerid][pLastVW] = 0;
    PlayerInfo[playerid][pIsDead] = false;
    PlayerInfo[playerid][pDeathTick] = 0;
    PlayerInfo[playerid][pDeathTimer] = 0;
    PlayerInfo[playerid][pHunger] = 100;
    PlayerInfo[playerid][pThirst] = 100;
    PlayerInfo[playerid][pHungerTimer] = 0;
    PlayerInfo[playerid][pThirstTimer] = 0;
    PlayerInfo[playerid][pHudCreated] = false;
    PlayerInfo[playerid][ptdThirstIcon] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdThirstBG] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdThirstBar] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdThirstPct] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdHungerIcon] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdHungerBG] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdHungerBar] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdHungerPct] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdMoneyText] = INVALID_PLAYER_TD;

    // Inventory
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
    {
        PlayerInfo[playerid][pInvItems][i] = ITEM_NONE;
        PlayerInfo[playerid][pInvAmounts][i] = 0;
    }
    PlayerInfo[playerid][pHasTas] = false;
    PlayerInfo[playerid][pInvOpen] = false;
    PlayerInfo[playerid][pInvSelected] = -1;

    // Phone
    PlayerInfo[playerid][pPhoneOpen] = false;
    PlayerInfo[playerid][pPhoneApp] = 0;
    PlayerInfo[playerid][pPhoneNumber][0] = EOS;
    PlayerInfo[playerid][pPhoneContactCount] = 0;
    for(new i = 0; i < MAX_CONTACTS; i++)
    {
        PlayerInfo[playerid][pPhoneContacts][i] = INVALID_PLAYER_ID;
        PhoneContactNames[playerid][i][0] = EOS;
    }
    PlayerInfo[playerid][ptdPhoneFrame] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneBG] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneStatus] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneStatusTxt] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneWallpaper] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneTitle] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp1] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp1Lbl] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp2] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp2Lbl] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp3] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp3Lbl] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp4] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp4Lbl] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp5] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp5Lbl] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp6] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp6Lbl] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp7] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp7Lbl] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp8] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneApp8Lbl] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdBadge1] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdBadge2] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneNav] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneHome] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneSpeaker] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneNotch] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneBack] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdPhoneRecent] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdAppHeader] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdAppTitle] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdAppScrollUp] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdAppScrollDn] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdAppBtn1] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdAppBtn2] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_HOME;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;
    PlayerInfo[playerid][pPhoneChatContact] = 0;
    for(new j = 0; j < MAX_APP_LINES; j++)
        PhoneAppLines[playerid][j] = PlayerText:INVALID_TEXT_DRAW;

    // Bank
    PlayerInfo[playerid][pBank] = 0;
    PlayerInfo[playerid][pBankAccount][0] = EOS;

    // Kuota
    PlayerInfo[playerid][pKuota] = KUOTA_DEFAULT;
    PlayerInfo[playerid][pKuotaTimer] = 0;

    // Toast & Badge
    PlayerInfo[playerid][ptdToast] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][pToastTimer] = 0;
    PlayerInfo[playerid][pBadgeWA] = 0;
    PlayerInfo[playerid][pBadgeTW] = 0;

    // GPS Tracking
    PlayerInfo[playerid][ptdGPSDistance] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdGPSArrow] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][pGPSMapIconID] = 0;
    PlayerInfo[playerid][pGPSTimer] = 0;
    PlayerInfo[playerid][pGPSActive] = false;
    PlayerInfo[playerid][pGPSTargetX] = 0.0;
    PlayerInfo[playerid][pGPSTargetY] = 0.0;
    PlayerInfo[playerid][pGPSTargetZ] = 0.0;
    PlayerInfo[playerid][pGPSTargetName][0] = EOS;

    // Twitter
    PlayerInfo[playerid][pTwitterID] = 0;
    PlayerInfo[playerid][pTwitterUser][0] = EOS;

    // Notepad
    PlayerInfo[playerid][pNotepadEditID] = -1;
    PlayerInfo[playerid][pNotepadTempTitle][0] = EOS;
    PlayerInfo[playerid][pTempTweetID] = 0;

    // Wallet
    PlayerInfo[playerid][pWalletOpen] = false;
    PlayerInfo[playerid][pWalletSelected] = -1;
    PlayerInfo[playerid][pWalletShowTarget] = INVALID_PLAYER_ID;

    // AME
    PlayerInfo[playerid][pAMELabel] = Text3D:INVALID_3DTEXT_ID;
    PlayerInfo[playerid][pAMETimer] = 0;

    // KTP
    PlayerInfo[playerid][pHasKTP] = false;
    PlayerInfo[playerid][pKTPNIK][0] = EOS;
    PlayerInfo[playerid][pKTPFullName][0] = EOS;
    PlayerInfo[playerid][pBirthPlace][0] = EOS;
    PlayerInfo[playerid][pAddress][0] = EOS;
    PlayerInfo[playerid][pMaritalStatus][0] = EOS;
    PlayerInfo[playerid][pOccupation][0] = EOS;
    PlayerInfo[playerid][pBloodType][0] = EOS;

    // SIM
    PlayerInfo[playerid][pHasSIMA] = false;
    PlayerInfo[playerid][pHasSIMB] = false;
    PlayerInfo[playerid][pHasSIMC] = false;
    PlayerInfo[playerid][pSIMNumber][0] = EOS;
    PlayerInfo[playerid][pSIMQuizScore] = 0;
    PlayerInfo[playerid][pSIMQuizQuestion] = 0;
    PlayerInfo[playerid][pSIMQuizType] = 0;

    // Go Food
    ResetGoFoodData(playerid);

    // Admin
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pMuted] = false;
    PlayerInfo[playerid][pFrozen] = false;
    PlayerInfo[playerid][pJailed] = false;
    PlayerInfo[playerid][pJailTimer] = 0;
    PlayerInfo[playerid][pAdminDuty] = false;
    PlayerInfo[playerid][pSpecMode] = false;
    PlayerInfo[playerid][pSpecTarget] = INVALID_PLAYER_ID;

    // Temp
    PlayerInfo[playerid][pTempTarget] = INVALID_PLAYER_ID;
    PlayerInfo[playerid][pTempListingSlot] = -1;
    TempContactName[playerid][0] = EOS;

    TempInfo[playerid][pRegPassword][0] = EOS;
    TempInfo[playerid][pRegICName][0] = EOS;
    TempInfo[playerid][pRegICAge] = 0;
    TempInfo[playerid][pRegGender] = 0;
    TempInfo[playerid][pRegSkin] = 0;
    TempInfo[playerid][pRegCity] = 0;
    TempInfo[playerid][pRegSpawn] = 0;
    return true;
}
